"""Build the Shop and Hud ScreenGui models from the uploaded art kit.

    .venv/bin/python assets/source/ui/shop/build_ui.py   (run from the repository root)

Inputs: manifest.json (sizes, 9-slice rects) and roblox-ids.json (uploaded asset ids) next to this file.
Outputs: assets/ui/Shop.model.json, assets/ui/Hud.model.json and src/shared/Config/UiImages.luau.
Edit layout here and rerun; do not hand-edit the generated files.
"""
import json
import pathlib

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[3]
IDS = json.loads((HERE / "roblox-ids.json").read_text())
SLICE = {e["file"]: e["sliceCenter"] for e in json.loads((HERE / "manifest.json").read_text())}

FRED = {"Font": {"family": "rbxasset://fonts/families/FredokaOne.json", "weight": "Regular", "style": "Normal"}}
BROWN = [0.29, 0.13, 0.05]
INK = [0.38, 0.19, 0.08]


def img(file):
    return IDS[file]


def u(xs, xo, ys, yo):
    return {"UDim2": [[xs, xo], [ys, yo]]}


def node(name, cls, props=None, children=None):
    d = {"Name": name, "ClassName": cls, "Properties": props or {}}
    if children:
        d["Children"] = children
    return d


def maxtext(n):
    return node("MaxText", "UITextSizeConstraint", {"MaxTextSize": n})


def text(name, value, pos, size, color=(1, 1, 1), stroke=True, align="Center", anchor=(0, 0), max_size=28, z=5, extra=None):
    p = {"AnchorPoint": list(anchor), "Position": pos, "Size": size, "BackgroundTransparency": 1, "Text": value,
         "TextColor3": list(color), "TextScaled": True, "FontFace": FRED, "TextXAlignment": align, "ZIndex": z,
         "TextStrokeTransparency": 0 if stroke else 1, "TextStrokeColor3": BROWN}
    if extra:
        p.update(extra)
    return node(name, "TextLabel", p, [maxtext(max_size)])


def image(name, file, pos, size, anchor=(0, 0), z=2, cls="ImageLabel", slice_scale=None, extra=None, children=None):
    p = {"AnchorPoint": list(anchor), "Position": pos, "Size": size, "BackgroundTransparency": 1, "Image": img(file), "ZIndex": z}
    rect = SLICE.get(file)
    if rect and slice_scale:
        p.update({"ScaleType": "Slice", "SliceCenter": {"Rect": [[rect[0], rect[1]], [rect[2], rect[3]]]}, "SliceScale": slice_scale})
    else:
        p["ScaleType"] = "Fit"
    if cls == "ImageButton":
        p["AutoButtonColor"] = False
    if extra:
        p.update(extra)
    return node(name, cls, p, children)


def button(name, file, label, pos, size, anchor=(0, 0), z=6, max_size=24, order=None, icon=None):
    extra = {"LayoutOrder": order} if order is not None else None
    kids = []
    if icon:
        # Square icon as tall as the button (RelativeYY), text starting right after it.
        height = size["UDim2"][1][1]
        kids.append(image("Icon", icon, u(0, 2, 0.5, 0), u(1.1, 0, 1.1, 0), anchor=(0, 0.5), z=z + 1,
                          extra={"SizeConstraint": "RelativeYY"}))
        kids.append(text("Label", label, u(0, height + 4, 0, 6), u(1, -height - 12, 1, -14), max_size=max_size, z=z + 1))
    else:
        kids.append(text("Label", label, u(0, 8, 0, 6), u(1, -16, 1, -14), max_size=max_size, z=z + 1))
    return image(name, file, pos, size, anchor=anchor, z=z, cls="ImageButton", slice_scale=0.5, extra=extra, children=kids)


def burst(name, file, label, pos, size, anchor=(0, 0), z=8, visible=True):
    return image(name, file, pos, size, anchor=anchor, z=z, extra={"Visible": visible, "Rotation": 10},
                 children=[text("Label", label, u(0.15, 0, 0.25, 0), u(0.7, 0, 0.5, 0), max_size=20, z=z + 1)])


def scroller(name, layout, visible=False):
    return node(name, "ScrollingFrame", {"Size": u(1, 0, 1, 0), "BackgroundTransparency": 1, "BorderSizePixel": 0,
        "CanvasSize": u(0, 0, 0, 0), "AutomaticCanvasSize": "Y", "ScrollingDirection": "Y", "ScrollBarThickness": 8,
        "ScrollBarImageColor3": [1, 0.75, 0.3], "Visible": visible, "ZIndex": 3},
        [layout, node("Padding", "UIPadding", {"PaddingTop": {"UDim": [0, 16]}, "PaddingBottom": {"UDim": [0, 16]},
                                               "PaddingLeft": {"UDim": [0, 8]}, "PaddingRight": {"UDim": [0, 14]}})])


def grid(cell_h):
    return node("Grid", "UIGridLayout", {"CellSize": u(0.235, 0, 0, cell_h), "CellPadding": u(0, 14, 0, 22),
                                          "SortOrder": "LayoutOrder", "HorizontalAlignment": "Center"})


# Cards ---------------------------------------------------------------------
item_template = image("ItemTemplate", "slot_normal.png", u(0, 0, 0, 0), u(0, 150, 0, 190), z=3, slice_scale=0.5,
    extra={"Visible": False}, children=[
        text("RarityLabel", "COMMON", u(0, 12, 0, 10), u(1, -24, 0, 16), max_size=14, z=5),
        image("Icon", "icon_red_hat.png", u(0.5, 0, 0, 22), u(0.7, 0, 0.5, 0), anchor=(0.5, 0), z=4),
        text("ItemName", "Item", u(0, 10, 1, -78), u(1, -20, 0, 24), color=INK, stroke=False, max_size=22, z=5),
        burst("DealTag", "burst_red.png", "-30%", u(1, 10, 0, -12), u(0, 58, 0, 58), anchor=(1, 0), visible=False),
        button("Buy", "price_tag.png", "Buy", u(0.5, 0, 1, 8), u(0.86, 0, 0, 44), anchor=(0.5, 1), max_size=22),
    ])

pack_template = image("PackTemplate", "slot_normal.png", u(0, 0, 0, 0), u(0, 150, 0, 220), z=3, slice_scale=0.5,
    extra={"Visible": False}, children=[
        button("Badge", "button_red.png", "POPULAR", u(0.5, 0, 0, -14), u(0.86, 0, 0, 32), anchor=(0.5, 0), z=8, max_size=16),
        image("Icon", "icon_coins_small.png", u(0.5, 0, 0, 22), u(0.62, 0, 0.42, 0), anchor=(0.5, 0), z=4),
        text("Amount", "100", u(0, 10, 0.56, 0), u(1, -20, 0, 32), color=(1, 0.78, 0.15), max_size=30, z=5),
        text("Bonus", "+10% bonus", u(0, 10, 0.56, 32), u(1, -20, 0, 18), color=[0.18, 0.55, 0.15], stroke=False, max_size=16, z=5),
        button("Buy", "button_green.png", "Soon", u(0.5, 0, 1, 8), u(0.86, 0, 0, 46), anchor=(0.5, 1), max_size=22),
    ])

pass_template = image("PassTemplate", "slot_normal.png", u(0, 0, 0, 0), u(1, 0, 0, 120), z=3, slice_scale=0.5,
    extra={"Visible": False}, children=[
        image("Icon", "icon_lightning.png", u(0, 18, 0.5, 0), u(0, 90, 0, 90), anchor=(0, 0.5), z=4),
        text("PassName", "2x Coins", u(0, 120, 0, 18), u(0.6, -130, 0, 34), color=INK, stroke=False, align="Left", max_size=30, z=5),
        text("Description", "Double every coin.", u(0, 120, 0, 54), u(0.6, -130, 0, 44), color=INK, stroke=False, align="Left",
             max_size=18, z=5, extra={"TextWrapped": True, "TextYAlignment": "Top", "TextTransparency": 0.15}),
        button("Buy", "button_green.png", "Soon", u(1, -18, 0.5, 0), u(0.3, 0, 0, 56), anchor=(1, 0.5), max_size=24),
    ])

deal = image("Deal", "slot_featured.png", u(0, 0, 0, 0), u(1, 0, 0, 180), z=3, slice_scale=0.5, extra={"LayoutOrder": 1}, children=[
    button("Ribbon", "button_red.png", "DAILY DEAL", u(0, 6, 0, -16), u(0, 200, 0, 38), z=8, max_size=20, icon="icon_fire.png"),
    image("Icon", "icon_golden_crown.png", u(0, 20, 0.5, 6), u(0, 140, 0, 140), anchor=(0, 0.5), z=4),
    text("ItemName", "Item", u(0, 175, 0, 34), u(0.6, -185, 0, 42), align="Left", max_size=38, z=5),
    text("OldPrice", "", u(0, 175, 0, 82), u(0, 120, 0, 32), align="Left", color=(1, 0.92, 0.85), max_size=26, z=5, extra={"RichText": True}),
    burst("Discount", "burst_red.png", "-30%", u(0, 300, 0, 64), u(0, 74, 0, 74)),
    button("Buy", "price_tag.png", "Buy", u(1, -22, 0.5, 6), u(0.32, 0, 0, 62), anchor=(1, 0.5), max_size=30),
])

featured = node("Featured", "ScrollingFrame", {"Size": u(1, 0, 1, 0), "BackgroundTransparency": 1, "BorderSizePixel": 0,
    "CanvasSize": u(0, 0, 0, 0), "AutomaticCanvasSize": "Y", "ScrollingDirection": "Y", "ScrollBarThickness": 8,
    "ScrollBarImageColor3": [1, 0.75, 0.3], "Visible": True, "ZIndex": 3}, [
    node("Layout", "UIListLayout", {"Padding": {"UDim": [0, 26]}, "SortOrder": "LayoutOrder"}),
    node("Padding", "UIPadding", {"PaddingTop": {"UDim": [0, 22]}, "PaddingBottom": {"UDim": [0, 16]},
                                  "PaddingLeft": {"UDim": [0, 8]}, "PaddingRight": {"UDim": [0, 14]}}),
    deal,
    node("Picks", "Frame", {"Size": u(1, 0, 0, 220), "BackgroundTransparency": 1, "LayoutOrder": 2}, [
        node("Grid", "UIGridLayout", {"CellSize": u(0.48, 0, 0, 220), "CellPadding": u(0.04, 0, 0, 10), "SortOrder": "LayoutOrder"})]),
    node("PassPick", "Frame", {"Size": u(1, 0, 0, 120), "BackgroundTransparency": 1, "LayoutOrder": 3}, [
        node("Layout", "UIListLayout", {"SortOrder": "LayoutOrder"})]),
])


def tab(name, label, order):
    return button(name, "tab_off.png", label, u(0, 0, 0, 0), u(0.25, -8, 1, 0), z=7, max_size=20, order=order)


panel = node("Panel", "Frame", {"AnchorPoint": [0.5, 0.5], "Position": u(0.5, 0, 0.53, 0), "Size": u(0.96, 0, 0.88, 0),
                                "BackgroundTransparency": 1, "ZIndex": 2}, [
    node("MaxSize", "UISizeConstraint", {"MaxSize": [860, 620]}),
    node("Scale", "UIScale", {"Scale": 1}),
    image("Board", "board.png", u(0, 0, 0, 60), u(1, 0, 1, -60), z=1, slice_scale=0.42),
    image("Awning", "awning.png", u(0.5, 0, 0, 40), u(1, 24, 0, 96), anchor=(0.5, 0), z=4, extra={"ScaleType": "Stretch"}),
    node("Header", "Frame", {"Size": u(1, 0, 0, 170), "BackgroundTransparency": 1, "ZIndex": 5}, [
        image("Sign", "sign_plate.png", u(0.5, 0, 0, -18), u(0, 330, 0, 104), anchor=(0.5, 0), z=6, children=[
            text("Title", "SHOP", u(0.5, 0, 0.5, 0), u(0.56, 0, 0.6, 0), anchor=(0.5, 0.5), color=(1, 0.84, 0.25), max_size=58, z=7),
        ]),
        image("TimerPlate", "timer_plate.png", u(0.5, 0, 0, 80), u(0, 210, 0, 52), anchor=(0.5, 0), z=6, children=[
            text("Timer", "00:00:00", u(0.33, 0, 0.12, 0), u(0.6, 0, 0.76, 0), max_size=30, z=7),
        ]),
        image("Balance", "price_tag.png", u(0, 30, 0, 86), u(0, 150, 0, 46), z=6, slice_scale=0.5, children=[
            image("CoinIcon", "icon_coin.png", u(0, -12, 0.5, 0), u(0, 52, 0, 52), anchor=(0, 0.5), z=7),
            text("Amount", "0", u(0, 42, 0, 6), u(1, -52, 1, -12), max_size=26, z=7),
        ]),
        image("Close", "close_button.png", u(1, -6, 0, 70), u(0, 62, 0, 62), anchor=(1, 0), z=8, cls="ImageButton"),
    ]),
    node("Tabs", "Frame", {"Position": u(0, 44, 0, 150), "Size": u(1, -88, 0, 46), "BackgroundTransparency": 1, "ZIndex": 6}, [
        node("Layout", "UIListLayout", {"FillDirection": "Horizontal", "Padding": {"UDim": [0, 10]}, "SortOrder": "LayoutOrder",
                                        "HorizontalAlignment": "Center"}),
        tab("Featured", "Deals", 1), tab("Items", "Items", 2), tab("Coins", "Coins", 3), tab("Passes", "Passes", 4),
    ]),
    node("Pages", "Frame", {"Position": u(0, 40, 0, 200), "Size": u(1, -80, 1, -232), "BackgroundTransparency": 1,
                            "ClipsDescendants": True, "ZIndex": 3}, [
        featured,
        scroller("Items", grid(190)),
        scroller("Coins", grid(220)),
        scroller("Passes", node("Layout", "UIListLayout", {"Padding": {"UDim": [0, 14]}, "SortOrder": "LayoutOrder"})),
    ]),
    node("Templates", "Folder", {}, [item_template, pack_template, pass_template]),
])

shop = {"ClassName": "ScreenGui",
        "Properties": {"ResetOnSpawn": False, "Enabled": False, "IgnoreGuiInset": True, "DisplayOrder": 10, "ZIndexBehavior": "Sibling"},
        "Children": [node("Dim", "Frame", {"Size": u(1, 0, 1, 0), "BackgroundColor3": [0, 0, 0], "BackgroundTransparency": 0.45,
                                           "Active": True, "ZIndex": 0}), panel]}

# Hud -------------------------------------------------------------------------
hud = {"ClassName": "ScreenGui", "Properties": {"ResetOnSpawn": False, "IgnoreGuiInset": False, "ZIndexBehavior": "Sibling"}, "Children": [
    image("CashPill", "price_tag.png", u(0.5, 0, 0, 12), u(0, 180, 0, 50), anchor=(0.5, 0), z=2, slice_scale=0.5, children=[
        image("CoinIcon", "icon_coin.png", u(0, -14, 0.5, 0), u(0, 58, 0, 58), anchor=(0, 0.5), z=3),
        text("Cash", "...", u(0, 46, 0, 7), u(1, -58, 1, -14), max_size=28, z=3),
    ]),
    node("Buttons", "Frame", {"AnchorPoint": [1, 0.5], "Position": u(1, -30, 0.5, 0), "Size": u(0, 150, 0, 190), "BackgroundTransparency": 1}, [
        node("Layout", "UIListLayout", {"Padding": {"UDim": [0, 12]}, "SortOrder": "LayoutOrder"}),
        button("ShopButton", "button_yellow.png", "Shop", u(0, 0, 0, 0), u(1, 0, 0, 54), z=3, max_size=26, order=1, icon="icon_cart.png"),
        button("DailyButton", "button_green.png", "Daily", u(0, 0, 0, 0), u(1, 0, 0, 54), z=3, max_size=26, order=2, icon="icon_gift.png"),
        button("SettingsButton", "button_grey.png", "Settings", u(0, 0, 0, 0), u(1, 0, 0, 54), z=3, max_size=22, order=3, icon="icon_gear.png"),
    ]),
]}
# SALE seal on the Shop button.
for child in hud["Children"]:
    if child["Name"] == "Buttons":
        for b in child["Children"]:
            if b["Name"] == "ShopButton":
                b["Children"].append(burst("Badge", "burst_red.png", "SALE", u(1, 14, 0, -18), u(0, 50, 0, 50), anchor=(1, 0), z=6))


def write(path, data):
    (ROOT / path).write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")


write("assets/ui/Shop.model.json", shop)
write("assets/ui/Hud.model.json", hud)

names = {
    "ButtonGreen": "button_green.png", "ButtonYellow": "button_yellow.png", "ButtonRed": "button_red.png",
    "ButtonGrey": "button_grey.png", "PriceTag": "price_tag.png", "TabOn": "tab_on.png", "TabOff": "tab_off.png",
    "SlotNormal": "slot_normal.png", "SlotFeatured": "slot_featured.png",
}
lines = ["--!strict", "", "-- Generated by assets/source/ui/shop/build_ui.py from roblox-ids.json. Do not edit by hand.",
         "-- Images the shop swaps at runtime; buttons share one SliceCenter, slots share another.", "return table.freeze({"]
lines += [f'\t{key} = "{IDS[file]}",' for key, file in names.items()]
lines += ["})", ""]
(ROOT / "src/shared/Config/UiImages.luau").write_text("\n".join(lines))
print("built Shop, Hud and UiImages")
