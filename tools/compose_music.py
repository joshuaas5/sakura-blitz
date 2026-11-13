"""Rebuild Sakura Blitz's original synthesized loops. Requires Python + numpy.

No samples, recordings, MIDI songs, or third-party melodies are used.
All note patterns below were written for this project.
"""
from pathlib import Path
import wave
import numpy as np

RATE = 22050
OUT = Path(__file__).resolve().parents[1] / "assets" / "audio" / "original"
OUT.mkdir(parents=True, exist_ok=True)


def frequency(midi):
    return 440 * 2 ** ((midi - 69) / 12)


def render(name, bpm, roots, melody, energy, seed):
    rng = np.random.default_rng(seed)
    beat = 60 / bpm
    seconds = beat * 64
    mix = np.zeros(round(seconds * RATE), dtype=np.float64)

    def add(sound, at, gain=1):
        # Wrap instrument tails into the beginning for a seamless musical loop.
        start = round(at * RATE)
        indices = (np.arange(len(sound)) + start) % len(mix)
        np.add.at(mix, indices, sound * gain)

    def note(midi, duration, flavor="bell"):
        t = np.arange(round(duration * RATE)) / RATE
        phase = 2 * np.pi * frequency(midi) * t
        attack = np.minimum(t / 0.012, 1)
        release = np.minimum((duration - t) / 0.09, 1)
        if flavor == "pad":
            shape = np.sin(phase) + 0.20 * np.sin(phase * 2) + 0.10 * np.sin(phase * 0.998)
            envelope = np.minimum(t / 0.28, 1) * np.minimum((duration - t) / 0.6, 1)
        elif flavor == "bass":
            shape = np.sin(phase) + 0.22 * np.sin(phase * 2)
            envelope = attack * np.exp(-t * 3.4) * release
        else:
            shape = np.sin(phase) + 0.28 * np.sin(phase * 2) + 0.12 * np.sin(phase * 3)
            envelope = attack * np.exp(-t * 4.4) * release
        return shape * envelope

    for bar in range(16):
        root = roots[bar % len(roots)]
        at = bar * beat * 4
        # Warm major-seventh voicings; later bars invert the upper notes.
        for step in [0, 7, 12, 16, 23]:
            add(note(root + step, beat * 4.4, "pad"), at, 0.035)
        for tick in range(8):
            if energy < 0.5 and tick % 2:
                continue
            degree = melody[(bar * 3 + tick) % len(melody)]
            pitch = root + 24 + degree + (12 if bar % 8 == 7 and tick == 6 else 0)
            tone = note(pitch, beat * 1.5)
            add(tone, at + tick * beat / 2, 0.10)
            add(tone, at + tick * beat / 2 + beat * 0.75, 0.025)
        for tick in [0, 1.5, 2.5, 3.5]:
            add(note(root - 12, beat * 0.8, "bass"), at + tick * beat, 0.16)
        for tick in range(4):
            t = np.arange(round(0.25 * RATE)) / RATE
            kick = np.sin(2 * np.pi * (48 * t + 65 * 0.035 * (1 - np.exp(-t / 0.035))))
            kick *= np.exp(-t * 22) * np.minimum(t / 0.004, 1)
            add(kick, at + tick * beat, 0.14 * energy)
            if tick % 2:
                t = np.arange(round(0.16 * RATE)) / RATE
                noise = rng.normal(0, 1, len(t))
                clap = (noise - np.roll(noise, 1)) * np.exp(-t * 35) * np.minimum(t / 0.002, 1)
                add(clap, at + tick * beat, 0.032 * energy)
        for tick in range(8):
            t = np.arange(round(0.07 * RATE)) / RATE
            noise = rng.normal(0, 1, len(t))
            hat = (noise - np.roll(noise, 1)) * np.exp(-t * 80) * np.minimum(t / 0.002, 1)
            add(hat, at + (tick + 0.5) * beat / 2, 0.012 * energy)

    mix -= mix.mean()
    mix = np.tanh(mix * 1.2)
    mix *= 0.72 / max(np.max(np.abs(mix)), 0.001)
    pcm = (mix * 32767).astype("<i2")
    with wave.open(str(OUT / (name + ".wav")), "wb") as stream:
        stream.setnchannels(1)
        stream.setsampwidth(2)
        stream.setframerate(RATE)
        stream.writeframes(pcm.tobytes())
    print(f"{name}: {seconds:.2f}s, peak {np.max(np.abs(mix)):.2f}, {len(pcm)*2/1048576:.2f} MiB")


if __name__ == "__main__":
    render("bloom_lobby", 82, [48, 53, 45, 55], [0, 7, 4, 11, 7, 2, 9, 4, 12, 7, 2, 4], 0.25, 1101)
    render("petal_dash", 124, [50, 57, 55, 52], [7, 0, 4, 12, 9, 7, 2, 11, 4, 7, 12, 2], 0.85, 1102)
    render("neon_skirmish", 112, [45, 52, 48, 55], [0, 7, 12, 4, 2, 9, 7, 4, 11, 2, 7, 12], 0.75, 1103)
