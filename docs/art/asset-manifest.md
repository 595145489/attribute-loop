# Asset Manifest — AttributeLoop

> Update `[ ]` to `[x]` after each asset is saved to disk.
> Path B assets: mark done after all animation actions are complete.

---

## Component Icons · `resources/icons/` · Path A · 128×128, transparent bg

### Trigger Icons
- [x] trigger_hit.png          — 受击 · shield cracking, impact lines
- [x] trigger_kill.png         — 击杀 · skull or sword, decisive energy
- [x] trigger_loop.png         — 完成一圈 · circular arrow, loop motif
- [x] trigger_pass.png         — 经过 · footstep or arrow crossing a line
- [x] trigger_rule_fire.png    — 规则触发 · chain link or spark cascade
- [x] trigger_low_hp.png       — 低血 · cracked heart, red warning
- [x] trigger_full_hp.png      — 满血 · full glowing heart, bright aura

### Effect Icons
- [x] effect_heal.png          — 治愈 · water drop, soft green glow
- [x] effect_overflow_heal.png — 溢出治愈 · water drop overflowing into shield
- [x] effect_shield.png        — 护盾 · geometric shield, blue glow
- [x] effect_reflect.png       — 反射 · mirrored arrow, silver sheen
- [x] effect_lifesteal.png     — 吸血 · fangs or red tendril draining
- [x] effect_haste.png         — 加速 · lightning bolt, motion lines
- [x] effect_slow.png          — 减速 · hourglass or frozen crystal
- [ ] effect_charge.png        — 蓄能 · battery or orb filling with energy
- [x] effect_empower.png       — 强化 · upward arrow wrapped in light
- [ ] effect_chain.png         — 连锁 · chain links branching outward

---

## Enemy Sprites · `resources/sprites/enemies/` · Path B · per-action PNG sequences

### 汲取者 (Drainer) — small shadowy creature, thin limbs, trigger-heavy
- [x] drainer/reference.png    — static reference front-facing (locked look) <!-- resourceId: 622175813860621717 -->
- [ ] drainer/walk/            — walking cycle frames
- [x] drainer/idle/            — idle loop (16 frames, 1-3s, 8fps)
- [x] drainer/activate/        — activate animation (40 frames, full video, 8fps)
- [ ] drainer/death/           — death animation frames

### 守卫者 (Guardian) — heavy armored block-like form, effect-heavy
- [x] guardian/reference.png   <!-- resourceId: 622187322477175091 -->
- [ ] guardian/walk/
- [x] guardian/idle/            — idle loop (24 frames, 0-3s, 8fps)
- [x] guardian/activate/        — activate animation (40 frames, full video, 8fps)
- [ ] guardian/death/

### 急袭者 (Rusher) — origami dart creature, low HP, fast aggressive folds
- [x] rusher/reference.png    <!-- resourceId: 622166535909204275 -->
- [ ] rusher/walk/
- [x] rusher/activate/
- [ ] rusher/death/

### 复制者 (Replicator) — medium form, spawns a weakened copy on death
- [x] replicator/reference.png
- [ ] replicator/walk/
- [x] replicator/idle/            — idle loop (24 frames, 0-3s, 8fps)
- [x] replicator/activate/        — activate animation (80 frames, full video, 8fps)
- [ ] replicator/death/
- [ ] replicator/spawn/        — spawning copy animation

### 先驱者 (Vanguard) — large, high HP, full component loadout
- [x] vanguard/reference.png
- [ ] vanguard/walk/
- [x] vanguard/idle/            — idle loop (24 frames, 0-3s, 8fps)
- [x] vanguard/activate/        — activate animation (80 frames, full video, 8fps)
- [ ] vanguard/death/

---

## Player · `resources/sprites/player/` · Path B · per-action PNG sequences

- [x] player/reference.png     — static reference, neutral stance <!-- resourceId: 621329941727968661 -->
- [x] player/walk/             — walking cycle along track
- [ ] player/idle/             — idle loop, standing still with gentle breathing
- [ ] player/attack/           — combat strike, forward motion
- [ ] player/hit/              — taking damage, recoiling backward
- [ ] player/death/            — death animation

---

## Tiles · `resources/tiles/` · Path A

- [x] tile_empty.png           — empty tile slot on track, subtle border
- [x] tile_occupied.png        — tile with component(s), active glow

---

## UI · `resources/ui/` · Path A

### Panels
- [x] panel_bg.png             — general panel background texture, dark semi-transparent
- [x] altar_panel_bg.png       — altar panel background, stone tablet with transparent center
- [x] panel_combat_bg.png      — combat/enemy encounter overlay background
- [x] panel_strip_bg.png       — strip pickup panel background, open magic book style
- [x] panel_log_bg.png         — combat log panel background, tall vertical parchment journal page, ornate ink border, decorative header zone, faint ruled lines in content area, warm golden candlelight glow
- [x] panel_game_over_bg.png   — game over panel background, worn dramatic parchment, dark vignette at corners, cracked ornate border, dim candlelight glow, melancholic yet mystical
- [x] rule_panel_bg.png        — tile rule panel background, ornate parchment frame with decorative header/footer bands, clean minimal center field for UI overlay
- [x] panel_enemy_inspect_bg.png — enemy inspect panel background, ornate ink border frame with plain clean center area, dark vignette corners
- [x] panel_character_bg.png   — character attribute panel background, warm parchment with ornate ink border, clean transparent center for stat text overlay
- [x] service_activate_popup_bg.png — service activate popup background, dark brown leather card with gold filigree corner ornaments, clean dark center for UI overlay

### Buttons
- [x] btn_normal.png           — button default state
- [x] btn_hover.png            — button hover state, slight glow
- [x] btn_pressed.png          — button pressed state, slightly inset

### Component Cards
- [x] card_trigger_bg.png      — trigger component card background
- [x] card_effect_bg.png       — effect component card background
- [x] card_strip_bg.png        — unified strip pickup card background, blue-grey card style

### HUD Elements
- [x] hp_bar_bg.png            — HP bar background track
- [x] hp_bar_fill.png          — HP bar fill (green → red based on HP %)
- [x] gold_icon.png            — gold coin icon, 32×32
- [x] phase_badge_bg.png       — phase indicator background

---

## Backgrounds · `resources/backgrounds/` · Path A · 1152×648

- [x] bg_main.png              — main game scene background, looping track environment
- [x] bg_ground.png           — ground base layer, indigo blue-grey twilight grass
- [x] bg_game_over.png        — game over full-screen background, dramatic parchment atmosphere, wide 16:9

### Narrative Backgrounds (叙事背景)
- [x] bg_phase_1_2.png        — dawn mist, loop path leading to small wooden pavilion, lamp lit, single white flower on step, stones recently rearranged nearby, someone was just here but isn't, empty quiet expectant, soft blue-grey mist, pale gold light
- [x] bg_phase_3_4.png        — morning light angled low, same path and pavilion, stones on ground clearly spelling question mark and exclamation point side by side, a few carved words just beginning to show on pavilion wooden wall, warm golden morning light
- [x] bg_phase_5_6.png        — dusk, two sets of footprints on path going opposite directions never overlapping, pavilion lamp casting wide warm intimate circle of light, amber rose tones
- [x] bg_phase_7_8.png        — night falling, pavilion walls dense with tiny writing nearly full, path darker, one wall side has fewer recent marks, deep indigo sky
- [x] bg_phase_9_10.png       — deep night, pavilion walls completely covered no blank space, pavilion lamp is out, only moonlight, the original flower on step dried
- [x] bg_game_over_win.png    — moonlit night, loop path, far distance two figures just met backs to camera facing pavilion, warm ambient light, close but not sentimental
- [x] bg_game_over_lose.png   — empty pavilion lamp still burning, walls covered in writing, no one present, the light is on as if still waiting

### Auction Panel (梦境残市)
- [x] panel_auction_bg.png      — auction panel background, dark indigo with ornate gold ink border frame, misty center
