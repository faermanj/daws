#!/usr/bin/env python3

# Install dependencies if needed:
# sudo pip install pillow numpy

from PIL import Image, ImageDraw, ImageOps
import numpy as np
import random, os

FILENAME = "bigfile.jpg"
TARGET_MB = 1
TARGET_BYTES = TARGET_MB * 1024 * 1024

JPEG_QUALITY = 100
SUBSAMPLING = 0

WHITE  = (255, 255, 255)
BLACK  = (20, 20, 20)
ORANGE = (240, 150, 60)
OUTLINE = BLACK

def make_cat(S):
    W, H = S, S
    bg = (np.random.rand(H, W, 3) * 255).astype(np.uint8)
    img = Image.fromarray(bg, 'RGB')
    d = ImageDraw.Draw(img)

    cx, cy = W // 2, H // 2
    head_r = min(W, H) // 5
    body_w = head_r * 2 + head_r // 2
    body_h = head_r * 3

    # Body
    body_top = cy + head_r // 3
    body_box = (cx - body_w//2, body_top, cx + body_w//2, body_top + body_h)
    d.ellipse(body_box, fill=WHITE, outline=OUTLINE, width=12)

    # Head
    head_box = (cx - head_r, cy - head_r, cx + head_r, cy + head_r)
    d.ellipse(head_box, fill=WHITE, outline=OUTLINE, width=12)

    # Ears
    ear_h = head_r * 3 // 5
    ear_w = head_r * 2 // 5
    d.polygon([(cx - head_r//2, cy - head_r - ear_h//3),
               (cx - head_r + ear_w//3, cy - head_r + ear_w//3),
               (cx - head_r//3, cy - head_r + ear_w//4)], fill=WHITE, outline=OUTLINE)
    d.polygon([(cx + head_r//2, cy - head_r - ear_h//3),
               (cx + head_r//3, cy - head_r + ear_w//4),
               (cx + head_r - ear_w//3, cy - head_r + ear_w//3)], fill=WHITE, outline=OUTLINE)

    # Tail
    tail_thick = head_r // 6
    tail_box = (cx + body_w//3, body_top + body_h//3, cx + body_w, body_top + body_h)
    for offset in range(-tail_thick//2, tail_thick//2, 6):
        tb = (tail_box[0]-offset, tail_box[1]-offset, tail_box[2]-offset, tail_box[3]-offset)
        d.arc(tb, start=200, end=310, fill=WHITE, width=tail_thick)

    # Calico patches
    patch_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    def add_patches(n, color, size_range=(head_r//2, head_r*2)):
        for _ in range(n):
            w = random.randint(*size_range)
            h = random.randint(*size_range)
            angle = random.randint(0, 359)
            x = random.randint(cx - body_w//2 - head_r, cx + body_w//2 + head_r)
            y = random.randint(cy - head_r*2, body_top + body_h + head_r)
            ellipse = Image.new("RGBA", (w, h), (0, 0, 0, 0))
            ImageDraw.Draw(ellipse).ellipse([0,0,w-1,h-1], fill=color+(230,))
            ellipse = ellipse.rotate(angle, expand=True)
            patch_layer.alpha_composite(ellipse, (x-w//2, y-h//2))
    add_patches(15, ORANGE)
    add_patches(10, BLACK)

    mask = Image.new("L", (W, H), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.ellipse(body_box, fill=255)
    mask_draw.ellipse(head_box, fill=255)
    mask_draw.ellipse((tail_box[0]-tail_thick, tail_box[1]-tail_thick,
                       tail_box[2]+tail_thick*2, tail_box[3]+tail_thick*2), fill=255)
    img = Image.composite(img.convert("RGBA"),
                          Image.alpha_composite(img.convert("RGBA"), patch_layer),
                          ImageOps.invert(mask))

    # Face
    d = ImageDraw.Draw(img)
    eye_r = head_r // 5
    d.ellipse((cx - head_r//2 - eye_r, cy - eye_r//2,
               cx - head_r//2 + eye_r, cy + eye_r//2), fill=WHITE, outline=OUTLINE, width=8)
    d.ellipse((cx + head_r//2 - eye_r, cy - eye_r//2,
               cx + head_r//2 + eye_r, cy + eye_r//2), fill=WHITE, outline=OUTLINE, width=8)
    pup_r = eye_r // 2
    d.ellipse((cx - head_r//2 - pup_r, cy - pup_r, cx - head_r//2 + pup_r, cy + pup_r), fill=BLACK)
    d.ellipse((cx + head_r//2 - pup_r, cy - pup_r, cx + head_r//2 + pup_r, cy + pup_r), fill=BLACK)

    nose_r = head_r // 12
    d.ellipse((cx - nose_r, cy + nose_r//3, cx + nose_r, cy + nose_r + nose_r//2), fill=BLACK)

    smile_w = head_r // 2
    d.arc((cx - smile_w, cy + head_r//6, cx, cy + head_r//2), 0, 180, fill=OUTLINE, width=8)
    d.arc((cx, cy + head_r//6, cx + smile_w, cy + head_r//2), 0, 180, fill=OUTLINE, width=8)

    for side in (-1, 1):
        for off in (-30, 0, 30):
            x1 = cx + side * 40
            y1 = cy + head_r//6 + off
            x2 = cx + side * (40 + 220)
            y2 = y1 + off//3
            d.line((x1, y1, x2, y2), fill=BLACK, width=8)

    return img.convert("RGB")

def filesize(path):
    return os.path.getsize(path)

# -------------------------
# Binary search for S
# -------------------------
low, high = 500, 16000
best_under_S, best_under_size = None, -1
best_over_S, best_over_size = None, None

while low <= high:
    mid = (low + high) // 2
    img = make_cat(mid)
    img.save(FILENAME, "JPEG", quality=JPEG_QUALITY,
             subsampling=SUBSAMPLING, optimize=False)
    sz = filesize(FILENAME)
    print(f"Tried S={mid} -> {sz/(1024*1024):.2f} MB")
    if sz > TARGET_BYTES:
        if best_over_S is None or sz < best_over_size:
            best_over_S, best_over_size = mid, sz
        high = mid - 1   # shrink
    else:
        if sz > best_under_size:
            best_under_S, best_under_size = mid, sz
        low = mid + 1   # grow

if best_under_S is not None:
    best_S, best_size = best_under_S, best_under_size
elif best_over_S is not None:
    best_S, best_size = best_over_S, best_over_size
else:
    raise RuntimeError("Unable to approximate target size within the configured search range.")

# Final with best S
img = make_cat(best_S)
img.save(FILENAME, "JPEG", quality=JPEG_QUALITY,
         subsampling=SUBSAMPLING, optimize=False)

# Pad up to exact 333 MB
cur = filesize(FILENAME)
if cur < TARGET_BYTES:
    with open(FILENAME, "ab") as f:
        f.write(b"\0" * (TARGET_BYTES - cur))
final = filesize(FILENAME)

print(f"Saved {FILENAME} at exactly {final/(1024*1024):.2f} MB using S={best_S}")
