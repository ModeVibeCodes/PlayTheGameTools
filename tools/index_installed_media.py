"""Read-only media-path indexing. Never imports/executes addon code or copies assets."""
import argparse
import json
from pathlib import Path
import re

ROOT=Path(__file__).resolve().parents[1]
KINDS={'font','statusbar','background','border'}
def collect(addons):
    records=set()
    def add(kind,label,path):
        relative=path.relative_to(addons)
        if path.is_file() and relative.parts[0]!='PlayTheGameTools':
            records.add((kind,relative.parts[0]+': '+label,'Interface\\AddOns\\'+str(relative).replace('/','\\')))
    for path in addons.rglob('*'):
        if path.is_file() and path.suffix.lower() in ('.ttf','.otf'):
            add('font',path.stem,path)
    # Extract literal registrations only; resolve a relative suffix only when
    # exactly one installed file matches. Dynamic code is deliberately not run.
    call=re.compile(r'\bRegister\(\s*(["\'])(font|statusbar|background|border)\1\s*,\s*(["\'])(.*?)\3\s*,([^\n]*?)\)',re.I)
    literal=re.compile(r'\[\[(.*?)\]\]|["\']([^"\']+\.(?:ttf|otf|tga|blp|png))["\']',re.I)
    for folder in sorted(p for p in addons.iterdir() if p.is_dir() and p.name!='PlayTheGameTools'):
        files=None
        for source in folder.rglob('*.lua'):
            text=source.read_text(encoding='utf-8-sig',errors='replace')
            for match in call.finditer(text):
                for item in literal.finditer(match[5]):
                    suffix=(item[1] or item[2]).replace('\\\\','\\').replace('/','\\')
                    if suffix.lower().startswith('interface\\addons\\'):
                        candidate=addons.joinpath(*suffix.split('\\')[2:])
                        if candidate.is_file(): add(match[2].lower(),match[4],candidate)
                    else:
                        if files is None: files=[p for p in folder.rglob('*') if p.is_file()]
                        matches=[p for p in files if str(p).replace('/','\\').lower().endswith('\\'+suffix.lower())]
                        if len(matches)==1: add(match[2].lower(),match[4],matches[0])
        # Ellesmere's bar catalog is data rather than literal LSM registrations.
        source=folder/'EllesmereUI.lua'
        if source.is_file():
            table=re.search(r'BAR_TEXTURE_FILES\s*=\s*\{(.*?)\}',source.read_text(encoding='utf-8-sig'),re.S)
            if table:
                for filename in re.findall(r'=\s*"([^"]+\.(?:tga|blp))"',table[1],re.I):
                    add('statusbar',Path(filename).stem,folder/'media/textures'/filename)
    return sorted(records)

def render(records):
    lines=['local _,addon=...', '-- Generated path/name facts only; no provider code or assets are bundled.',
           '-- Refresh: python tools/index_installed_media.py --addons <Forever AddOns directory>',
           'addon.Media.providerCatalog={']
    for record in records:
        lines.append('    {'+','.join(json.dumps(s,ensure_ascii=False) for s in record)+'},')
    return '\n'.join(lines+['}',''])

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--addons',type=Path,required=True)
    args=parser.parse_args()
    if not args.addons.is_dir(): parser.error('AddOns directory does not exist')
    records=collect(args.addons)
    target=ROOT/'PlayTheGameTools/Core/MediaCatalog.lua'
    target.write_text(render(records),encoding='utf-8')
    print('Indexed '+str(len(records))+' installed media paths; no assets copied.')
