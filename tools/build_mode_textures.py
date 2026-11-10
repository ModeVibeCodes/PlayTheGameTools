"""Convert original Figma PNG exports to runtime RGBA TGA without changing pixels."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / 'PlayTheGameTools/Media/Textures/Mode'

def build():
    DEST.mkdir(parents=True, exist_ok=True)
    for name, size in {'Surface': (128, 128), 'Border': (128, 128), 'Selection': (8, 64)}.items():
        image = Image.open(ROOT / 'design/mode' / (name + '.png')).convert('RGBA')
        assert image.size == size
        target = DEST / (name + '.tga')
        image.save(target, compression=None)
        assert Image.open(target).convert('RGBA').tobytes() == image.tobytes()
        print('PASS exact Figma pixels:', target.name)

if __name__ == '__main__':
    build()
