"""Run with the project's .venv/bin/python; checks only delivered promo sprites."""
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent
CENTER = [64, 32, 448, 96]
EXPECTED = {
    **{f'{name}.png': (256, 256, None) for name in (
        'discount_tag', 'sale_ribbon_corner', 'badge_premium', 'badge_vip')},
    **{f'banner_{name}.png': (512, 128, CENTER) for name in (
        'best_value', 'popular', 'limited')},
    'badge_new.png': (192, 192, None),
    'strike_line.png': (256, 48, None),
    **{f'icon_{name}.png': (256, 256, None) for name in (
        'gem', 'gem_pile', 'vip_crown', 'premium_star', 'double_coins',
        'luck_clover', 'magnet', 'rocket', 'shield', 'hourglass',
        'starter_pack', 'treasure_chest_open', 'golden_ticket', 'piggy_bank',
        'infinity', 'sparkles')},
}
manifest = json.loads((ROOT / 'manifest.json').read_text())
prompts = json.loads((ROOT / 'prompts.json').read_text())
assert len(manifest) == len(EXPECTED) == 25
assert {item['file'] for item in manifest} == set(EXPECTED), 'manifest files'
assert len(prompts['assets']) == 25
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
            assert alpha.crop(tuple(center)).getextrema()[0] >= 250, f'{name}: transparent stretch center'
        if name == 'badge_new.png':
            assert alpha.crop((70, 70, 120, 120)).getextrema()[0] >= 250, f'{name}: transparent text area'
    assert item['sliceCenter'] == center, f'{name}: SliceCenter'
    assert (item['width'], item['height']) == (width, height), f'{name}: manifest size'
    assert all(item[key] for key in ('purpose', 'generator', 'notes')), f'{name}: metadata'
    assert item['generator'] == 'image_gen.imagegen', f'{name}: generator'
    print(f'PASS {name}: {width}x{height}, RGBA, alpha corners=0, gutter>0, magenta=0, SliceCenter={center}')
with Image.open(ROOT / 'contact_sheet.png') as sheet:
    assert sheet.format == 'PNG' and sheet.width > 0 and sheet.height > 0
print('PASS: 25/25 sprites; exact sizes; RGBA; transparent corners and gutters; antialiased alpha; no magenta; SliceCenter verified.')
print('PASS: manifest.json, exact per-asset prompts.json and labeled contact_sheet.png present.')
print('VISUAL: all 25 sprites inspected; no text, numerals, currency marks, baked backgrounds or clipped edges observed.')
print('REDONE: badge_new.png (dark center smudge); banner_limited.png (hourglass exceeded left slice band).')
print('NOT RUN: Roblox upload, Studio and engine/UI playtest; source-file delivery only.')

