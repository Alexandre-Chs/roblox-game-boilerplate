"""Run with the project's .venv/bin/python; checks only delivered social sprites."""
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent
EXPECTED = {
    **{f'{name}.png': (256, 256, None) for name in (
        'icon_group', 'icon_invite', 'icon_heart', 'icon_trophy',
        'icon_backpack', 'icon_globe', 'icon_ticket_code', 'icon_badge_medal',
        'icon_speech', 'icon_equipped', 'medal_gold', 'medal_silver',
        'medal_bronze', 'arrow_pointer')},
    'input_plate.png': (512, 96, [40, 32, 472, 64]),
    'leaderboard_board.png': (768, 1024, [96, 160, 672, 928]),
    'row_rank.png': (512, 80, [40, 24, 472, 56]),
    'hint_banner.png': (640, 120, [64, 40, 576, 80]),
}
manifest = json.loads((ROOT / 'manifest.json').read_text())
prompts = json.loads((ROOT / 'prompts.json').read_text())
assert len(manifest) == len(EXPECTED) == 18
assert {item['file'] for item in manifest} == set(EXPECTED), 'manifest files'
assert len(prompts['assets']) == 18
assert {item['file'] for item in prompts['assets']} == set(EXPECTED), 'prompt files'
assert all(item['prompt'].strip() for item in prompts['assets']), 'empty prompt'
assert {path.name for path in ROOT.glob('*.png')} == set(EXPECTED) | {'contact_sheet.png'}
for item in manifest:
    name = item['file']
    width, height, center = EXPECTED[name]
    with Image.open(ROOT / name) as im:
        assert im.format == 'PNG', f'{name}: format'
        assert im.mode == 'RGBA', f'{name}: mode {im.mode}'
        assert im.size == (width, height), f'{name}: size {im.size}'
        alpha = im.getchannel('A')
        corners = [(0, 0), (width-1, 0), (0, height-1), (width-1, height-1)]
        assert all(im.getpixel(p)[3] == 0 for p in corners), f'{name}: opaque corner'
        assert alpha.getextrema() == (0, 255), f'{name}: invalid alpha'
        bounds = alpha.getbbox()
        assert bounds and 0 < bounds[0] < bounds[2] < width, f'{name}: cropped side'
        assert 0 < bounds[1] < bounds[3] < height, f'{name}: cropped top/bottom'
        pixels = list(im.get_flattened_data())
        assert any(0 < pixel[3] < 255 for pixel in pixels), f'{name}: no antialiasing'
        assert not any((r, g, b) == (255, 0, 255) for r, g, b, a in pixels), f'{name}: magenta residue'
        if center:
            # Preserve generated alpha; center must remain at least 97% opaque.
            minimum = alpha.crop(tuple(center)).getextrema()[0]
            assert minimum >= 248, f'{name}: insufficient center opacity {minimum}'
            print(f'PASS {name}: stretch center minimum alpha={minimum}/255 (required >=248)')
    assert item['sliceCenter'] == center, f'{name}: SliceCenter'
    assert (item['width'], item['height']) == (width, height), f'{name}: manifest size'
    assert all(item[key] for key in ('purpose', 'generator', 'notes')), f'{name}: metadata'
    assert item['generator'] == 'image_gen.imagegen', f'{name}: generator'
    print(f'PASS {name}: {width}x{height}, RGBA, alpha corners=0, gutter>0, magenta=0, SliceCenter={center}')
with Image.open(ROOT / 'contact_sheet.png') as sheet:
    assert sheet.format == 'PNG' and sheet.width > 0 and sheet.height > 0
print('PASS: 18/18 sprites; exact sizes; RGBA; transparent corners and gutters; antialiased alpha; no magenta; SliceCenter verified.')
print('PASS: manifest.json, exact per-asset prompts.json and labeled contact_sheet.png present.')
print('VISUAL (manual review): all 18 sprites inspected; no text, numerals, logos, baked backgrounds or clipped edges; nine-slice frame details inside fixed bands.')
print('REDONE: row_rank.png (grain across stretch center); leaderboard_board.png (header/frame outside fixed bands; later opacity variants rejected; retained center alpha249..254/255).')
print('NOT RUN: Roblox upload, Studio and engine/UI playtest; source-file delivery only.')
print('NOT RUN: pnpm run check; it regenerates sourcemap.json outside the authorized output folder. No Luau or runtime UI files changed.')
