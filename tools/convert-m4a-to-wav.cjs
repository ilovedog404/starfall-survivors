const fs = require("node:fs");
const path = require("node:path");
const { chromium } = require("C:/Users/ilove/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright");

const inputPath = process.argv[2];
const outputPath = process.argv[3];
const targetSampleRate = Number(process.argv[4] || 32000);

if (!inputPath || !outputPath) {
  throw new Error("Usage: node convert-m4a-to-wav.cjs <input.m4a> <output.wav> [sample-rate]");
}

function pcm16Wav(samples, sampleRate) {
  const dataSize = samples.length * 2;
  const wav = Buffer.allocUnsafe(44 + dataSize);
  wav.write("RIFF", 0, "ascii");
  wav.writeUInt32LE(36 + dataSize, 4);
  wav.write("WAVE", 8, "ascii");
  wav.write("fmt ", 12, "ascii");
  wav.writeUInt32LE(16, 16);
  wav.writeUInt16LE(1, 20);
  wav.writeUInt16LE(1, 22);
  wav.writeUInt32LE(sampleRate, 24);
  wav.writeUInt32LE(sampleRate * 2, 28);
  wav.writeUInt16LE(2, 32);
  wav.writeUInt16LE(16, 34);
  wav.write("data", 36, "ascii");
  wav.writeUInt32LE(dataSize, 40);
  for (let index = 0; index < samples.length; index += 1) {
    const sample = Math.max(-1, Math.min(1, samples[index]));
    wav.writeInt16LE(sample < 0 ? Math.round(sample * 32768) : Math.round(sample * 32767), 44 + index * 2);
  }
  return wav;
}

(async () => {
  const browser = await chromium.launch({ channel: "msedge", headless: true });
  try {
    const page = await browser.newPage();
    const sourceBase64 = fs.readFileSync(inputPath).toString("base64");
    const decoded = await page.evaluate(async ({ sourceBase64, targetSampleRate }) => {
      const raw = atob(sourceBase64);
      const bytes = new Uint8Array(raw.length);
      for (let index = 0; index < raw.length; index += 1) bytes[index] = raw.charCodeAt(index);

      const audioContext = new AudioContext();
      const source = await audioContext.decodeAudioData(bytes.buffer);
      const frameCount = Math.ceil(source.duration * targetSampleRate);
      const offline = new OfflineAudioContext(1, frameCount, targetSampleRate);
      const node = offline.createBufferSource();
      node.buffer = source;
      node.connect(offline.destination);
      node.start();
      const rendered = await offline.startRendering();
      const samples = rendered.getChannelData(0);
      const chunkSize = 32768;
      const chunks = [];
      for (let offset = 0; offset < samples.length; offset += chunkSize) {
        chunks.push(Array.from(samples.subarray(offset, Math.min(offset + chunkSize, samples.length))));
      }
      await audioContext.close();
      return { duration: source.duration, chunks };
    }, { sourceBase64, targetSampleRate });

    const samples = new Float32Array(decoded.chunks.reduce((sum, chunk) => sum + chunk.length, 0));
    let offset = 0;
    for (const chunk of decoded.chunks) {
      samples.set(chunk, offset);
      offset += chunk.length;
    }
    fs.mkdirSync(path.dirname(outputPath), { recursive: true });
    fs.writeFileSync(outputPath, pcm16Wav(samples, targetSampleRate));
    console.log(JSON.stringify({
      input: path.resolve(inputPath),
      output: path.resolve(outputPath),
      durationSeconds: Number(decoded.duration.toFixed(3)),
      sampleRate: targetSampleRate,
      outputBytes: fs.statSync(outputPath).size,
    }));
  } finally {
    await browser.close();
  }
})().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
