"""Run with the project's .venv/bin/python; checks only delivered sprites."""
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent
EXPECTED = {
    'board.png': (1024, 768, 96), 'awning.png': (1024, 220, None),
    'sign_plate.png': (640, 200, None), 'timer_plate.png': (440, 110, None),
    'slot_normal.png': (256, 256, 48), 'slot_featured.png': (256, 256, 48),
    'price_tag.png': (256, 80, 36),
    **{f'burst_{color}.png': (128, 128, None) for color in ('red', 'blue', 'green', 'purple')},
    **{f'button_{color}.png': (256, 96, 40) for color in ('green', 'yellow', 'red', 'grey')},
    'tab_on.png': (256, 80, 32), 'tab_off.png': (256, 80, 32),
    'close_button.png': (128, 128, None),
    **{f'icon_{name}.png': (256, 256, None) for name in (
        'red_hat', 'speed_boots', 'magic_wand', 'golden_crown', 'coin',
        'coins_small', 'coins_medium', 'coins_large', 'lightning', 'gift',
        'gear', 'cart', 'clock', 'fire')},
}
manifest = json.loads((ROOT / 'manifest.json').read_text())
assert len(manifest) == len(EXPECTED) == 32
assert {item['file'] for item in manifest} == set(EXPECTED)
for item in manifest:
    name = item['file']
    width, height, margin = EXPECTED[name]
    with Image.open(ROOT / name) as im:
        assert im.format == 'PNG', f'{name}: format'
        assert im.mode == 'RGBA', f'{name}: mode {im.mode}'
        assert im.size == (width, height), f'{name}: size {im.size}'
        corners = [(0, 0), (width-1, 0), (0, height-1), (width-1, height-1)]
        assert all(im.getpixel(p)[3] == 0 for p in corners), f'{name}: opaque corner'
        assert im.getchannel('A').getextrema() == (0, 255), f'{name}: invalid alpha'
        pixels = list(im.get_flattened_data())
        assert any(0 < pixel[3] < 255 for pixel in pixels), f'{name}: no antialiasing'
        assert not any((r, g, b) == (255, 0, 255) for r, g, b, a in pixels), f'{name}: magenta residue'
    center = [margin, margin, width-margin, height-margin] if margin else None
    assert item['sliceCenter'] == center, f'{name}: SliceCenter'
    assert (item['width'], item['height']) == (width, height), f'{name}: manifest size'
    assert all(key in item for key in ('purpose', 'generator', 'notes'))
    print(f'PASS {name}: {width}x{height}, RGBA, alpha corners=0, magenta=0, SliceCenter={center}')
assert (ROOT / 'contact_sheet.png').is_file()
assert (ROOT / 'prompts.json').is_file()
print('PASS: 32/32 sprites; exact sizes; RGBA; transparent corners; antialiased alpha; no magenta; SliceCenter verified.')
print('PASS: manifest.json, prompts.json and labeled contact_sheet.png present.')
