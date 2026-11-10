"""Runtime texture silhouettes, neutral material pixels and licensed font packaging."""
from pathlib import Path
import struct
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from build_release import payload, ROOT

files, _, _ = payload()
for name, size in {'Surface': (128, 128), 'Border': (128, 128), 'Selection': (8, 64)}.items():
    data = files['Media/Textures/Mode/' + name + '.tga']
    h = struct.unpack('<BBBHHBHHHHBB', data[:18])
    assert h[2] == 2 and h[10] == 32 and h[8:10] == size
    pixels = [tuple(data[i:i+4]) for i in range(18, 18+size[0]*size[1]*4, 4)]
    assert len(pixels) == size[0] * size[1]
    assert pixels[0][3] == 0, 'transparent corner, not a rectangular backing'
    if name == 'Surface':
        assert all(b == g == r for b, g, r, _ in pixels), 'no blue cast in body material'
        assert pixels[(size[1]//2)*size[0]+size[0]//2][3] == 255
    elif name == 'Border':
        assert pixels[(size[1]//2)*size[0]+size[0]//2][3] == 0, 'border does not wash the body'
        assert any(a > 200 for _, _, _, a in pixels)
    else:
        assert any(a > 200 and b > 240 and g > 225 and r < 4 for b, g, r, a in pixels), 'cyan selection core'
for name in ('Lato-Regular.ttf', 'Lato-Bold.ttf'):
    assert files['Media/Fonts/' + name][:4] == b'\x00\x01\x00\x00'
assert b'SIL OPEN FONT LICENSE' in files['LICENSES/Lato-OFL.txt']
print('PASS Figma texture geometry/neutrality/transparency, cyan selection and packaged Lato license')
