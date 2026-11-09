"""Generate original MIT-licensed grayscale UI media; no third-party art inputs."""
from pathlib import Path
import struct

DEST=Path(__file__).resolve().parents[1]/'PlayTheGameTools/Media/SharedMedia'
def tga(name,width,height,pixel):
    header=struct.pack('<BBBHHBHHHHBB',0,0,2,0,0,0,0,0,width,height,32,0x28)
    data=bytearray(header)
    for y in range(height):
        for x in range(width):
            r,g,b,a=pixel(x,y);data.extend((b,g,r,a))
    DEST.mkdir(parents=True,exist_ok=True)
    (DEST/name).write_bytes(data)

def border(x,y):
    # Native Backdrop.lua's eight horizontal cells: left, right, top, bottom,
    # top-left, top-right, bottom-left, bottom-right. Its UVs crop 2px padding.
    tile,x=divmod(x,32)
    left=2<=x<=5;right=26<=x<=29;top=2<=y<=5;bottom=26<=y<=29
    visible=(left if tile in (0,2) else right if tile in (1,3) else
             (left or top) if tile==4 else (right or top) if tile==5 else
             (left or bottom) if tile==6 else (right or bottom))
    return 255,255,255,255 if visible else 0

def satin(x,y):
    shade=round(255-42*y/31)
    return shade,shade,shade,255

def matte(x,y):
    shade=246+((x*17+y*13)%5)
    return shade,shade,shade,255

if __name__=='__main__':
    tga('PTG_Clean.tga',256,32,border)
    tga('PTG_Satin.tga',128,32,satin)
    tga('PTG_Matte.tga',32,32,matte)
