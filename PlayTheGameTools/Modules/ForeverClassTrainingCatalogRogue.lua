local _, addon = ...
local P = addon.ForeverTrainingData
--[[
Class catalog facts adapted from What's Training? by Sveng / fusionpit.
Forever revision: dd4256471d65149ad6e8d00ad1f18fa7c31e7a6e; Classes/Camelot/Rogue.lua
Normalized source SHA-256: a63a7aa658f8c3088e2e31007c5c5462c3e6e9413d9f9cc769268d983e295a03
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
P.factories.ROGUE = function()
    return {
        version="FOREVER-4.0-rogue-1", class="ROGUE",
        reference="dd4256471d65149ad6e8d00ad1f18fa7c31e7a6e", sourceHash="a63a7aa658f8c3088e2e31007c5c5462c3e6e9413d9f9cc769268d983e295a03",
        records={
            {id=1784, rank=1, level=1, cost=10, chain="stealth", order=1},
            {id=53, rank=1, level=4, cost=100, chain="backstab", order=1},
            {id=921, rank=1, level=4, cost=100, chain="spell921", order=1},
            {id=1776, rank=1, level=6, cost=100, chain="gouge", order=1},
            {id=1757, rank=2, level=6, cost=100, chain="sinisterStrike", order=2, previous=1752},
            {id=5277, rank=1, level=8, cost=200, chain="spell5277", order=1},
            {id=6760, rank=2, level=8, cost=200, chain="eviscerate", order=2, previous=2098},
            {id=674, rank=1, level=10, cost=300, chain="spell674", order=1},
            {id=6770, rank=1, level=10, cost=300, chain="sap", order=1},
            {id=5171, rank=1, level=10, cost=300, chain="sliceAndDice", order=1},
            {id=2983, rank=1, level=10, cost=300, chain="sprint", order=1},
            {id=2589, rank=2, level=12, cost=800, chain="backstab", order=2, previous=53},
            {id=1766, rank=1, level=12, cost=800, chain="kick", order=1},
            {id=3127, rank=1, level=12, cost=800, chain="spell3127", order=1},
            {id=8647, rank=1, level=14, cost=1200, chain="exposeArmor", order=1},
            {id=703, rank=1, level=14, cost=1200, chain="garrote", order=1},
            {id=1758, rank=3, level=14, cost=1200, chain="sinisterStrike", order=3, previous=1757},
            {id=6761, rank=3, level=16, cost=1800, chain="eviscerate", order=3, previous=6760},
            {id=1966, rank=1, level=16, cost=1800, chain="feint", order=1},
            {id=1804, rank=1, level=16, cost=1800, chain="spell1804", order=1},
            {id=8676, rank=1, level=18, cost=2900, chain="ambush", order=1},
            {id=1777, rank=2, level=18, cost=2900, chain="gouge", order=2, previous=1776},
            {id=2590, rank=3, level=20, cost=3000, chain="backstab", order=3, previous=2589},
            {id=3420, rank=1, level=20, cost=3000, chain="cripplingPoison", order=1, skill={id=40, rank=1}},
            {id=1943, rank=1, level=20, cost=3000, chain="rupture", order=1},
            {id=1785, rank=2, level=20, cost=3000, chain="stealth", order=2, previous=1784},
            {id=1725, rank=1, level=22, cost=4000, chain="spell1725", order=1},
            {id=8631, rank=2, level=22, cost=4000, chain="garrote", order=2, previous=703},
            {id=1759, rank=4, level=22, cost=4000, chain="sinisterStrike", order=4, previous=1758},
            {id=1856, rank=1, level=22, cost=4000, chain="vanish", order=1},
            {id=2836, rank=1, level=24, cost=5000, chain="spell2836", order=1},
            {id=6762, rank=4, level=24, cost=5000, chain="eviscerate", order=4, previous=6761},
            {id=5763, rank=1, level=24, cost=5000, chain="mindNumbingPoison", order=1, skill={id=40, rank=100}},
            {id=8724, rank=2, level=26, cost=6000, chain="ambush", order=2, previous=8676},
            {id=1833, rank=1, level=26, cost=6000, chain="spell1833", order=1},
            {id=8649, rank=2, level=26, cost=6000, chain="exposeArmor", order=2, previous=8647},
            {id=1767, rank=2, level=26, cost=6000, chain="kick", order=2, previous=1766},
            {id=2591, rank=4, level=28, cost=8000, chain="backstab", order=4, previous=2590},
            {id=6768, rank=2, level=28, cost=8000, chain="feint", order=2, previous=1966},
            {id=8687, rank=2, level=28, cost=8000, chain="instantPoison", order=1, skill={id=40, rank=120}},
            {id=8639, rank=2, level=28, cost=8000, chain="rupture", order=2, previous=1943},
            {id=2070, rank=2, level=28, cost=8000, chain="sap", order=2, previous=6770},
            {id=2835, rank=1, level=30, cost=10000, chain="deadlyPoison", order=1, skill={id=40, rank=130}},
            {id=1842, rank=1, level=30, cost=10000, chain="spell1842", order=1, previous=2836},
            {id=8632, rank=3, level=30, cost=10000, chain="garrote", order=3, previous=8631},
            {id=408, rank=1, level=30, cost=10000, chain="kidneyShot", order=1},
            {id=1760, rank=5, level=30, cost=10000, chain="sinisterStrike", order=5, previous=1759},
            {id=8623, rank=5, level=32, cost=12000, chain="eviscerate", order=5, previous=6762},
            {id=8629, rank=3, level=32, cost=12000, chain="gouge", order=3, previous=1777},
            {id=13220, rank=1, level=32, cost=12000, chain="woundPoison", order=1, skill={id=40, rank=140}},
            {id=8725, rank=3, level=34, cost=14000, chain="ambush", order=3, previous=8724},
            {id=2094, rank=1, level=34, cost=14000, chain="spell2094", order=1, skill={id=40, rank=1}},
            {id=6510, rank=1, level=34, cost=14000, chain="spell6510", order=1, skill={id=40, rank=150}},
            {id=8696, rank=2, level=34, cost=14000, chain="sprint", order=2, previous=2983},
            {id=8721, rank=5, level=36, cost=16000, chain="backstab", order=5, previous=2591},
            {id=8650, rank=3, level=36, cost=16000, chain="exposeArmor", order=3, previous=8649},
            {id=8691, rank=3, level=36, cost=16000, chain="instantPoison", order=2, skill={id=40, rank=160}},
            {id=8640, rank=3, level=36, cost=16000, chain="rupture", order=3, previous=8639},
            {id=2837, rank=2, level=38, cost=18000, chain="deadlyPoison", order=2, skill={id=40, rank=170}},
            {id=8633, rank=4, level=38, cost=18000, chain="garrote", order=4, previous=8632},
            {id=8694, rank=2, level=38, cost=18000, chain="mindNumbingPoison", order=2, skill={id=40, rank=170}},
            {id=8621, rank=6, level=38, cost=18000, chain="sinisterStrike", order=6, previous=1760},
            {id=8624, rank=6, level=40, cost=20000, chain="eviscerate", order=6, previous=8623},
            {id=8637, rank=3, level=40, cost=20000, chain="feint", order=3, previous=6768},
            {id=399956, rank=1, level=40, cost=10000, chain="mutilate", order=2, previous=1310706, talent=1310706},
            {id=1860, rank=1, level=40, cost=20000, chain="spell1860", order=1},
            {id=1786, rank=3, level=40, cost=20000, chain="stealth", order=3, previous=1785},
            {id=13228, rank=2, level=40, cost=20000, chain="woundPoison", order=2, skill={id=40, rank=180}},
            {id=11267, rank=4, level=42, cost=27000, chain="ambush", order=4, previous=8725},
            {id=1768, rank=3, level=42, cost=27000, chain="kick", order=3, previous=1767},
            {id=6774, rank=2, level=42, cost=27000, chain="sliceAndDice", order=2, previous=5171},
            {id=1857, rank=2, level=42, cost=27000, chain="vanish", order=2, previous=1856},
            {id=11279, rank=6, level=44, cost=29000, chain="backstab", order=6, previous=8721},
            {id=11341, rank=4, level=44, cost=29000, chain="instantPoison", order=3, skill={id=40, rank=200}},
            {id=11273, rank=4, level=44, cost=29000, chain="rupture", order=4, previous=8640},
            {id=11357, rank=3, level=46, cost=31000, chain="deadlyPoison", order=3, skill={id=40, rank=210}},
            {id=11197, rank=4, level=46, cost=31000, chain="exposeArmor", order=4, previous=8650},
            {id=11289, rank=5, level=46, cost=31000, chain="garrote", order=5, previous=8633},
            {id=11285, rank=4, level=46, cost=31000, chain="gouge", order=4, previous=8629},
            {id=11293, rank=7, level=46, cost=31000, chain="sinisterStrike", order=7, previous=8621},
            {id=11299, rank=7, level=48, cost=33000, chain="eviscerate", order=7, previous=8624},
            {id=11297, rank=3, level=48, cost=33000, chain="sap", order=3, previous=2070},
            {id=13229, rank=3, level=48, cost=33000, chain="woundPoison", order=3, skill={id=40, rank=220}},
            {id=11268, rank=5, level=50, cost=35000, chain="ambush", order=5, previous=11267},
            {id=3421, rank=2, level=50, cost=35000, chain="cripplingPoison", order=2, skill={id=40, rank=230}},
            {id=8643, rank=2, level=50, cost=35000, chain="kidneyShot", order=2, previous=408},
            {id=1241582, rank=2, level=50, cost=35000, chain="mutilate", order=3, previous=399956, talent=1310706},
            {id=11280, rank=7, level=52, cost=46000, chain="backstab", order=7, previous=11279},
            {id=11303, rank=4, level=52, cost=46000, chain="feint", order=4, previous=8637},
            {id=11342, rank=5, level=52, cost=46000, chain="instantPoison", order=4, skill={id=40, rank=240}},
            {id=11400, rank=3, level=52, cost=46000, chain="mindNumbingPoison", order=3, skill={id=40, rank=240}},
            {id=11274, rank=5, level=52, cost=46000, chain="rupture", order=5, previous=11273},
            {id=11358, rank=4, level=54, cost=48000, chain="deadlyPoison", order=4, skill={id=40, rank=250}},
            {id=11290, rank=6, level=54, cost=48000, chain="garrote", order=6, previous=11289},
            {id=11294, rank=8, level=54, cost=48000, chain="sinisterStrike", order=8, previous=11293},
            {id=11300, rank=8, level=56, cost=50000, chain="eviscerate", order=8, previous=11299},
            {id=11198, rank=5, level=56, cost=50000, chain="exposeArmor", order=5, previous=11197},
            {id=13230, rank=4, level=56, cost=50000, chain="woundPoison", order=4, skill={id=40, rank=260}},
            {id=11269, rank=6, level=58, cost=52000, chain="ambush", order=6, previous=11268},
            {id=1769, rank=4, level=58, cost=52000, chain="kick", order=4, previous=1768},
            {id=11305, rank=3, level=58, cost=52000, chain="sprint", order=3, previous=8696},
            {id=11281, rank=8, level=60, cost=54000, chain="backstab", order=8, previous=11280},
            {id=11286, rank=5, level=60, cost=54000, chain="gouge", order=5, previous=11285},
            {id=11343, rank=6, level=60, cost=54000, chain="instantPoison", order=5, skill={id=40, rank=280}},
            {id=1241584, rank=3, level=60, cost=54000, chain="mutilate", order=4, previous=1241582, talent=1310706},
            {id=11275, rank=6, level=60, cost=54000, chain="rupture", order=6, previous=11274},
            {id=1787, rank=4, level=60, cost=54000, chain="stealth", order=4, previous=1786},
        },
        chains={
            stealth={1784,1785,1786,1787},
            backstab={53,2589,2590,2591,8721,11279,11280,11281},
            gouge={1776,1777,8629,11285,11286},
            sinisterStrike={1752,1757,1758,1759,1760,8621,11293,11294},
            eviscerate={2098,6760,6761,6762,8623,8624,11299,11300},
            sap={6770,2070,11297},
            sliceAndDice={5171,6774},
            sprint={2983,8696,11305},
            kick={1766,1767,1768,1769},
            exposeArmor={8647,8649,8650,11197,11198},
            garrote={703,8631,8632,8633,11289,11290},
            feint={1966,6768,8637,11303},
            ambush={8676,8724,8725,11267,11268,11269},
            cripplingPoison={3420,3421},
            rupture={1943,8639,8640,11273,11274,11275},
            vanish={1856,1857},
            mindNumbingPoison={5763,8694,11400},
            instantPoison={8687,8691,11341,11342,11343},
            deadlyPoison={2835,2837,11357,11358},
            kidneyShot={408,8643},
            woundPoison={13220,13228,13229,13230},
            mutilate={1310706,399956,1241582,1241584},
        },
    }
end
