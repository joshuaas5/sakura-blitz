import os
import math
import struct
import wave
import random

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AUDIO_DIR = os.path.join(BASE_DIR, "assets", "audio")
os.makedirs(AUDIO_DIR, exist_ok=True)

SR = 22050


def save_wav(name: str, samples: list[float]):
    path = os.path.join(AUDIO_DIR, name)
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        frames = bytearray()
        for s in samples:
            v = max(-1.0, min(1.0, s))
            frames.extend(struct.pack("<h", int(v * 31000)))
        w.writeframes(bytes(frames))


def gen_sfx():
    rng = random.Random(77)

    # 1. AK-47 / Commando Rifle Shot - punchy metallic crack + low body thump
    n = int(SR * 0.19)
    s = []
    ph = 0.0
    for i in range(n):
        t = i / SR
        env = math.exp(-t * 24.0)
        freq = 320.0 * math.exp(-t * 28.0) + 75.0
        ph += 2.0 * math.pi * freq / SR
        crack = (rng.random() * 2.0 - 1.0) * math.exp(-t * 32.0) * 0.85
        bolt = math.sin(2.0 * math.pi * 1450.0 * t) * math.exp(-abs(t - 0.045) * 95.0) * 0.35
        val = (math.sin(ph) * 0.65 + crack + bolt) * env
        s.append(math.tanh(val * 2.4))
    save_wav("smg_shoot.wav", s)

    # 2. AWP / L96A1 Sniper Cannon - massive boom + long icy echo + bolt cycle
    n = int(SR * 0.55)
    s = []
    ph = 0.0
    for i in range(n):
        t = i / SR
        env = math.exp(-t * 7.5)
        freq = 190.0 * math.exp(-t * 14.0) + 46.0
        ph += 2.0 * math.pi * freq / SR
        noise = (rng.random() * 2.0 - 1.0) * math.exp(-t * 9.5) * 0.9
        sub = math.sin(2.0 * math.pi * 55.0 * t) * math.exp(-t * 10.0) * 0.8
        # Bolt clack at 0.32s and 0.44s
        clack1 = math.sin(2 * math.pi * 1150 * t) * math.exp(-abs(t - 0.32) * 85.0) * 0.4
        clack2 = math.sin(2 * math.pi * 1480 * t) * math.exp(-abs(t - 0.44) * 85.0) * 0.4
        val = (math.sin(ph) * 0.6 + sub + noise) * env + clack1 + clack2
        s.append(math.tanh(val * 2.5))
    save_wav("shotgun_shoot.wav", s)

    # 3. Desert Eagle .50 - sharp heavy hand-cannon bark
    n = int(SR * 0.26)
    s = []
    ph = 0.0
    for i in range(n):
        t = i / SR
        env = math.exp(-t * 16.0)
        freq = 410.0 * math.exp(-t * 20.0) + 88.0
        ph += 2.0 * math.pi * freq / SR
        noise = (rng.random() * 2.0 - 1.0) * math.exp(-t * 22.0) * 0.75
        ring = math.sin(2.0 * math.pi * 880.0 * t) * math.exp(-t * 26.0) * 0.3
        val = (math.sin(ph) * 0.65 + noise + ring) * env
        s.append(math.tanh(val * 2.3))
    save_wav("rail_shoot.wav", s)

    # 4. Tactical Magazine Reload (mag out -> mag in -> bolt rack)
    n = int(SR * 0.48)
    s = []
    for i in range(n):
        t = i / SR
        c1 = math.exp(-abs(t - 0.06) * 85.0) * math.sin(2 * math.pi * 720 * t)
        c2 = math.exp(-abs(t - 0.22) * 85.0) * math.sin(2 * math.pi * 980 * t)
        c3 = math.exp(-abs(t - 0.38) * 75.0) * math.sin(2 * math.pi * 1350 * t)
        noise = (rng.random() * 2 - 1) * (
            math.exp(-abs(t - 0.06) * 90.0)
            + math.exp(-abs(t - 0.22) * 90.0)
            + math.exp(-abs(t - 0.38) * 90.0)
        ) * 0.45
        s.append(max(-1.0, min(1.0, (c1 + c2 + c3 + noise) * 0.9)))
    save_wav("reload.wav", s)

    # 5. CoD Black Ops Hitmarker "thwip"
    n = int(SR * 0.055)
    s = []
    for i in range(n):
        t = i / SR
        env = math.exp(-t * 65.0)
        val = (
            (rng.random() * 2 - 1) * 0.65
            + math.sin(2 * math.pi * 1850 * t) * 0.45
        ) * env
        s.append(math.tanh(val * 1.8))
    save_wav("hitmarker.wav", s)

    # 6. CS:GO / CoD Fatal Headshot Helmet DINK!
    n = int(SR * 0.24)
    s = []
    for i in range(n):
        t = i / SR
        env = math.exp(-t * 18.0)
        dink1 = math.sin(2 * math.pi * 2480.0 * t) * 0.55
        dink2 = math.sin(2 * math.pi * 3720.0 * t) * 0.35
        crunch = (rng.random() * 2 - 1) * math.exp(-t * 38.0) * 0.5
        s.append(math.tanh((dink1 + dink2 + crunch) * env * 2.0))
    save_wav("headshot.wav", s)

    # 7. Enemy Down / Kill confirm thud
    n = int(SR * 0.22)
    s = []
    for i in range(n):
        t = i / SR
        env = math.exp(-t * 16.0)
        thud = math.sin(2 * math.pi * (180 * math.exp(-t * 18.0) + 52) * t) * 0.7
        noise = (rng.random() * 2 - 1) * math.exp(-t * 28.0) * 0.35
        s.append(math.tanh((thud + noise) * env * 1.8))
    save_wav("enemy_die.wav", s)

    # 8. Jump / Bhop step
    n = int(SR * 0.10)
    s = []
    for i in range(n):
        t = i / SR
        env = math.exp(-t * 28.0)
        noise = (rng.random() * 2 - 1) * 0.45
        thump = math.sin(2 * math.pi * (140 + t * 400) * t) * 0.5
        s.append((noise + thump) * env)
    save_wav("jump.wav", s)

    # 9. Knife Draw / Slash
    n = int(SR * 0.16)
    s = []
    for i in range(n):
        t = i / SR
        env = math.exp(-t * 24.0)
        ring = math.sin(2 * math.pi * (2800 - t * 6000) * t) * 0.45
        whoosh = (rng.random() * 2 - 1) * 0.45
        s.append((ring + whoosh) * env)
    save_wav("double_jump.wav", s)

    # 10. ADS Sight Raise / Crouch subtle cloth tick
    n = int(SR * 0.08)
    s = []
    for i in range(n):
        t = i / SR
        env = math.exp(-t * 42.0)
        val = ((rng.random() * 2 - 1) * 0.35 + math.sin(2 * math.pi * 620 * t) * 0.25) * env
        s.append(val)
    save_wav("dash.wav", s)

    # 11. Boost / Ladder / Surf slide
    n = int(SR * 0.18)
    s = []
    for i in range(n):
        t = i / SR
        env = math.exp(-t * 16.0)
        s.append(math.sin(2 * math.pi * (340 + t * 800) * t) * env * 0.5)
    save_wav("jumppad.wav", s)

    # 12. KZ Checkpoint beep
    n = int(SR * 0.16)
    s = []
    for i in range(n):
        t = i / SR
        f = 880.0 if t < 0.07 else 1318.5
        env = math.exp(-t * 14.0)
        s.append(math.sin(2 * math.pi * f * t) * env * 0.55)
    save_wav("ring_pass.wav", s)

    # 13. KZ / Round Win Fanfare
    n = int(SR * 0.65)
    s = []
    fanfare = [440.0, 554.37, 659.25, 880.0]
    for i in range(n):
        t = i / SR
        idx = min(len(fanfare) - 1, int(t / 0.12))
        f = fanfare[idx]
        env = math.exp(-max(0.0, t - 0.35) * 7.0)
        val = (math.sin(2 * math.pi * f * t) * 0.5 + math.sin(2 * math.pi * f * 1.5 * t) * 0.2) * env
        s.append(val)
    save_wav("course_win.wav", s)

    # 14. Weapon Pickup / Ammo click
    n = int(SR * 0.16)
    s = []
    for i in range(n):
        t = i / SR
        c1 = math.exp(-abs(t - 0.03) * 90.0) * math.sin(2 * math.pi * 920 * t)
        c2 = math.exp(-abs(t - 0.10) * 90.0) * math.sin(2 * math.pi * 1380 * t)
        s.append((c1 + c2) * 0.7)
    save_wav("pickup.wav", s)

    # 15. Player hurt impact
    n = int(SR * 0.16)
    s = []
    ph = 0.0
    for i in range(n):
        t = i / SR
        env = math.exp(-t * 18.0)
        f = 160.0 * math.exp(-t * 10.0) + 50.0
        ph += 2 * math.pi * f / SR
        noise = (rng.random() * 2 - 1) * 0.4
        s.append(math.tanh((math.sin(ph) * 0.7 + noise) * env * 1.8))
    save_wav("hurt.wav", s)

    # 16. Shop Cash / Unlock "Ka-Ching!"
    n = int(SR * 0.34)
    s = []
    for i in range(n):
        t = i / SR
        bell1 = math.sin(2 * math.pi * 1567.98 * t) * math.exp(-t * 18.0) * 0.45
        bell2 = (
            math.sin(2 * math.pi * 2093.00 * max(0.0, t - 0.07))
            * math.exp(-max(0.0, t - 0.07) * 10.0)
            * (0.55 if t >= 0.07 else 0.0)
        )
        shimmer = math.sin(2 * math.pi * 3135.96 * max(0.0, t - 0.07)) * math.exp(-max(0.0, t - 0.07) * 14.0) * (0.28 if t >= 0.07 else 0.0)
        s.append(max(-1.0, min(1.0, bell1 + bell2 + shimmer)))
    save_wav("cash_buy.wav", s)

    # 17. Ranked Up / BO2 Level-Up Stinger
    n = int(SR * 0.75)
    s = []
    chord = [293.66, 369.99, 440.0, 587.33, 880.0]
    for i in range(n):
        t = i / SR
        env = math.exp(-max(0.0, t - 0.25) * 5.5)
        val = 0.0
        for idx, cf in enumerate(chord):
            delay = idx * 0.045
            if t >= delay:
                lt = t - delay
                val += (math.sin(2 * math.pi * cf * lt) * 0.22 + math.sin(2 * math.pi * cf * 2.0 * lt) * 0.09) * math.exp(-lt * 4.5)
        s.append(math.tanh(val * env * 1.8))
    save_wav("rank_up.wav", s)

    # 18. Call of Duty KillCam Slow-Mo Bass Drop + Camera Shutter Whoosh
    n = int(SR * 0.48)
    s = []
    ph = 0.0
    for i in range(n):
        t = i / SR
        # Tape-stop bass drop (260Hz -> 42Hz) + crisp shutter click at t=0.04s
        freq = 240.0 * math.exp(-t * 6.5) + 40.0
        ph += 2 * math.pi * freq / SR
        sub = math.sin(ph) * math.exp(-t * 4.2) * 0.72
        shutter = (rng.random() * 2 - 1) * math.exp(-abs(t - 0.04) * 95.0) * 0.65
        whoosh = (rng.random() * 2 - 1) * math.exp(-abs(t - 0.14) * 18.0) * 0.25
        s.append(math.tanh((sub + shutter + whoosh) * 1.9))
    save_wav("killcam.wav", s)


def gen_panadero_bgm():
    # Garry's Mod Parkour / Deathrun Nostalgia: Cheerful "El Panadero con el Pan" Cumbia-Accordion Radio!
    bpm = 132.0
    beat_sec = 60.0 / bpm
    step_sec = beat_sec / 2.0  # Eighth-note steps
    # Notes in Hz: G4=392, A4=440, B4=493.88, C5=523.25, D5=587.33, E5=659.25, F5=698.46, G5=783.99
    G4, A4, B4, C5, D5, E5, F5, G5 = 392.0, 440.0, 493.88, 523.25, 587.33, 659.25, 698.46, 783.99
    # Iconic cheerful bouncy phrase ("El panadero con el pan, el panadero con el pan...")
    melody = [
        # Bar 1-2: "El pa-na-de-ro con el pan..." (C major)
        G4, G4, G4, E5, E5, D5, C5, 0.0,
        G4, G4, G4, E5, E5, D5, C5, 0.0,
        # Bar 3-4: "El pa-na-de-ro con el pan..." (G7 -> C)
        G4, G4, G4, D5, D5, C5, B4, 0.0,
        G4, A4, B4, D5, C5, B4, C5, 0.0,
        # Bar 5-6: "Tem-pra-ni-to va y lo sa-ca..." (High brass/accordion hook)
        C5, E5, G5, G5, F5, E5, D5, 0.0,
        B4, D5, F5, F5, E5, D5, C5, 0.0,
        # Bar 7-8: "Ca-lien-ti-to en su ca-nas-ta!"
        G4, C5, E5, E5, D5, C5, B4, D5,
        C5, G4, E5, D5, C5, 0.0, C5, 0.0,
    ]
    total_steps = len(melody)
    total_samples = int(total_steps * step_sec * SR)
    samples = [0.0] * total_samples
    rng = random.Random(1975)

    for i in range(total_samples):
        t = i / SR
        step = int(t / step_sec) % total_steps
        local_t = t - (int(t / step_sec) * step_sec)
        bar = (step // 8) % 8

        # Accordion / Marimba Lead
        mf = melody[step]
        lead = 0.0
        if mf > 0.0:
            vib = 1.0 + 0.004 * math.sin(2 * math.pi * 6.5 * t)
            f = mf * vib
            env = math.exp(-local_t * 6.5)
            # Warm accordion harmonics
            lead = (
                math.sin(2 * math.pi * f * t) * 0.22
                + math.sin(2 * math.pi * f * 2.0 * t) * 0.11
                + math.sin(2 * math.pi * f * 3.0 * t) * 0.05
            ) * env

        # Bouncy Cumbia Tuba/Bass (C2=130.81, G2=98.0)
        is_g_chord = bar in (2, 4, 5, 6)
        root_b = 98.0 if is_g_chord else 130.81
        fifth_b = 146.83 if is_g_chord else 196.00
        b_freq = root_b if (step % 2 == 0) else fifth_b
        b_env = math.exp(-local_t * 11.0)
        bass = math.sin(2 * math.pi * b_freq * t) * b_env * 0.24

        # Cumbia Guiro ("ch-ch-ch" on off-beats) + Kick on even steps
        perc = 0.0
        if step % 2 == 0:
            kf = 110.0 * math.exp(-local_t * 28.0) + 48.0
            perc += math.sin(2 * math.pi * kf * local_t) * math.exp(-local_t * 18.0) * 0.20
        else:
            # Cheerful guiro scrape
            perc += (rng.random() * 2 - 1) * math.exp(-local_t * 22.0) * 0.09

        samples[i] = max(-0.92, min(0.92, lead + bass + perc))

    save_wav("bgm_panadero.wav", samples)


def gen_bgm():
    # Subtle, tense Call of Duty Black OpsCold-War / Pentagon synth pulse (low volume so gunshots dominate!)
    bpm = 110.0
    beat_sec = 60.0 / bpm
    step_sec = beat_sec / 4.0
    total_steps = 64
    total_samples = int(total_steps * step_sec * SR)
    samples = [0.0] * total_samples

    bass_notes = [55.0, 55.0, 65.41, 61.74]  # A1 -> A1 -> C2 -> B1 (dark tactical ostinato)
    arp_seq = [220.0, 261.63, 329.63, 293.66, 220.0, 329.63, 293.66, 246.94]

    rng = random.Random(2010)
    for i in range(total_samples):
        t = i / SR
        step = int(t / step_sec) % total_steps
        bar = (step // 16) % 4
        step_in_bar = step % 16
        local_t = t - (int(t / step_sec) * step_sec)

        b_freq = bass_notes[bar]
        b_env = math.exp(-local_t * 16.0)
        bass = math.sin(2 * math.pi * b_freq * t) * b_env * 0.18

        arp_f = arp_seq[step_in_bar % 8]
        arp_env = math.exp(-local_t * 22.0)
        arp = math.sin(2 * math.pi * arp_f * t) * arp_env * 0.06

        drum = 0.0
        if step_in_bar in (0, 6, 12):
            kf = 115.0 * math.exp(-local_t * 30.0) + 42.0
            drum += math.sin(2 * math.pi * kf * local_t) * math.exp(-local_t * 20.0) * 0.22
        if step_in_bar % 2 == 1:
            drum += (rng.random() * 2 - 1) * math.exp(-local_t * 48.0) * 0.035

        samples[i] = max(-0.9, min(0.9, bass + arp + drum))

    save_wav("bgm_sakura.wav", samples)


if __name__ == "__main__":
    gen_sfx()
    gen_bgm()
    gen_panadero_bgm()
    print("Generated CoD Black Ops 2 / CS:GO / GMod Panadero audio successfully!")
