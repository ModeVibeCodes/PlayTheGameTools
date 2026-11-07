"""Reproduce the pinned licensed catalog import; never download or install addons."""
from pathlib import Path
import argparse
import hashlib
import zipfile

ROOT = Path(__file__).resolve().parents[1]
SHA256 = '6446886ad6fd9a58b5edbf4661aef3fe05970e9f131408c485d320ebf375777c'
BANNER = '''-- SPDX-License-Identifier: GPL-3.0-only
-- Data from Lootified 1.2.0 by Alen (TepsiPepsi), derived in part from CMaNGOS classic-db.
-- Modified 2026-11-07 for Play The Game Tools: namespace binding only.
-- Original source/provenance comments follow. No UI, fonts, icons or map images imported.
-- See CATALOG_SOURCES.md and LICENSES/GPL-3.0.txt.
'''


def imported(archive):
    data = archive.read_bytes()
    if hashlib.sha256(data).hexdigest() != SHA256:
        raise ValueError('Archive does not match the reviewed Lootified 1.2.0 snapshot')
    with zipfile.ZipFile(archive) as source:
        result = {}
        for name in ('Items', 'Instances', 'Quests'):
            suffix = '/Data/' + name + '.lua'
            matches = [p for p in source.namelist() if p.endswith(suffix)]
            if len(matches) != 1:
                raise ValueError('Expected exactly one ' + suffix)
            text = source.read(matches[0]).decode('utf-8-sig').replace('\r\n', '\n')
            binding = 'local _, LJ = ...'
            if text.count(binding) != 1:
                raise ValueError('Unexpected namespace binding')
            text = text.replace(binding, 'local _, addon = ...\nlocal LJ = addon.DungeonLootCatalog\nif not LJ then return end')
            result['ModeTools/Modules/DungeonLootCatalog' + name + '.lua'] = (BANNER + text).encode('utf-8')
        licenses = [p for p in source.namelist() if p.endswith('/LICENSE')]
        if len(licenses) != 1:
            raise ValueError('Expected exactly one LICENSE')
        result['LICENSES/GPL-3.0.txt'] = source.read(licenses[0])
        return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('archive', type=Path, help='Local pinned Lootified-1.2.0.zip; see CATALOG_SOURCES.md')
    parser.add_argument('--write', action='store_true', help='Replace only the three reviewed data files and license')
    args = parser.parse_args()
    for name, data in imported(args.archive).items():
        path = ROOT / name
        if args.write:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)
        elif path.read_bytes() != data:
            raise ValueError('Imported file differs: ' + name)
    print('PASS pinned catalog ' + ('imported' if args.write else 'matches reviewed source'))


if __name__ == '__main__':
    main()
