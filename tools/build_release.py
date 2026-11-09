"""Build the standalone Forever addon; never install or publish it."""
from pathlib import Path, PurePosixPath
import hashlib
import io
import re
import zipfile
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / 'PlayTheGameTools'
DOCUMENTS = ('README.md', 'CHANGELOG.md', 'LICENSE', 'THIRD_PARTY_NOTICES.md', 'TESTING.md', 'CATALOG_SOURCES.md', 'LICENSES/GPL-3.0.txt', 'LICENSES/LGPL-2.1.txt', 'LICENSES/CallbackHandler-BSD.txt', 'LICENSES/JetBrainsMono-OFL.txt')
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
    toc = (ADDON / 'PlayTheGameTools.toc').read_text(encoding='utf-8-sig')
    for field in ('## Interface: 16001', '## Title: Play The Game Tools',
                  '## X-PlayTheGameTools-Edition: Forever', '## SavedVariables: PTGToolsDB, ModeToolsDB'):
        if field not in toc.splitlines():
            raise ValueError(f'Missing Forever identity: {field}')
    order = [s.strip().replace('\\', '/') for s in toc.splitlines() if s.strip() and not s.lstrip().startswith('#')]
    if len(order) != len(set(order)) or order[0] != 'Core/Edition.lua' or order[-2:] != ['Core/Init.lua', 'Core/ReleaseMetadata.lua']:
        raise ValueError('Invalid TOC order or duplicate entries')
    runtime = order
    xml_name = 'Modules/DungeonLootMapPins.xml'
    if runtime.count(xml_name) != 1 or runtime.index(xml_name) != runtime.index('Modules/DungeonLootMap.lua') + 1:
        raise ValueError('Map pin template must follow its Lua mixin')
    template = ET.fromstring(source_path(xml_name).read_bytes())
    nodes = list(template)
    ns = '{http://www.blizzard.com/wow/ui/}'
    if (template.tag != ns + 'Ui' or len(nodes) != 1 or nodes[0].tag != ns + 'Frame'
            or nodes[0].attrib != {'name': 'PlayTheGameToolsDungeonLootMapPinTemplate', 'virtual': 'true',
                                   'enableMouse': 'true', 'mixin': 'PlayTheGameToolsDungeonLootMapPinMixin'}
            or len(nodes[0]) != 0):
        raise ValueError('Unexpected map pin template contents')
    actual_xml = {p.relative_to(ADDON).as_posix() for p in ADDON.rglob('*.xml')}
    binding_name='Bindings.xml'
    binding=ET.fromstring(source_path(binding_name).read_bytes())
    entries=list(binding)
    if (binding.tag!='Bindings' or len(entries)!=1 or entries[0].tag!='Binding'
            or entries[0].attrib!={'name':'PTGTOOLS_DUNGEON_LOOT','category':'ADDONS','header':'PTGTOOLS'}
            or len(entries[0]) or (entries[0].text or '').strip()!='PlayTheGameToolsOpenDungeonLoot();'):
        raise ValueError('Unexpected Dungeon Loot binding definition')
    if actual_xml != {xml_name,binding_name}:
        raise ValueError('XML source inventory differs from TOC')
    order = [name for name in runtime if name != xml_name]
    for name in order:
        if not re.fullmatch(r'(?:Core|Config|Modules)/.+\.lua', name):
            raise ValueError(f'Unsupported runtime source: {name}')
    files = {'PlayTheGameTools.toc': (ADDON / 'PlayTheGameTools.toc').read_bytes(), binding_name:source_path(binding_name).read_bytes()}
    files.update({name: source_path(name).read_bytes() for name in runtime})
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
            info = zipfile.ZipInfo('PlayTheGameTools/' + name, (2026, 1, 1, 0, 0, 0))
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
        assert sorted(archive.namelist()) == sorted('PlayTheGameTools/' + n for n in files)
        assert all(archive.read('PlayTheGameTools/' + n) == d for n, d in files.items())
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
