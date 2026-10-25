"""Run with the project's .venv/bin/python; verify sprites and rebuild their contact sheet."""
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

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
    'panel.png': (768, 768, 96), 'title_ribbon.png': (640, 160, None),
    'row_plate.png': (512, 112, 40),
    'button_square_green.png': (128, 128, 40), 'button_square_red.png': (128, 128, 40),
    'toggle_on.png': (192, 96, None), 'toggle_off.png': (192, 96, None),
    'slider_track.png': (512, 48, 20), 'slider_fill.png': (512, 48, 20),
    'slider_knob.png': (96, 96, None),
    **{f'day_tile{state}.png': (192, 224, 40) for state in ('', '_today', '_claimed')},
    'toast_plate.png': (512, 96, 40), 'dock.png': (256, 512, 64),
    'loading_bg.png': (1024, 576, None),
    'progress_track.png': (512, 48, 20), 'progress_fill.png': (512, 48, 20),
    **{f'icon_{name}.png': (256, 256, None) for name in (
        'music', 'speaker', 'speaker_mute', 'minus', 'plus', 'check',
        'lock', 'chest', 'calendar', 'bell', 'home', 'close_x')},
}
manifest = json.loads((ROOT / 'manifest.json').read_text())
assert len(manifest) == len(EXPECTED) == 62
assert {item['file'] for item in manifest} == set(EXPECTED)
prompts = json.loads((ROOT / 'prompts.json').read_text())['assets']
assert len(prompts) == 62 and {item['file'] for item in prompts} == set(EXPECTED)
assert all(item['prompt'].strip() for item in prompts)
for item in manifest:
    name = item['file']
    width, height, margin = EXPECTED[name]
    with Image.open(ROOT / name) as im:
        assert im.format == 'PNG', f'{name}: format'
        assert im.mode == 'RGBA', f'{name}: mode {im.mode}'
        assert im.size == (width, height), f'{name}: size {im.size}'
        corners = [(0, 0), (width-1, 0), (0, height-1), (width-1, height-1)]
        pixels = list(im.get_flattened_data())
        if name == 'loading_bg.png':
            assert im.getchannel('A').getextrema() == (255, 255), f'{name}: background not opaque'
        else:
            assert all(im.getpixel(p)[3] == 0 for p in corners), f'{name}: opaque corner'
            assert im.getchannel('A').getextrema() == (0, 255), f'{name}: invalid alpha'
            assert any(0 < pixel[3] < 255 for pixel in pixels), f'{name}: no antialiasing'
        if name == 'day_tile_claimed.png':
            green = [(x, y) for y in range(height) for x in range(width)
                     if (p := im.getpixel((x, y)))[3] > 128 and p[1] > p[0] * 1.2 and p[1] > p[2] * 1.2]
            assert green and all(x >= width-margin and y < margin for x, y in green), f'{name}: check outside corner'
        if name == 'panel.png':
            assert im.getchannel('A').crop((margin, margin, width-margin, height-margin)).getextrema()[0] >= 240, f'{name}: transparent interior'
        assert not any((r, g, b) == (255, 0, 255) for r, g, b, a in pixels), f'{name}: magenta residue'
    center = [margin, margin, width-margin, height-margin] if margin else None
    assert item['sliceCenter'] == center, f'{name}: SliceCenter'
    assert (item['width'], item['height']) == (width, height), f'{name}: manifest size'
    assert all(key in item for key in ('purpose', 'generator', 'notes'))
    alpha = 'opaque backdrop' if name == 'loading_bg.png' else 'alpha corners=0'
    print(f'PASS {name}: {width}x{height}, RGBA, {alpha}, magenta=0, SliceCenter={center}')

font = ImageFont.load_default(size=14)
sheet = Image.new('RGB', (1440, 52 + ((len(manifest)+5)//6)*280), '#133f43')
draw = ImageDraw.Draw(sheet)
draw.text((16, 15), f'TROPICAL MARKET / UI KIT / {len(manifest)} ASSETS', font=font, fill='#ffedc5')
for index, item in enumerate(manifest):
    x, y = (index % 6)*240, 52+(index//6)*280
    draw.rounded_rectangle((x+4, y+4, x+236, y+276), radius=12, fill='#1b4b4e')
    with Image.open(ROOT / item['file']) as im:
        im.thumbnail((220, 220), Image.Resampling.LANCZOS)
        sheet.paste(im, (x+(240-im.width)//2, y+8+(220-im.height)//2), im)
    draw.text((x+10, y+237), item['file'], font=font, fill='#ffedc5')
    draw.text((x+10, y+257), f"{item['width']} x {item['height']}", font=font, fill='#91b7b6')
sheet.save(ROOT / 'contact_sheet.png')
assert (ROOT / 'contact_sheet.png').is_file()
assert (ROOT / 'prompts.json').is_file()
print('PASS: 62/62 sprites; exact sizes; RGBA; transparent corners and antialiased alpha (except opaque loading_bg); no magenta; SliceCenter verified.')
print('PASS: manifest.json, prompts.json and labeled contact_sheet.png present.')
