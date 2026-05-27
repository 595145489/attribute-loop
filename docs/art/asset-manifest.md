# Asset Manifest — AttributeLoop

> Update `[ ]` to `[x]` after each asset is saved to disk.
> Path B assets: mark done after all animation actions are complete.

---

## Component Icons · `resources/icons/` · Path A · 128×128, transparent bg

### Trigger Icons
- [x] trigger_hit.png          — 受击 · shield cracking, impact lines
- [x] trigger_kill.png         — 击杀 · skull or sword, decisive energy
- [x] trigger_loop.png         — 完成一圈 · circular arrow, loop motif
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

- [x] player/reference.png     — static reference, neutral stance <!-- resourceId: 621329941727968661 -->
- [x] player/walk/             — walking cycle along track
- [ ] player/idle/             — idle loop, standing still with gentle breathing
- [ ] player/attack/           — combat strike, forward motion
- [ ] player/hit/              — taking damage, recoiling backward
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

- [x] bg_main.png              — main game scene background, looping track environment
- [x] bg_ground.png           — ground base layer, indigo blue-grey twilight grass
