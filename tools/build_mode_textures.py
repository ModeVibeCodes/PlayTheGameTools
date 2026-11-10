"""Convert Figma PNGs to RGBA TGA, with documented checkbox/logo/detail sizing."""
from pathlib import Path
from PIL import Image, ImageDraw
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / 'PlayTheGameTools/Media/Textures/Mode'
SIZES = {'Surface': (128,128), 'Border': (128,128), 'Selection': (128,4),
         'ControlSurface': (64,32), 'ControlBorder': (64,32),
         'Thumb': (32,32), 'ScrollThumb': (4,64), 'Divider': (256,4)}

def build():
    DEST.mkdir(parents=True, exist_ok=True)
    for name, size in SIZES.items():
        image = Image.open(ROOT / 'design/mode' / (name + '.png')).convert('RGBA')
        assert image.size == size
        target = DEST / (name + '.tga')
        image.save(target, compression=None)
        assert Image.open(target).convert('RGBA').tobytes() == image.tobytes()
        print('PASS exact Figma pixels:', target.name)
    # Keep the original Figma source intact; only the runtime checkbox is
    # resampled to a power-of-two canvas. Small controls render without slices.
    for source,target,size in (
        ('CheckSurface','CheckSurfaceRound',(32,32)),
        ('CheckBorder','CheckBorderRound',(32,32)),
        ('ToggleSurface','ToggleSurfacePill',(32,16)),
        ('ToggleBorder','ToggleBorderPill',(32,16)),
    ):
        image=Image.open(ROOT/'design/mode'/(source+'.png')).convert('RGBA')
        if image.size!=size: image=image.resize(size,Image.Resampling.LANCZOS)
        image.save(DEST/(target+'.tga'),compression=None)
        print('PASS power-of-two full sprite:',target)
    logo=ROOT/'design/mode/Logo.png'
    if logo.exists():
        Image.open(logo).convert('RGBA').resize((128,128),Image.Resampling.LANCZOS).save(DEST/'Logo.tga',compression=None)
    # Figma-generated abstract detail is a full-frame overlay, never sliced.
    detail=Image.open(ROOT/'design/mode/PageAbstractSource.png').convert('RGBA')
    assert detail.size==(1024,1024)
    detail.resize((512,512),Image.Resampling.LANCZOS).save(DEST/'PageAbstract.tga',compression=None)
    print('PASS Figma page detail: PageAbstract.tga')
    # Dedicated native UI capsule: supersample the repository's simple SVG
    # geometry instead of enlarging the 32x16 toggle sprite across wide tabs.
    svg=ET.parse(ROOT/'design/mode/PillSurface.svg').getroot()
    rect=svg.find('{http://www.w3.org/2000/svg}rect')
    assert svg.attrib['viewBox']=='0 0 256 64' and rect is not None
    assert rect.attrib=={'x':'0','y':'0','width':'256','height':'64','rx':'32','fill':'white'}
    mask=Image.new('L',(2048,512),0)
    ImageDraw.Draw(mask).rounded_rectangle((0,0,2047,511),radius=256,fill=255)
    pill=Image.new('RGBA',(256,64),'white')
    pill.putalpha(mask.resize((256,64),Image.Resampling.LANCZOS))
    pill.save(DEST/'PillSurface.tga',compression=None)
    print('PASS supersampled SVG capsule: PillSurface.tga')

if __name__ == '__main__':
    build()
