"""Lua 5.1 syntax, startup, UI construction and settings restoration; not WoW."""
import io
from pathlib import Path
import sys
import zipfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from build_release import ROOT, payload, archive_bytes
from lupa.lua51 import LuaRuntime


def load(encoded=None, project=18):
    files, order, toc = payload()
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute((ROOT / 'tests/wow_mock.lua').read_text(encoding='utf-8'))
    lua.globals().testProject = project
    lua.execute('''
        WOW_PROJECT_MAINLINE=1; WOW_PROJECT_CAMELOT=18; WOW_PROJECT_ID=testProject
        messages={}; function print(s) messages[#messages+1]=s end
        C_UI={Reload=function() end}
        function UnitClass() return 'Rogue','ROGUE',4 end
        function UnitGUID() return 'Player-Collaboration-Fixture' end
        function UnitFullName() return 'Fixture','TestRealm' end
    ''')
    metadata = {line[3:].split(':', 1)[0]: line.split(':', 1)[1].strip()
                for line in toc.splitlines() if line.startswith('## ')}
    lua.globals().metadata = lua.table_from(metadata)
    lua.execute('C_AddOns.GetAddOnMetadata=function(_,key) return metadata[key] end')
    addon = lua.table()
    execute = lua.eval('function(s,n,...) local f,e=loadstring(s,n); assert(f,e); return f(...) end')
    for name in order:
        execute(files[name].decode('utf-8-sig'), name, 'ModeTools', addon)
    lua.globals().addon = addon
    if encoded is not None:
        lua.globals().encoded = encoded
        lua.execute('ModeToolsDB=addon.ProfileCodec.Decode(encoded)')
    lua.execute("FireEvent('ADDON_LOADED','ModeTools'); FireEvent('PLAYER_LOGIN')")
    return lua, addon


files, order, _ = payload()
lua, addon = load()
lua.execute('''
    assert(addon.initialized and #addon.moduleOrder==6 and #addon.categoryOrder==4)
    assert(addon.Edition.name=='Forever' and addon.developmentPhase=='Forever Beta')
    assert(addon.PartyCooldownSessions==nil and addon.InterruptTracking==nil)
    assert(SLASH_MODETOOLS1=='/modetools' and SLASH_MODETOOLS2=='/mode')
    SlashCmdList.MODETOOLS()
    assert(addon.configWindow.title:GetText()=='Play The Game Tools')
    assert(addon.configWindow.moduleHeader.title:GetText()=='Dashboard')
    assert(addon.configWindow.pages.dashboard.welcomeTexts[1]=='Welcome to Play The Game Tools!')
    for _,id in ipairs(addon.moduleOrder) do
        addon:SelectConfigPage(id)
        assert(addon.configWindow.pages[id],id)
        assert(addon.configWindow.moduleHeader.title:GetText()==addon.modules[id].title,id)
    end
    addon.db.window.x=123; addon.db.window.y=45
    addon:SetModuleEnabled('combatTimer',true)
    assert(addon.modules.combatTimer.enabled)
''')
state = lua.eval('addon.ProfileCodec.Encode(ModeToolsDB)')
restored, _ = load(state)
restored.execute('''
    assert(addon.db.window.x==123 and addon.db.window.y==45)
    assert(addon.modules.combatTimer.enabled)
    addon:SetModuleEnabled('combatTimer',false)
    assert(not addon.modules.combatTimer.enabled)
''')
wrong, _ = load(project=1)
wrong.execute('assert(not addon.initialized and ModeToolsDB==nil)')
archive = archive_bytes(files)
assert archive == archive_bytes(files)
with zipfile.ZipFile(io.BytesIO(archive)) as zipped:
    assert sorted(zipped.namelist()) == sorted('ModeTools/' + n for n in files)
    for name, data in files.items():
        assert zipped.read('ModeTools/' + name) == data
assert not any(p in n.split('/') for n in files for p in ('WTF','SavedVariables','.git','tests','tools'))
print(f'PASS {len(order)} Lua chunks, Forever startup, all module pages, title/commands, profile roundtrip, wrong-client block, deterministic ZIP')
