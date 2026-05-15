# Music Wall Breaker Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build "I Am Thinking Of You" — a vertical portrait music game where a neon guitarist breaks walls to unlock 10 instrument stems, building the full song layer by layer.

**Architecture:** Single `web/game.html` file with all JS inline. Canvas 2D renders the tunnel, walls, particles, and waves each frame. Character is a `<video>` element with CSS `mix-blend-mode: screen` — black vanishes, golden neon glows. Web Audio API loads all 10 stems simultaneously at gain=0; unlocking a stem ramps its gain to 1 over 0.8s. No framework, no dependencies.

**Tech Stack:** Vanilla Canvas 2D, Web Audio API, CSS mix-blend-mode, VP9 WebM video, HTML5

---

## File Map

| File | Purpose |
|------|---------|
| `web/game.html` | Entire game — HTML + CSS + JS inline |
| `web/character.webm` | Trimmed 4s loop of neon guitarist (from character.mov) |
| `web/sounds/guitar_ac.mp3` | Stem 0 — starts playing immediately |
| `web/sounds/bass.mp3` | Stem 1 — wall 1 |
| `web/sounds/guitar_baritone.mp3` | Stem 2 — wall 2 |
| `web/sounds/synth_drone.mp3` | Stem 3 — wall 3 |
| `web/sounds/synth_lead.mp3` | Stem 4 — wall 4 |
| `web/sounds/guitar_main.mp3` | Stem 5 — wall 5 |
| `web/sounds/strings.mp3` | Stem 6 — wall 6 |
| `web/sounds/fx.mp3` | Stem 7 — wall 7 |
| `web/sounds/vox1.mp3` | Stem 8 — wall 8 |
| `web/sounds/vox2.mp3` | Stem 9 — wall 9 → finale |

---

## Task 1: Prepare Assets

**Files:**
- Create: `web/sounds/` (directory + 10 stem files)
- Create: `web/character.webm`

- [ ] **Step 1: Create sounds directory**

```bash
mkdir -p /Users/mike/Downloads/bitbird\(ios\)/.claude/worktrees/cool-williamson-6cf607/web/sounds
```

- [ ] **Step 2: Copy all 10 stems**

```bash
TRACK="/Users/mike/Documents/Track1"
WEB="/Users/mike/Downloads/bitbird(ios)/.claude/worktrees/cool-williamson-6cf607/web/sounds"

cp "$TRACK/01. i am thinking of you 150BPM] -  8 GUITAR ac.mp3"                        "$WEB/guitar_ac.mp3"
cp "$TRACK/01. i am thinking of you - 5 BASS.mp3"                                       "$WEB/bass.mp3"
cp "$TRACK/01. i am thinking of you [150BPM] -  9 GUITAR baritone notes.mp3"            "$WEB/guitar_baritone.mp3"
cp "$TRACK/01. i am thinking of you [150BPM] -  7 SYTNH DRONE.mp3"                      "$WEB/synth_drone.mp3"
cp "$TRACK/01. i am thinking of you [150BPM] -  6 SYNTH LEAD.mp3"                       "$WEB/synth_lead.mp3"
cp "$TRACK/01. i am thinking of you - Remix Stems [150BPM] -  10 GUITAR main melody.mp3" "$WEB/guitar_main.mp3"
cp "$TRACK/01. i am thinking of you - Remix Stems [150BPM] -  11 STRINGS.mp3"           "$WEB/strings.mp3"
cp "$TRACK/01. i am thinking of you - Remix Stems [150BPM] -  15 FX.mp3"               "$WEB/fx.mp3"
cp "$TRACK/01. i am thinking of you - Remix Stems [150BPM] -  12 VOX 1.mp3"            "$WEB/vox1.mp3"
cp "$TRACK/01. i am thinking of you - Remix Stems [150BPM] -  13 VOX 2.mp3"            "$WEB/vox2.mp3"
```

Expected: `ls web/sounds/` shows 10 .mp3 files.

- [ ] **Step 3: Convert character video — trim 4s clean loop to WebM**

```bash
ffmpeg -y \
  -i "/Users/mike/Library/Mobile Documents/com~apple~CloudDocs/character.mov" \
  -t 4 \
  -c:v libvpx-vp9 -b:v 0 -crf 30 -an \
  /Users/mike/Downloads/bitbird\(ios\)/.claude/worktrees/cool-williamson-6cf607/web/character.webm
```

Expected: `web/character.webm` exists, ~1MB.

- [ ] **Step 4: Verify**

```bash
ls -lh /Users/mike/Downloads/bitbird\(ios\)/.claude/worktrees/cool-williamson-6cf607/web/sounds/
ls -lh /Users/mike/Downloads/bitbird\(ios\)/.claude/worktrees/cool-williamson-6cf607/web/character.webm
```

Expected: 10 mp3 files + character.webm present.

- [ ] **Step 5: Commit**

```bash
cd /Users/mike/Downloads/bitbird\(ios\)/.claude/worktrees/cool-williamson-6cf607
git add web/sounds/ web/character.webm
git commit -m "feat: add stem audio assets and character webm"
```

---

## Task 2: HTML Skeleton + Canvas Game Loop

**Files:**
- Create: `web/game.html`

- [ ] **Step 1: Create `web/game.html` with canvas, video, and RAF loop**

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1, user-scalable=no">
<title>I Am Thinking Of You</title>
<style>
* { box-sizing: border-box; margin: 0; padding: 0; }
html, body { width: 100%; height: 100%; overflow: hidden; background: #000; }
canvas#game { display: block; width: 100%; height: 100%; touch-action: none; }
#charVideo {
  display: none;
  position: fixed;
  width: 140px; height: 140px;
  mix-blend-mode: screen;
  pointer-events: none;
}
</style>
</head>
<body>
<canvas id="game"></canvas>
<video id="charVideo" loop playsinline muted>
  <source src="character.webm" type="video/webm">
</video>

<script>
'use strict';

// ── Canvas setup ──────────────────────────────────────────────
const canvas = document.getElementById('game');
const ctx    = canvas.getContext('2d');
const video  = document.getElementById('charVideo');

function resize() {
  canvas.width  = window.innerWidth;
  canvas.height = window.innerHeight;
}
resize();
window.addEventListener('resize', resize);

// ── Constants ────────────────────────────────────────────────
const BPM          = 150;
const BEAT_S       = 60 / BPM;          // 0.4s per beat
const UNLOCK_RAMP  = BEAT_S * 2;        // 0.8s gain ramp
const CHAR_W       = 140;
const CHAR_H       = 140;

// Vanishing point = top-centre at 25% height
function vp() { return { x: canvas.width / 2, y: canvas.height * 0.25 }; }

// ── Game state ───────────────────────────────────────────────
const SCENE = { TITLE: 0, PLAYING: 1, BREAKING: 2, WALKING: 3, FINALE: 4 };
let scene        = SCENE.TITLE;
let currentWall  = 0;     // 0-8 (9 walls)
let charOffsetY  = 0;     // walk animation offset (px, positive = up)
let chargeLevel  = 0;     // 0-1
let isHolding    = false;
let chargeStart  = 0;
let particles    = [];
let waveRings    = [];
let walkStart    = 0;
let finaleStart  = 0;
let unlockedDots = 1;     // guitar_ac starts unlocked
let frameDt      = 0.016; // updated each loop tick, used by drawParticles

// ── RAF loop ─────────────────────────────────────────────────
let lastTime = 0;
function loop(ts) {
  frameDt  = Math.min((ts - lastTime) / 1000, 0.05);
  lastTime = ts;
  update(frameDt, ts);
  draw(ts);
  requestAnimationFrame(loop);
}

function update(dt, ts) {
  // placeholder — filled in later tasks
}

function draw(ts) {
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  // placeholder — filled in later tasks
  ctx.fillStyle = '#020010';
  ctx.fillRect(0, 0, canvas.width, canvas.height);
}

video.addEventListener('canplay', () => { video.play().catch(() => {}); });
video.load();
requestAnimationFrame(loop);
</script>
</body>
</html>
```

- [ ] **Step 2: Open in browser and verify**

Open `web/game.html` directly in Chrome. Expected: solid dark `#020010` background, no errors in console.

- [ ] **Step 3: Commit**

```bash
cd /Users/mike/Downloads/bitbird\(ios\)/.claude/worktrees/cool-williamson-6cf607
git add web/game.html
git commit -m "feat: html skeleton with canvas game loop"
```

---

## Task 3: Tunnel Renderer

**Files:**
- Modify: `web/game.html` — add `drawBackground()`, `drawTunnel()`, `drawFloorGrid()`

- [ ] **Step 1: Add background + tunnel draw functions inside `<script>`, before the `update` function**

```javascript
// ── Renderers ────────────────────────────────────────────────

function drawBackground() {
  const grad = ctx.createLinearGradient(0, 0, 0, canvas.height);
  grad.addColorStop(0,   '#020010');
  grad.addColorStop(0.5, '#0a0028');
  grad.addColorStop(1,   '#14002a');
  ctx.fillStyle = grad;
  ctx.fillRect(0, 0, canvas.width, canvas.height);
}

function drawStars(ts) {
  // Deterministic star field seeded by position
  const seed = 42;
  for (let i = 0; i < 80; i++) {
    const t  = (seed * (i + 1) * 1.618) % 1;
    const t2 = (seed * (i + 1) * 3.141) % 1;
    const t3 = (seed * (i + 1) * 2.718) % 1;
    const x  = (t  * canvas.width);
    const y  = (t2 * canvas.height * 0.7);
    const r  = 0.5 + t3 * 1.2;
    const blink = 0.3 + 0.5 * Math.sin(ts * 0.001 * (1 + t3 * 2) + i);
    ctx.beginPath();
    ctx.arc(x, y, r, 0, Math.PI * 2);
    ctx.fillStyle = `rgba(255,255,255,${blink.toFixed(2)})`;
    ctx.fill();
  }
}

function drawTunnel() {
  const v = vp();
  const floorY = canvas.height - canvas.height * 0.22;
  const sides  = canvas.width * 0.05;

  ctx.strokeStyle = 'rgba(255,40,200,0.18)';
  ctx.lineWidth   = 1;

  // Left wall line
  ctx.beginPath();
  ctx.moveTo(v.x, v.y);
  ctx.lineTo(sides, floorY);
  ctx.stroke();

  // Right wall line
  ctx.beginPath();
  ctx.moveTo(v.x, v.y);
  ctx.lineTo(canvas.width - sides, floorY);
  ctx.stroke();

  // Top horizontal line
  const topW = canvas.width * 0.35;
  ctx.beginPath();
  ctx.moveTo(v.x - topW / 2, v.y);
  ctx.lineTo(v.x + topW / 2, v.y);
  ctx.stroke();
}

function drawFloorGrid() {
  const floorY = canvas.height - canvas.height * 0.22;
  const h      = canvas.height - floorY;

  // Vertical grid lines (perspective-converging)
  ctx.strokeStyle = 'rgba(255,40,200,0.15)';
  ctx.lineWidth   = 1;
  const v = vp();
  const cols = 10;
  for (let i = 0; i <= cols; i++) {
    const t  = i / cols;
    const bx = t * canvas.width;
    ctx.beginPath();
    ctx.moveTo(v.x + (bx - v.x) * 0.05, floorY);
    ctx.lineTo(bx, canvas.height);
    ctx.stroke();
  }

  // Horizontal grid lines
  const rows = 6;
  for (let i = 0; i <= rows; i++) {
    const t  = i / rows;
    const y  = floorY + t * h;
    const xL = v.x + (0 - v.x) * (1 - t * 0.95);
    const xR = v.x + (canvas.width - v.x) * (1 - t * 0.95);
    ctx.globalAlpha = 0.1 + t * 0.1;
    ctx.beginPath();
    ctx.moveTo(xL, y);
    ctx.lineTo(xR, y);
    ctx.stroke();
  }
  ctx.globalAlpha = 1;
}
```

- [ ] **Step 2: Replace `draw()` to call the new functions**

```javascript
function draw(ts) {
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  drawBackground();
  drawStars(ts);
  drawTunnel();
  drawFloorGrid();
}
```

- [ ] **Step 3: Open in browser and verify**

Expected: dark gradient background, faint pink tunnel perspective lines converging to a vanishing point in the upper centre, retrowave grid floor, twinkling stars. No console errors.

- [ ] **Step 4: Commit**

```bash
git add web/game.html
git commit -m "feat: tunnel renderer with perspective lines and grid floor"
```

---

## Task 4: Character Renderer

**Files:**
- Modify: `web/game.html` — add `drawCharacter()`, position video element

The video has `mix-blend-mode: screen` in CSS so its black background vanishes on screen. We draw its position by moving a real DOM element — no canvas drawImage needed, which avoids cross-origin issues with the video element.

- [ ] **Step 1: Change `#charVideo` CSS to `display: block; position: fixed`**

Replace the existing `#charVideo` style block:

```css
#charVideo {
  position: fixed;
  width: 140px;
  height: 140px;
  mix-blend-mode: screen;
  pointer-events: none;
  z-index: 10;
  transform-origin: bottom center;
}
```

- [ ] **Step 2: Add `positionCharacter()` function inside `<script>`, after `drawFloorGrid`**

```javascript
function positionCharacter() {
  const floorY  = canvas.height - canvas.height * 0.22;
  const centerX = canvas.width / 2;
  // Character sits with its bottom on the floor line, centred
  const left = centerX - CHAR_W / 2;
  const top  = floorY - CHAR_H - charOffsetY;
  video.style.left = left + 'px';
  video.style.top  = top  + 'px';
  video.style.display = 'block';

  // Scale up slightly when charging
  const scale = 1 + chargeLevel * 0.06;
  video.style.transform = `scale(${scale.toFixed(3)})`;

  // Playback rate: faster when charging
  video.playbackRate = isHolding ? 1.8 : 1.0;
}
```

- [ ] **Step 3: Add character glow canvas function, after `positionCharacter`**

```javascript
function drawCharacterGlow() {
  if (chargeLevel < 0.05) return;
  const floorY  = canvas.height - canvas.height * 0.22;
  const centerX = canvas.width / 2;
  const r = 30 + chargeLevel * 100;
  const grd = ctx.createRadialGradient(centerX, floorY, 0, centerX, floorY, r);
  grd.addColorStop(0,   `rgba(255,100,200,${(chargeLevel * 0.5).toFixed(2)})`);
  grd.addColorStop(1,   'rgba(255,40,200,0)');
  ctx.fillStyle = grd;
  ctx.beginPath();
  ctx.ellipse(centerX, floorY, r, r * 0.5, 0, 0, Math.PI * 2);
  ctx.fill();
}
```

- [ ] **Step 4: Call both in `draw()`**

```javascript
function draw(ts) {
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  drawBackground();
  drawStars(ts);
  drawTunnel();
  drawFloorGrid();
  drawCharacterGlow();
  positionCharacter();
}
```

- [ ] **Step 5: Open in browser and verify**

Expected: Golden neon guitarist visible at the bottom-centre of the screen, glowing against the dark tunnel background. No black box around the character.

- [ ] **Step 6: Commit**

```bash
git add web/game.html
git commit -m "feat: character video renderer with screen blend"
```

---

## Task 5: Wall Renderer

**Files:**
- Modify: `web/game.html` — add wall depth data, `drawWall()`

Each wall has a `depth` value: 1.0 = far (tiny, near VP), 0.0 = arrived (full width at floor). During PLAYING state the wall stays at 0.0 (already arrived, waiting to be broken).

- [ ] **Step 1: Add STEMS config and wall label data after the constants block**

```javascript
const STEMS = [
  { file: 'sounds/guitar_ac.mp3',       label: 'GUITAR AC',       startGain: 1 },
  { file: 'sounds/bass.mp3',            label: 'BASS',            startGain: 0 },
  { file: 'sounds/guitar_baritone.mp3', label: 'GUITAR BARITONE', startGain: 0 },
  { file: 'sounds/synth_drone.mp3',     label: 'SYNTH DRONE',     startGain: 0 },
  { file: 'sounds/synth_lead.mp3',      label: 'SYNTH LEAD',      startGain: 0 },
  { file: 'sounds/guitar_main.mp3',     label: 'GUITAR MAIN',     startGain: 0 },
  { file: 'sounds/strings.mp3',         label: 'STRINGS',         startGain: 0 },
  { file: 'sounds/fx.mp3',              label: 'FX',              startGain: 0 },
  { file: 'sounds/vox1.mp3',            label: 'VOX 1',           startGain: 0 },
  { file: 'sounds/vox2.mp3',            label: 'VOX 2',           startGain: 0 },
];

// Wall approach: 0 = currentWall approaching from distance
let wallDepth = 0.85;  // starts far, approaches to 0
```

- [ ] **Step 2: Add `drawWall()` function after `drawCharacterGlow`**

```javascript
// depth: 1.0=vanishing point, 0.0=floor level (arrived)
function drawWall(depth, label) {
  const v      = vp();
  const floorY = canvas.height - canvas.height * 0.22;
  const sides  = canvas.width * 0.05;

  // Interpolate wall quad between VP (depth=1) and floor edges (depth=0)
  const t   = 1 - depth;  // t=0 far, t=1 arrived
  const top = v.y  + (floorY - 80 - v.y)  * t;
  const bot = v.y  + (floorY - v.y)        * t;
  const xL  = v.x  + (sides - v.x)         * t;
  const xR  = v.x  + (canvas.width - sides - v.x) * t;

  const alpha = 0.3 + t * 0.6;

  // Wall fill
  ctx.fillStyle = `rgba(100,0,120,${(alpha * 0.4).toFixed(2)})`;
  ctx.beginPath();
  ctx.moveTo(xL, top);
  ctx.lineTo(xR, top);
  ctx.lineTo(xR, bot);
  ctx.lineTo(xL, bot);
  ctx.closePath();
  ctx.fill();

  // Wall border — glowing pink
  ctx.strokeStyle = `rgba(255,60,220,${alpha.toFixed(2)})`;
  ctx.lineWidth   = 2 + t * 2;
  ctx.shadowColor  = '#ff40cc';
  ctx.shadowBlur   = 8 + t * 16;
  ctx.stroke();
  ctx.shadowBlur   = 0;

  // Label — only show when close enough (depth < 0.5)
  if (depth < 0.5 && label) {
    const fontSize = Math.round(10 + t * 18);
    ctx.font      = `700 ${fontSize}px 'Helvetica Neue', Arial, sans-serif`;
    ctx.textAlign = 'center';
    ctx.fillStyle = `rgba(255,128,238,${(t * 1.2).toFixed(2)})`;
    ctx.shadowColor = '#ff40cc';
    ctx.shadowBlur  = 12;
    ctx.fillText('🎸 ' + label + ' LOCKED', v.x, (top + bot) / 2 + fontSize * 0.35);
    ctx.shadowBlur  = 0;
  }
}
```

- [ ] **Step 3: Add wall approach to `update()` and call `drawWall()` in `draw()`**

Update `update()`:

```javascript
function update(dt, ts) {
  if (scene === SCENE.PLAYING) {
    // Wall approaches slowly from depth 0.85 to 0.0 over ~3s
    if (wallDepth > 0) {
      wallDepth = Math.max(0, wallDepth - dt * 0.28);
    }
  }
}
```

Update `draw()` — add wall draw before character glow:

```javascript
function draw(ts) {
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  drawBackground();
  drawStars(ts);
  drawTunnel();
  drawFloorGrid();

  if (scene === SCENE.PLAYING || scene === SCENE.BREAKING) {
    const label = currentWall < STEMS.length - 1 ? STEMS[currentWall + 1].label : null;
    drawWall(wallDepth, label);
  }

  drawCharacterGlow();
  positionCharacter();
}
```

- [ ] **Step 4: Set initial scene to PLAYING to preview wall, add temp start**

Add after `video.load()`:

```javascript
scene = SCENE.PLAYING;
wallDepth = 0.85;
```

- [ ] **Step 5: Open in browser and verify**

Expected: Wall trapezoid slowly approaches from near the vanishing point. As it gets closer, the "🎸 BASS LOCKED" label appears, font grows, glow intensifies. Character sits in front of the arriving wall.

- [ ] **Step 6: Commit**

```bash
git add web/game.html
git commit -m "feat: wall renderer with perspective depth approach"
```

---

## Task 6: Audio Engine

**Files:**
- Modify: `web/game.html` — add `initAudio()`, `unlockStem()`

- [ ] **Step 1: Add audio state variables after the game state block**

```javascript
// ── Audio ─────────────────────────────────────────────────────
let audioCtx   = null;
let gainNodes  = [];   // GainNode per stem, indexed 0-9
let audioReady = false;
```

- [ ] **Step 2: Add `initAudio()` function — fetches, decodes, and starts all stems**

Add after `drawFloorGrid`:

```javascript
async function initAudio() {
  if (audioCtx) return;
  audioCtx = new (window.AudioContext || window.webkitAudioContext)();
  if (audioCtx.state === 'suspended') await audioCtx.resume();

  const startTime = audioCtx.currentTime + 0.3;

  const buffers = await Promise.all(
    STEMS.map(s => fetch(s.file).then(r => r.arrayBuffer()).then(b => audioCtx.decodeAudioData(b)))
  );

  buffers.forEach((buf, i) => {
    const gain = audioCtx.createGain();
    gain.gain.setValueAtTime(STEMS[i].startGain, audioCtx.currentTime);
    gain.connect(audioCtx.destination);
    gainNodes[i] = gain;

    const src = audioCtx.createBufferSource();
    src.buffer = buf;
    src.loop   = true;
    src.connect(gain);
    src.start(startTime);
  });

  audioReady = true;
}

function unlockStem(index) {
  if (!audioCtx || index >= gainNodes.length) return;
  gainNodes[index].gain.linearRampToValueAtTime(1, audioCtx.currentTime + UNLOCK_RAMP);
}
```

- [ ] **Step 3: Add iOS-safe first-interaction handler — call `initAudio()` on first touch**

Add before `requestAnimationFrame(loop)`:

```javascript
let audioStarted = false;
async function onFirstInteraction() {
  if (audioStarted) return;
  audioStarted = true;
  await initAudio();
}
canvas.addEventListener('pointerdown', onFirstInteraction, { once: true });
```

- [ ] **Step 4: Open in browser, tap/click the screen, open DevTools console**

Expected: No errors. After tap, `audioReady` becomes true (add `console.log('audio ready')` temporarily in `initAudio` to verify). Acoustic guitar stem should begin playing.

- [ ] **Step 5: Remove the temporary console.log, commit**

```bash
git add web/game.html
git commit -m "feat: web audio engine with 10 stems and iOS unlock"
```

---

## Task 7: Input System — Hold to Charge, Release to Fire

**Files:**
- Modify: `web/game.html` — add charge logic, charge bar UI, input handlers

- [ ] **Step 1: Add charge bar UI draw function after `drawCharacterGlow`**

```javascript
function drawChargeBar() {
  if (scene !== SCENE.PLAYING) return;
  const floorY  = canvas.height - canvas.height * 0.22;
  const barW    = canvas.width * 0.5;
  const barH    = 4;
  const x       = (canvas.width - barW) / 2;
  const y       = floorY - CHAR_H - charOffsetY - 16;

  // Track
  ctx.fillStyle = 'rgba(255,40,200,0.12)';
  ctx.beginPath();
  ctx.roundRect(x, y, barW, barH, 2);
  ctx.fill();

  // Fill
  if (chargeLevel > 0) {
    const grd = ctx.createLinearGradient(x, 0, x + barW, 0);
    grd.addColorStop(0, '#ff30cc');
    grd.addColorStop(1, '#aa00ff');
    ctx.fillStyle = grd;
    ctx.shadowColor = '#ff30cc';
    ctx.shadowBlur  = 6;
    ctx.beginPath();
    ctx.roundRect(x, y, barW * chargeLevel, barH, 2);
    ctx.fill();
    ctx.shadowBlur = 0;
  }
}
```

- [ ] **Step 2: Add input event handlers before `requestAnimationFrame(loop)`**

```javascript
// ── Input ────────────────────────────────────────────────────
canvas.addEventListener('pointerdown', async (e) => {
  e.preventDefault();
  await onFirstInteraction();
  if (scene !== SCENE.PLAYING) return;
  isHolding   = true;
  chargeStart = performance.now();
});

canvas.addEventListener('pointerup', (e) => {
  e.preventDefault();
  if (!isHolding || scene !== SCENE.PLAYING) return;
  isHolding = false;
  fireWave();
});

canvas.addEventListener('pointerleave', () => {
  if (isHolding) { isHolding = false; fireWave(); }
});
```

- [ ] **Step 3: Add charge update to `update()`**

```javascript
function update(dt, ts) {
  // Charge
  if (isHolding && scene === SCENE.PLAYING) {
    chargeLevel = Math.min((performance.now() - chargeStart) / 2000, 1);
  } else if (!isHolding) {
    chargeLevel = Math.max(0, chargeLevel - dt * 3);
  }

  if (scene === SCENE.PLAYING) {
    if (wallDepth > 0) {
      wallDepth = Math.max(0, wallDepth - dt * 0.28);
    }
  }
}
```

- [ ] **Step 4: Add `fireWave()` stub (implementation in Task 8)**

```javascript
function fireWave() {
  const power = chargeLevel;
  chargeLevel = 0;
  if (power < 0.01) return;
  // wave rings added in Task 8
  console.log('fire! power:', power.toFixed(2));
}
```

- [ ] **Step 5: Add `drawChargeBar()` call in `draw()`**

```javascript
function draw(ts) {
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  drawBackground();
  drawStars(ts);
  drawTunnel();
  drawFloorGrid();

  if (scene === SCENE.PLAYING || scene === SCENE.BREAKING) {
    const label = currentWall < STEMS.length - 1 ? STEMS[currentWall + 1].label : null;
    drawWall(wallDepth, label);
  }

  drawCharacterGlow();
  drawChargeBar();
  positionCharacter();
}
```

- [ ] **Step 6: Open in browser and verify**

Expected: Hold anywhere on canvas — charge bar fills pink→purple from the left. Release — bar drains. Console shows "fire! power: 0.82" (or whatever charge level).

- [ ] **Step 7: Commit**

```bash
git add web/game.html
git commit -m "feat: hold-to-charge input with charge bar UI"
```

---

## Task 8: Sound Wave Animation

**Files:**
- Modify: `web/game.html` — add wave ring objects, `drawWaves()`

- [ ] **Step 1: Add wave ring draw function after `drawChargeBar`**

```javascript
function drawWaves(ts) {
  const floorY  = canvas.height - canvas.height * 0.22;
  const centerX = canvas.width / 2;
  const originY = floorY - CHAR_H * 0.5;

  waveRings = waveRings.filter(w => {
    const elapsed = (ts - w.startTs) / 1000;
    const t       = Math.min(elapsed / w.duration, 1);
    if (t >= 1) return false;

    const size   = w.size0 + t * w.maxSize;
    const alpha  = (1 - t) * 0.8;
    const y      = originY - t * (originY - vp().y - 20);

    ctx.save();
    ctx.translate(centerX, y);
    ctx.scale(1, 0.35);  // flatten to ellipse (perspective)
    ctx.beginPath();
    ctx.arc(0, 0, size / 2, 0, Math.PI * 2);
    ctx.strokeStyle = `rgba(255,60,200,${alpha.toFixed(2)})`;
    ctx.lineWidth   = 2 + w.power * 2;
    ctx.shadowColor = '#ff40cc';
    ctx.shadowBlur  = 10;
    ctx.stroke();
    ctx.restore();

    return true;
  });
}
```

- [ ] **Step 2: Replace `fireWave()` stub with the real implementation**

```javascript
function fireWave() {
  const power = chargeLevel;
  chargeLevel = 0;
  if (power < 0.01) return;

  const ts = performance.now();
  // Spawn 3 staggered wave rings
  for (let i = 0; i < 3; i++) {
    waveRings.push({
      startTs:  ts + i * 120,
      duration: 0.7 + power * 0.6,
      size0:    20,
      maxSize:  60 + power * 200,
      power,
    });
  }
  // Trigger wall break if wall has arrived
  if (wallDepth <= 0.05) {
    setTimeout(() => breakWall(power), 350);
  }
}
```

- [ ] **Step 3: Add `breakWall()` stub (implemented in Task 9)**

```javascript
function breakWall(power) {
  console.log('break wall', currentWall, 'power', power.toFixed(2));
}
```

- [ ] **Step 4: Call `drawWaves()` in `draw()`, before character**

```javascript
function draw(ts) {
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  drawBackground();
  drawStars(ts);
  drawTunnel();
  drawFloorGrid();

  if (scene === SCENE.PLAYING || scene === SCENE.BREAKING) {
    const label = currentWall < STEMS.length - 1 ? STEMS[currentWall + 1].label : null;
    drawWall(wallDepth, label);
  }

  drawWaves(ts);
  drawCharacterGlow();
  drawChargeBar();
  positionCharacter();
}
```

- [ ] **Step 5: Open in browser and verify**

Expected: Hold and release — 3 elliptical wave rings shoot upward from the character toward the wall vanishing point. Bigger charge = bigger, faster rings. Console logs "break wall 0 power 0.73" when wall is at depth ≤ 0.05.

- [ ] **Step 6: Commit**

```bash
git add web/game.html
git commit -m "feat: sound wave rings with perspective ellipse animation"
```

---

## Task 9: Wall Break Effect + Stem Unlock

**Files:**
- Modify: `web/game.html` — implement `breakWall()`, particle system, `drawParticles()`

- [ ] **Step 1: Add particle draw function after `drawWaves`**

```javascript
function spawnParticles(power) {
  const v      = vp();
  const count  = Math.round(20 + power * 30);
  for (let i = 0; i < count; i++) {
    const angle = Math.random() * Math.PI * 2;
    const speed = 80 + Math.random() * 200 * power;
    particles.push({
      x:    v.x,
      y:    v.y + 40,
      vx:   Math.cos(angle) * speed,
      vy:   Math.sin(angle) * speed,
      life: 1,
      size: 2 + Math.random() * 4,
      hue:  280 + Math.random() * 60,  // pink-purple range
    });
  }
}

function drawParticles(dt) {
  particles = particles.filter(p => {
    p.x    += p.vx * dt;
    p.y    += p.vy * dt;
    p.vy   += 120 * dt;  // gravity
    p.life -= dt * 1.5;
    if (p.life <= 0) return false;

    ctx.beginPath();
    ctx.arc(p.x, p.y, p.size * p.life, 0, Math.PI * 2);
    ctx.fillStyle = `hsla(${p.hue},100%,70%,${p.life.toFixed(2)})`;
    ctx.shadowColor = `hsl(${p.hue},100%,70%)`;
    ctx.shadowBlur  = 6;
    ctx.fill();
    ctx.shadowBlur  = 0;
    return true;
  });
}
```

- [ ] **Step 2: Add screen flash state variable after game state block**

```javascript
let flashAlpha = 0;  // 0-1, screen white flash on wall break
```

- [ ] **Step 3: Implement `breakWall()` fully**

```javascript
function breakWall(power) {
  if (scene !== SCENE.PLAYING) return;
  scene = SCENE.BREAKING;

  // Flash
  flashAlpha = 0.6 + power * 0.4;

  // Particles
  spawnParticles(power);

  // Unlock the next stem (currentWall+1 because stem 0 is guitar_ac, already playing)
  const stemIndex = currentWall + 1;
  unlockStem(stemIndex);
  unlockedDots = stemIndex + 1;

  // After 1.2s: walk to next wall
  setTimeout(() => startWalk(), 1200);
}
```

- [ ] **Step 4: Add flash draw and particle draw in `draw()`**

Update `draw()`:

```javascript
function draw(ts) {
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  drawBackground();
  drawStars(ts);
  drawTunnel();
  drawFloorGrid();

  if (scene === SCENE.PLAYING || scene === SCENE.BREAKING) {
    const label = currentWall < STEMS.length - 1 ? STEMS[currentWall + 1].label : null;
    drawWall(wallDepth, label);
  }

  drawWaves(ts);
  drawCharacterGlow();
  drawChargeBar();
  positionCharacter();
  drawParticles(frameDt);  // particles update with fixed dt approximation

  // Screen flash
  if (flashAlpha > 0) {
    ctx.fillStyle = `rgba(255,200,255,${flashAlpha.toFixed(2)})`;
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    flashAlpha = Math.max(0, flashAlpha - 0.04);
  }
}
```

- [ ] **Step 5: Add `startWalk()` stub (implemented in Task 10)**

```javascript
function startWalk() {
  console.log('walk to wall', currentWall + 1);
  scene = SCENE.PLAYING;
  currentWall++;
  wallDepth = 0.85;
}
```

- [ ] **Step 6: Open in browser and verify**

- Hold to full charge, release when wall arrives (wallDepth ≤ 0.05)
- Expected: white screen flash, pink/purple particle burst near vanishing point
- After 1.2s: currentWall increments, new wall label shows (e.g. "GUITAR BARITONE LOCKED")
- Audio: acoustic guitar plays from start; after first break, bass fades in

- [ ] **Step 7: Commit**

```bash
git add web/game.html
git commit -m "feat: wall break effect with particles, flash, and stem unlock"
```

---

## Task 10: Character Walk Animation + Next Wall

**Files:**
- Modify: `web/game.html` — implement `startWalk()` with tween, handle finale

- [ ] **Step 1: Replace `startWalk()` stub with the animated version**

```javascript
function startWalk() {
  scene = SCENE.WALKING;
  walkStart = performance.now();
}
```

- [ ] **Step 2: Add walk update logic in `update()`**

Replace the full `update()` function:

```javascript
function update(dt, ts) {
  // Charge
  if (isHolding && scene === SCENE.PLAYING) {
    chargeLevel = Math.min((performance.now() - chargeStart) / 2000, 1);
  } else if (!isHolding) {
    chargeLevel = Math.max(0, chargeLevel - dt * 3);
  }

  // Wall approach
  if (scene === SCENE.PLAYING && wallDepth > 0) {
    wallDepth = Math.max(0, wallDepth - dt * 0.28);
  }

  // Walk animation: character moves forward (up-screen) over 800ms
  if (scene === SCENE.WALKING) {
    const walkDur = 0.8;
    const t = Math.min((performance.now() - walkStart) / 1000 / walkDur, 1);
    charOffsetY = easeInOut(t) * 40;

    if (t >= 1) {
      charOffsetY = 0;
      currentWall++;
      if (currentWall >= STEMS.length - 1) {
        startFinale();
      } else {
        scene     = SCENE.PLAYING;
        wallDepth = 0.85;
      }
    }
  }

  // Finale pulsing
  if (scene === SCENE.FINALE) {
    // handled in drawFinale()
  }
}

function easeInOut(t) {
  return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
}
```

- [ ] **Step 3: Add `startFinale()` stub (Task 11)**

```javascript
function startFinale() {
  scene       = SCENE.FINALE;
  finaleStart = performance.now();
  console.log('finale!');
}
```

- [ ] **Step 4: Open in browser and verify**

After breaking wall 1 (bass): particles burst, then character glides forward slightly (~40px), then resets and wall 2 (GUITAR BARITONE) approaches from the distance. Repeat through multiple walls. Console logs "finale!" after wall 9 broken.

- [ ] **Step 5: Commit**

```bash
git add web/game.html
git commit -m "feat: character walk animation between walls"
```

---

## Task 11: Stem Dots UI

**Files:**
- Modify: `web/game.html` — add `drawStemDots()`

- [ ] **Step 1: Add `drawStemDots()` function after `drawChargeBar`**

```javascript
function drawStemDots() {
  const total  = STEMS.length;  // 10
  const dotR   = 4;
  const gap    = 14;
  const totalW = total * (dotR * 2) + (total - 1) * (gap - dotR * 2);
  let x = (canvas.width - totalW) / 2;
  const y = 18;

  for (let i = 0; i < total; i++) {
    const on = i < unlockedDots;
    ctx.beginPath();
    ctx.arc(x + dotR, y, dotR, 0, Math.PI * 2);
    if (on) {
      ctx.fillStyle = '#ff30cc';
      ctx.shadowColor = '#ff30cc';
      ctx.shadowBlur  = 8;
    } else {
      ctx.fillStyle = 'rgba(150,0,100,0.25)';
      ctx.shadowBlur  = 0;
    }
    ctx.fill();
    ctx.shadowBlur = 0;

    if (!on) {
      ctx.strokeStyle = 'rgba(200,30,160,0.3)';
      ctx.lineWidth   = 1;
      ctx.stroke();
    }

    x += gap;
  }
}
```

- [ ] **Step 2: Call `drawStemDots()` in `draw()` — add after flash block**

```javascript
drawStemDots();
```

- [ ] **Step 3: Open in browser and verify**

Expected: Row of 10 dots near top of screen. Dot 1 glows pink (guitar_ac active). Each wall break lights up the next dot.

- [ ] **Step 4: Commit**

```bash
git add web/game.html
git commit -m "feat: stem progress dots UI"
```

---

## Task 12: Title Scene

**Files:**
- Modify: `web/game.html` — `drawTitle()`, transition to PLAYING on hold+release

- [ ] **Step 1: Add `drawTitle()` function after `drawStemDots`**

```javascript
function drawTitle() {
  const cx = canvas.width / 2;
  const cy = canvas.height * 0.42;

  // Song title
  ctx.textAlign   = 'center';
  ctx.font        = `300 ${Math.round(canvas.width * 0.06)}px 'Helvetica Neue', Arial, sans-serif`;
  ctx.fillStyle   = 'rgba(255,200,240,0.9)';
  ctx.shadowColor = '#ff60cc';
  ctx.shadowBlur  = 20;
  ctx.fillText('i am thinking of you', cx, cy);

  // Subtitle
  ctx.font      = `400 ${Math.round(canvas.width * 0.035)}px 'Helvetica Neue', Arial, sans-serif`;
  ctx.fillStyle = 'rgba(200,100,180,0.7)';
  ctx.shadowBlur = 8;
  ctx.fillText('150 BPM', cx, cy + canvas.width * 0.08);

  // Prompt — blink
  const blink = 0.4 + 0.4 * Math.sin(performance.now() * 0.003);
  ctx.font      = `400 ${Math.round(canvas.width * 0.032)}px 'Helvetica Neue', Arial, sans-serif`;
  ctx.fillStyle = `rgba(255,80,200,${blink.toFixed(2)})`;
  ctx.shadowBlur = 6;
  ctx.fillText('hold to begin', cx, cy + canvas.width * 0.19);
  ctx.shadowBlur = 0;
}
```

- [ ] **Step 2: Update input handlers to start game from title**

Replace the `pointerdown` handler:

```javascript
canvas.addEventListener('pointerdown', async (e) => {
  e.preventDefault();
  await onFirstInteraction();
  if (scene === SCENE.TITLE) {
    // First hold enters PLAYING
    scene     = SCENE.PLAYING;
    wallDepth = 0.85;
    return;
  }
  if (scene !== SCENE.PLAYING) return;
  isHolding   = true;
  chargeStart = performance.now();
});
```

- [ ] **Step 3: Remove the `scene = SCENE.PLAYING` debug line added in Task 5, set scene back to TITLE**

Find and replace:
```javascript
// Remove this (added in Task 5 for preview):
scene = SCENE.PLAYING;
wallDepth = 0.85;
```
With:
```javascript
scene = SCENE.TITLE;
```

- [ ] **Step 4: Add title draw to `draw()`**

```javascript
if (scene === SCENE.TITLE) {
  drawTunnel();
  drawFloorGrid();
  positionCharacter();
  drawTitle();
  return;
}
```

Add this block at the start of `draw()`, right after `drawBackground()` and `drawStars()`:

```javascript
function draw(ts) {
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  drawBackground();
  drawStars(ts);

  if (scene === SCENE.TITLE) {
    drawTunnel();
    drawFloorGrid();
    positionCharacter();
    drawTitle();
    drawStemDots();
    return;
  }

  drawTunnel();
  drawFloorGrid();

  if (scene === SCENE.PLAYING || scene === SCENE.BREAKING) {
    const label = currentWall < STEMS.length - 1 ? STEMS[currentWall + 1].label : null;
    drawWall(wallDepth, label);
  }

  drawWaves(ts);
  drawCharacterGlow();
  drawChargeBar();
  positionCharacter();
  drawParticles(frameDt);

  if (flashAlpha > 0) {
    ctx.fillStyle = `rgba(255,200,255,${flashAlpha.toFixed(2)})`;
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    flashAlpha = Math.max(0, flashAlpha - 0.04);
  }

  drawStemDots();
}
```

- [ ] **Step 5: Open in browser and verify**

Expected: Title screen shows "i am thinking of you / 150 BPM / hold to begin". Tapping once enters PLAYING with the wall approaching. Audio (guitar ac) plays from the tap.

- [ ] **Step 6: Commit**

```bash
git add web/game.html
git commit -m "feat: title scene with song name and hold-to-begin"
```

---

## Task 13: Finale Scene

**Files:**
- Modify: `web/game.html` — `drawFinale()`, light ring animation

- [ ] **Step 1: Add `drawFinale()` after `drawTitle`**

```javascript
function drawFinale(ts) {
  const cx      = canvas.width / 2;
  const elapsed = (performance.now() - finaleStart) / 1000;

  // Expanding light rings
  for (let i = 0; i < 5; i++) {
    const phase  = (elapsed * 0.7 + i * 0.4) % 3;
    const t      = phase / 3;
    const r      = t * canvas.width * 0.9;
    const alpha  = (1 - t) * 0.3;
    ctx.beginPath();
    ctx.arc(cx, canvas.height * 0.5, r, 0, Math.PI * 2);
    ctx.strokeStyle = `rgba(255,100,220,${alpha.toFixed(2)})`;
    ctx.lineWidth   = 2;
    ctx.shadowColor = '#ff60cc';
    ctx.shadowBlur  = 20;
    ctx.stroke();
    ctx.shadowBlur  = 0;
  }

  // Fade-in text after 1.5s
  const textAlpha = Math.min((elapsed - 1.5) / 1.5, 1);
  if (textAlpha > 0) {
    ctx.textAlign   = 'center';
    ctx.font        = `300 ${Math.round(canvas.width * 0.06)}px 'Helvetica Neue', Arial, sans-serif`;
    ctx.fillStyle   = `rgba(255,200,240,${textAlpha.toFixed(2)})`;
    ctx.shadowColor = '#ff60cc';
    ctx.shadowBlur  = 24;
    ctx.fillText('i am thinking of you', cx, canvas.height * 0.38);

    ctx.font      = `400 ${Math.round(canvas.width * 0.034)}px 'Helvetica Neue', Arial, sans-serif`;
    ctx.fillStyle = `rgba(200,120,180,${textAlpha.toFixed(2)})`;
    ctx.shadowBlur = 10;
    ctx.fillText('thank you', cx, canvas.height * 0.38 + canvas.width * 0.1);
    ctx.shadowBlur = 0;
  }
}
```

- [ ] **Step 2: Add finale to `draw()`**

Add after the flash block and before `drawStemDots()`:

```javascript
if (scene === SCENE.FINALE) {
  drawFinale(ts);
  positionCharacter();
}
```

- [ ] **Step 3: Open in browser, play through all 9 walls, verify finale**

Expected: After breaking wall 9 (VOX 2), character walks forward, scene transitions to FINALE. Expanding pink light rings fill the screen. After 1.5s "i am thinking of you / thank you" fades in. All 10 stems play together.

- [ ] **Step 4: Commit**

```bash
git add web/game.html
git commit -m "feat: finale scene with light rings and full song playback"
```

---

## Task 14: Polish — Beat Sync, Wall Pulse, Mobile Fit

**Files:**
- Modify: `web/game.html` — beat-driven wall pulse, ensure portrait fit on mobile

- [ ] **Step 1: Add beat pulse to wall in `drawWall()` — walls glow brighter on the beat**

Add a `getBeatPulse()` helper after `easeInOut`:

```javascript
function getBeatPulse() {
  if (!audioCtx) return 0;
  const beat   = (audioCtx.currentTime % BEAT_S) / BEAT_S;
  const pulse  = beat < 0.15 ? (1 - beat / 0.15) : 0;
  return pulse;
}
```

Inside `drawWall()`, replace the `ctx.shadowBlur` line:

```javascript
ctx.shadowBlur = 8 + t * 16 + getBeatPulse() * 12;
```

- [ ] **Step 2: Add `viewport-fit=cover` and safe-area padding for iPhone notch**

Replace the `<meta name="viewport">` tag:

```html
<meta name="viewport" content="width=device-width, initial-scale=1, user-scalable=no, viewport-fit=cover">
```

Add to CSS:

```css
canvas#game {
  display: block;
  width: 100%;
  height: 100%;
  touch-action: none;
  padding-top: env(safe-area-inset-top);
  padding-bottom: env(safe-area-inset-bottom);
}
```

- [ ] **Step 3: Open on mobile (or use DevTools device simulation at 390×844)**

Expected: No overflow. Wall glows slightly brighter on every beat at 150BPM. On mobile, no content is hidden behind notch/home indicator.

- [ ] **Step 4: Commit**

```bash
git add web/game.html
git commit -m "feat: beat-synced wall pulse and mobile safe-area support"
```

---

## Task 15: Final Test + Deploy

**Files:**
- Modify: `web/game.html` — remove any debug `console.log` statements
- Verify: full playthrough, audio on iOS Safari

- [ ] **Step 1: Search and remove any leftover console.log debug lines**

```bash
grep -n "console.log" /Users/mike/Downloads/bitbird\(ios\)/.claude/worktrees/cool-williamson-6cf607/web/game.html
```

Remove any found lines from `game.html`.

- [ ] **Step 2: Full playthrough test**

Open `web/game.html` in Chrome. Verify:
- [ ] Title screen shows correctly
- [ ] First tap starts game + audio
- [ ] Wall approaches from distance
- [ ] Hold charges bar; release fires waves
- [ ] Wave hits wall → particles + flash + stem unlocks (check audio layers build)
- [ ] Character walks; next wall appears
- [ ] All 9 walls break; finale triggers
- [ ] All 10 stem dots lit in finale

- [ ] **Step 3: Test on iOS Safari (if device available)**

- Open via local server or Cloudflare tunnel
- Verify audio plays after first tap
- Verify character video visible

- [ ] **Step 4: Final commit**

```bash
cd /Users/mike/Downloads/bitbird\(ios\)/.claude/worktrees/cool-williamson-6cf607
git add web/game.html
git commit -m "feat: complete music wall breaker game - i am thinking of you"
```

- [ ] **Step 5: Push branch**

```bash
git push origin claude/cool-williamson-6cf607
```
