"""Original deterministic ambience; no external recordings or samples."""
from pathlib import Path
import math
import random
import struct
import wave

OUT = Path(__file__).resolve().parents[1] / 'assets/audio/original'
RATE = 22050
SECONDS = 8
for name, seed in [('courtyard_water', 202613), ('garden_breeze', 202614)]:
    rng = random.Random(seed)
    slow = 0.0
    smooth = 0.0
    samples = []
    for i in range(RATE * SECONDS):
        t = i / RATE
        noise = rng.uniform(-1, 1)
        smooth = smooth * 0.84 + noise * 0.16
        slow = slow * 0.996 + noise * 0.004
        if name == 'courtyard_water':
            amplitude = 0.72 + 0.13 * math.sin(math.tau * t / 8) + 0.1 * math.sin(math.tau * t * 3 / 8)
            value = (smooth * 0.8 + noise * 0.08 + slow * 1.3) * amplitude
        else:
            value = slow * (2.8 + 1.2 * math.sin(math.tau * t / 8)) + smooth * 0.035
        samples.append(value)
    # Crossfade the seam while preserving a full constant-rate loop.
    seam = RATE // 8
    for i in range(seam):
        blend = i / seam
        samples[i] = samples[-seam + i] * (1 - blend) + samples[i] * blend
    with wave.open(str(OUT / (name + '.wav')), 'wb') as wav:
        wav.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        wav.writeframes(b''.join(struct.pack('<h', round(max(-1, min(1, v)) * 24000)) for v in samples))
    print(name, len(samples), 'original synthesized samples')
