# I Am Thinking Of You — Music Wall Breaker

**Date:** 2026-05-15  
**Song:** 01. i am thinking of you [150BPM]  
**Stack:** Vanilla Canvas 2D + Web Audio API  
**Screen:** Vertical portrait, mobile-friendly  

---

## Concept

A pure music experience game. The player is a neon guitarist standing at the bottom of a first-person tunnel. Walls block the path — each wall locks one instrument stem. Hold to charge, release to fire a sound wave that shatters the wall and unlocks that stem. The song builds layer by layer until all 10 stems play together at the finale. No score. No fail state. Pure progression.

---

## Game Flow

### Title Screen
- Song title displayed in neon pink on dark background
- Acoustic guitar stem (`8 GUITAR ac`) begins playing immediately
- "Hold to start" prompt — first hold/release launches the game

### Per-Wall Loop (×9)
1. **Wall appears** far in the tunnel distance, glowing with the stem name (e.g. "BASS LOCKED")
2. **Player holds** finger/mouse down — charge bar at bottom fills, character glow intensifies, video playback rate increases (×1.5–2×)
3. **Player releases** — massive neon sound wave erupts up the tunnel toward the wall
4. **Wall shatters** — particle burst, screen flash
5. **Stem unlocks** — that stem's gain ramps from 0 → 1 over 2 beats (~0.8s at 150BPM); the corresponding dot in the header lights up
6. **Character walks forward** — character translates up-screen ~0.5s, next wall fades in from the distance

### Finale
- After wall 9 breaks (VOX 2), all 10 stems play simultaneously
- Screen fills with expanding light rings
- Song title + "Thank you" fade in
- Song continues playing; the scene loops gently

---

## Stems — Unlock Order

| # | File | Unlock trigger |
|---|------|----------------|
| 0 | `01. i am thinking of you 150BPM] - 8 GUITAR ac.mp3` | Plays from start, no wall |
| 1 | `01. i am thinking of you - 5 BASS.mp3` | Wall 1 |
| 2 | `01. i am thinking of you [150BPM] - 9 GUITAR baritone notes.mp3` | Wall 2 |
| 3 | `01. i am thinking of you [150BPM] - 7 SYTNH DRONE.mp3` | Wall 3 |
| 4 | `01. i am thinking of you [150BPM] - 6 SYNTH LEAD.mp3` | Wall 4 |
| 5 | `01. i am thinking of you - Remix Stems [150BPM] - 10 GUITAR main melody.mp3` | Wall 5 |
| 6 | `01. i am thinking of you - Remix Stems [150BPM] - 11 STRINGS.mp3` | Wall 6 |
| 7 | `01. i am thinking of you - Remix Stems [150BPM] - 15 FX.mp3` | Wall 7 |
| 8 | `01. i am thinking of you - Remix Stems [150BPM] - 12 VOX 1.mp3` | Wall 8 |
| 9 | `01. i am thinking of you - Remix Stems [150BPM] - 13 VOX 2.mp3` | Wall 9 → finale |

---

## Visual Design

### Style: Neon Synthwave
- **Background:** Near-black `#020010` → `#14002a` gradient
- **Tunnel:** Perspective vanishing-point lines in hot pink `rgba(255,40,200,0.2)`
- **Floor:** Retrowave grid — repeating horizontal + vertical lines in pink
- **Walls:** Pink-bordered glowing quads with stem name in `#ff80ee`
- **Sound waves:** Elliptical rings (scaleY 0.3) expanding up the tunnel in pink/purple
- **Charge bar:** Thin horizontal bar below character, fills pink → purple as held
- **Stem tracker:** 10 dots at top of screen; unlocked dots glow pink with drop-shadow
- **Particle burst:** On wall break — 20–30 pink/purple particles scatter from wall center

### Character
- Source: `character.mov` — neon laser-outline guitarist, golden amber on black, 492×500px, 60fps
- Trimmed to first clean loop (~4s) and converted to `character.webm`
- Displayed at bottom-center of screen, ~22px equivalent height scaled to fit
- Drawn each frame via hidden `<video>` element onto Canvas with `globalCompositeOperation = 'screen'` — black background vanishes, only glowing neon lines remain
- **States:**
  - *Idle/playing:* video loops at normal rate
  - *Charging:* video playback rate ×1.5; radial glow gradient expands around character
  - *Firing:* single white flash frame, then wave launches
  - *Walking:* character Y position tweens upward ~30px over 500ms

---

## Audio Architecture

Single `AudioContext`. All 10 stems are decoded and scheduled to start simultaneously at `AudioContext.currentTime + 0.1`. Each stem routes through its own `GainNode` initialized to `gain.value = 0` (except stem 0 which starts at `1`).

On wall break:
```
gainNode.gain.linearRampToValueAtTime(1, ctx.currentTime + beatDuration * 2)
```
`beatDuration = 60 / 150 = 0.4s` → ramp over 0.8s.

Because all stems are playing silently in sync from the start, unlocking is instantaneous with no load latency and perfect musical timing.

**iOS Safari:** `AudioContext` is resumed inside the first `pointerdown` handler (gesture unlock). All stems start inside the same handler call.

---

## Rendering Architecture

### Canvas Setup
- Single `<canvas>` element, sized to `window.innerWidth × window.innerHeight`
- Game loop via `requestAnimationFrame`
- Coordinate system: origin top-left, Y increases downward

### Tunnel Renderer
Vanishing point fixed at `(canvas.width/2, canvas.height * 0.25)`. Walls are rendered as trapezoids:
- At distance 1.0 (far): narrow quad near vanishing point
- At distance 0.0 (arrival): full-width quad at floor level
- Wall scales linearly between these as it approaches each frame

### Draw Order (per frame)
1. Background gradient fill
2. Floor grid
3. Tunnel perspective lines
4. Walls (back to front)
5. Sound wave rings
6. Particle systems
7. Character (screen blend)
8. Charge glow overlay
9. UI (stem dots, charge bar)

---

## File Structure

```
web/
  index.html          ← entire game (HTML + CSS + JS inline)
  sounds/
    guitar_ac.mp3     ← copied from /Documents/Track1/
    bass.mp3
    guitar_baritone.mp3
    synth_drone.mp3
    synth_lead.mp3
    guitar_main.mp3
    strings.mp3
    fx.mp3
    vox1.mp3
    vox2.mp3
  character.webm      ← trimmed + converted from character.mov
```

---

## Out of Scope
- Score / combo system
- Fail state or lives
- Multiple songs
- Level editor
- Mobile app wrapper
