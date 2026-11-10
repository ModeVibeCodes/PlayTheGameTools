"""Convert original Figma PNG exports to runtime RGBA TGA without changing pixels."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / 'PlayTheGameTools/Media/Textures/Mode'
SIZES = {'Surface': (128,128), 'Border': (128,128), 'Selection': (128,4),
         'ControlSurface': (64,32), 'ControlBorder': (64,32),
         'CheckSurface': (24,24), 'CheckBorder': (24,24),
         'ToggleSurface': (32,16), 'ToggleBorder': (32,16),
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
    logo=ROOT/'design/mode/Logo.png'
    if logo.exists():
        Image.open(logo).convert('RGBA').resize((128,128),Image.Resampling.LANCZOS).save(DEST/'Logo.tga',compression=None)

if __name__ == '__main__':
    build()
