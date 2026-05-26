# Art Production Workflow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create the `art-production` skill and two supporting files that enable AI-driven art asset generation for AttributeLoop using the aiart MCP.

**Architecture:** Three deliverables: (1) `asset-manifest.md` — full list of every art asset the game needs with status tracking; (2) `style-bible.md` — empty template filled during first art session; (3) the `art-production` skill at `~/.claude/skills/art-production/SKILL.md` — complete workflow instructions for running art production sessions.

**Tech Stack:** Markdown files, aiart MCP (`create_image_task`, `create_video_task`, `upload_file`, `removeBackground`), visual companion browser server (superpowers brainstorming scripts), ffmpeg for sprite frame extraction.

---

### Task 1: Create Asset Manifest

**Files:**
- Create: `docs/art/asset-manifest.md`

- [ ] **Step 1: Write the asset manifest**

Create `docs/art/asset-manifest.md` with the following content. This file is the single source of truth for art production progress. `[ ]` = pending, `[x]` = done.

```markdown
# Asset Manifest — AttributeLoop

> Update `[ ]` to `[x]` after each asset is saved to disk.
> Path B assets: mark done after all animation actions are complete.

---

## Component Icons · `resources/icons/` · Path A · 128×128, transparent bg

### Trigger Icons
- [ ] trigger_hit.png          — 受击 · shield cracking, impact lines
- [ ] trigger_kill.png         — 击杀 · skull or sword, decisive energy
- [ ] trigger_loop.png         — 完成一圈 · circular arrow, loop motif
- [ ] trigger_pass.png         — 经过 · footstep or arrow crossing a line
- [ ] trigger_rule_fire.png    — 规则触发 · chain link or spark cascade
- [ ] trigger_low_hp.png       — 低血 · cracked heart, red warning
- [ ] trigger_full_hp.png      — 满血 · full glowing heart, bright aura

### Effect Icons
- [ ] effect_heal.png          — 治愈 · water drop, soft green glow
- [ ] effect_overflow_heal.png — 溢出治愈 · water drop overflowing into shield
- [ ] effect_shield.png        — 护盾 · geometric shield, blue glow
- [ ] effect_reflect.png       — 反射 · mirrored arrow, silver sheen
- [ ] effect_lifesteal.png     — 吸血 · fangs or red tendril draining
- [ ] effect_haste.png         — 加速 · lightning bolt, motion lines
- [ ] effect_slow.png          — 减速 · hourglass or frozen crystal
- [ ] effect_charge.png        — 蓄能 · battery or orb filling with energy
- [ ] effect_empower.png       — 强化 · upward arrow wrapped in light
- [ ] effect_chain.png         — 连锁 · chain links branching outward

---

## Enemy Sprites · `resources/sprites/enemies/` · Path B · per-action PNG sequences

### 汲取者 (Drainer) — small shadowy creature, thin limbs, trigger-heavy
- [ ] drainer/reference.png    — static reference front-facing (locked look)
- [ ] drainer/walk/            — walking cycle frames
- [ ] drainer/attack/          — attack animation frames
- [ ] drainer/death/           — death animation frames

### 守卫者 (Guardian) — heavy armored block-like form, effect-heavy
- [ ] guardian/reference.png
- [ ] guardian/walk/
- [ ] guardian/attack/
- [ ] guardian/death/

### 急袭者 (Rusher) — low HP, very fast movement, aggressive posture
- [ ] rusher/reference.png
- [ ] rusher/walk/
- [ ] rusher/attack/
- [ ] rusher/death/

### 复制者 (Replicator) — medium form, spawns a weakened copy on death
- [ ] replicator/reference.png
- [ ] replicator/walk/
- [ ] replicator/attack/
- [ ] replicator/death/
- [ ] replicator/spawn/        — spawning copy animation

### 先驱者 (Vanguard) — large, high HP, full component loadout
- [ ] vanguard/reference.png
- [ ] vanguard/walk/
- [ ] vanguard/attack/
- [ ] vanguard/death/

---

## Player · `resources/sprites/player/` · Path B · per-action PNG sequences

- [ ] player/reference.png     — static reference, neutral stance
- [ ] player/walk/             — walking cycle along track
- [ ] player/idle/             — idle loop
- [ ] player/hit/              — taking damage reaction
- [ ] player/death/            — death animation

---

## Tiles · `resources/tiles/` · Path A

- [ ] tile_empty.png           — empty tile slot on track, subtle border
- [ ] tile_occupied.png        — tile with component(s), active glow
- [ ] tile_altar.png           — altar tile, visually distinct landmark, ornate

---

## UI · `resources/ui/` · Path A

### Panels
- [ ] panel_bg.png             — general panel background texture, dark semi-transparent
- [ ] panel_combat_bg.png      — combat/enemy encounter overlay background

### Buttons
- [ ] btn_normal.png           — button default state
- [ ] btn_hover.png            — button hover state, slight glow
- [ ] btn_pressed.png          — button pressed state, slightly inset

### Component Cards
- [ ] card_trigger_bg.png      — trigger component card background
- [ ] card_effect_bg.png       — effect component card background

### HUD Elements
- [ ] hp_bar_bg.png            — HP bar background track
- [ ] hp_bar_fill.png          — HP bar fill (green → red based on HP %)
- [ ] gold_icon.png            — gold coin icon, 32×32
- [ ] phase_badge_bg.png       — phase indicator background

---

## Backgrounds · `resources/backgrounds/` · Path A · 1152×648

- [ ] bg_main.png              — main game scene background, looping track environment
```

- [ ] **Step 2: Commit**

```bash
git add docs/art/asset-manifest.md
git commit -m "feat: add art asset manifest with full game asset list"
```

---

### Task 2: Create Style Bible Template

**Files:**
- Create: `docs/art/style-bible.md`

- [ ] **Step 1: Write the style bible template**

Create `docs/art/style-bible.md` with this content. The fields marked `(TBD — set during first art session)` are filled in during the style setup run of the `art-production` skill.

```markdown
# Style Bible — AttributeLoop

> This file is populated during the first art production session.
> All aiart generation calls use `positive_prefix` and `negative_prompt` verbatim.
> Anchor image IDs maintain visual consistency across assets via referenceImages.

---

## Status

- [ ] Style bible established (run `art-production` skill to set up)

---

## positive_prefix

(TBD — set during first art session)

---

## negative_prompt

(TBD — set during first art session)

---

## art_spec_ids

(TBD — leave empty if no art pack used)

---

## anchor_image_ids

> These are aiart imageIds from the approved style test images.
> Pass them as referenceImages (purpose: "source", weight: 0.3) in generation calls.

(TBD — populated after style setup)

---

## Technical Specs by Asset Type

| Type | aspectRatio | width | height | removeBackground |
|------|------------|-------|--------|-----------------|
| Component icons | 1:1 | 128 | 128 | yes |
| Enemy/Player sprites | 1:1 | 256 | 256 | yes |
| Tiles | 1:1 | 128 | 128 | no |
| UI panels/buttons | — | as needed | as needed | no |
| Backgrounds | 16:9 | 1152 | 648 | no |
```

- [ ] **Step 2: Commit**

```bash
git add docs/art/style-bible.md
git commit -m "feat: add style bible template for art production"
```

---

### Task 3: Create the Art Production Skill

**Files:**
- Create: `C:\Users\happyelements\.claude\skills\art-production\SKILL.md`

- [ ] **Step 1: Create skill directory and write SKILL.md**

Create `C:\Users\happyelements\.claude\skills\art-production\SKILL.md`:

```markdown
---
name: art-production
description: Use when generating any art assets for AttributeLoop — icons, sprites, UI, backgrounds. Runs the full aiart generation workflow including style setup, variation review, and file saving.
---

# Art Production Workflow

Generates game art assets using aiart MCP. Two paths: static images (icons, UI, tiles) and animated sprites (video → frames). All assets use a shared style bible for visual consistency.

## On Invocation

1. Check if `docs/art/style-bible.md` contains an established `positive_prefix` (look for the `(TBD` marker). If TBD, run **Style Bible Setup** before anything else.
2. Read `docs/art/asset-manifest.md` and show a summary: total assets, how many done, how many pending.
3. Ask: "Which assets do you want to work on this session?" Options: specific items by name, a category (icons / enemies / UI / backgrounds), or "continue from where we left off" (pick first pending item).
4. For each selected asset, check its type and run **Path A** or **Path B** accordingly.

---

## Style Bible Setup (run once)

Run this when `docs/art/style-bible.md` has no established prefix.

1. Ask the user to describe the visual direction in a few words (e.g., "dark fantasy, flat icon style" or "pixel art, retro roguelike").
2. Build a test prompt from their description. Start broad — use keywords that describe mood, rendering style, and medium. Do not include asset-specific details yet.
3. Start the visual companion server:
   ```bash
   bash "C:/Users/happyelements/.claude/plugins/cache/obra-superpowers/superpowers/5.0.7/skills/brainstorming/scripts/start-server.sh" --project-dir "S:/attribute-loop"
   ```
   Run with `run_in_background: true`. Then read `S:/attribute-loop/.superpowers/brainstorm/<session>/state/server-info` for the URL.
4. Call `aiart.create_image_task` four times in parallel:
   - `taskType: "general"`
   - `positivePrompt`: test prompt built in step 2
   - `negativePrompt`: "photorealistic, 3d render, blurry, text, watermark, signature"
   - `aspectRatio: "1:1"`
   - `waitForCompletion: true`
5. Download all four result images (from artifact URLs in the task response) to `.superpowers/brainstorm/<session>/content/style-test-*.png` using a Bash curl/wget call.
6. Write a browser page showing the four images side by side. Tell the user the URL and ask them to pick one or give feedback.
7. If the user picks one: proceed to step 8. If feedback is given: adjust the prompt and repeat from step 4.
8. Write the approved prompt to `docs/art/style-bible.md`:
   - `positive_prefix`: the full prompt text that produced the approved result
   - `negative_prompt`: the negative prompt used
   - `anchor_image_ids`: the aiart imageId of the chosen test image
   - Mark the status checkbox as done
9. Commit: `git commit -m "feat: establish art style bible"`

---

## Path A — Static Assets

For: component icons, UI elements, tiles, backgrounds.

**Steps:**
1. Read the asset's description from `docs/art/asset-manifest.md`.
2. Read `docs/art/style-bible.md` to get `positive_prefix`, `negative_prompt`, `anchor_image_ids`, and technical specs for this asset type.
3. Build the full prompt:
   - `positivePrompt`: `<positive_prefix>, <asset-specific description from manifest>`
   - `negativePrompt`: value from style bible
4. Call `aiart.create_image_task` four times in parallel:
   - `taskType: "general"`
   - `positivePrompt` and `negativePrompt` from step 3
   - `referenceImages`: anchor image IDs from style bible, each with `purpose: "source"`, `weight: 0.3`
   - `width` / `height` from style bible technical specs for this asset type
   - `waitForCompletion: true`
5. Download the four result images to `.superpowers/brainstorm/<session>/content/<asset-name>-*.png`.
6. Show all four in the browser visual companion. Tell the user the URL. Ask them to pick one or give feedback.
7. If feedback: adjust the asset description part of the prompt only (never change `positive_prefix`). Repeat from step 4.
8. For icon/sprite assets (`removeBackground: yes` in style bible): call `aiart.create_image_task` with `taskType: "removeBackground"` on the chosen image's imageId.
9. Download the final image. Save to the target path from the manifest (e.g., `resources/icons/effect_heal.png`).
10. Mark the asset as `[x]` in `docs/art/asset-manifest.md`.
11. Commit: `git commit -m "art: add <asset-name>"`

**If all four variations are wrong:** ask the user for feedback, adjust prompt, regenerate. No limit on iterations.

**If style bible itself seems wrong** (e.g., "all icons look too dark"): update `positive_prefix` in `docs/art/style-bible.md` and all future assets use the new prefix. Do not regenerate already-approved assets unless user requests it.

---

## Path B — Animated Sprites

For: player, all enemy types.

Animated sprites are generated in two independent stages.

### Stage 1 — Lock Character Appearance

1. Run **Path A steps 1–9** but with `width: 256`, `height: 256`, transparent background.
2. The approved image is the character's canonical reference. Save it to `resources/sprites/<name>/reference.png`.
3. Upload it to aiart: call `aiart.upload_file` with `filePath: <absolute path>`, `fileType: "image"`, `businessType: 8`. Save the returned `resourceId` into the manifest entry as a comment: `<!-- resourceId: <id> -->`.
4. Mark `reference.png` as `[x]` in the manifest.
5. Commit: `git commit -m "art: add <name> reference sprite"`

### Stage 2 — Generate Animation Actions

For each action (walk, attack, death, etc.) listed in the manifest for this character:

1. Choose generation method:
   - **`driveImageWithVideo`** (preferred if a suitable motion reference video exists): provide the character `resourceId` as `character` reference. `bodyProportionType`: use `"humanLike"` for player and humanoid enemies, `"nonHuman"` for creature-type enemies (drainer).
   - **`generation` image-to-video**: provide the character image as `firstFrameImage` reference. Write a motion prompt describing the action (e.g., `"side-view walking cycle, looping, smooth movement, 2 steps"`).
2. Call `aiart.create_video_task`:
   - `taskType`: `"driveImageWithVideo"` or `"generation"`
   - Relevant `referenceResources` based on method above
   - `duration: "5s"`
   - `waitForCompletion: true`
3. Show the video to the user: download it and tell them the file path, or embed in browser if possible.
4. If the motion is wrong: adjust the motion prompt and repeat from step 2. Stage 1 reference image does not change.
5. Once approved: extract frames with ffmpeg. Default fps is 12; adjust if the animation needs more/less smoothness:
   ```bash
   ffmpeg -i "<video-path>" -vf fps=12 "S:/attribute-loop/resources/sprites/<name>/<action>/frame_%04d.png"
   ```
6. Mark the action as `[x]` in the manifest.
7. Commit: `git commit -m "art: add <name> <action> animation frames"`

---

## Iteration Rules

- Adjust **asset description** when a single asset looks wrong.
- Adjust **`positive_prefix`** only when a systemic style problem is confirmed across multiple assets.
- Never skip the browser review step — always show images to the user before saving.
- Never save an asset without user approval.
```

- [ ] **Step 2: Verify skill appears in available skills**

Restart or open a new Claude Code session and check that `art-production` appears in the available skills list in the system reminder. If it doesn't appear, check that the file is saved to `C:\Users\happyelements\.claude\skills\art-production\SKILL.md` with correct frontmatter.

- [ ] **Step 3: Commit supporting files**

```bash
git add docs/art/
git commit -m "docs: add art production workflow supporting files"
```

---

### Task 4: Smoke Test the Skill

- [ ] **Step 1: Invoke the skill**

In a new session, type: "帮我生成治愈图标" or invoke `/art-production`. Verify:
- Skill loads and checks `docs/art/style-bible.md`
- Since style bible is TBD, it prompts for visual direction
- It calls `aiart.create_image_task` four times
- It starts the visual companion server and shows results in browser

- [ ] **Step 2: Confirm iteration works**

Give feedback ("太亮了"). Verify:
- Claude adjusts the prompt
- Calls aiart again
- Shows new results

- [ ] **Step 3: Confirm save works**

Approve one image. Verify:
- `removeBackground` is called
- File saved to `resources/icons/effect_heal.png`
- `docs/art/asset-manifest.md` updated with `[x]`
- Git commit created

- [ ] **Step 4: Final commit**

```bash
git add .
git commit -m "feat: complete art production workflow setup"
```
