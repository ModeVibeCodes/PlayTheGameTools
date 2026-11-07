local _, addon = ...
local P = addon.ForeverTrainingData
--[[
Class catalog facts adapted from What's Training? by Sveng / fusionpit.
Forever revision: dd4256471d65149ad6e8d00ad1f18fa7c31e7a6e; Classes/Camelot/Warrior.lua
Normalized source SHA-256: d061a87bcbe25e82adba25229077e529916c144a1c1bb3a2ce3d41c867c5aedb
Independent PlayTheGameTools runtime; reference prices, not verified offers.

MIT License

Copyright (c) 2019

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]
P.factories.WARRIOR = function()
    return {
        version="FOREVER-4.0-warrior-1", class="WARRIOR",
        reference="dd4256471d65149ad6e8d00ad1f18fa7c31e7a6e", sourceHash="d061a87bcbe25e82adba25229077e529916c144a1c1bb3a2ce3d41c867c5aedb",
        records={
            {id=6673, rank=1, level=1, cost=10, chain="battleShout", order=1},
            {id=100, rank=1, level=4, cost=100, chain="charge", order=1},
            {id=772, rank=1, level=4, cost=100, chain="rend", order=1},
            {id=3127, rank=1, level=6, cost=100, chain="spell3127", order=1},
            {id=6343, rank=1, level=6, cost=100, chain="thunderClap", order=1},
            {id=1715, rank=1, level=8, cost=200, chain="hamstring", order=1},
            {id=284, rank=2, level=8, cost=200, chain="heroicStrike", order=2, previous=78},
            {id=2687, rank=1, level=10, cost=600, chain="spell2687", order=1},
            {id=6546, rank=2, level=10, cost=600, chain="rend", order=2, previous=772},
            {id=5242, rank=2, level=12, cost=1000, chain="battleShout", order=2, previous=6673},
            {id=7384, rank=1, level=12, cost=1000, chain="overpower", order=1},
            {id=72, rank=1, level=12, cost=1000, chain="shieldBash", order=1},
            {id=1160, rank=1, level=14, cost=1500, chain="demoralizingShout", order=1},
            {id=6572, rank=1, level=14, cost=1500, chain="revenge", order=1, previous=71},
            {id=1310185, rank=1, level=14, cost=1500, chain="spell1310185", order=1},
            {id=285, rank=3, level=16, cost=2000, chain="heroicStrike", order=3, previous=284},
            {id=694, rank=1, level=16, cost=2000, chain="mockingBlow", order=1},
            {id=2565, rank=1, level=16, cost=2000, chain="spell2565", order=1, previous=71},
            {id=676, rank=1, level=18, cost=3000, chain="spell676", order=1, previous=71},
            {id=8198, rank=2, level=18, cost=3000, chain="thunderClap", order=2, previous=6343},
            {id=845, rank=1, level=20, cost=4000, chain="cleave", order=1},
            {id=674, rank=1, level=20, cost=4000, chain="spell674", order=1},
            {id=6547, rank=3, level=20, cost=4000, chain="rend", order=3, previous=6546},
            {id=20230, rank=1, level=20, cost=4000, chain="spell20230", order=1},
            {id=1240193, rank=1, level=20, cost=4000, chain="slam", order=1},
            {id=402927, rank=1, level=20, cost=4000, chain="spell402927", order=1},
            {id=6192, rank=3, level=22, cost=6000, chain="battleShout", order=3, previous=5242},
            {id=5246, rank=1, level=22, cost=6000, chain="spell5246", order=1},
            {id=7405, rank=2, level=22, cost=6000, chain="sunderArmor", order=2, previous=7386},
            {id=6190, rank=2, level=24, cost=8000, chain="demoralizingShout", order=2, previous=1160},
            {id=5308, rank=1, level=24, cost=8000, chain="execute", order=1},
            {id=1608, rank=4, level=24, cost=8000, chain="heroicStrike", order=4, previous=285},
            {id=6574, rank=2, level=24, cost=8000, chain="revenge", order=2, previous=6572},
            {id=1161, rank=1, level=26, cost=10000, chain="spell1161", order=1},
            {id=6178, rank=2, level=26, cost=10000, chain="charge", order=2, previous=100},
            {id=7400, rank=2, level=26, cost=10000, chain="mockingBlow", order=2, previous=694},
            {id=7887, rank=2, level=28, cost=11000, chain="overpower", order=2, previous=7384},
            {id=871, rank=1, level=28, cost=11000, chain="spell871", order=1, previous=71},
            {id=8204, rank=3, level=28, cost=11000, chain="thunderClap", order=3, previous=8198},
            {id=18499, rank=1, level=30, cost=12000, chain="spell18499", order=1, previous=2458},
            {id=7369, rank=2, level=30, cost=12000, chain="cleave", order=2, previous=845},
            {id=6548, rank=4, level=30, cost=12000, chain="rend", order=4, previous=6547},
            {id=1464, rank=2, level=30, cost=12000, chain="slam", order=2, previous=1240193},
            {id=11549, rank=4, level=32, cost=14000, chain="battleShout", order=4, previous=6192},
            {id=20658, rank=2, level=32, cost=14000, chain="execute", order=2, previous=5308},
            {id=7372, rank=2, level=32, cost=14000, chain="hamstring", order=2, previous=1715},
            {id=11564, rank=5, level=32, cost=14000, chain="heroicStrike", order=5, previous=1608},
            {id=1671, rank=2, level=32, cost=14000, chain="shieldBash", order=2, previous=72},
            {id=11554, rank=3, level=34, cost=16000, chain="demoralizingShout", order=3, previous=6190},
            {id=7379, rank=3, level=34, cost=16000, chain="revenge", order=3, previous=6574},
            {id=8380, rank=3, level=34, cost=16000, chain="sunderArmor", order=3, previous=7405},
            {id=7402, rank=3, level=36, cost=18000, chain="mockingBlow", order=3, previous=7400},
            {id=1680, rank=1, level=36, cost=18000, chain="spell1680", order=1, previous=2458},
            {id=6552, rank=1, level=38, cost=20000, chain="pummel", order=1, previous=2458},
            {id=8820, rank=3, level=38, cost=20000, chain="slam", order=3, previous=1464},
            {id=8205, rank=4, level=38, cost=20000, chain="thunderClap", order=4, previous=8204},
            {id=11608, rank=3, level=40, cost=22000, chain="cleave", order=3, previous=7369},
            {id=20660, rank=3, level=40, cost=22000, chain="execute", order=3, previous=20658},
            {id=11565, rank=6, level=40, cost=22000, chain="heroicStrike", order=6, previous=11564},
            {id=750, rank=1, level=40, cost=22000, chain="spell750", order=1},
            {id=11572, rank=5, level=40, cost=22000, chain="rend", order=5, previous=6548},
            {id=11550, rank=5, level=42, cost=32000, chain="battleShout", order=5, previous=11549},
            {id=20616, rank=2, level=42, cost=32000, chain="intercept", order=2, previous=20252},
            {id=11555, rank=4, level=44, cost=34000, chain="demoralizingShout", order=4, previous=11554},
            {id=11584, rank=3, level=44, cost=34000, chain="overpower", order=3, previous=7887},
            {id=11600, rank=4, level=44, cost=34000, chain="revenge", order=4, previous=7379},
            {id=11578, rank=3, level=46, cost=36000, chain="charge", order=3, previous=6178},
            {id=20559, rank=4, level=46, cost=36000, chain="mockingBlow", order=4, previous=7402},
            {id=11604, rank=4, level=46, cost=36000, chain="slam", order=4, previous=8820},
            {id=11596, rank=4, level=46, cost=36000, chain="sunderArmor", order=4, previous=8380},
            {id=23892, rank=2, level=48, cost=2000, chain="bloodthirst", order=2, previous=23881, talent=23881},
            {id=20661, rank=4, level=48, cost=40000, chain="execute", order=4, previous=20660},
            {id=11566, rank=7, level=48, cost=40000, chain="heroicStrike", order=7, previous=11565},
            {id=21551, rank=2, level=48, cost=2000, chain="mortalStrike", order=2, previous=12294, talent=12294},
            {id=23923, rank=2, level=48, cost=2000, chain="shieldSlam", order=2, previous=23922, talent=23922},
            {id=11580, rank=5, level=48, cost=40000, chain="thunderClap", order=5, previous=8205},
            {id=11609, rank=4, level=50, cost=42000, chain="cleave", order=4, previous=11608},
            {id=1719, rank=1, level=50, cost=42000, chain="spell1719", order=1, previous=2458},
            {id=11573, rank=6, level=50, cost=42000, chain="rend", order=6, previous=11572},
            {id=11551, rank=6, level=52, cost=54000, chain="battleShout", order=6, previous=11550},
            {id=20617, rank=3, level=52, cost=54000, chain="intercept", order=3, previous=20616},
            {id=1672, rank=3, level=52, cost=54000, chain="shieldBash", order=3, previous=1671},
            {id=23893, rank=3, level=54, cost=2800, chain="bloodthirst", order=3, previous=23892, talent=23881},
            {id=11556, rank=5, level=54, cost=56000, chain="demoralizingShout", order=5, previous=11555},
            {id=7373, rank=3, level=54, cost=56000, chain="hamstring", order=3, previous=7372},
            {id=21552, rank=3, level=54, cost=2800, chain="mortalStrike", order=3, previous=21551, talent=12294},
            {id=11601, rank=5, level=54, cost=56000, chain="revenge", order=5, previous=11600},
            {id=23924, rank=3, level=54, cost=2800, chain="shieldSlam", order=3, previous=23923, talent=23922},
            {id=11605, rank=5, level=54, cost=56000, chain="slam", order=5, previous=11604},
            {id=20662, rank=5, level=56, cost=58000, chain="execute", order=5, previous=20661},
            {id=11567, rank=8, level=56, cost=58000, chain="heroicStrike", order=8, previous=11566},
            {id=20560, rank=5, level=56, cost=58000, chain="mockingBlow", order=5, previous=20559},
            {id=6554, rank=2, level=58, cost=60000, chain="pummel", order=2, previous=6552},
            {id=11597, rank=5, level=58, cost=60000, chain="sunderArmor", order=5, previous=11596},
            {id=11581, rank=6, level=58, cost=60000, chain="thunderClap", order=6, previous=11580},
            {id=23894, rank=4, level=60, cost=3100, chain="bloodthirst", order=4, previous=23893, talent=23881},
            {id=20569, rank=5, level=60, cost=62000, chain="cleave", order=5, previous=11609},
            {id=21553, rank=4, level=60, cost=3100, chain="mortalStrike", order=4, previous=21552, talent=12294},
            {id=11585, rank=4, level=60, cost=62000, chain="overpower", order=4, previous=11584},
            {id=11574, rank=7, level=60, cost=62000, chain="rend", order=7, previous=11573},
            {id=23925, rank=4, level=60, cost=3100, chain="shieldSlam", order=4, previous=23924, talent=23922},
        },
        chains={
            battleShout={6673,5242,6192,11549,11550,11551},
            charge={100,6178,11578},
            rend={772,6546,6547,6548,11572,11573,11574},
            thunderClap={6343,8198,8204,8205,11580,11581},
            hamstring={1715,7372,7373},
            heroicStrike={78,284,285,1608,11564,11565,11566,11567},
            overpower={7384,7887,11584,11585},
            shieldBash={72,1671,1672},
            demoralizingShout={1160,6190,11554,11555,11556},
            revenge={6572,6574,7379,11600,11601},
            mockingBlow={694,7400,7402,20559,20560},
            cleave={845,7369,11608,11609,20569},
            slam={1240193,1464,8820,11604,11605},
            sunderArmor={7386,7405,8380,11596,11597},
            execute={5308,20658,20660,20661,20662},
            pummel={6552,6554},
            intercept={20252,20616,20617},
            bloodthirst={23881,23892,23893,23894},
            mortalStrike={12294,21551,21552,21553},
            shieldSlam={23922,23923,23924,23925},
        },
    }
end
