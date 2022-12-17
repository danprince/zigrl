let seed = Date.now();
let maxCanvasScale = 8;
let fontGlyphWidth = 6;
let fontGlyphHeight = 6;
let fontImage = await loadImage("font.png");
let terminalWidth = 0;
let terminalHeight = 0;
let canvas = document.createElement("canvas");
let ctx = canvas.getContext("2d");

let { instance } = await WebAssembly.instantiateStreaming(
  fetch("dist/zigrl.wasm"),
  {
    env: {
      print,
      printError,
      initTerm,
      flushTerm,
    }
  }
);

/**
 * @type {{
 *  memory: WebAssembly.Memory;
 *  onInit(seed: number): number;
 *  onFrame(dt: number): void;
 *  onKeyDown(key: number): void;
 *  onPointerMove(x: number, y: number): void;
 *  onPointerDown(x: number, y: number): void;
 * }}
 */
let exports = instance.exports;

/**
 * @param {number} pointer
 * @param {number} size
 * @param {number} level
 */
function print(pointer, size, level) {
  let buffer = new Uint8Array(exports.memory.buffer, pointer, size);
  let decoder = new TextDecoder();
  let string = decoder.decode(buffer);
  if (level === 0) console.info(string);
  if (level === 1) console.log(string);
  if (level === 2) console.warn(string);
  if (level === 3) console.error(string);
}

/**
 * @param {number} pointer
 * @param {number} size
 */
function printError(pointer, size) {
  let buffer = new Uint8Array(exports.memory.buffer, pointer, size);
  let decoder = new TextDecoder();
  let string = decoder.decode(buffer);
  console.error(string);
}

/**
 * Initialize the rendering terminal.
 * @param {number} width Width of the terminal in columns
 * @param {number} height Height of the terminal in rows.
 */
function initTerm(width, height) {
  terminalWidth = width;
  terminalHeight = height;
  canvas.width = fontGlyphWidth * width;
  canvas.height = fontGlyphHeight * height;
  canvas.style.imageRendering = "pixelated";
  ctx.imageSmoothingEnabled = false;
  scaleTerminalToFitScreen();
}

/**
 * Flush the data from the shared buffer to the renderer's canvas.
 * @param {number} bufferPointer The memory offset of the terminal buffer.
 * @param {number} bufferSize The length of the terminal buffer.
 */
function flushTerm(bufferPointer, bufferSize) {
  let bufferStep = 3;
  let fontCols = fontImage.width / fontGlyphWidth;

  // It's important that this buffer is recreated after during each render
  // because allocations in Zig have the potential to request more pages of
  // WebAssembly memory, which invalidates the ArrayBuffer in memory.
  let buffer = new Int32Array(
    exports.memory.buffer,
    bufferPointer,
    bufferSize,
  );

  ctx.clearRect(0, 0, canvas.width, canvas.height);

  for (let y = 0; y < terminalHeight; y++) {
    for (let x = 0; x < terminalWidth; x++) {
      let i = (x + y * terminalWidth) * bufferStep;
      let ch = buffer[i + 0];
      let fg = buffer[i + 1];
      let bg = buffer[i + 2];

      let w = fontGlyphWidth;
      let h = fontGlyphHeight;
      let dx = x * w;
      let dy = y * h;

      if (bg > 0) {
        ctx.fillStyle = intToRgb(bg);
        ctx.fillRect(dx, dy, w, h);
      }

      // Don't draw whitespace chars
      if (ch > 0 && ch !== 32) {
        let color = intToRgb(fg);
        let col = ch % fontCols | 0;
        let row = ch / fontCols | 0;
        let sx = col * w;
        let sy = row * h;
        let img = tint(color);
        ctx.drawImage(img, sx, sy, w, h, dx, dy, w, h);
      }
    }
  }
}

/**
 * A cache of recolored font images.
 * @type {Record<string, HTMLCanvasElement>}
 */
 let tintCanvasCache = {};

 /**
  * Creates a recolored version of the current font's image.
  * @param {string} color
  * @return {HTMLCanvasElement}
  */
function tint(color) {
  let canvas = tintCanvasCache[color];

  if (!canvas) {
    canvas = document.createElement("canvas");
    let ctx = canvas.getContext("2d");
    let img = fontImage;
    canvas.width = img.width;
    canvas.height = img.height;

    ctx.globalCompositeOperation = "multiply";
    ctx.fillStyle = color;
    ctx.fillRect(0, 0, img.width, img.height);
    ctx.drawImage(img, 0, 0);
    ctx.globalCompositeOperation = "destination-atop";
    ctx.drawImage(img, 0, 0);

    tintCanvasCache[color] = canvas;
  }

  return canvas;
}

/**
 * Resize the terminal renderer to fill the available screenspace whilst still
 * maintaining its aspect ratio and not exceeding `maxCanvasScale` in either
 * dimension.
 */
function scaleTerminalToFitScreen() {
  console.log(canvas.width, canvas.height)
  let scaleX = window.innerWidth / canvas.width;
  let scaleY = window.innerHeight / canvas.height;
  let scale = Math.min(scaleX, scaleY, maxCanvasScale);
  canvas.style.width = `${canvas.width * scale}px`;
  canvas.style.height = `${canvas.height * scale}px`;
}

/**
 * 
 */
function startRenderingLoop() {
  let previousFrameTime = performance.now();

  /**
   * @param {number} time
   */
  function next(time) {
    requestAnimationFrame(next);
    let delta = time - previousFrameTime;
    previousFrameTime = time;
    exports.onFrame(delta);
  }

  requestAnimationFrame(next);
}

/**
 * @param {number} hex Hex value in BGR format.
 * @returns {string} CSS color string.
 */
function intToRgb(hex) {
  let r = hex >> 16 & 0xFF;
  let g = hex >> 8 & 0xFF;
  let b = hex >> 0 & 0xFF;
  return `rgb(${r}, ${g}, ${b})`;
}

/**
 * @param {string} src
 * @returns {Promise<HTMLImageElement>}
 */
function loadImage(src) {
  return new Promise((resolve, reject) => {
    let image = new Image();
    image.src = src;
    image.onload = () => resolve(image);
    image.onreject = err => reject(err);
  });
}

/**
 * Convert a screen coordinate to a terminal grid coordinate.
 * @param {number} screenX
 * @param {number} screenY
 * @return {{ x: number, y: number }}
 */
export function screenToGrid(screenX, screenY) {
  let rect = canvas.getBoundingClientRect();
  let localX = (screenX - rect.x) / (rect.width / canvas.width);
  let localY = (screenY - rect.y) / (rect.height / canvas.height);
  let gridX = Math.floor(localX / fontGlyphWidth);
  let gridY = Math.floor(localY / fontGlyphHeight);
  return { x: gridX, y: gridY };
}

/**
 * @param {KeyboardEvent} event
 */
function handleKeyDown(event) {
  let mod = 0;
  if (event.shiftKey) mod |= 1;
  if (event.altKey) mod |= 2;
  if (event.ctrlKey) mod |= 4;
  exports.onKeyDown(event.which, mod);
}

/**
 * @param {PointerEvent} event
 */
function handlePointerMove(event) {
  let { x, y } = screenToGrid(event.clientX, event.clientY);
  exports.onPointerMove(x, y);
}

/**
 * @param {PointerEvent} event
 */
function handlePointerDown(event) {
  let { x, y } = screenToGrid(event.clientX, event.clientY);
  exports.onPointerDown(x, y);
}

addEventListener("resize", scaleTerminalToFitScreen);
addEventListener("keydown", handleKeyDown);
addEventListener("pointermove", handlePointerMove);
addEventListener("pointerdown", handlePointerDown);

startRenderingLoop();
exports.onInit(seed);
document.body.append(canvas);

export {};
