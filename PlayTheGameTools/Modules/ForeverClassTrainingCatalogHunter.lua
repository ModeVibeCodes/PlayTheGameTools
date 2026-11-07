local _, addon = ...
local P = addon.ForeverTrainingData
--[[
Class catalog facts adapted from What's Training? by Sveng / fusionpit.
Forever revision: dd4256471d65149ad6e8d00ad1f18fa7c31e7a6e; Classes/Camelot/Hunter.lua
Normalized source SHA-256: 72da1043ff7b592c20bb5050676c81845d557e4d06ac13c9294c542cf28870a6
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
P.factories.HUNTER = function()
    return {
        version="FOREVER-4.0-hunter-1", class="HUNTER",
        reference="dd4256471d65149ad6e8d00ad1f18fa7c31e7a6e", sourceHash="72da1043ff7b592c20bb5050676c81845d557e4d06ac13c9294c542cf28870a6",
        records={
            {id=1494, rank=1, level=1, cost=10, chain="spell1494", order=1},
            {id=13163, rank=1, level=4, cost=100, chain="spell13163", order=1},
            {id=1978, rank=1, level=4, cost=100, chain="spell1978", order=1},
            {id=3044, rank=1, level=6, cost=100, chain="spell3044", order=1},
            {id=1130, rank=1, level=6, cost=100, chain="spell1130", order=1},
            {id=5116, rank=1, level=8, cost=200, chain="spell5116", order=1},
            {id=3127, rank=1, level=8, cost=200, chain="spell3127", order=1},
            {id=14260, rank=2, level=8, cost=200, chain="spell14260", order=1},
            {id=13165, rank=1, level=10, cost=400, chain="spell13165", order=1},
            {id=13549, rank=2, level=10, cost=400, chain="spell13549", order=1, previous=1978},
            {id=19883, rank=1, level=10, cost=400, chain="spell19883", order=1},
            {id=14281, rank=2, level=12, cost=600, chain="spell14281", order=1, previous=3044},
            {id=20736, rank=1, level=12, cost=600, chain="spell20736", order=1},
            {id=136, rank=1, level=12, cost=600, chain="spell136", order=1, previous=1515},
            {id=2974, rank=1, level=12, cost=600, chain="spell2974", order=1},
            {id=6197, rank=1, level=14, cost=1200, chain="spell6197", order=1},
            {id=1002, rank=1, level=14, cost=1200, chain="spell1002", order=1},
            {id=1513, rank=1, level=14, cost=1200, chain="spell1513", order=1},
            {id=13795, rank=1, level=16, cost=1500, chain="spell13795", order=1},
            {id=1495, rank=1, level=16, cost=1500, chain="spell1495", order=1},
            {id=14261, rank=3, level=16, cost=1500, chain="spell14261", order=1, previous=14260},
            {id=14318, rank=2, level=18, cost=1600, chain="spell14318", order=1, previous=13165},
            {id=2643, rank=1, level=18, cost=1600, chain="spell2643", order=1},
            {id=13550, rank=3, level=18, cost=1600, chain="spell13550", order=1, previous=13549},
            {id=19884, rank=1, level=18, cost=1600, chain="spell19884", order=1},
            {id=19434, rank=1, level=20, cost=2100, chain="spell19434", order=1},
            {id=14282, rank=3, level=20, cost=2100, chain="spell14282", order=1, previous=14281},
            {id=5118, rank=1, level=20, cost=2100, chain="spell5118", order=1},
            {id=781, rank=1, level=20, cost=2100, chain="spell781", order=1},
            {id=14274, rank=2, level=20, cost=2100, chain="spell14274", order=1, previous=20736},
            {id=674, rank=1, level=20, cost=2100, chain="spell674", order=1},
            {id=1499, rank=1, level=20, cost=2100, chain="spell1499", order=1},
            {id=3111, rank=2, level=20, cost=2100, chain="spell3111", order=1, previous=136},
            {id=14323, rank=2, level=22, cost=7000, chain="spell14323", order=1, previous=1130},
            {id=3043, rank=1, level=22, cost=7000, chain="spell3043", order=1},
            {id=1462, rank=1, level=24, cost=7200, chain="spell1462", order=1},
            {id=14262, rank=4, level=24, cost=7200, chain="spell14262", order=1, previous=14261},
            {id=19885, rank=1, level=24, cost=7200, chain="spell19885", order=1},
            {id=14302, rank=2, level=26, cost=7400, chain="spell14302", order=1, previous=13795},
            {id=3045, rank=1, level=26, cost=7400, chain="spell3045", order=1},
            {id=13551, rank=4, level=26, cost=7400, chain="spell13551", order=1, previous=13550},
            {id=19880, rank=1, level=26, cost=7400, chain="spell19880", order=1},
            {id=20900, rank=2, level=28, cost=7500, chain="spell20900", order=1, previous=19434},
            {id=14283, rank=4, level=28, cost=7500, chain="spell14283", order=1, previous=14282},
            {id=14319, rank=3, level=28, cost=7500, chain="spell14319", order=1, previous=14318},
            {id=13809, rank=1, level=28, cost=7500, chain="spell13809", order=1},
            {id=3661, rank=3, level=28, cost=7500, chain="spell3661", order=1, previous=3111},
            {id=13161, rank=1, level=30, cost=7600, chain="spell13161", order=1},
            {id=1242634, rank=2, level=30, cost=7600, chain="spell1242634", order=1, previous=19306, talent=19306},
            {id=15629, rank=3, level=30, cost=7600, chain="spell15629", order=1, previous=14274},
            {id=5384, rank=1, level=30, cost=7600, chain="spell5384", order=1},
            {id=14269, rank=2, level=30, cost=7600, chain="spell14269", order=1, previous=1495},
            {id=14326, rank=2, level=30, cost=7600, chain="spell14326", order=1, previous=1513},
            {id=1543, rank=1, level=32, cost=10000, chain="spell1543", order=1},
            {id=14263, rank=5, level=32, cost=10000, chain="spell14263", order=1, previous=14262},
            {id=19878, rank=1, level=32, cost=10000, chain="spell19878", order=1},
            {id=1299348, rank=2, level=32, cost=10000, chain="spell1299348", order=1, previous=1299346, talent=1299346},
            {id=14272, rank=2, level=34, cost=11000, chain="spell14272", order=1, previous=781},
            {id=13813, rank=1, level=34, cost=11000, chain="spell13813", order=1},
            {id=13552, rank=5, level=34, cost=11000, chain="spell13552", order=1, previous=13551},
            {id=20901, rank=3, level=36, cost=13000, chain="spell20901", order=1, previous=20900},
            {id=14284, rank=5, level=36, cost=13000, chain="spell14284", order=1, previous=14283},
            {id=14303, rank=3, level=36, cost=13000, chain="spell14303", order=1, previous=14302},
            {id=3662, rank=4, level=36, cost=13000, chain="spell3662", order=1, previous=3661},
            {id=1293525, rank=2, level=36, cost=13000, chain="spell1293525", order=1, previous=1293241, talent=1293241},
            {id=3034, rank=1, level=36, cost=13000, chain="spell3034", order=1},
            {id=14320, rank=4, level=38, cost=15000, chain="spell14320", order=1, previous=14319},
            {id=14267, rank=2, level=38, cost=15000, chain="spell14267", order=1, previous=2974},
            {id=1299445, rank=2, level=40, cost=16000, chain="spell1299445", order=1, previous=13161},
            {id=13159, rank=1, level=40, cost=16000, chain="spell13159", order=1},
            {id=15630, rank=4, level=40, cost=16000, chain="spell15630", order=1, previous=15629},
            {id=14310, rank=2, level=40, cost=16000, chain="spell14310", order=1, previous=1499},
            {id=14324, rank=3, level=40, cost=16000, chain="spell14324", order=1, previous=14323},
            {id=8737, rank=1, level=40, cost=16000, chain="spell8737", order=1},
            {id=14264, rank=6, level=40, cost=16000, chain="spell14264", order=1, previous=14263},
            {id=19882, rank=1, level=40, cost=16000, chain="spell19882", order=1},
            {id=19506, rank=3, level=40, cost=16000, chain="spell19506", order=1, previous=1299348, talent=1299346},
            {id=1510, rank=1, level=40, cost=16000, chain="spell1510", order=1},
            {id=20909, rank=3, level=42, cost=22000, chain="spell20909", order=1, previous=1242634, talent=19306},
            {id=13553, rank=6, level=42, cost=22000, chain="spell13553", order=1, previous=13552},
            {id=20902, rank=4, level=44, cost=23000, chain="spell20902", order=1, previous=20901},
            {id=14285, rank=6, level=44, cost=23000, chain="spell14285", order=1, previous=14284},
            {id=14316, rank=2, level=44, cost=23000, chain="spell14316", order=1, previous=13813},
            {id=13542, rank=5, level=44, cost=23000, chain="spell13542", order=1, previous=3662},
            {id=14270, rank=3, level=44, cost=23000, chain="spell14270", order=1, previous=14269},
            {id=20043, rank=1, level=46, cost=28000, chain="spell20043", order=1},
            {id=14304, rank=4, level=46, cost=28000, chain="spell14304", order=1, previous=14303},
            {id=14327, rank=3, level=46, cost=28000, chain="spell14327", order=1, previous=14326},
            {id=14279, rank=2, level=46, cost=28000, chain="spell14279", order=1, previous=3034},
            {id=14321, rank=5, level=48, cost=29000, chain="spell14321", order=1, previous=14320},
            {id=14273, rank=3, level=48, cost=29000, chain="spell14273", order=1, previous=14272},
            {id=14265, rank=7, level=48, cost=29000, chain="spell14265", order=1, previous=14264},
            {id=1310785, rank=2, level=48, cost=29000, chain="spell1310785", order=1, previous=1310687, talent=1310687},
            {id=1293526, rank=3, level=48, cost=29000, chain="spell1293526", order=1, previous=1293525, talent=1293241},
            {id=1299446, rank=3, level=50, cost=30000, chain="spell1299446", order=1, previous=1299445},
            {id=15631, rank=5, level=50, cost=30000, chain="spell15631", order=1, previous=15630},
            {id=13554, rank=7, level=50, cost=30000, chain="spell13554", order=1, previous=13553},
            {id=19879, rank=1, level=50, cost=30000, chain="spell19879", order=1},
            {id=20905, rank=4, level=50, cost=30000, chain="spell20905", order=1, previous=19506, talent=1299346},
            {id=14294, rank=2, level=50, cost=30000, chain="spell14294", order=1, previous=1510},
            {id=20903, rank=5, level=52, cost=36000, chain="spell20903", order=1, previous=20902},
            {id=14286, rank=7, level=52, cost=36000, chain="spell14286", order=1, previous=14285},
            {id=13543, rank=6, level=52, cost=36000, chain="spell13543", order=1, previous=13542},
            {id=20910, rank=4, level=54, cost=37000, chain="spell20910", order=1, previous=20909, talent=19306},
            {id=14317, rank=3, level=54, cost=37000, chain="spell14317", order=1, previous=14316},
            {id=20190, rank=2, level=56, cost=38000, chain="spell20190", order=1, previous=20043},
            {id=14305, rank=5, level=56, cost=38000, chain="spell14305", order=1, previous=14304},
            {id=14266, rank=8, level=56, cost=38000, chain="spell14266", order=1, previous=14265},
            {id=14280, rank=3, level=56, cost=38000, chain="spell14280", order=1, previous=14279},
            {id=14322, rank=6, level=58, cost=39000, chain="spell14322", order=1, previous=14321},
            {id=14325, rank=4, level=58, cost=39000, chain="spell14325", order=1, previous=14324},
            {id=14271, rank=4, level=58, cost=39000, chain="spell14271", order=1, previous=14270},
            {id=13555, rank=8, level=58, cost=39000, chain="spell13555", order=1, previous=13554},
            {id=1310786, rank=3, level=58, cost=39000, chain="spell1310786", order=1, previous=1310785, talent=1310687},
            {id=14295, rank=3, level=58, cost=39000, chain="spell14295", order=1, previous=14294},
            {id=20904, rank=6, level=60, cost=42000, chain="spell20904", order=1, previous=20903},
            {id=14287, rank=8, level=60, cost=42000, chain="spell14287", order=1, previous=14286},
            {id=1299447, rank=4, level=60, cost=39000, chain="spell1299447", order=1, previous=1299446},
            {id=15632, rank=6, level=60, cost=42000, chain="spell15632", order=1, previous=15631},
            {id=14311, rank=3, level=60, cost=42000, chain="spell14311", order=1, previous=14310},
            {id=13544, rank=7, level=60, cost=42000, chain="spell13544", order=1, previous=13543},
            {id=1293527, rank=4, level=60, cost=42000, chain="spell1293527", order=1, previous=1293526, talent=1293241},
            {id=20906, rank=5, level=60, cost=42000, chain="spell20906", order=1, previous=20905, talent=1299346},
            {id=14268, rank=3, level=60, cost=42000, chain="spell14268", order=1, previous=14267},
        },
        chains={
        },
    }
end
