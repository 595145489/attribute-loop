"""
Subset the LXGW font to only glyphs used by the project + a safety buffer
of common CJK punctuation/digits/punctuation. Drastically cuts web size.

Steps:
1. Scan all .gd / .tscn / .tres / .json / .md / .cfg for CJK characters.
2. Build the union set of used glyphs + ASCII + punctuation.
3. Subset LXGWWenKaiLite-Regular.ttf with pyftsubset.
"""
import os, glob, subprocess, sys, tempfile

ROOT = "."
SCAN_EXT = (".gd", ".tscn", ".tres", ".json", ".md", ".cfg", ".txt", ".csv")
FONT = "resources/fonts/LXGWWenKaiLite-Regular.ttf"

# 1. collect characters
used = set()
def is_cjk(c):
    o = ord(c)
    return (0x4E00 <= o <= 0x9FFF) or (0x3400 <= o <= 0x4DBF) or (0x3000 <= o <= 0x30FF) or (0xFF00 <= o <= 0xFFEF)

count_files = 0
for ext in SCAN_EXT:
    for f in glob.glob(os.path.join(ROOT, "**", "*" + ext), recursive=True):
        if ".godot" in f or ".git" in f:
            continue
        try:
            with open(f, encoding="utf-8") as fh:
                for ch in fh.read():
                    if is_cjk(ch):
                        used.add(ch)
        except Exception:
            pass
        count_files += 1

# 2. add ASCII printable + common punctuation
for o in range(0x20, 0x7F):
    used.add(chr(o))
# common CJK punctuation & digits already covered by FF00-FFEF range above,
# but ensure CJK symbols/fullwidth explicitly
for o in range(0x3000, 0x303F):   # CJK symbols & punctuation
    used.add(chr(o))
for o in range(0xFF00, 0xFFEF):   # fullwidth forms
    used.add(chr(o))

chars = "".join(sorted(used))
print(f"Scanned {count_files} files. Unique glyphs to keep: {len(used)} "
      f"({sum(1 for c in used if is_cjk(c))} CJK)")

before = os.path.getsize(FONT)

# 3. subset using pyftsubset
with tempfile.NamedTemporaryFile("w", suffix=".txt", delete=False, encoding="utf-8") as tf:
    tf.write(chars)
    unicodes_file = tf.name

out = FONT + ".subset"  # write alongside, rename after success
cmd = [
    sys.executable, "-m", "fontTools.subset",
    FONT,
    "--text-file=" + unicodes_file,
    "--output-file=" + out,
    "--layout-features=*",
    "--notdef-outline",
    "--with-zopfli",
]
print("Running pyftsubset ...")
r = subprocess.run(cmd, capture_output=True, text=True)
if r.returncode != 0:
    print("STDERR:", r.stderr[-2000:])
    raise SystemExit("subset failed")
os.remove(unicodes_file)

# replace original
backup = FONT + ".bak"
os.replace(FONT, backup)
os.replace(out, FONT)
after = os.path.getsize(FONT)
print(f"\n{FONT}")
print(f"  {before/1e6:.2f} MB -> {after/1e6:.2f} MB  ({100*(1-after/before):.0f}% smaller)")
print(f"Backup at {backup} (delete after verifying).")
