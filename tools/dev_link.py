"""Point the local Forever client's AddOns/PlayTheGameTools at a checkout.

Owner-machine development helper (see docs/DEVELOPMENT.md, "Local /reload
testing"). It replaces only the AddOns/PlayTheGameTools *link* with a Windows
directory junction to a checkout's PlayTheGameTools folder, so source edits are
read on the next /reload. It never copies files, never deletes a real folder and
never touches WTF/SavedVariables.

    python tools/dev_link.py status
    python tools/dev_link.py link                  # this checkout
    python tools/dev_link.py link --source <path>  # another checkout or addon folder

The AddOns directory is taken from --addons, then the PTG_FOREVER_ADDONS
environment variable, then the standard "World of Warcraft/_forever_" location
on each drive.
"""
from pathlib import Path
import argparse
import os
import string
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
NAME = 'PlayTheGameTools'
TOC = NAME + '.toc'
REPARSE = 0x400
INSTALL_DIRS = ('World of Warcraft', 'Program Files (x86)/World of Warcraft',
                'Program Files/World of Warcraft', 'Games/World of Warcraft')


def fail(message):
    print('error: ' + message, file=sys.stderr)
    sys.exit(1)


def is_link(path):
    try:
        st = os.lstat(path)
    except FileNotFoundError:
        return False
    return path.is_symlink() or bool(getattr(st, 'st_file_attributes', 0) & REPARSE)


def link_target(path):
    try:
        return Path(os.readlink(path))
    except OSError:
        return None


def clean(path):
    text = str(path)
    for prefix in ('\\\\?\\', '\\??\\'):
        if text.startswith(prefix):
            text = text[len(prefix):]
    return Path(text)


def find_addons(explicit):
    if explicit:
        return Path(explicit)
    if os.environ.get('PTG_FOREVER_ADDONS'):
        return Path(os.environ['PTG_FOREVER_ADDONS'])
    found = []
    for letter in string.ascii_uppercase:
        drive = Path(letter + ':/')
        if not drive.exists():
            continue
        for rel in INSTALL_DIRS:
            addons = drive / rel / '_forever_' / 'Interface' / 'AddOns'
            if addons.is_dir():
                found.append(addons)
    if len(found) == 1:
        return found[0]
    if not found:
        fail('no Forever AddOns directory found; pass --addons or set PTG_FOREVER_ADDONS')
    fail('several Forever AddOns directories found; pass --addons:\n  '
         + '\n  '.join(map(str, found)))


def addon_folder(source):
    source = Path(source).resolve()
    if (source / TOC).is_file():
        return source
    if (source / NAME / TOC).is_file():
        return (source / NAME).resolve()
    fail(f'{source} holds neither {TOC} nor {NAME}/{TOC}')


def git(folder, *args):
    try:
        out = subprocess.run(['git', '-C', str(folder), *args], capture_output=True,
                             text=True, timeout=20)
    except (OSError, subprocess.TimeoutExpired):
        return None
    return out.stdout.strip() if out.returncode == 0 else None


def describe(folder):
    if not folder.is_dir():
        return 'MISSING (dangling link: the checkout was moved or deleted)'
    branch = git(folder, 'rev-parse', '--abbrev-ref', 'HEAD')
    if branch is None:
        return 'not a Git checkout'
    head = git(folder, 'log', '-1', '--format=%h %s') or '?'
    dirty = git(folder, 'status', '--porcelain', '--', '.')
    state = f'{len(dirty.splitlines())} uncommitted path(s)' if dirty else 'clean'
    return f'branch {branch} @ {head} ({state})'


def toc_text(folder):
    try:
        return (folder / TOC).read_text(encoding='utf-8-sig').replace('\r\n', '\n')
    except OSError:
        return None


def client_running():
    if os.name != 'nt':
        return False
    try:
        out = subprocess.run(['tasklist', '/FI', 'IMAGENAME eq Wow.exe', '/NH'],
                             capture_output=True, text=True, timeout=20).stdout
    except (OSError, subprocess.TimeoutExpired):
        return False
    return 'wow.exe' in out.lower()


def status(addons):
    dest = addons / NAME
    print(f'AddOns:  {addons}')
    if not os.path.lexists(dest):
        print(f'{NAME}: not installed')
        return
    if not is_link(dest):
        print(f'{NAME}: a real folder (copied install), not a link')
        return
    target = clean(link_target(dest) or '?')
    print(f'{NAME} -> {target}')
    print(f'Source:  {describe(target)}')


def make_junction(source, dest):
    try:
        import _winapi
        _winapi.CreateJunction(str(source), str(dest))
        return
    except (ImportError, AttributeError):
        pass
    except OSError as err:
        fail(f'could not create the junction: {err}')
    out = subprocess.run(['cmd', '/c', 'mklink', '/J', str(dest), str(source)],
                         capture_output=True, text=True)
    if out.returncode != 0:
        fail('mklink failed: ' + (out.stderr or out.stdout).strip())


def link(addons, source):
    if os.name != 'nt':
        fail('link uses Windows directory junctions; run it on the Windows client machine')
    if not addons.is_dir():
        fail(f'{addons} is not a directory')
    source = addon_folder(source)
    dest = addons / NAME
    if os.path.normcase(str(source)).startswith(os.path.normcase(str(addons.resolve())) + os.sep):
        fail(f'{source} is inside the AddOns directory; pass the checkout itself')
    old = None
    if os.path.lexists(dest):
        if not is_link(dest):
            fail(f'{dest} is a real folder; move it out of AddOns yourself first '
                 '(it is never deleted by this tool)')
        old = clean(link_target(dest) or '')
        if old and os.path.normcase(str(old.resolve())) == os.path.normcase(str(source)):
            print(f'{NAME} already -> {source}')
            print(f'Source:  {describe(source)}')
            return
        os.rmdir(dest) if not dest.is_symlink() else os.unlink(dest)
    make_junction(source, dest)
    print(f'{NAME} -> {source}')
    print(f'Source:  {describe(source)}')
    if old:
        print(f'Was:     {old}')
        print(f'Undo:    python tools/dev_link.py link --source "{old}"')
    if client_running():
        if old is None or toc_text(old) != toc_text(source):
            print('The TOC differs from what the running client loaded: exit the game '
                  'fully and start it again (a /reload does not pick up TOC changes).')
        else:
            print('Same TOC as before: type /reload in game (out of combat).')
    else:
        print('Start the game; afterwards edits load with /reload.')


def main():
    parser = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    parser.add_argument('command', choices=('status', 'link'))
    parser.add_argument('--addons', help='Forever Interface/AddOns directory')
    parser.add_argument('--source', default=str(ROOT),
                        help='checkout root or addon folder to load (default: this checkout)')
    args = parser.parse_args()
    addons = find_addons(args.addons)
    if args.command == 'status':
        status(addons)
    else:
        link(addons, args.source)


if __name__ == '__main__':
    main()
