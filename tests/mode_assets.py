"""Runtime texture silhouettes, neutral material pixels and licensed font packaging."""
from pathlib import Path
import struct
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from build_release import payload, ROOT

files, _, _ = payload()
sizes={'Surface':(128,128),'Border':(128,128),'Selection':(128,4),
       'ControlSurface':(64,32),'ControlBorder':(64,32),'CheckSurfaceRound':(32,32),
       'CheckBorderRound':(32,32),'ToggleSurfacePill':(32,16),'ToggleBorderPill':(32,16),
       'Thumb':(32,32),'ScrollThumb':(4,64),'Divider':(256,4),'Logo':(128,128)}
for name, size in sizes.items():
    data = files['Media/Textures/Mode/' + name + '.tga']
    h = struct.unpack('<BBBHHBHHHHBB', data[:18])
    assert h[2] == 2 and h[10] == 32 and h[8:10] == size
    assert all(n>0 and n&(n-1)==0 for n in size),'runtime textures must have power-of-two dimensions'
    pixels = [tuple(data[i:i+4]) for i in range(18, 18+size[0]*size[1]*4, 4)]
    assert len(pixels) == size[0] * size[1]
    assert any(a<128 for _,_,_,a in pixels), 'transparent/antialiased silhouette, not an opaque rectangular backing'
    if 'Surface' in name:
        assert all(b == g == r for b, g, r, _ in pixels), 'no blue cast in body material'
        assert pixels[(size[1]//2)*size[0]+size[0]//2][3] == 255
    elif 'Border' in name:
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

# Sample the actual alpha sprites at fractional UI coordinates. Every visible
# inset fill sample must stay within the larger solid backing;
# checking rectangle sizes alone missed the native hollow-ring artifact.
def alpha_at(data, x, y):
    w,h=struct.unpack_from('<HH',data,12)
    x=max(0,min(w-1,x*w-.5));y=max(0,min(h-1,y*h-.5))
    ix,iy=int(x),int(y);fx,fy=x-ix,y-iy
    def a(px,py):
        return data[18+(min(py,h-1)*w+min(px,w-1))*4+3]/255
    return (a(ix,iy)*(1-fx)+a(ix+1,iy)*fx)*(1-fy)+(a(ix,iy+1)*(1-fx)+a(ix+1,iy+1)*fx)*fy

for name,w,h in [('CheckSurfaceRound',18,18),('ToggleSurfacePill',34,18)]:
    data=files['Media/Textures/Mode/'+name+'.tga']
    for iy in range((h-2)*8):
        for ix in range((w-2)*8):
            x=(ix+.5)/8;y=(iy+.5)/8
            fill=alpha_at(data,x/(w-2),y/(h-2))
            outer=alpha_at(data,(x+1)/w,(y+1)/h)
            # Allow one 8-bit alpha level for independent bilinear resampling.
            assert outer+1/255>=fill,'colored interior must stay within the solid outer silhouette'
print('PASS rounded Figma controls, circular thumb, neutral sheen, fading/beveled lines, transparent logo and font license')
