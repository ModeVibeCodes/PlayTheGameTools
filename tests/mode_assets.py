"""Runtime texture silhouettes, neutral material pixels and licensed font packaging."""
from pathlib import Path
import struct
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from build_release import payload, ROOT

files, _, _ = payload()
sizes={'Surface':(128,128),'Border':(128,128),'Selection':(128,4),
       'ControlSurface':(64,32),'ControlBorder':(64,32),'CheckSurface':(24,24),
       'CheckBorder':(24,24),'ToggleSurface':(32,16),'ToggleBorder':(32,16),
       'Thumb':(32,32),'ScrollThumb':(4,64),'Divider':(256,4),'Logo':(128,128)}
for name, size in sizes.items():
    data = files['Media/Textures/Mode/' + name + '.tga']
    h = struct.unpack('<BBBHHBHHHHBB', data[:18])
    assert h[2] == 2 and h[10] == 32 and h[8:10] == size
    pixels = [tuple(data[i:i+4]) for i in range(18, 18+size[0]*size[1]*4, 4)]
    assert len(pixels) == size[0] * size[1]
    assert any(a<128 for _,_,_,a in pixels), 'transparent/antialiased silhouette, not an opaque rectangular backing'
    if name.endswith('Surface'):
        assert all(b == g == r for b, g, r, _ in pixels), 'no blue cast in body material'
        assert pixels[(size[1]//2)*size[0]+size[0]//2][3] == 255
    elif name.endswith('Border'):
        assert pixels[(size[1]//2)*size[0]+size[0]//2][3] == 0, 'border does not wash the body'
        assert any(a > 200 for _, _, _, a in pixels)
    elif name=='Selection':
        assert any(a > 200 and b > 240 and g > 225 and r < 4 for b, g, r, a in pixels), 'cyan selection core'
        left=max(pixels[y*size[0]+2][3] for y in range(size[1]))
        right=max(pixels[y*size[0]+size[0]-1][3] for y in range(size[1]))
        assert left>220 and right<8,'selection fades toward the right'
    elif name=='Thumb':
        assert pixels[0][3]==0 and pixels[16*32+16][3]==255,'circular thumb silhouette'
    elif name=='Logo':
        assert pixels[0][3]==0 and any(a>200 for _,_,_,a in pixels),'transparent owner logo'
for name in ('Lato-Regular.ttf', 'Lato-Bold.ttf'):
    assert files['Media/Fonts/' + name][:4] == b'\x00\x01\x00\x00'
assert b'SIL OPEN FONT LICENSE' in files['LICENSES/Lato-OFL.txt']
print('PASS rounded Figma controls, circular thumb, neutral sheen, fading/beveled lines, transparent logo and font license')
