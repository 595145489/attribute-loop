# Style Bible — AttributeLoop

> All aiart generation calls use `positive_prefix` and `negative_prompt` verbatim.
> Anchor image IDs maintain visual consistency across assets via referenceImages.

---

## Status

- [x] Style bible established

---

## positive_prefix

2D painterly illustration, anime background art style, soft blue-grey ambient light, warm golden glow, slightly out of focus edges, hand-painted texture, Your Name Kimi no Na wa art style, peaceful, dreamlike, magical realism, misty twilight atmosphere

---

## positive_prefix_icon

> Use this prefix for component icons and UI elements instead of positive_prefix.

soft hand-painted anime illustration, warm golden light, blue-grey tones, magical sparkles, Little Prince inspired art style, game ability icon, single centered symbol, dark background, clean readable silhouette, gentle glow, whimsical fantasy roguelike

---

## negative_prompt

photorealistic, 3d render, pixel art, flat vector, dark fantasy, horror, characters, people, text, watermark, busy composition, neon colors, sci-fi, sharp edges, oversaturated

---

## art_spec_ids

(none)

---

## anchor_image_ids

> Pass as referenceImages with purpose: "source", weight: 0.3 in all generation calls.

- `621299057020690739` — approved background style test (bg_main.png)
- `621315087801573683` — approved ground base color tone (bg_ground.png)

---

## Technical Specs by Asset Type

| Type | aspectRatio | width | height | removeBackground |
|------|------------|-------|--------|-----------------|
| Component icons | 1:1 | 512 | 512 | yes |
| Enemy/Player sprites | 1:1 | 512 | 512 | yes |
| Tiles | 1:1 | 512 | 512 | no |
| UI panels/buttons | — | as needed | as needed | no |
| Backgrounds | 16:9 | 1024 | 768 | no |
