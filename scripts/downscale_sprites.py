"""
Downscale large images across resource categories to shrink the web build.
Targets chosen by display role:
  sprites     -> 512 (already done, but re-runnable)
  backgrounds -> 1920 (full-screen)
  ui          -> 512
  icons       -> 256
  tiles       -> 256
Only downsizes images larger than the target.
Source PNGs are tracked in git -> `git checkout resources` restores originals.
"""
from PIL import Image
import glob, os

TARGETS = {
    "resources/sprites": 512,
    "resources/backgrounds": 1920,
    "resources/ui": 512,
    "resources/icons": 256,
    "resources/tiles": 256,
}

grand_before = 0
grand_after = 0

for root, tmax in TARGETS.items():
    files = glob.glob(os.path.join(root, "**", "*.png"), recursive=True)
    processed = skipped = 0
    before = after = 0
    for f in files:
        try:
            with Image.open(f) as im:
                w, h = im.size
                before += os.path.getsize(f)
                if max(w, h) <= tmax:
                    skipped += 1
                    after += os.path.getsize(f)
                    continue
                ratio = tmax / float(max(w, h))
                new_size = (max(1, int(round(w * ratio))), max(1, int(round(h * ratio))))
                if im.mode in ("P", "LA", "I;16"):
                    im = im.convert("RGBA")
                im.resize(new_size, Image.LANCZOS).save(f, format="PNG", optimize=True)
                after += os.path.getsize(f)
                processed += 1
        except Exception as e:
            print(f"  SKIP (error) {f}: {e}")
    print(f"{root} (max={tmax}): processed={processed} skipped={skipped}  "
          f"{before/1e6:.1f}MB -> {after/1e6:.1f}MB")
    grand_before += before
    grand_after += after

print(f"\nGRAND TOTAL: {grand_before/1e6:.1f}MB -> {grand_after/1e6:.1f}MB  "
      f"({100*(1-grand_after/grand_before):.0f}% smaller)")
