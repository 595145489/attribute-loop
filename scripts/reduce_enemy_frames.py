"""
Reduce each enemy animation to KEEP frames, evenly sampled and renumbered
contiguously (frame_0001..frame_000N.png).

Why renumber: Enemy.gd scans frame_0001, frame_0002... and breaks on the
first gap, so kept frames must be contiguous starting at 0001.

For each enemy/{idle,activate}: sample KEEP indices evenly across the range
(including first and last frame), write them back as frame_0001..frame_000K,
delete every other png and its stale .import file. Source PNGs are in git
history -> revert with git checkout if needed.
"""
import os, glob, shutil, sys

KEEP = 10
ENEMIES_ROOT = "resources/sprites/enemies"
ANIMS = ["idle", "activate"]

total_before = 0
total_after = 0

for enemy in sorted(os.listdir(ENEMIES_ROOT)):
    edir = os.path.join(ENEMIES_ROOT, enemy)
    if not os.path.isdir(edir):
        continue
    for anim in ANIMS:
        adir = os.path.join(edir, anim)
        if not os.path.isdir(adir):
            continue
        pngs = sorted(glob.glob(os.path.join(adir, "frame_*.png")))
        n = len(pngs)
        if n == 0:
            continue
        keep_n = min(KEEP, n)
        # evenly spaced indices over 0..n-1
        picked_idx = sorted(set(round(k * (n - 1) / (keep_n - 1)) for k in range(keep_n))) if keep_n > 1 else [0]
        picked_idx = picked_idx[:keep_n]
        before = sum(os.path.getsize(p) for p in pngs)

        tmp = adir.rstrip("/") + ".__tmp__"
        if os.path.exists(tmp):
            shutil.rmtree(tmp)
        os.makedirs(tmp)
        for new_i, src_idx in enumerate(picked_idx, start=1):
            shutil.copy(pngs[src_idx], os.path.join(tmp, "frame_%04d.png" % new_i))
            after_file = os.path.getsize(os.path.join(tmp, "frame_%04d.png" % new_i))

        # wipe all original pngs + stale .import files in this dir
        for p in glob.glob(os.path.join(adir, "frame_*.png")):
            os.remove(p)
        for p in glob.glob(os.path.join(adir, "frame_*.png.import")):
            os.remove(p)
        # also clear .import for any files we just removed (no-op if none)
        for f in os.listdir(adir):
            full = os.path.join(adir, f)
            if f.endswith(".import"):
                os.remove(full)

        # move kept frames back
        after = 0
        for f in os.listdir(tmp):
            shutil.move(os.path.join(tmp, f), os.path.join(adir, f))
            after += os.path.getsize(os.path.join(adir, f))
        os.rmdir(tmp)
        total_before += before
        total_after += after
        print(f"{enemy}/{anim}: {n} -> {keep_n} frames  ({before/1e3:.0f}KB -> {after/1e3:.0f}KB)")

print(f"\nTOTAL enemies sprites: {total_before/1e6:.1f}MB -> {total_after/1e6:.1f}MB "
      f"({100*(1-total_after/total_before):.0f}% smaller)")
