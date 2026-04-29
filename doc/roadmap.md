# Roadmap

## Current State (2026-04-29)

Project skeleton complete. Headless validation passes (EXIT: 0).

### Done
- Godot 4.6.2 project initialized
- Character auto-walks along track (Track + Player)
- Enemies spawn on timer and attack player (Enemy)
- Entry system data structures (EntryComponent + Rule)
- Inventory system
- Game state / pause mechanic (GameState, Space to toggle)
- HUD skeleton (HP bar + pause label)
- Player starter rule: heal on hit
- Full doc system (CLAUDE.md + doc/ modules)

---

## V1 Milestone: Demo

**Goal:** Complete playable proof of the "strip → assemble → rule fires" loop.

### Remaining

#### 1. Drag-strip UI
- Show component cards on enemies when paused
- Player drags a card to inventory
- Calls `Enemy.strip_component()`, card enters `Inventory`
- Visual feedback on enemy after strip (broken / missing piece)

#### 2. Inventory + Rule Assembly UI
- Bottom panel displays EntryComponent cards from inventory
- Rule slots (TRIGGER slot + EFFECT slot)
- Drag card to slot → creates Rule → added to `Player.rules`
- Empty slot displays as inactive / greyed out

#### 3. Rule Trigger Feedback
- Particle / highlight effect when a rule fires
- Visual traces back to the rule slot that triggered
- Player clearly sees which rule is working

#### 4. Second Enemy Type
- Different component combination from first enemy
- At least 2 distinct strippable entry types in the world

#### 5. Stability
- Survives 2–3 loops without crash
- Player death triggers a restart

---

## V2 and Beyond (design phase, not started)

- **Mutation system** — forcing wrong-type components into slots produces unknown mutant entries
- **World accumulation** — entries persist across loops and cause ripple effects on map tiles
- **Entry will** — strong entries attempt to migrate to more powerful hosts
- **VERB slot** — activate the third slot for full three-part rule sentences
- **Boss / level structure**
- **Sound effects + art pass**
- **HTML5 export configuration**
