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
