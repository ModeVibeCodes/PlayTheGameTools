"""Generate PlayTheGameTools/Modules/CityLabelsData.lua from Efficient Games data.

The input is a local checkout of the public EG Link WoW: Forever dataset
(https://github.com/JIVESCORP/eg-link-output-wowf), licensed CC BY 4.0. This
tool never downloads anything; clone the repository, check out a commit and
pass its directory and commit:

    git clone https://github.com/JIVESCORP/eg-link-output-wowf eg-data
    git -C eg-data checkout <commit>
    python tools/build_city_labels.py eg-data <commit>

Only builds from the released Forever client are read (MIN_BUILD onward), so
map coordinates match the live, redrawn maps. For each NPC the newest build
that recorded it wins; its recorded player positions are reduced to one
representative point on the map where it was seen most. Same-service NPCs
standing together become one label. The changes are summarized in the
generated file's header, as CC BY 4.0 asks.
"""
from pathlib import Path
import json
import math
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / 'PlayTheGameTools' / 'Modules' / 'CityLabelsData.lua'
PRODUCT = 'wowf'
MIN_BUILD = 70790  # first released-client build in the dataset
CLUSTER_YARDS = 12.0
# Auctioneers and bankers can stand around a whole hall (Undercity's ring).
HALL_YARDS = {'auctionHouse': 50.0, 'bank': 50.0}

CLASSES = ('WARRIOR', 'PALADIN', 'HUNTER', 'ROGUE', 'PRIEST', 'SHAMAN', 'MAGE', 'WARLOCK', 'DRUID')
# Trainer titles naming a class, and the class-specific specialists.
CLASS_TITLES = {c.title() + ' Trainer': c for c in CLASSES}
CLASS_TITLES.update({'Portal Trainer': 'MAGE', 'Pet Trainer': 'HUNTER', 'Demon Trainer': 'WARLOCK'})
# Spells only one class's trainer teaches; used when a trainer has no title.
CLASS_SPELLS = {
    "Hunter's Mark": 'HUNTER', 'Serpent Sting': 'HUNTER', 'Mend Pet': 'HUNTER',
    'Frostbolt': 'MAGE', 'Arcane Intellect': 'MAGE', 'Fireball': 'MAGE',
    'Heroic Strike': 'WARRIOR', 'Battle Shout': 'WARRIOR', 'Seal of Righteousness': 'PALADIN',
    'Sinister Strike': 'ROGUE', 'Stealth': 'ROGUE', 'Power Word: Fortitude': 'PRIEST',
    'Lightning Bolt': 'SHAMAN', 'Rockbiter Weapon': 'SHAMAN', 'Shadow Bolt': 'WARLOCK',
    'Corruption': 'WARLOCK', 'Wrath': 'DRUID', 'Mark of the Wild': 'DRUID',
}
PROFESSIONS = (
    ('Alchemy', r'alchem'), ('Blacksmithing', r'blacksmith'), ('Enchanting', r'enchant'),
    ('Engineering', r'engineer'), ('Herbalism', r'herbalis'), ('Leatherworking', r'leatherwork'),
    ('Mining', r'\bmin(?:ing|er)\b'), ('Skinning', r'skinn'), ('Tailoring', r'tailor'),
    ('Cooking', r'\bcook|\bchef\b'), ('First Aid', r'first aid|\bmedic\b|physician|\bdoctor\b|\bnurse\b'),
    ('Fishing', r'\bfish'),
)
# Labels and map text per kind. Order is the priority for multi-role NPCs.
SERVICES = (
    ('Binder', 'inn', 'Inn'), ('Auctioneer', 'auctionHouse', 'Auction House'),
    ('Banker', 'bank', 'Bank'), ('CharacterBanker', 'bank', 'Bank'),
    ('TaxiNode', 'flightMaster', 'Flight Master'), ('StableMaster', 'stableMaster', 'Stable Master'),
)
OTHER = (('Registrar', 'Guild Master'), ('GuildTabardVendor', 'Guild Master'), ('Transmogrifier', 'Transmogrifier'))


def build_dirs(source):
    base = Path(source) / 'data' / PRODUCT
    found = []
    for path in base.iterdir():
        match = re.fullmatch(r'\d+\.\d+\.\d+\.(\d+)', path.name)
        if path.is_dir() and match and int(match[1]) >= MIN_BUILD:
            found.append((int(match[1]), path))
    if not found:
        raise SystemExit(f'No {PRODUCT} builds >= {MIN_BUILD} under {base}')
    return [p for _, p in sorted(found)]


def read(path, collection):
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding='utf-8')).get(collection, {})


def profession(title, services):
    for name, pattern in PROFESSIONS:
        if title and re.search(pattern, title, re.I):
            return name
    for service in services.values():
        skill = service.get('skill')
        if service.get('profession') and service.get('name'):
            skill = skill or service['name'].split(' ', 1)[-1]
        for name, _ in PROFESSIONS:
            if skill == name:
                return name
    return None


def trainer_class(title, services):
    if title in CLASS_TITLES:
        return CLASS_TITLES[title]
    seen = {CLASS_SPELLS[s.get('name')] for s in services.values() if s.get('name') in CLASS_SPELLS}
    return seen.pop() if len(seen) == 1 else None


def classify(npc, title, trainer, vendor):
    """Return (kind, label, class) or None; never guesses an unknown trainer."""
    roles = set(npc.get('interactions', ()))
    for role, kind, label in SERVICES:
        if role in roles:
            return kind, label, None
    if 'Trainer' in roles or trainer or title in CLASS_TITLES:
        if title == 'Weapon Master':
            return 'weaponMaster', 'Weapon Master', None
        services = (trainer or {}).get('services', {})
        token = trainer_class(title, services)
        if token:
            return 'classTrainer', title if title in CLASS_TITLES else token.title() + ' Trainer', token
        name = profession(title, services)
        if name:
            return 'professionTrainer', name, None
        return None
    for role, label in OTHER:
        if role in roles:
            return 'otherService', label, None
    if 'Merchant' in roles:
        if vendor and vendor.get('repairs'):
            return 'repair', 'Repair', None
        return 'vendor', title or 'Vendor', None
    return None


def representative(positions):
    """The recorded point on the most-seen map closest to all the others."""
    by_map = {}
    for p in positions:
        if all(isinstance(p.get(k), (int, float)) for k in ('uiMap', 'mapX', 'mapY', 'worldX', 'worldY')) \
                and p['uiMap'] > 0 and 0 <= p['mapX'] <= 1 and 0 <= p['mapY'] <= 1:
            by_map.setdefault(p['uiMap'], []).append(p)
    if not by_map:
        return None
    ui_map = min(by_map, key=lambda m: (-len(by_map[m]), m))
    points = by_map[ui_map]
    best = min(points, key=lambda a: (sum(math.dist((a['worldX'], a['worldY']), (b['worldX'], b['worldY'])) for b in points),
                                      a['mapX'], a['mapY']))
    return best


def load(source):
    npcs, titles, trainers, vendors, mail, vaults = {}, {}, {}, {}, {}, {}
    builds = build_dirs(source)
    for build in builds:  # oldest first: newer records replace older ones
        titles.update({k: v['title'] for k, v in read(build / 'creature_details.enUS.json', 'creatures').items() if v.get('title')})
        npcs.update(read(build / 'npcs.json', 'npcs'))
        trainers.update(read(build / 'trainers.json', 'trainers'))
        vendors.update(read(build / 'vendors.json', 'vendors'))
        objects = read(build / 'npcs.json', 'objects')
        approached = read(build / 'npcs.json', 'approached')
        for collection in (objects, approached):
            for key, obj in collection.items():
                roles = set(obj.get('interactions', ()))
                if obj.get('name') == 'Mailbox' or 'MailInfo' in roles:
                    mail.setdefault(key, []).extend(obj.get('positions', ()))
                elif obj.get('name') == 'Guild Vault' or 'GuildBanker' in roles:
                    vaults.setdefault(key, []).extend(obj.get('positions', ()))
    return builds, npcs, titles, trainers, vendors, mail, vaults


def point_entries(groups, kind, label):
    """Objects share one ID everywhere; each recorded spot is its own entry."""
    entries = []
    for positions in groups.values():
        for p in positions:
            if representative([p]):
                entries.append({'kind': kind, 'label': label, 'map': p['uiMap'], 'x': p['mapX'], 'y': p['mapY'],
                                'wx': p['worldX'], 'wy': p['worldY'], 'names': [], 'side': None, 'class': None})
    return entries


def cluster(entries):
    """Chain same-label entries within CLUSTER_YARDS (HALL_YARDS) of a neighbour into one label.

    A bank counter's tellers, or the many spots players recorded around one
    mailbox, end up as one label at their average position.
    """
    groups = {}
    for e in sorted(entries, key=lambda e: (e['map'], e['kind'], e['label'], e['x'], e['y'], e['names'])):
        groups.setdefault((e['map'], e['kind'], e['label'], e['class'], e['side']), []).append(e)
    merged = []
    for members in groups.values():
        parent = list(range(len(members)))

        def root(i):
            while parent[i] != i:
                parent[i] = parent[parent[i]]
                i = parent[i]
            return i
        for i, a in enumerate(members):
            for j in range(i):
                if math.dist((a['wx'], a['wy']), (members[j]['wx'], members[j]['wy'])) <= HALL_YARDS.get(a['kind'], CLUSTER_YARDS):
                    parent[root(i)] = root(j)
        sets = {}
        for i, e in enumerate(members):
            sets.setdefault(root(i), []).append(e)
        for part in sets.values():
            m = dict(part[0])
            m['x'] = sum(e['x'] for e in part) / len(part)
            m['y'] = sum(e['y'] for e in part) / len(part)
            m['wx'] = sum(e['wx'] for e in part) / len(part)
            m['wy'] = sum(e['wy'] for e in part) / len(part)
            m['names'] = sorted({n for e in part for n in e['names']})
            merged.append(m)
    # A guild vault beside a bank is listed in that bank's label, not drawn on top of it.
    banks = [m for m in merged if m['kind'] == 'bank' and m['label'] == 'Bank']
    kept = []
    for m in merged:
        if m['label'] == 'Guild Vault':
            near = [b for b in banks if b['map'] == m['map'] and math.dist((b['wx'], b['wy']), (m['wx'], m['wy'])) <= HALL_YARDS['bank']]
            if near:
                bank = min(near, key=lambda b: math.dist((b['wx'], b['wy']), (m['wx'], m['wy'])))
                bank['names'] = sorted(set(bank['names']) | {'Guild Vault'})
                continue
        kept.append(m)
    return sorted(kept, key=lambda m: (m['map'], m['kind'], m['label'], m['x'], m['y']))


def lua_string(value):
    return '"' + value.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n') + '"'


def generate(source, commit):
    if not re.fullmatch(r'[0-9a-f]{40}', commit):
        raise SystemExit('Pass the full 40-character source commit')
    builds, npcs, titles, trainers, vendors, mail, vaults = load(source)
    entries, skipped = [], []
    for key, npc in npcs.items():
        title = titles.get(key)
        found = classify(npc, title, trainers.get(key), vendors.get(key))
        if not found:
            if 'Trainer' in npc.get('interactions', ()):
                skipped.append(npc.get('name', key))
            continue
        positions = npc.get('positions') or (trainers.get(key) or {}).get('positions') or (vendors.get(key) or {}).get('positions') or ()
        point = representative(positions)
        if not point or not npc.get('name'):
            continue
        kind, label, token = found
        side = {'Alliance': 'A', 'Horde': 'H'}.get(npc.get('side'))
        name = npc['name'] + (' - ' + title if title else '')
        entries.append({'kind': kind, 'label': label, 'map': point['uiMap'], 'x': point['mapX'], 'y': point['mapY'],
                        'wx': point['worldX'], 'wy': point['worldY'], 'names': [name], 'side': side, 'class': token})
    entries += point_entries(mail, 'mailbox', 'Mailbox')
    entries += point_entries(vaults, 'bank', 'Guild Vault')
    merged = cluster(entries)
    first, last = builds[0].name, builds[-1].name
    lines = [
        '-- Generated by tools/build_city_labels.py; do not edit by hand.',
        '-- Data from Efficient Games (https://efficient.games), licensed under CC BY 4.0',
        '-- (https://creativecommons.org/licenses/by/4.0/). Source: EG Link WoW: Forever dataset,',
        f'-- github.com/JIVESCORP/eg-link-output-wowf at {commit}, builds {first}-{last}.',
        '-- Changed: one representative recorded player position per NPC; same-service points',
        '-- chained within 12 yards (50 for auction houses and banks) merged; guild vaults',
        '-- folded into an adjacent bank; roles mapped to label categories. Positions are where',
        '-- players stood when they used the service, so they are near, not exactly on, the NPC.',
        'local _, addon = ...',
        'if not addon.Edition or addon.Edition.name ~= "Forever" then return end',
        '-- Row: kind, x, y, map text, tooltip names ("\\n"-separated), side (A/H/nil), class token.',
        'addon.CityLabelsData = {',
        f'    source = {{ commit = {lua_string(commit)}, builds = {lua_string(first + "-" + last)} }},',
        '    maps = {',
    ]
    for ui_map in sorted({m['map'] for m in merged}):
        lines.append(f'        [{ui_map}] = {{')
        for m in (m for m in merged if m['map'] == ui_map):
            row = [lua_string(m['kind']), f"{m['x']:.4f}", f"{m['y']:.4f}", lua_string(m['label']),
                   lua_string('\n'.join(m['names'])), lua_string(m['side']) if m['side'] else 'nil',
                   lua_string(m['class']) if m['class'] else 'nil']
            while row[-1] == 'nil':
                row.pop()
            lines.append('            { ' + ', '.join(row) + ' },')
        lines.append('        },')
    lines += ['    },', '}', '']
    OUTPUT.write_text('\n'.join(lines), encoding='utf-8', newline='\n')
    counts = {}
    for m in merged:
        counts[m['kind']] = counts.get(m['kind'], 0) + 1
    print(f'PASS {len(merged)} labels on {len({m["map"] for m in merged})} maps from builds {first}-{last}: {dict(sorted(counts.items()))}')
    if skipped:
        print('Skipped trainers with no recognizable class or profession: ' + ', '.join(sorted(skipped)))


if __name__ == '__main__':
    if len(sys.argv) != 3:
        raise SystemExit(__doc__)
    generate(sys.argv[1], sys.argv[2])
