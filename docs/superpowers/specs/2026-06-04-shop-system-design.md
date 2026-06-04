# AttributeLoop — Shop System Design (梦境残市)

**Date:** 2026-06-04
**Status:** Approved

---

## 1. Overview

The shop system is not a traditional store. It is a per-loop auction called **梦境残市** where players bid gold to win **operation services** — actions that modify their existing build in ways not otherwise possible. Two phantom buyers compete simultaneously.

The core distinction from the component strip system: components come exclusively from stripping enemies. The auction sells operations on those components and tile rules, not new components.

---

## 2. The Six Services

| Service | Effect |
|---------|--------|
| 规则复制 | Copy a placed tile rule to an empty slot on another tile. The copy starts at pass_count = 0. |
| 词条改写 | Change the N value of a trigger (range 1–3), or increase the base_value of an effect by up to 50%. |
| 词条融合 | Merge two components of the same kind (both TRIGGER or both EFFECT) into one. Result base_value = sum × 0.8. Both originals consumed. |
| 敌人赦免 | Next 3 enemies of a chosen type do not fight — they auto-drop their components. |
| 删除特赦 | Next component deletion costs 0 gold and does not increment the global deletion counter |
| 压力延缓 | World pressure countdown -1 loop |

---

## 3. Service Pool Generation

Each loop, the enemies the player kills each contribute one candidate service to the pool. Up to 3 services are drawn from this pool and placed in the auction. If fewer than 3 enemies were killed, the remaining slots are filled with randomly selected services from the full pool of 6. A service that receives zero bids carries over to the next loop; its card displays a small "↩" indicator but bid resolution is unchanged — there is no price floor or escalation mechanic.

---

## 4. Auction Mechanics

### Timing
- The auction panel is accessible at any time during the walk via the HUD — no forced game pause.
- Bids are **end-of-loop settled**: all player and phantom bids are revealed simultaneously when the loop completes.
- Players may update their bids freely during the loop until settlement.

### Resolution
- Highest bidder per service wins and pays their bid.
- All losing bidders (player and phantoms alike) receive a full gold refund.
- A service with zero bids carries over to the next loop.

### Service Bar
- Won services go into the **service bar** (5 slots maximum).
- All services are manually activated — nothing auto-applies.
- Activating a service opens a targeting popup for the player to complete the operation.
- If the player wins a service while all 5 slots are occupied, a popup immediately appears showing all 6 services (5 held + 1 new). The player selects one to discard before proceeding.

---

## 5. Phantom Buyers

Two phantom buyers participate in every auction throughout the entire run.

### 影子甲 — 激进型 (Aggressive)
- Spends approximately 75% of current budget each loop.
- Has 2 preferred service types. Distributes spend across them proportionally.
- Does not save: remaining budget rarely exceeds one loop's income.
- Creates consistent, predictable pressure on their preferred services.

### 影子乙 — 蓄势型 (Patient)
- Has 1 absolute priority service.
- Below 200g: bids only 10–20g symbolically, accumulating savings.
- At or above 200g, when the priority service appears: bids 80%+ of total savings to guarantee a win.
- If the priority service has not appeared for 5 consecutive loops: spends 60% of savings on the best available alternative and resets.
- Creates periodic high-stakes spikes rather than steady pressure.

### Phantom Income (unspent gold carries over)

| Phase | Income per Loop |
|-------|----------------|
| 1–2   | 40g            |
| 3–4   | 70g            |
| 5–6   | 110g           |
| 7–8   | 150g           |
| 9–10  | 200g           |

---

## 6. Information & Counterplay

### What the Player Can See
- **Always visible on HUD:** both phantoms' current gold budgets, and an indicator when the auction is open.
- **Loop start:** for each service in this loop's auction, each phantom's interest level is shown as a bar (none / low / medium / high).
- **Auction panel — top section:** full results from the previous loop, including exact bids from all three parties and refund indicators.

### What is Hidden
- Phantom service type preferences are not directly disclosed.
- Players discover them through observation: repeated high-interest signals on the same service types across loops reveal each phantom's preference. After a phantom wins their first auction, a small type icon appears on their HUD entry as a first hint.

### Strategic Levers
- **Service pool control:** killing specific enemy types influences which services appear. Avoiding certain enemy types can deny the patient phantom's priority service from entering the pool.
- **Strategic denial:** bid high on a service the aggressive phantom wants, even if you don't need it, to deplete their budget.
- **Budget reading:** the patient phantom's accumulated gold is always visible. Once it approaches or exceeds 200g, anticipate an incoming heavy bid.
- **Timing service use:** services sit in the service bar until manually activated, giving the player full control over when to deploy them.

---

## 7. UI Structure

### HUD Constant Bar (always visible)
- Displays both phantom gold balances.
- Shows ⚠ warning when a phantom's balance approaches their threshold.
- Auction open/closed indicator with click-to-expand.

### Auction Panel (slides in from side, no pause)
- **Top section:** last loop's results — each service, each party's exact bid, winner marked ✓, losers marked ↩退.
- **Bottom section:** current loop's services — each with description, per-phantom interest bars, and a gold input field.
- Footer: current gold, allocated total, lock-bid button, auto-settle reminder.

### Service Bar (HUD)
- 5 icon slots displayed in HUD.
- Click icon → targeting popup opens for that service.
- Slot-full popup: displays all 6 services side by side for discard selection.

---

## 8. Narrative Layer

The two phantom buyers are emotional fragments of the Other Person — the unnamed presence the player shares the dream with. Their bidding behavior over many loops reveals something about who that person is: what they are always chasing, what they never touch.

In later phases, the patient phantom's behavior subtly shifts. Some services they would normally contest, they let go. The dream is beginning to resolve.

---

## 9. Implementation Notes

**New code (no existing systems modified):**
- `AuctionManager.gd` — service pool generation, bid collection, settlement logic
- `PhantomBuyer.gd` — budget tracking, interest calculation, bid execution for both personality types
- `ServiceBar.gd` — 5-slot UI, activation handling, full-slot discard popup
- `AuctionPanel.tscn / AuctionPanel.gd` — HUD panel with last-loop results and current bids

**Light extensions to existing systems:**
- `GameLoop.gd` — emit `loop_completed` signal that AuctionManager listens to for settlement
- `Tile.gd` — add `copy_rule_to(target_tile)` for 规则复制
- `ComponentData` — add `modify_n(new_n)` and `modify_base_value(delta)` for 词条改写
- `EconomyManager.gd` — expose deletion cost override hook for 删除特赦
- `PhaseManager.gd` — expose pressure counter adjustment for 压力延缓
