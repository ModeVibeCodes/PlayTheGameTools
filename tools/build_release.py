"""Build the standalone Forever addon; never install or publish it."""
from pathlib import Path, PurePosixPath
import hashlib
import io
import re
import zipfile

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / 'ModeTools'
DOCUMENTS = ('README.md', 'CHANGELOG.md', 'LICENSE', 'THIRD_PARTY_NOTICES.md', 'TESTING.md')
MEDIA = {'.tga', '.blp', '.png', '.jpg', '.jpeg', '.ogg', '.mp3', '.wav', '.ttf', '.otf'}


def ordinary(path):
    for p in (path, *path.parents):
        if p.exists() and (p.is_symlink() or getattr(p.lstat(), 'st_file_attributes', 0) & 0x400):
            raise ValueError(f'Refusing link/reparse point: {p}')


def source_path(name):
    if '\\' in name or ':' in name or any(ord(c) < 32 for c in name):
        raise ValueError(f'Unsafe path: {name}')
    if PurePosixPath(name).is_absolute() or any(p in ('', '.', '..') for p in name.split('/')):
        raise ValueError(f'Unsafe path: {name}')
    path = ADDON / name
    ordinary(path)
    return path


def payload():
    ordinary(ADDON)
    toc = (ADDON / 'ModeTools.toc').read_text(encoding='utf-8-sig')
    for field in ('## Interface: 16001', '## Title: Play The Game Tools',
                  '## X-ModeTools-Edition: Forever', '## SavedVariables: ModeToolsDB'):
        if field not in toc.splitlines():
            raise ValueError(f'Missing Forever identity: {field}')
    order = [s.strip().replace('\\', '/') for s in toc.splitlines() if s.strip() and not s.lstrip().startswith('#')]
    if len(order) != len(set(order)) or order[0] != 'Core/Edition.lua' or order[-2:] != ['Core/Init.lua', 'Core/ReleaseMetadata.lua']:
        raise ValueError('Invalid TOC order or duplicate entries')
    for name in order:
        if not re.fullmatch(r'(?:Core|Config|Modules)/.+\.lua', name):
            raise ValueError(f'Unsupported runtime source: {name}')
    files = {'ModeTools.toc': (ADDON / 'ModeTools.toc').read_bytes()}
    files.update({name: source_path(name).read_bytes() for name in order})
    for path in (ADDON / 'Media').rglob('*'):
        ordinary(path)
        if path.is_file():
            if path.suffix.lower() not in MEDIA:
                raise ValueError(f'Non-runtime media: {path}')
            files[path.relative_to(ADDON).as_posix()] = path.read_bytes()
    actual_lua = {p.relative_to(ADDON).as_posix() for p in ADDON.rglob('*.lua')}
    if actual_lua != set(order):
        raise ValueError('Lua source inventory differs from TOC')
    for name in DOCUMENTS:
        files[name] = (ROOT / name).read_bytes()
    return files, order, toc


def archive_bytes(files):
    buffer = io.BytesIO()
    with zipfile.ZipFile(buffer, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for name, data in sorted(files.items()):
            info = zipfile.ZipInfo('ModeTools/' + name, (2026, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.create_system = 3
            info.external_attr = 0o100644 << 16
            archive.writestr(info, data, compresslevel=9)
    return buffer.getvalue()


def main():
    files, order, toc = payload()
    version = re.search(r'^## Version: ([A-Za-z0-9.+-]+)$', toc, re.M)
    if not version:
        raise ValueError('Missing valid version')
    target = ROOT / 'dist' / f'PlayTheGameTools-{version[1]}-forever.zip'
    ordinary(target)
    data = archive_bytes(files)
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        assert sorted(archive.namelist()) == sorted('ModeTools/' + n for n in files)
        assert all(archive.read('ModeTools/' + n) == d for n, d in files.items())
    if target.exists() and target.read_bytes() != data:
        raise ValueError('Different artifact already exists; preserve it or bump the version')
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(data)
    checksum = hashlib.sha256(data).hexdigest()
    target.with_suffix('.zip.sha256').write_text(f'{checksum}  {target.name}\n', encoding='ascii')
    print(f'PASS {len(order)} Lua / {len(files)} package files: {target.name}')
    print(f'SHA256 {checksum}')


if __name__ == '__main__':
    main()
