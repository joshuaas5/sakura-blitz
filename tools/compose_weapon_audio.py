"""Deterministic arcade weapon cues; original synthesis, no external samples."""
import math
from pathlib import Path
import random
import struct
import wave

RATE = 22050
ROOT = Path(__file__).resolve().parents[1] / "assets/audio/original"

for name, duration, low, decay in [
    ("brisa_shoot", 0.115, 190, 52),
    ("flora_shoot", 0.38, 82, 19),
]:
    rng = random.Random(name)
    filtered = 0.0
    samples = []
    for i in range(round(duration * RATE)):
        t = i / RATE
        noise = rng.uniform(-1, 1)
        filtered = filtered * 0.73 + noise * 0.27
        attack = min(1, t / 0.001)
        transient = noise * math.exp(-t * 210) * 0.6
        body = math.sin(math.tau * (low * t + 0.9 * (1 - math.exp(-t * 35))))
        signal = transient + (body * 0.42 + filtered * 1.3) * math.exp(-t * decay)
        if name == "flora_shoot":
            signal += filtered * 0.55 * math.exp(-t * 10)
        samples.append(signal * attack * (1 - t / duration))
    peak = max(abs(value) for value in samples)
    pcm = [round(value / peak * 0.78 * 32767) for value in samples]
    with wave.open(str(ROOT / (name + ".wav")), "wb") as output:
        output.setparams((1, 2, RATE, 0, "NONE", "not compressed"))
        output.writeframes(struct.pack("<%dh" % len(pcm), *pcm))
    print(name, len(pcm), "original synthesized samples")
