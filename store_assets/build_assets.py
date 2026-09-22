from PIL import Image, ImageDraw, ImageFont
import os

BASE = r"c:/ajem project/BALE BELAJAR/BALE_BELAJAR_APP"
ICON_SRC = f"{BASE}/assets/icon/icon_apps.png"
MASCOT_SRC = f"{BASE}/assets/mascot/welcome.png"
OUT_GFX = f"{BASE}/store_assets/graphics"
OUT_SHOT = f"{BASE}/store_assets/screenshots"

GOLD = (244, 180, 0)
GOLD_LIGHT = (255, 205, 60)
NAVY = (27, 42, 75)

# 1) Play Store icon 512x512
icon = Image.open(ICON_SRC).convert("RGBA").resize((512, 512), Image.LANCZOS)
icon.save(f"{OUT_GFX}/icon_512.png")
print("icon_512 done", icon.size)

# 2) Feature graphic 1024x500
fg = Image.new("RGB", (1024, 500), GOLD)
draw = ImageDraw.Draw(fg)
# soft vertical gradient
for y in range(500):
    t = y / 499
    r = int(GOLD[0] + (GOLD_LIGHT[0]-GOLD[0])*t)
    g = int(GOLD[1] + (GOLD_LIGHT[1]-GOLD[1])*t)
    b = int(GOLD[2] + (GOLD_LIGHT[2]-GOLD[2])*t)
    draw.line([(0,y),(1024,y)], fill=(r,g,b))

mascot = Image.open(MASCOT_SRC).convert("RGBA")
# crop mascot's bounding box (remove empty transparent padding)
bbox = mascot.getbbox()
mascot_c = mascot.crop(bbox)
mh = 460
mw = int(mascot_c.width * (mh / mascot_c.height))
mascot_c = mascot_c.resize((mw, mh), Image.LANCZOS)
fg.paste(mascot_c, (40, 500 - mh - 10), mascot_c)

font_title = ImageFont.truetype(r"C:/Windows/Fonts/arialbd.ttf", 92)
font_sub = ImageFont.truetype(r"C:/Windows/Fonts/arialbd.ttf", 34)

text_x = 40 + mw + 40
draw.text((text_x, 150), "Bale Belajar", font=font_title, fill=NAVY)
draw.text((text_x, 270), "Belajar lebih ringan,", font=font_sub, fill=NAVY)
draw.text((text_x, 315), "seru, dan terarah.", font=font_sub, fill=NAVY)

fg.save(f"{OUT_GFX}/feature_graphic_1024x500.png")
print("feature graphic done", fg.size)

# 3) Crop phone screenshots to 9:16 (1080x1920) from 1080x2340
shots = ["01_onboarding.png","02_login.png","03_onboarding_goal.png","04_analisis.png","05_widget.png","06_dashboard.png"]
os.makedirs(f"{OUT_SHOT}/play_ready", exist_ok=True)
for name in shots:
    p = f"{OUT_SHOT}/{name}"
    if not os.path.exists(p):
        print("missing", p)
        continue
    im = Image.open(p).convert("RGB")
    w, h = im.size
    target_h = int(w / 9 * 16)  # 1080 -> 1920
    if target_h >= h:
        cropped = im
    else:
        top = (h - target_h) // 2
        cropped = im.crop((0, top, w, top + target_h))
    cropped.save(f"{OUT_SHOT}/play_ready/{name}")
    print(name, im.size, "->", cropped.size)
