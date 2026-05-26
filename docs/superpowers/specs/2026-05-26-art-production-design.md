# Art Production Workflow — Design Spec

**Date:** 2026-05-26
**Status:** Approved

---

## 1. Overview

This document defines the AI-driven art production workflow for AttributeLoop. All art assets are generated via the aiart MCP tool. Claude orchestrates the process — constructing prompts, calling aiart, presenting results in the browser, saving approved assets, and tracking progress.

The workflow is packaged as a reusable skill (`art-production`) invoked at the start of any art generation session.

---

## 2. Supporting Files

| File | Purpose |
|------|---------|
| `docs/art/style-bible.md` | Master prompt prefix shared by all assets. Created once during style setup session. |
| `docs/art/asset-manifest.md` | Full list of required assets with status (pending / done), description, and target path. |

---

## 3. Style Bible Setup (One-Time)

Before any assets can be generated, the style bible must be established. This happens once and is never repeated unless a deliberate style reset is requested.

**Steps:**
1. User describes the desired visual direction in natural language.
2. Claude constructs a test prompt from the description.
3. Claude calls `aiart.create_image_task` (taskType: `general`) four times in parallel with the same prompt, `waitForCompletion: true`.
4. The four results are shown in the browser visual companion for the user to pick from.
5. If none are satisfactory, the user gives text feedback → Claude adjusts the prompt → repeat from step 3.
6. Once a direction is approved, Claude writes `docs/art/style-bible.md` containing:
   - `positive_prefix`: the prompt text that produced the approved look
   - `negative_prompt`: elements to exclude from all generations
   - `art_spec_ids`: any aiart art pack IDs that contributed to the style (may be empty)
   - `anchor_image_ids`: the aiart imageIds of the approved test images, used as `referenceImages` in future generation calls to maintain visual consistency

---

## 4. Asset Manifest Format

`docs/art/asset-manifest.md` lists every asset the game needs. Claude reads this file at the start of each session to know what remains.

```markdown
## Component Icons · resources/icons/
- [ ] heal.png         — 治愈 · green water drop, soft glow
- [ ] shield.png       — 护盾 · blue shield, geometric
- [ ] reflect.png      — 反射 · mirror arrow motif
- [x] ...

## Enemy Sprites · resources/sprites/enemies/
- [ ] drainer.png      — 汲取者 · small shadowy creature, thin limbs
- [ ] guardian.png     — 守卫者 · heavy armored block-like form

## Player Sprites · resources/sprites/player/
- [ ] player.png       — player character reference image

## Tiles · resources/tiles/
- [ ] tile_empty.png   — empty tile slot
- [ ] tile_altar.png   — altar tile, visually distinct landmark

## UI · resources/ui/
- [ ] panel_bg.png     — panel background texture
- [ ] btn_normal.png   — button default state
- [ ] btn_hover.png    — button hover state

## Backgrounds · resources/backgrounds/
- [ ] bg_main.png      — main game background, 16:9
```

Claude updates `[ ]` to `[x]` after each asset is saved.

---

## 5. Two Generation Paths

### Path A — Static Assets

Used for: component icons, UI elements, tiles, backgrounds, the altar.

**Steps:**
1. Read the asset's description from `asset-manifest.md`.
2. Construct prompt: `style-bible positive_prefix` + asset-specific description.
3. Call `aiart.create_image_task` (taskType: `general`) four times in parallel:
   - `positivePrompt`: constructed prompt
   - `negativePrompt`: from style bible
   - `referenceImages`: anchor image IDs from style bible (for visual consistency)
   - `aspectRatio`: `1:1` for icons/sprites, `16:9` for backgrounds
   - `waitForCompletion: true`
4. Show all four results in the browser. User selects one.
5. If none are acceptable: user gives text feedback → Claude adjusts the asset description in the prompt (not the style bible prefix) → repeat from step 3.
6. For sprite-type assets: call `aiart.create_image_task` (taskType: `removeBackground`) on the chosen image.
7. Download the final image and save to the target path from the manifest.
8. Mark asset as `[x]` in `asset-manifest.md`.

### Path B — Animated Sprites

Used for: player character, all enemy types (汲取者, 守卫者, 急袭者, 复制者, 先驱者).

Animated sprites are produced in two separate stages that can be iterated independently.

**Stage 1 — Lock character appearance (static reference image):**
1. Generate a static front-facing character image using Path A steps 1–6.
2. User approves the look. This image becomes the character's canonical reference.
3. Upload the approved image via `aiart.upload_file` (fileType: `image`, businessType: `8`) and save the returned `resourceId` to the manifest entry.

**Stage 2 — Generate animation (video → frames):**
1. Call `aiart.create_video_task` using one of two methods:
   - **`driveImageWithVideo`**: provide the character's `resourceId` as `character` reference and a motion reference video as `motion` reference. Set `bodyProportionType` appropriately (`humanLike` for player, `nonHuman` for creature-type enemies).
   - **`generation` image-to-video**: provide the character image as `firstFrameImage` reference with a text prompt describing the motion (e.g., "walking cycle loop, side view").
2. Show the resulting video in the browser. User confirms the motion is acceptable.
3. If the motion is wrong: user gives feedback → Claude adjusts the motion prompt or switches method → repeat step 1.
4. Extract frames from the approved video using ffmpeg. Default fps is 12; adjust per character based on animation smoothness needs:
   ```
   ffmpeg -i input.mp4 -vf fps=12 resources/sprites/<name>/frame_%04d.png
   ```
5. Save the PNG frame sequence to `resources/sprites/<name>/`.
6. Mark asset as `[x]` in `asset-manifest.md`.

**Per-animation-action:** Each distinct action (walk, attack, death) is a separate video generation call using the same Stage 1 reference image, ensuring visual consistency across all actions for a given character.

---

## 6. Iteration Loop

Both paths support unlimited iteration before saving:

```
Generate 4 images (or 1 video)
  ↓
Satisfied? → save → next asset
Not satisfied? → user gives text feedback
                → Claude adjusts prompt (asset description only, not style bible)
                → regenerate
                ↑________________________________|
```

If the feedback reveals a problem with the style bible itself (e.g., "all icons look too dark"), the style bible `positive_prefix` is updated and all pending assets use the new prefix going forward.

---

## 7. Directory Structure

```
resources/
  icons/                  # Component card icons, 128×128, transparent bg
  sprites/
    player/               # Player PNG frame sequences per action
    enemies/
      drainer/            # 汲取者 frame sequences
      guardian/           # 守卫者 frame sequences
      rusher/             # 急袭者 frame sequences
      replicator/         # 复制者 frame sequences
      vanguard/           # 先驱者 frame sequences
  tiles/                  # Tile and altar images
  ui/                     # Panels, buttons, HUD elements
  backgrounds/            # Full-screen background images

docs/art/
  style-bible.md          # Master prompt prefix and anchor image IDs
  asset-manifest.md       # All assets with status and descriptions
```

---

## 8. Skill Trigger

The `art-production` skill is invoked at the start of any session where art assets are being created or iterated. On invocation it:

1. Checks whether `docs/art/style-bible.md` exists. If not, runs the Style Bible Setup (Section 3) before proceeding.
2. Reads `docs/art/asset-manifest.md` to show current progress.
3. Asks the user which assets to work on in this session (specific items, a category, or "continue from where we left off").
4. Runs Path A or Path B based on the asset type.

---

## 9. Out of Scope

- Sprite sheet packing (frames stay as individual PNGs; Godot AnimatedSprite2D handles the sequence)
- Audio assets
- Particle effects (handled in Godot, not aiart)
- Art style changes after style bible is established (requires explicit user request)
