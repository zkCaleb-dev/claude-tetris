# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Classic Tetris in vanilla JS on an HTML5 canvas. No dependencies, no `package.json`, no bundler, no build step, no tests. Three files: `index.html` (DOM + the two canvases), `style.css` (dark arcade theme), `game.js` (~300 lines, all the logic).

## Running

Open `index.html` directly in a browser, or serve locally:

```bash
python3 -m http.server 8000   # then http://localhost:8000
npx serve .
```

There is nothing to build, lint, or test — reload the page to see changes.

## Architecture

`game.js` is a single top-level script (`'use strict'`, no modules, no classes). Order: constants → DOM handles → mutable globals → pure helpers → game-state mutators → drawing → loop → `init()` → event listeners → `init()` call at the bottom.

**Cell values are color indices.** A board cell and a piece cell hold `0` (empty) or `1–7`. That number indexes `COLORS` *and* `PIECES`, and it is baked into the shape matrices themselves (the T piece's matrix is filled with `3`s). So `merge()` copies the number straight from the shape into the board and nothing else needs to track the piece type. Adding a piece means appending to `COLORS` and `PIECES` at the *same* index and filling its matrix with that index.

**Shapes are square matrices; rotation is transpose-then-reverse** (`rotateCW`). That is why I lives in a 4×4 and T/S/Z/J/L in a 3×3 padded with zeros — the padding is what keeps rotation centered. O is 2×2, so rotating it is a no-op by construction. Keep any new piece's matrix square.

**Wall kicks are not SRS.** `tryRotate()` rotates, then tries horizontal offsets `[0, -1, 1, -2, 2]` in that order and takes the first that doesn't collide; if all collide the rotation is silently dropped. There is no rotation-state tracking and no floor kick.

**`collide(shape, ox, oy)`** is the single gate for every move. It rejects out-of-bounds left/right/bottom and occupied cells, but deliberately allows `ny < 0` so a piece may hang above the board.

**Game state is free-standing `let` globals** (`board, current, next, score, lines, level, paused, gameOver, lastTime, dropAccum, dropInterval, animId`) — not a state object. `init()` is the only reset path and is reused by the restart button.

**Loop** — `requestAnimationFrame` drives `loop(ts)`, which accumulates `dt` into `dropAccum` and drops one row when it passes `dropInterval` (`dropAccum` is reset to `0`, not decremented by the interval). Speed is `max(100, 1000 - (level - 1) * 90)` ms, recomputed only inside `clearLines()`.

**Scoring / HUD** — `LINE_SCORES[cleared] * level`, plus 2/cell for hard drop and 1/row for soft drop. `updateHUD()` is called from `clearLines()`, `softDrop()`, and unconditionally at the end of the `keydown` handler — that last call is what makes hard-drop points appear, since `hardDrop()` never calls it itself.

**Line clearing** — `clearLines()` walks bottom-up, `splice`s the full row out, `unshift`s an empty one, then does `r++` to re-test the same index. Preserve that compensating increment if you touch the loop.

**Drawing** — `drawBlock()` is shared by both canvases; it takes an explicit `size` and optional `alpha`, and always restores `globalAlpha` to `1`. `draw()` paints grid → locked board → ghost (`alpha 0.2`, position from `ghostY()`) → current piece. `drawNext()` centers the next shape inside a virtual 4×4 at 30 px per cell, which is why `#next-canvas` is 120×120.

## Gotchas

- **Canvas dimensions are hardcoded in `index.html`.** `#board` is `300×600`; it must stay `COLS * BLOCK` × `ROWS * BLOCK`. Changing `COLS`/`ROWS`/`BLOCK` in `game.js` without editing the HTML silently breaks rendering.
- **The loop stops on game over via two guards.** `endGame()` calls `cancelAnimationFrame(animId)` (this covers the input-driven paths: hard/soft drop reaching `lockPiece()` from the `keydown` handler), and `loop()` bails with `if (gameOver) return;` *before* scheduling the next frame (this covers gravity reaching `lockPiece()` from inside `loop()`, where the cancel alone did nothing because the frame it cancelled was already running). Keep both — removing either lets pieces keep falling behind the overlay.
- **One overlay serves both PAUSE and GAME OVER**, swapping `#overlay-title` / `#overlay-score` text. The restart button is always visible, including while paused.
- **Piece selection is a uniform `Math.random()`**, not a 7-bag, so long droughts happen by design.

## Conventions

- In-game prose and the README are in Spanish (`Reiniciar`, `Puntuación`, `mover`, `pausa`); the HUD labels are uppercase English (`SCORE`, `LINES`, `LEVEL`, `NEXT`). Code identifiers and the few code comments are English. Match that split.
- Tuning constants are `const`s at the top of `game.js` (`COLS`, `ROWS`, `BLOCK`, `COLORS`, `PIECES`, `LINE_SCORES`); `dropInterval` is a mutable global because level progression rewrites it.
- Colors are inline hex in `game.js` for pieces and in `style.css` for chrome — there is no shared token file, so a palette change touches both.
