"""Generate the Points of Interest Labels data files from two pinned public sources.

1. PlayTheGameTools/Modules/CityLabelsData.lua (CC BY 4.0): the EG Link WoW:
   Forever dataset by Efficient Games (https://github.com/JIVESCORP/eg-link-output-wowf),
   where players recorded each service on the released Forever client.
2. PlayTheGameTools/Modules/CityLabelsClassicData.lua (GPL-3.0): Classic spawn
   positions from CMaNGOS classic-db (https://github.com/cmangos/classic-db) for
   trainers and services Efficient Games has not placed yet.

This tool never downloads anything. Clone the dataset at a commit, download the
classic-db Full_DB dump at a commit, and pass both with their commits:

    git clone https://github.com/JIVESCORP/eg-link-output-wowf eg-data
    git -C eg-data checkout <eg-commit>
    curl -LO https://raw.githubusercontent.com/cmangos/classic-db/<db-commit>/Full_DB/ClassicDB_1_12_1_z2815.sql.gz
    python tools/build_city_labels.py eg-data <eg-commit> ClassicDB_1_12_1_z2815.sql.gz <db-commit>

Only released-client builds are read (MIN_BUILD onward). For each NPC the newest
build that recorded it wins; its recorded player positions become one point on
the map where it was seen most. Same-service NPCs standing together become one
label. Classic world positions are converted with a per-map transform fitted
to Efficient Games' own Forever points (world yards to map position), so
redrawn Forever maps are handled; a Classic label is never drawn next to an
Efficient Games label for the same service. Both file headers summarize the
changes, as CC BY 4.0 asks.
"""
from pathlib import Path
import gzip
import json
import math
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
MODULES = ROOT / 'PlayTheGameTools' / 'Modules'
OUTPUT = MODULES / 'CityLabelsData.lua'
CLASSIC_OUTPUT = MODULES / 'CityLabelsClassicData.lua'
PRODUCT = 'wowf'
MIN_BUILD = 70790  # first released-client build in the dataset
CLUSTER_YARDS = 12.0
# Auctioneers and bankers can stand around a whole hall (Undercity's ring); one
# class's trainers share a room.
HALL_YARDS = {'auctionHouse': 50.0, 'bank': 50.0, 'classTrainer': 30.0}
# A Classic point this close to an Efficient Games label of the same service is redundant.
CLASSIC_NEAR_YARDS = 40.0
# A map's fitted transform must reproduce every recorded point this closely (map fraction).
MAX_FIT_ERROR = 0.003
MIN_FIT_POINTS = 10
# The nearest Forever-recorded point within this range decides a Classic point's map.
NEAREST_YARDS = 80.0
# Labels go on zone and city maps, never the Azeroth or continent overviews.
OVERVIEW_MAPS = {947, 1414, 1415}
# Fallback placements this close to a map edge are rejected (map fraction).
EDGE = 0.03

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
# CMaNGOS creature_template.TrainerClass values (1.12 ChrClasses IDs).
CLASSIC_CLASS_IDS = {1: 'WARRIOR', 2: 'PALADIN', 3: 'HUNTER', 4: 'ROGUE', 5: 'PRIEST', 7: 'SHAMAN',
                     8: 'MAGE', 9: 'WARLOCK', 11: 'DRUID'}
PROFESSIONS = (
    ('Alchemy', r'alchem'), ('Blacksmithing', r'blacksmith'), ('Enchanting', r'enchant'),
    ('Engineering', r'engineer'), ('Herbalism', r'herbalis'), ('Leatherworking', r'leatherwork'),
    ('Mining', r'\bmin(?:ing|er)\b'), ('Skinning', r'skinn'), ('Tailoring', r'tailor'),
    ('Cooking', r'\bcook|\bchef\b'), ('First Aid', r'first aid|\bmedic\b|physician|\bdoctor\b|\bnurse\b|surgeon'),
    ('Fishing', r'\bfish'),
)
# Labels and map text per kind. Order is the priority for multi-role NPCs.
SERVICES = (
    ('Binder', 'inn', 'Inn'), ('Auctioneer', 'auctionHouse', 'Auction House'),
    ('Banker', 'bank', 'Bank'), ('CharacterBanker', 'bank', 'Bank'),
    ('TaxiNode', 'flightMaster', 'Flight Master'), ('StableMaster', 'stableMaster', 'Stable Master'),
)
OTHER = (('Registrar', 'Guild Master'), ('GuildTabardVendor', 'Guild Master'), ('Transmogrifier', 'Transmogrifier'))
# Titles that name a service, for NPCs recorded only by a gossip window.
TITLE_SERVICES = {
    'Banker': ('bank', 'Bank'), 'Innkeeper': ('inn', 'Inn'), 'Stable Master': ('stableMaster', 'Stable Master'),
    'Flight Master': ('flightMaster', 'Flight Master'), 'Gryphon Master': ('flightMaster', 'Flight Master'),
    'Wind Rider Master': ('flightMaster', 'Flight Master'), 'Hippogryph Master': ('flightMaster', 'Flight Master'),
    'Bat Handler': ('flightMaster', 'Flight Master'), 'Guild Master': ('otherService', 'Guild Master'),
}
# CMaNGOS 1.12 NpcFlags, in the same priority order as SERVICES.
CLASSIC_FLAGS = ((128, 'inn', 'Inn'), (4096, 'auctionHouse', 'Auction House'), (256, 'bank', 'Bank'),
                 (8, 'flightMaster', 'Flight Master'), (8192, 'stableMaster', 'Stable Master'))
CLASSIC_TRAINER_FLAG = 16
# "Train me." gossip option icon (Interface/GossipFrame/TrainerGossipIcon). Classic
# trainers greet with gossip first, so players often never open the trainer list.
TRAINER_GOSSIP_ICON = 132058
# A profession trainer's title names the person ("Expert Alchemist", "Herbalism
# Trainer"); supply vendors ("Alchemy Supplies") never match.
TRAINER_TITLE = re.compile(
    r'^(?:(?:apprentice|journeyman|expert|artisan|master|grand master|junior|superior)\s+)?'
    r'(?:[a-z ]+\s+trainer|alchemist|blacksmith|enchanter|engineer|herbalist|leatherworker|miner|skinner|'
    r'tailor|cook|chef|fisherman|fisher|medic|physician|surgeon)(?:\s+trainer)?$', re.I)


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


def usable(p):
    return all(isinstance(p.get(k), (int, float)) for k in ('instance', 'uiMap', 'mapX', 'mapY', 'worldX', 'worldY')) \
        and p['uiMap'] > 0 and 0 <= p['mapX'] <= 1 and 0 <= p['mapY'] <= 1


def profession(title, services=None):
    for name, pattern in PROFESSIONS:
        if title and re.search(pattern, title, re.I):
            return name
    for service in (services or {}).values():
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


def offers_training(npc):
    return any(o.get('icon') == TRAINER_GOSSIP_ICON for o in (npc.get('options') or {}).values())


def trainer_kind(title, token, name):
    if title == 'Weapon Master':
        return 'weaponMaster', 'Weapon Master', None
    if token:
        return 'classTrainer', title if title in CLASS_TITLES else token.title() + ' Trainer', token
    if name:
        return 'professionTrainer', name, None
    return None


def classify(npc, title, trainer, vendor):
    """Return (kind, label, class) or None; never guesses an unknown trainer."""
    roles = set(npc.get('interactions', ()))
    for role, kind, label in SERVICES:
        if role in roles:
            return kind, label, None
    titled = bool(title) and 'Merchant' not in roles and (title == 'Weapon Master' or TRAINER_TITLE.match(title))
    if 'Trainer' in roles or trainer or title in CLASS_TITLES or offers_training(npc) or titled:
        services = (trainer or {}).get('services', {})
        return trainer_kind(title, trainer_class(title, services), profession(title, services))
    for role, label in OTHER:
        if role in roles:
            return 'otherService', label, None
    if title in TITLE_SERVICES and 'Merchant' not in roles:
        return TITLE_SERVICES[title] + (None,)
    if 'Merchant' in roles:
        if vendor and vendor.get('repairs'):
            return 'repair', 'Repair', None
        return 'vendor', title or 'Vendor', None
    return None


def classify_classic(template, title):
    """Classic template flags decide the service only when the title agrees.

    Some Classic templates carry stray service flags (a mount vendor flagged as
    an innkeeper), so a flag counts only with that service's title; auctioneers
    are untitled and named "Auctioneer ...".
    """
    flags = template['flags']
    for flag, kind, label in CLASSIC_FLAGS:
        if flags & flag:
            agrees = (not title and template['name'].startswith('Auctioneer')) if kind == 'auctionHouse' \
                else TITLE_SERVICES.get(title, (None,))[0] == kind
            if agrees:
                return kind, label, None
    if title in TITLE_SERVICES:
        return TITLE_SERVICES[title] + (None,)
    if flags & CLASSIC_TRAINER_FLAG or title in CLASS_TITLES or (title and TRAINER_TITLE.match(title)):
        token = CLASS_TITLES.get(title)
        if not token and template['trainerType'] == 0:
            token = CLASSIC_CLASS_IDS.get(template['trainerClass'])
        if not token and template['trainerType'] == 3:
            token = 'HUNTER'
        if title == 'Weapon Master':
            token = None
        return trainer_kind(title, token, profession(title) if template['trainerType'] == 2 or not token else None)
    return None


def representative(positions):
    """The recorded point on the most-seen map closest to all the others."""
    by_map = {}
    for p in positions:
        if usable(p):
            by_map.setdefault(p['uiMap'], []).append(p)
    if not by_map:
        return None
    ui_map = min(by_map, key=lambda m: (-len(by_map[m]), m))
    points = by_map[ui_map]
    return min(points, key=lambda a: (sum(math.dist((a['worldX'], a['worldY']), (b['worldX'], b['worldY'])) for b in points),
                                      a['mapX'], a['mapY']))


def load(source):
    npcs, titles, trainers, vendors, mail, vaults, points = {}, {}, {}, {}, {}, {}, {}
    builds = build_dirs(source)
    for build in builds:  # oldest first: newer records replace older ones
        details = read(build / 'creature_details.enUS.json', 'creatures')
        titles.update({k: v['title'] for k, v in details.items() if v.get('title')})
        recorded = read(build / 'npcs.json', 'npcs')
        npcs.update(recorded)
        trainers.update(read(build / 'trainers.json', 'trainers'))
        vendors.update(read(build / 'vendors.json', 'vendors'))
        objects = read(build / 'npcs.json', 'objects')
        approached = read(build / 'npcs.json', 'approached')
        for collection in (recorded, objects, approached):
            for record in collection.values():
                for p in record.get('positions', ()):
                    if usable(p):
                        points.setdefault(p['uiMap'], []).append(p)
        for collection in (objects, approached):
            for key, obj in collection.items():
                roles = set(obj.get('interactions', ()))
                if obj.get('name') == 'Mailbox' or 'MailInfo' in roles:
                    mail.setdefault(key, []).extend(obj.get('positions', ()))
                elif obj.get('name') == 'Guild Vault' or 'GuildBanker' in roles:
                    vaults.setdefault(key, []).extend(obj.get('positions', ()))
    return builds, npcs, titles, trainers, vendors, mail, vaults, points


def point_entries(groups, kind, label):
    """Objects share one ID everywhere; each recorded spot is its own entry."""
    entries = []
    for positions in groups.values():
        for p in positions:
            if usable(p):
                entries.append({'kind': kind, 'label': label, 'map': p['uiMap'], 'x': p['mapX'], 'y': p['mapY'],
                                'wx': p['worldX'], 'wy': p['worldY'], 'names': [], 'side': None, 'class': None})
    return entries


def group_label(e):
    # One class's trainers together (e.g. Hunter and Pet Trainer) share a label.
    return e['class'] if e['kind'] == 'classTrainer' else e['label']


def cluster(entries):
    """Chain same-service entries within CLUSTER_YARDS (HALL_YARDS) of a neighbour into one label.

    A bank counter's tellers, or the many spots players recorded around one
    mailbox, end up as one label at their average position.
    """
    groups = {}
    for e in sorted(entries, key=lambda e: (e['map'], e['kind'], e['label'], e['x'], e['y'], e['names'])):
        groups.setdefault((e['map'], e['kind'], group_label(e), e['class'], e['side']), []).append(e)
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
            for key in ('x', 'y', 'wx', 'wy'):
                m[key] = sum(e[key] for e in part) / len(part)
            m['names'] = sorted({n for e in part for n in e['names']})
            if len({e['label'] for e in part}) > 1:
                m['label'] = m['class'].title() + ' Trainer'
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


def solve3(rows, values):
    """Least-squares fit value = a*wx + b*wy + c by the normal equations."""
    m = [[0.0] * 4 for _ in range(3)]
    for (wx, wy), v in zip(rows, values):
        vec = (wx, wy, 1.0)
        for i in range(3):
            m[i][3] += vec[i] * v
            for j in range(3):
                m[i][j] += vec[i] * vec[j]
    for c in range(3):
        pivot = max(range(c, 3), key=lambda r: abs(m[r][c]))
        m[c], m[pivot] = m[pivot], m[c]
        if abs(m[c][c]) < 1e-9:
            return None
        for r in range(3):
            if r != c:
                f = m[r][c] / m[c][c]
                for k in range(c, 4):
                    m[r][k] -= f * m[c][k]
    return [m[i][3] / m[i][i] for i in range(3)]


def transforms(points):
    """Per-map world-to-map transforms fitted to Forever-recorded points."""
    fitted = {}
    for ui_map, ps in points.items():
        counts = {}
        for p in ps:
            counts[p['instance']] = counts.get(p['instance'], 0) + 1
        instance = min(counts, key=lambda i: (-counts[i], i))
        ps = [p for p in ps if p['instance'] == instance]
        if len(ps) < MIN_FIT_POINTS:
            continue
        rows = [(p['worldX'], p['worldY']) for p in ps]
        ax, ay = solve3(rows, [p['mapX'] for p in ps]), solve3(rows, [p['mapY'] for p in ps])
        if not ax or not ay:
            continue
        error = max(math.hypot(ax[0]*wx + ax[1]*wy + ax[2] - p['mapX'], ay[0]*wx + ay[1]*wy + ay[2] - p['mapY'])
                    for (wx, wy), p in zip(rows, ps))
        # World maps are axis-aligned with a 3:2 width:height in yards; reject any
        # fit that is not, however small its residual.
        if error > MAX_FIT_ERROR or not ax[1] or not ay[0]:
            continue
        skew = max(abs(ax[0] / ax[1]), abs(ay[1] / ay[0]))
        if skew > .01 or abs(abs(ay[0] / ax[1]) - 1.5) > .03:
            continue
        xs, ys = [r[0] for r in rows], [r[1] for r in rows]
        fitted[ui_map] = {'instance': instance, 'x': ax, 'y': ay, 'box': (min(xs), max(xs), min(ys), max(ys))}
    return fitted


class RecordedPoints:
    """Forever-recorded points by world cell: the map a player stood on there."""
    CELL = 50.0

    def __init__(self, points):
        self.cells = {}
        for ui_map, ps in points.items():
            for p in ps:
                key = (p['instance'], int(p['worldX'] // self.CELL), int(p['worldY'] // self.CELL))
                self.cells.setdefault(key, []).append((p['worldX'], p['worldY'], ui_map))

    def nearest_map(self, instance, wx, wy, radius=NEAREST_YARDS):
        best = None
        cx, cy, reach = int(wx // self.CELL), int(wy // self.CELL), int(radius // self.CELL) + 1
        for i in range(cx - reach, cx + reach + 1):
            for j in range(cy - reach, cy + reach + 1):
                for x, y, ui_map in self.cells.get((instance, i, j), ()):
                    d = math.hypot(x - wx, y - wy)
                    if d <= radius and (not best or (d, ui_map) < best):
                        best = (d, ui_map)
        return best and best[1]


def project(fitted, recorded, instance, wx, wy):
    """Choose a map for a world point, then convert it with that map's transform.

    Map rectangles overlap near zone borders and around cities, so prefer the map
    players recorded nearest this spot; otherwise the smallest map whose recorded
    area, then whose whole rectangle, contains it.
    """
    inside = {}
    for ui_map, t in fitted.items():
        if t['instance'] != instance or ui_map in OVERVIEW_MAPS:
            continue
        x = t['x'][0]*wx + t['x'][1]*wy + t['x'][2]
        y = t['y'][0]*wx + t['y'][1]*wy + t['y'][2]
        if 0 <= x <= 1 and 0 <= y <= 1:
            inside[ui_map] = (x, y)
    if not inside:
        return None
    choice = recorded.nearest_map(instance, wx, wy)
    if choice not in inside:
        # Without a nearby recording, a point at a map's very edge most likely
        # belongs to an unfitted neighbouring zone: never guess it onto this one.
        inside = {m: p for m, p in inside.items() if all(EDGE <= v <= 1 - EDGE for v in p)}
        if not inside:
            return None
        def box_area(ui_map):
            x0, x1, y0, y1 = fitted[ui_map]['box']
            mx, my = (x1 - x0) * .1 + 20, (y1 - y0) * .1 + 20
            covered = x0 - mx <= wx <= x1 + mx and y0 - my <= wy <= y1 + my
            return (x1 - x0 + 1) * (y1 - y0 + 1) if covered else None
        boxed = [(box_area(m), m) for m in inside if box_area(m) is not None]
        if boxed:
            choice = min(boxed)[1]
        else:
            t = fitted
            choice = min(inside, key=lambda m: (1 / abs(t[m]['x'][0]*t[m]['y'][1] - t[m]['x'][1]*t[m]['y'][0]), m))
    return (choice,) + inside[choice]


def sql_tuples(line):
    """Yield the value tuples of one MySQL INSERT line, honouring quoted strings."""
    i, n = line.index('VALUES') + 6, len(line)
    while i < n:
        while i < n and line[i] != '(':
            i += 1
        if i >= n:
            return
        i += 1
        values, current, quoted = [], [], False
        while i < n:
            ch = line[i]
            if quoted:
                if ch == '\\':
                    current.append(line[i + 1]); i += 2; continue
                if ch == "'":
                    if i + 1 < n and line[i + 1] == "'":
                        current.append("'"); i += 2; continue
                    quoted = False
                else:
                    current.append(ch)
            elif ch == "'":
                quoted = True
            elif ch == ',':
                values.append(''.join(current)); current = []
            elif ch == ')':
                values.append(''.join(current)); i += 1
                break
            else:
                current.append(ch)
            i += 1
        yield values


def load_classic(path):
    columns = {}
    templates, spawns = {}, {}
    with gzip.open(path, 'rt', encoding='utf-8', errors='replace') as f:
        table = None
        for line in f:
            if line.startswith('CREATE TABLE `'):
                table = line.split('`')[1]
                columns[table] = []
            elif table and line.startswith('  `'):
                columns[table].append(line.split('`')[1])
            elif line.startswith(')'):
                table = None
            elif line.startswith('INSERT INTO `creature_template` VALUES'):
                c = {name: i for i, name in enumerate(columns['creature_template'])}
                for v in sql_tuples(line):
                    templates[int(v[c['Entry']])] = {
                        'name': v[c['Name']], 'subname': v[c['SubName']] if v[c['SubName']] != 'NULL' else '',
                        'flags': int(v[c['NpcFlags']]), 'trainerType': int(v[c['TrainerType']]),
                        'trainerClass': int(v[c['TrainerClass']])}
            elif line.startswith('INSERT INTO `creature` VALUES'):
                c = {name: i for i, name in enumerate(columns['creature'])}
                for v in sql_tuples(line):
                    world_map = int(v[c['map']])
                    if world_map in (0, 1):
                        spawns.setdefault(int(v[c['id']]), []).append(
                            (int(v[c['guid']]), world_map, float(v[c['position_x']]), float(v[c['position_y']])))
    return templates, spawns


def lua_string(value):
    return '"' + value.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n') + '"'


def lua_rows(merged):
    lines = []
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
    return lines


def counts(merged):
    found = {}
    for m in merged:
        found[m['kind']] = found.get(m['kind'], 0) + 1
    return dict(sorted(found.items()))


def nearest_side(placed, ui_map, x, y):
    """Classic rows take the side of the nearest sided Forever label within 15% of the map."""
    best = None
    for m in placed:
        if m['map'] == ui_map and m['side']:
            d = math.hypot(m['x'] - x, m['y'] - y)
            if d <= .15 and (not best or d < best[0]):
                best = (d, m['side'])
    return best and best[1]


def generate(source, commit, classic_path, classic_commit):
    for value in (commit, classic_commit):
        if not re.fullmatch(r'[0-9a-f]{40}', value):
            raise SystemExit('Pass the full 40-character source commits')
    builds, npcs, titles, trainers, vendors, mail, vaults, points = load(source)
    entries, skipped, placed_ids = [], [], set()
    for key, npc in npcs.items():
        title = titles.get(key)
        found = classify(npc, title, trainers.get(key), vendors.get(key))
        if not found:
            if 'Trainer' in npc.get('interactions', ()) or offers_training(npc):
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
        placed_ids.add(int(key))
    entries += point_entries(mail, 'mailbox', 'Mailbox')
    entries += point_entries(vaults, 'bank', 'Guild Vault')
    merged = cluster(entries)

    # Classic positions for trainers and services Efficient Games has not placed.
    fitted = transforms(points)
    recorded = RecordedPoints(points)
    templates, spawns = load_classic(classic_path)
    classic = []
    for npc_id in sorted(spawns):
        template = templates.get(npc_id)
        if npc_id in placed_ids or not template or not template['name']:
            continue
        title = titles.get(str(npc_id)) or template['subname']
        found = classify_classic(template, title)
        if not found:
            continue
        kind, label, token = found
        for _, world_map, wx, wy in sorted(spawns[npc_id])[:1]:  # lowest GUID: the primary spawn
            projected = project(fitted, recorded, world_map, wx, wy)
            if not projected:
                continue
            ui_map, x, y = projected
            entry = {'kind': kind, 'label': label, 'map': ui_map, 'x': x, 'y': y, 'wx': wx, 'wy': wy,
                     'names': [template['name'] + (' - ' + title if title else '')], 'class': token}
            entry['side'] = nearest_side(merged, ui_map, x, y)
            redundant = any(m['map'] == ui_map and m['kind'] == kind and group_label(m) == group_label(entry)
                            and math.dist((m['wx'], m['wy']), (wx, wy)) <= CLASSIC_NEAR_YARDS for m in merged)
            if not redundant:
                classic.append(entry)
    classic = cluster(classic)

    first, last = builds[0].name, builds[-1].name
    lines = [
        '-- Generated by tools/build_city_labels.py; do not edit by hand.',
        '-- Data from Efficient Games (https://efficient.games), licensed under CC BY 4.0',
        '-- (https://creativecommons.org/licenses/by/4.0/). Source: EG Link WoW: Forever dataset,',
        f'-- github.com/JIVESCORP/eg-link-output-wowf at {commit}, builds {first}-{last}.',
        '-- Changed: one representative recorded player position per NPC; same-service points',
        '-- chained within 12 yards (30 for class trainers, 50 for auction houses and banks)',
        '-- merged, one class\'s trainers sharing a label; guild vaults folded into an adjacent bank;',
        '-- roles mapped to label categories. Positions are where players stood when they used',
        '-- the service, so they are near, not exactly on, the NPC.',
        'local _, addon = ...',
        'if not addon.Edition or addon.Edition.name ~= "Forever" then return end',
        '-- Row: kind, x, y, map text, tooltip names ("\\n"-separated), side (A/H/nil), class token.',
        'addon.CityLabelsData = {',
        f'    source = {{ commit = {lua_string(commit)}, builds = {lua_string(first + "-" + last)} }},',
        '    maps = {',
    ] + lua_rows(merged) + ['    },', '}', '']
    OUTPUT.write_text('\n'.join(lines), encoding='utf-8', newline='\n')

    lines = [
        '-- Generated by tools/build_city_labels.py; do not edit by hand.',
        '-- Classic spawn positions from CMaNGOS classic-db (https://github.com/cmangos/classic-db)',
        f'-- at {classic_commit}, Full_DB/{Path(classic_path).name}. GPL-3.0; see LICENSES/GPL-3.0.txt.',
        '-- World of Warcraft names and content remain Blizzard Entertainment\'s.',
        '-- Changed: only trainers and services with no Efficient Games position are kept, each',
        '-- NPC\'s primary spawn converted to Forever map positions with per-map transforms fitted',
        '-- to Efficient Games\' Forever-recorded points (the map recorded nearest the spawn',
        '-- decides overlaps), sides taken from the nearest recorded',
        '-- label, and same-service points merged as in CityLabelsData.lua. Classic positions',
        '-- can differ where Forever moved an NPC.',
        'local _, addon = ...',
        'if not addon.Edition or addon.Edition.name ~= "Forever" then return end',
        '-- Row: kind, x, y, map text, tooltip names ("\\n"-separated), side (A/H/nil), class token.',
        'addon.CityLabelsClassicData = {',
        f'    source = {{ commit = {lua_string(classic_commit)} }},',
        '    maps = {',
    ] + lua_rows(classic) + ['    },', '}', '']
    CLASSIC_OUTPUT.write_text('\n'.join(lines), encoding='utf-8', newline='\n')

    print(f'PASS {len(merged)} Efficient Games labels on {len({m["map"] for m in merged})} maps, builds {first}-{last}: {counts(merged)}')
    print(f'PASS {len(classic)} Classic labels on {len({m["map"] for m in classic})} maps ({len(fitted)} fitted maps): {counts(classic)}')
    if skipped:
        print('Skipped trainers with no recognizable class or profession: ' + ', '.join(sorted(skipped)))


if __name__ == '__main__':
    if len(sys.argv) != 5:
        raise SystemExit(__doc__)
    generate(*sys.argv[1:])
