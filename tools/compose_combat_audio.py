"""Original short footsteps and landing cues, synthesized without external samples."""
import math
from pathlib import Path
import random
import struct
import wave

rate = 22050
root = Path(__file__).resolve().parents[1] / 'assets/audio/original'
for name, duration, frequency in [('step_stone', 0.14, 135), ('step_wood', 0.18, 210), ('land_soft', 0.24, 85), ('step_metal', 0.22, 360)]:
    rng = random.Random(name)
    smooth = 0.0
    values = []
    for i in range(int(duration * rate)):
        t = i / rate
        envelope = min(1, t / 0.004) * math.exp(-t * 32) * (1 - t / duration)
        noise = rng.uniform(-1, 1)
        smooth = smooth * 0.6 + noise * 0.4
        value = (math.sin(math.tau * frequency * t) * 0.35 + smooth * 0.6) * envelope
        if name == 'step_metal':
            value = (smooth * 0.6 + math.sin(math.tau * 360 * t) * 0.25 + math.sin(math.tau * 930 * t) * 0.12) * envelope
        values.append(round(value * 27000))
    with wave.open(str(root / (name + '.wav')), 'wb') as wav:
        wav.setparams((1, 2, rate, 0, 'NONE', 'not compressed'))
        wav.writeframes(struct.pack('<%dh' % len(values), *values))
    print(name, len(values), 'original synthesized samples')
