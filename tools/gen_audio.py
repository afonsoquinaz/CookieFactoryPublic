#!/usr/bin/env python3
"""Synthesises every sound effect and the music/ambience loops of Token Empire.

Everything is generated from code (oscillators, noise, Karplus-Strong plucks,
formant filters and a small convolution reverb) so the game ships with no
third-party audio. Output is deterministic: every sound reseeds its own RNG
from its name, so tweaking one sound never changes another.

    python3 tools/gen_audio.py                 # writes assets/audio/*.wav|*.ogg
    python3 tools/gen_audio.py sfx_pop music   # only the named generators

Needs numpy + scipy; ffmpeg (libvorbis) encodes the loops to Ogg Vorbis.
"""
import functools
import os
import subprocess
import sys
import wave
import zlib

import numpy as np
from scipy import signal

SR = 44100
OUT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "audio"))
SFX_PEAK_DB = -3.0
rng = np.random.default_rng(0)


def seeded(fn):
    """Reseed the module RNG from the generator's name + args (stable, per sound)."""
    @functools.wraps(fn)
    def wrapper(*args):
        global rng
        key = fn.__name__ + "/" + "/".join(str(a) for a in args)
        rng = np.random.default_rng(zlib.crc32(key.encode()))
        return fn(*args)
    return wrapper


# --------------------------------------------------------------------------- utils
def t_axis(dur):
    return np.arange(int(dur * SR)) / SR


def noise(dur):
    return rng.uniform(-1, 1, int(dur * SR))


def pink(dur):
    n = int(dur * SR)
    w = rng.standard_normal(n)
    b = [0.049922035, -0.095993537, 0.050612699, -0.004408786]
    a = [1, -2.494956002, 2.017265875, -0.522189400]
    p = signal.lfilter(b, a, w)
    return p / (np.max(np.abs(p)) + 1e-9)


def brown(dur):
    w = rng.standard_normal(int(dur * SR))
    b = np.cumsum(w)
    b = signal.lfilter([1, -1], [1, -0.995], b)  # leaky: no DC drift
    return b / (np.max(np.abs(b)) + 1e-9)


def lp(x, f, order=2):
    sos = signal.butter(order, min(f, SR * 0.45), "low", fs=SR, output="sos")
    return signal.sosfilt(sos, x)


def hp(x, f, order=2):
    sos = signal.butter(order, f, "high", fs=SR, output="sos")
    return signal.sosfilt(sos, x)


def bp(x, lo, hi, order=2):
    sos = signal.butter(order, [lo, min(hi, SR * 0.45)], "band", fs=SR, output="sos")
    return signal.sosfilt(sos, x)


def svf_lp(x, cutoff, q=0.7):
    """Time-varying state-variable low-pass; cutoff is an array (Hz)."""
    y = np.zeros_like(x)
    low = band = 0.0
    damp = 1.0 / q
    f = 2.0 * np.sin(np.pi * np.clip(cutoff, 20, SR / 6) / SR)
    for i in range(len(x)):
        high = x[i] - low - damp * band
        band += f[i] * high
        low += f[i] * band
        y[i] = low
    return y


def formants(x, spec):
    """Parallel resonators: spec = [(freq, Q, gain), ...] -> vowel colour."""
    out = np.zeros_like(x)
    for f, q, g in spec:
        b, a = signal.iirpeak(f, q, fs=SR)
        out += g * signal.lfilter(b, a, x)
    return out


def env_exp(dur, decay, attack=0.002):
    t = t_axis(dur)
    e = np.exp(-t / decay)
    a = np.clip(t / max(attack, 1e-4), 0, 1)
    return e * a


def fade(x, fin=0.002, fout=0.01):
    n_in, n_out = min(int(fin * SR), len(x)), min(int(fout * SR), len(x))
    if n_in:
        x[:n_in] *= np.linspace(0, 1, n_in) ** 2
    if n_out:
        x[-n_out:] *= np.linspace(1, 0, n_out) ** 2
    return x


def sine_sweep(dur, f0, f1, curve="exp"):
    t = t_axis(dur)
    if curve == "exp":
        f = f0 * (f1 / f0) ** (t / dur)
    else:
        f = f0 + (f1 - f0) * (t / dur)
    return np.sin(2 * np.pi * np.cumsum(f) / SR)


def osc(freq):
    """Sine from a per-sample frequency array."""
    return np.sin(2 * np.pi * np.cumsum(freq) / SR)


def saw(freq, nh=24):
    """Band-limited-ish additive sawtooth from a per-sample frequency array."""
    ph = 2 * np.pi * np.cumsum(freq) / SR
    fmax = np.max(freq)
    out = np.zeros_like(ph)
    for k in range(1, nh + 1):
        if k * fmax > SR * 0.45:
            break
        out += np.sin(k * ph) / k
    return out


def square(freq, nh=15):
    ph = 2 * np.pi * np.cumsum(freq) / SR
    fmax = np.max(freq)
    out = np.zeros_like(ph)
    for k in range(1, 2 * nh, 2):
        if k * fmax > SR * 0.45:
            break
        out += np.sin(k * ph) / k
    return out


def pad(x, dur):
    n = int(dur * SR)
    if len(x) >= n:
        return x[:n]
    return np.concatenate([x, np.zeros(n - len(x))])


def mix(*parts):
    n = max(len(p) for p in parts)
    out = np.zeros(n)
    for p in parts:
        out[: len(p)] += p
    return out


def place(buf, x, at):
    i = int(round(at * SR))
    if i >= len(buf) or i < 0:
        return
    j = min(len(buf), i + len(x))
    buf[i:j] += x[: j - i]


def place_wrap(buf, x, at):
    """Place with wrap-around so events crossing the end continue at the start."""
    n = len(buf)
    i = int(round(at * SR)) % n
    k = 0
    while k < len(x):
        j = min(n - i, len(x) - k)
        buf[i:i + j] += x[k:k + j]
        k += j
        i = 0


_ir_cache = {}


def reverb(x, wet=0.25, size=1.2, damp=5000, pre=0.012):
    key = (size, damp)
    if key not in _ir_cache:
        r = np.random.default_rng(int(size * 1000) + damp)  # IR independent of call order
        n = int(size * SR)
        t = np.arange(n) / SR
        ir = r.standard_normal(n) * np.exp(-t / (size / 5.5))
        ir = lp(ir, damp)
        ir[: int(pre * SR)] = 0
        ir /= np.sqrt(np.sum(ir**2)) + 1e-9
        _ir_cache[key] = ir
    ir = _ir_cache[key]
    tail = signal.fftconvolve(x, ir)
    dry = np.concatenate([x, np.zeros(len(tail) - len(x))])
    return dry * (1 - wet * 0.5) + tail * wet


def norm(x, peak_db=-1.0):
    peak = np.max(np.abs(x)) + 1e-9
    return x / peak * 10 ** (peak_db / 20)


def soft_clip(x, drive=1.0):
    return np.tanh(x * drive) / np.tanh(drive)


def trim_tail(x, thresh_db=-50):
    """Cut once the signal stays below thresh (relative to its peak)."""
    thresh = np.max(np.abs(x)) * 10 ** (thresh_db / 20)
    idx = np.where(np.abs(x) > thresh)[0]
    if len(idx) == 0:
        return x
    return x[: min(len(x), idx[-1] + int(0.005 * SR))]


def fold_loop(buf, n):
    """Wrap everything past the loop length back onto the start (reverb tails)."""
    out = buf[:n].copy()
    rest = buf[n:]
    while len(rest):
        k = min(n, len(rest))
        out[:k] += rest[:k]
        rest = rest[k:]
    return out


def circ_filter(fn, x):
    """Apply a causal filter to a loop as if it repeated forever (no seam transient)."""
    n = len(x)
    return fn(np.concatenate([x, x, x]))[n:2 * n]


def loop_xfade(x, n, xf):
    """x has n + xf samples: blend the overhang into the head for a seamless loop."""
    out = x[:n].copy()
    ramp = np.sin(np.linspace(0, np.pi / 2, xf)) ** 2
    out[:xf] = x[:xf] * ramp + x[n:n + xf] * (1 - ramp)
    return out


def write_wav(name, x, peak_db=SFX_PEAK_DB, trim=True, fin=0.001, fout=0.012, length=None):
    """Mono 16-bit wav. length (s) caps the tail; fout is then the tail fade."""
    path = os.path.join(OUT, name + ".wav")
    x = np.asarray(x, dtype=np.float64)
    x = hp(x, 25, 1)
    if trim:
        x = trim_tail(x, -50)
    if length is not None:
        x = x[: int(length * SR)]
    x = fade(norm(x, peak_db).copy(), fin, fout)
    x = norm(x, peak_db)  # fades can only lower the peak; re-pin to the target
    data = (np.clip(x, -1, 1) * 32767).astype(np.int16)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())
    return path


def write_ogg(name, x, peak_db=-8.0, quality=4):
    """x: mono array or (n, 2) stereo; loops are written exactly as given."""
    tmp = os.path.join(OUT, name + ".tmp.wav")
    x = x / (np.max(np.abs(x)) + 1e-9) * 10 ** (peak_db / 20)
    ch = 1 if x.ndim == 1 else 2
    data = (np.clip(x, -1, 1) * 32767).astype(np.int16)
    with wave.open(tmp, "wb") as w:
        w.setnchannels(ch)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())
    out = os.path.join(OUT, name + ".ogg")
    try:
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp, "-c:a", "libvorbis",
                        "-q:a", str(quality), "-map_metadata", "-1",
                        "-fflags", "+bitexact", "-flags:a", "+bitexact", out], check=True)
    finally:
        os.remove(tmp)
    return out


# --------------------------------------------------------------------------- instruments
def midi_hz(m):
    return 440.0 * 2 ** ((m - 69) / 12)


def marimba(freq, dur=0.9, vel=1.0, bright=1.0):
    t = t_axis(dur)
    x = (np.sin(2 * np.pi * freq * t) * np.exp(-t / 0.42)
         + 0.32 * bright * np.sin(2 * np.pi * freq * 3.93 * t) * np.exp(-t / 0.07)
         + 0.10 * bright * np.sin(2 * np.pi * freq * 9.2 * t) * np.exp(-t / 0.02))
    click = lp(noise(0.006), 3000) * 0.15
    x[: len(click)] += click
    return fade(x * vel, 0.001, 0.05)


def bell(freq, dur=1.2, vel=1.0):
    t = t_axis(dur)
    parts = [(1.0, 1.0, 0.9), (2.76, 0.5, 0.35), (5.40, 0.25, 0.18), (8.93, 0.12, 0.09)]
    x = sum(a * np.sin(2 * np.pi * freq * r * t) * np.exp(-t / d)
            for r, a, d in parts if freq * r < SR * 0.45)
    return fade(x * vel, 0.001, 0.05)


def glock(freq, dur=0.8, vel=1.0):
    """Glockenspiel: pure, bright, mostly fundamental + one high partial."""
    t = t_axis(dur)
    x = (np.sin(2 * np.pi * freq * t) * np.exp(-t / 0.5)
         + 0.25 * np.sin(2 * np.pi * freq * 2.76 * t) * np.exp(-t / 0.08)
         + 0.08 * np.sin(2 * np.pi * freq * 5.4 * t) * np.exp(-t / 0.03))
    return fade(x * vel, 0.0008, 0.05)


def pluck(freq, dur=1.2, vel=1.0, bright=0.5, damp=0.996):
    """Karplus-Strong pluck, computed one period per numpy step."""
    n = int(dur * SR)
    p = max(2, int(round(SR / freq - 0.5)))
    y = np.zeros(n + p)
    exc = lp(rng.uniform(-1, 1, p), 1500 + 5000 * bright)
    y[:p] = exc - exc.mean()
    i = p
    while i < n + p:
        k = min(p, n + p - i)
        a = y[i - p:i - p + k]
        b = np.concatenate([[0.0], y[i - p:i - p + k - 1]]) if i == p else y[i - p - 1:i - p - 1 + k]
        y[i:i + k] = damp * 0.5 * (a + b)
        i += k
    out = hp(y[p:], 80)
    return fade(out / (np.max(np.abs(out)) + 1e-9) * vel, 0.0005, 0.03)


def pizz(freq, dur=0.32, vel=1.0):
    """Pizzicato string: short damped KS pluck with a soft body thump."""
    x = pluck(freq, dur, 1.0, 0.35, 0.985)
    x = lp(x, 3200)
    x *= env_exp(dur, 0.11, 0.001)
    return fade(x / (np.max(np.abs(x)) + 1e-9) * vel, 0.0005, 0.03)


def soft_bass(freq, dur=0.6, vel=1.0):
    t = t_axis(dur)
    x = np.sin(2 * np.pi * freq * t) + 0.25 * np.sin(4 * np.pi * freq * t) * np.exp(-t / 0.08)
    e = np.exp(-t / 0.35) * np.clip(t / 0.008, 0, 1)
    return fade(x * e * vel, 0.001, 0.04)


def toy_brass(freq, dur=0.5, vel=1.0):
    """Cute toy-trumpet lead: saw through an opening low-pass, gentle vibrato."""
    t = t_axis(dur)
    vib = 1 + 0.008 * np.sin(2 * np.pi * 5.5 * t) * np.clip((t - 0.08) / 0.15, 0, 1)
    f = freq * vib * (1 - 0.03 * np.exp(-t / 0.025))
    x = saw(f, 16)
    x = lp(x, freq * 4.5, 2) * 0.7 + lp(x, freq * 2, 2) * 0.5
    amp = np.clip(t / 0.015, 0, 1) * (0.75 + 0.25 * np.exp(-t / 0.08))
    return fade(x * amp * vel, 0.001, 0.06)


def epiano(freq, dur=1.0, vel=1.0):
    """Soft FM electric piano: a sine carrier, a decaying 2:1 modulator, a tine."""
    t = t_axis(dur)
    mod = np.sin(2 * np.pi * freq * 2 * t) * 1.8 * np.exp(-t / 0.22)
    x = np.sin(2 * np.pi * freq * t + mod) * np.exp(-t / 0.7)
    x += 0.12 * np.sin(2 * np.pi * freq * 4.0 * t) * np.exp(-t / 0.09)
    return fade(x * vel * 0.8, 0.002, 0.08)


def synth_pluck(freq, dur=0.35, vel=1.0):
    """A soft analog pluck: a saw through a closing low-pass."""
    t = t_axis(dur)
    x = saw(np.full(len(t), freq), 14)
    x = lp(x, freq * 6, 2) * np.exp(-t / 0.05) + lp(x, freq * 2.2, 2) * np.exp(-t / 0.16)
    return fade(x * np.clip(t / 0.003, 0, 1) * vel * 0.6, 0.001, 0.04)


def synth_pad(freqs, dur, vel=1.0):
    """A warm pad: detuned saws per note, low-passed, slow attack and release."""
    t = t_axis(dur)
    x = np.zeros(len(t))
    for f in freqs:
        for det in (0.997, 1.004):
            x += saw(np.full(len(t), f * det), 8)
    x = lp(x, 900, 2)
    env = np.clip(t / 0.6, 0, 1) * np.clip((dur - t) / 0.8, 0, 1)
    return x * env * vel / max(1, len(freqs))


def shaker(vel=1.0, dur=0.08):
    x = hp(noise(dur), 6000) * env_exp(dur, 0.022, 0.006)
    return x * vel


def kick(vel=1.0):
    d = 0.25
    x = sine_sweep(d, 110, 48) * env_exp(d, 0.09, 0.002)
    return x * vel


def clap(vel=1.0):
    d = 0.22
    x = np.zeros(int(d * SR))
    for k, off in enumerate([0, 0.008, 0.017, 0.025]):
        b = bp(noise(0.2), 900, 3200) * env_exp(0.2, 0.011 if k < 3 else 0.06)
        place(x, b * (0.7 if k < 3 else 1.0), off)
    return lp(x, 5000) * vel


# --------------------------------------------------------------------------- sfx
@seeded
def sfx_pop(i):
    """Soft bubbly pick-up pop: a rising 'bloop' (Minnaert bubble) + tiny body."""
    d = 0.11
    f0 = [520, 590, 665][i]
    t = t_axis(d)
    f = f0 * (1 + 1.1 * (1 - np.exp(-t / 0.018)))
    x = osc(f) * env_exp(d, 0.028, 0.003)
    x += 0.22 * osc(f * 2) * env_exp(d, 0.014, 0.003)
    body = np.sin(2 * np.pi * f0 * 0.5 * t) * env_exp(d, 0.012, 0.002) * 0.35
    tick = lp(noise(0.004), 4000) * 0.08
    x = mix(x + body, tick)
    return write_wav("pop_%d" % (i + 1), lp(x, 6000), fout=0.02)


@seeded
def sfx_drop(i):
    """Woody/plasticky 'tok' into a hopper."""
    d = 0.22
    t = t_axis(d)
    f = [330, 285][i]
    x = (np.sin(2 * np.pi * f * t) * np.exp(-t / 0.045)
         + 0.55 * np.sin(2 * np.pi * f * 2.71 * t) * np.exp(-t / 0.022)
         + 0.25 * np.sin(2 * np.pi * f * 4.6 * t) * np.exp(-t / 0.012))
    thud = sine_sweep(d, 150, 80) * env_exp(d, 0.03, 0.001) * 0.6
    click = bp(noise(0.012), 1200, 5000) * env_exp(0.012, 0.0025) * 0.5
    x = mix(x + thud, click)
    return write_wav("drop_%d" % (i + 1), reverb(x, 0.12, 0.4, 4000), fout=0.08, length=0.25)


@seeded
def sfx_coin(i):
    """Bright little coin ching: two quick high bell strikes."""
    base = [93, 95][i]
    x = np.zeros(int(0.5 * SR))
    place(x, bell(midi_hz(base), 0.15, 0.6), 0)
    place(x, bell(midi_hz(base + 5), 0.42, 1.0), 0.055)
    place(x, hp(noise(0.006), 5000) * 0.25, 0)
    return write_wav("coin_%d" % (i + 1), reverb(x, 0.14, 0.6), fout=0.2, length=0.45)


@seeded
def sfx_cash():
    """Cash register: drawer clack + 'ka-ching' bell + coin cascade."""
    d = 1.0
    x = np.zeros(int(d * SR))
    clack = bp(noise(0.04), 800, 5000) * env_exp(0.04, 0.008, 0.001)
    clack2 = mix(np.sin(2 * np.pi * 420 * t_axis(0.06)) * env_exp(0.06, 0.015), bp(noise(0.02), 2000, 7000) * env_exp(0.02, 0.004))
    place(x, clack * 0.7, 0.0)
    place(x, clack2 * 0.6, 0.045)
    place(x, bell(midi_hz(96), 0.9, 1.0), 0.07)    # 'ching'
    place(x, bell(midi_hz(100), 0.9, 0.75), 0.075)
    n_coins = 16
    for k in range(n_coins):
        at = 0.14 + 0.5 * (k / n_coins) ** 1.3 + rng.uniform(-0.01, 0.01)
        f = rng.uniform(3200, 5200)
        dd = 0.12
        tt = t_axis(dd)
        c = (np.sin(2 * np.pi * f * tt) * np.exp(-tt / 0.035)
             + 0.5 * np.sin(2 * np.pi * f * 1.48 * tt) * np.exp(-tt / 0.02))
        place(x, c * rng.uniform(0.12, 0.28) * (1 - 0.5 * k / n_coins), at)
    return write_wav("cash", reverb(x, 0.18, 0.7), fout=0.22, length=0.85)


@seeded
def sfx_whoosh():
    d = 0.32
    t = t_axis(d)
    shape = np.sin(np.pi * (t / d) ** 0.8) ** 2
    cutoff = 500 + 3800 * shape
    x = svf_lp(noise(d), cutoff, 1.4) * shape
    x += 0.2 * hp(noise(d), 3000) * shape ** 2
    return write_wav("whoosh", x, fout=0.03)


@seeded
def sfx_plop():
    """Squishy dough plop: falling low bloop + wet squelch with a wobbling filter."""
    d = 0.26
    t = t_axis(d)
    f = 260 * np.exp(-t / 0.06) + 95
    body = osc(f) * env_exp(d, 0.07, 0.003)
    wob = 900 + 700 * np.exp(-t / 0.05) * (0.6 + 0.4 * np.sin(2 * np.pi * 38 * t))
    squelch = svf_lp(noise(d), wob, 2.5) * env_exp(d, 0.04, 0.002) * 0.6
    smack = lp(noise(0.015), 2500) * env_exp(0.015, 0.003) * 0.5
    x = mix(body * 1.1 + squelch, smack)
    return write_wav("plop", lp(x, 4000), fout=0.04)


@seeded
def sfx_dispense():
    """Hopper dispense: soft mechanical clunk, a ratchet tick, a little pour."""
    d = 0.7
    x = np.zeros(int(d * SR))
    clunk = sine_sweep(0.18, 120, 62) * env_exp(0.18, 0.05, 0.002)
    clunk = mix(clunk, bp(noise(0.05), 300, 2200) * env_exp(0.05, 0.01) * 0.6)
    tt = t_axis(0.1)
    metal = (np.sin(2 * np.pi * 820 * tt) * np.exp(-tt / 0.02) + 0.5 * np.sin(2 * np.pi * 1730 * tt) * np.exp(-tt / 0.012))
    place(x, clunk, 0.0)
    place(x, metal * 0.25, 0.004)
    place(x, bp(noise(0.02), 1500, 6000) * env_exp(0.02, 0.004) * 0.35, 0.07)
    # pour: little crumbs tumbling (granular clicks + soft hiss)
    n = int(0.45 * SR)
    dens = np.linspace(0.006, 0.001, n)
    grains = (rng.random(n) < dens).astype(float) * rng.uniform(0.3, 1, n)
    pour = bp(grains, 1500, 7000) * 0.8 + bp(noise(0.45), 1800, 5000) * 0.06
    pour *= np.sin(np.pi * np.linspace(0, 1, n)) ** 0.7
    place(x, pour * 1.1, 0.11)
    return write_wav("dispense", reverb(x, 0.12, 0.5), fout=0.1, length=0.65)


@seeded
def sfx_oven_ding():
    """Cute kitchen timer: a bright ding with a soft second ring."""
    d = 1.3
    x = np.zeros(int(d * SR))
    f = midi_hz(93)  # A6
    tt = t_axis(1.2)
    ding = (np.sin(2 * np.pi * f * tt) * np.exp(-tt / 0.45)
            + 0.45 * np.sin(2 * np.pi * f * 2.0 * tt) * np.exp(-tt / 0.18)
            + 0.18 * np.sin(2 * np.pi * f * 3.01 * tt) * np.exp(-tt / 0.07)
            + 0.08 * np.sin(2 * np.pi * f * 5.2 * tt) * np.exp(-tt / 0.03))
    ding *= 1 + 0.08 * np.sin(2 * np.pi * 6.2 * tt)  # tiny shimmer
    strike = hp(noise(0.005), 4000) * 0.2
    place(x, ding, 0)
    place(x, strike, 0)
    place(x, ding * 0.35, 0.16)
    return write_wav("oven_ding", reverb(x, 0.2, 1.0), fout=0.35, length=1.2)


def honk(dur, base):
    """One toy-horn honk: two detuned square-ish tones through an 'ee' formant."""
    t = t_axis(dur)
    bend = 1 - 0.06 * np.exp(-t / 0.02)
    src = square(base * bend, 10) + 0.8 * square(base * 1.26 * bend, 10)
    voc = formants(src, [(500, 3, 1.0), (1500, 4, 0.9), (2600, 6, 0.4)])
    voc = lp(voc + 0.15 * src, 4500)
    amp = np.clip(t / 0.012, 0, 1) * np.clip((dur - t) / 0.03, 0, 1)
    return voc * amp


@seeded
def sfx_horn():
    """Cute toy truck 'meep meep'."""
    x = np.zeros(int(0.6 * SR))
    place(x, honk(0.13, 560), 0.0)
    place(x, honk(0.17, 560), 0.19)
    return write_wav("horn", reverb(x, 0.12, 0.5), fout=0.1, length=0.5)


@seeded
def sfx_engine():
    """Short cute engine putter, steady so the tail can be looped."""
    d = 1.2
    period = d / 16  # 75 ms: 16 putts fit exactly -> loop-friendly
    n = int(d * SR)
    x = np.zeros(n + int(0.2 * SR))
    for k in range(16):
        dd = 0.09
        tt = t_axis(dd)
        strong = k % 2 == 0
        f0 = 95 if strong else 82
        putt = np.sin(2 * np.pi * np.cumsum(f0 * (1 + 0.6 * np.exp(-tt / 0.01))) / SR) * np.exp(-tt / 0.028)
        putt += bp(noise(dd), 250, 1600) * np.exp(-tt / 0.012) * 0.45
        place(x, putt * (1.0 if strong else 0.7) * rng.uniform(0.9, 1.0), k * period + rng.uniform(0, 0.003))
    x = fold_loop(x, n)
    t = t_axis(d)
    x += 0.12 * np.sin(2 * np.pi * 40 * t) * (0.6 + 0.4 * np.sin(2 * np.pi * t / period))  # gentle hum
    x = lp(x, 2200)
    # light fade in only; tail is steady (it's already wrap-folded for looping)
    return write_wav("engine", x, trim=False, fin=0.02, fout=0.004)


@seeded
def sfx_build():
    """Construction complete: three hammer taps + rising sparkle fanfare."""
    d = 1.6
    x = np.zeros(int(d * SR))
    for k, at in enumerate([0.0, 0.13, 0.26]):
        f = [430, 470, 520][k]
        tt = t_axis(0.18)
        tap = (np.sin(2 * np.pi * f * tt) * np.exp(-tt / 0.03)
               + 0.6 * np.sin(2 * np.pi * f * 2.8 * tt) * np.exp(-tt / 0.018)
               + 0.3 * np.sin(2 * np.pi * f * 5.3 * tt) * np.exp(-tt / 0.01))
        tap += sine_sweep(0.18, 140, 80) * np.exp(-tt / 0.025) * 0.6
        tap += bp(noise(0.18), 1500, 6000) * np.exp(-tt / 0.004) * 0.6
        place(x, tap * (0.75 + 0.1 * k), at)
    for k, m in enumerate([72, 76, 79, 84]):
        place(x, marimba(midi_hz(m), 0.9, 0.7), 0.42 + k * 0.075)
    place(x, toy_brass(midi_hz(84), 0.5, 0.3), 0.645)
    for k, m in enumerate([96, 100, 103, 108, 103, 108]):
        place(x, glock(midi_hz(m), 0.5, 0.28), 0.66 + k * 0.045)
    place(x, soft_bass(midi_hz(48), 0.6, 0.45), 0.645)
    return write_wav("build", reverb(x, 0.22, 1.0), fout=0.35, length=1.3)


@seeded
def sfx_upgrade():
    """Upgrade purchase: quick rising arpeggio + sparkle."""
    x = np.zeros(int(1.0 * SR))
    for k, m in enumerate([67, 72, 76, 79, 84]):
        place(x, marimba(midi_hz(m), 0.6, 0.6 + 0.08 * k), k * 0.055)
    for k, m in enumerate([96, 100, 103, 108]):
        place(x, glock(midi_hz(m), 0.4, 0.22), 0.22 + k * 0.04)
    return write_wav("upgrade", reverb(x, 0.22, 0.9), fout=0.25, length=0.7)


@seeded
def sfx_levelup():
    """Level-up: triumphant cute fanfare (toy brass + marimba + chord + sparkles)."""
    d = 2.2
    x = np.zeros(int(d * SR))
    mel = [(67, 0.0, 0.11), (72, 0.11, 0.11), (76, 0.22, 0.11), (79, 0.33, 0.22), (76, 0.55, 0.11), (79, 0.66, 0.9)]
    for m, at, ln in mel:
        place(x, toy_brass(midi_hz(m), ln + 0.06, 0.55), at)
        place(x, marimba(midi_hz(m + 12), 0.7, 0.35), at)
    for m in [60, 64, 67, 72]:
        place(x, pluck(midi_hz(m), 1.4, 0.3, 0.6, 0.997), 0.66 + (m - 60) * 0.004)
    place(x, soft_bass(midi_hz(48), 1.0, 0.7), 0.66)
    place(x, soft_bass(midi_hz(43), 0.4, 0.45), 0.33)
    place(x, kick(0.35), 0.66)
    for k, m in enumerate([96, 100, 103, 108, 112, 108, 103, 108]):
        place(x, glock(midi_hz(m), 0.5, 0.2), 0.72 + k * 0.05)
    x = mix(x, np.zeros(int(1.0 * SR)))
    return write_wav("levelup", reverb(x, 0.25, 1.2), fout=0.4, length=1.7)


@seeded
def sfx_hire():
    """Hire worker: a happy little 'hup!' + chime."""
    x = np.zeros(int(0.7 * SR))
    dv = 0.13
    t = t_axis(dv)
    f = 330 * (1 + 0.35 * np.clip(t / 0.06, 0, 1) ** 0.7) * (1 - 0.06 * np.clip((t - 0.08) / 0.05, 0, 1))
    src = saw(f, 30)
    voice = formants(src, [(820, 6, 1.0), (1500, 8, 0.6), (3000, 10, 0.18)])
    amp = np.clip(t / 0.02, 0, 1) * np.clip((dv - t) / 0.012, 0, 1) ** 0.5
    voice *= amp
    breath = bp(noise(0.035), 1000, 4500) * env_exp(0.035, 0.012, 0.004) * 0.25  # 'h'
    pop_p = lp(noise(0.006), 1500) * env_exp(0.006, 0.002) * 0.25                 # 'p'
    place(x, breath, 0.0)
    place(x, voice / (np.max(np.abs(voice)) + 1e-9), 0.02)
    place(x, pop_p, 0.02 + dv)
    place(x, bell(midi_hz(91), 0.45, 0.4), 0.17)
    place(x, bell(midi_hz(96), 0.5, 0.45), 0.23)
    return write_wav("hire", reverb(x, 0.15, 0.7), fout=0.2, length=0.55)


@seeded
def sfx_click():
    """Soft rounded UI tap."""
    d = 0.06
    t = t_axis(d)
    f = 720 * np.exp(-t / 0.03) + 380
    x = osc(f) * env_exp(d, 0.014, 0.0015)
    x += 0.2 * osc(f * 2) * env_exp(d, 0.006, 0.0015)
    return write_wav("click", lp(x, 3500), fout=0.015)


@seeded
def sfx_swoosh(up):
    d = 0.24
    t = t_axis(d)
    u = t / d if up else 1 - t / d
    shape = np.sin(np.pi * t / d) ** 1.5
    air = svf_lp(noise(d), 600 + 3000 * u ** 1.5, 1.2) * shape
    f = 340 * 2.0 ** u  # rises for open, falls for close
    tone = osc(f) * shape * 0.22
    x = air * 0.8 + tone
    return write_wav("open" if up else "close", lp(x, 6000), fout=0.03)


@seeded
def sfx_deny():
    """Gentle 'uh-uh': two soft, slightly nasal falling notes."""
    x = np.zeros(int(0.42 * SR))
    for k, (f, at) in enumerate([(233, 0.0), (196, 0.14)]):
        d = 0.13 if k == 0 else 0.2
        t = t_axis(d)
        ff = f * (1 - 0.03 * t / d)
        src = square(ff, 8) * 0.6 + saw(ff, 8) * 0.4
        v = formants(src, [(600, 3, 1.0), (1100, 5, 0.5)])
        v = lp(v, 1800) * np.clip(t / 0.01, 0, 1) * np.clip((d - t) / 0.03, 0, 1) * (1 + 0.15 * np.sin(2 * np.pi * 28 * t))
        place(x, v, at)
    return write_wav("deny", x, fout=0.03)


@seeded
def sfx_pay_tick():
    d = 0.045
    t = t_axis(d)
    x = np.sin(2 * np.pi * 2350 * t) * env_exp(d, 0.008, 0.0008)
    x += 0.3 * np.sin(2 * np.pi * 3520 * t) * env_exp(d, 0.004, 0.0008)
    x += pad(hp(noise(0.003), 4000) * 0.15, d)
    return write_wav("pay_tick", x, fout=0.01)


def voice_syll(dur, f0, f1, spec, nh=30, onset_noise=0.0, band=(1500, 5000)):
    t = t_axis(dur)
    f = f0 * (f1 / f0) ** (t / dur)
    src = saw(f, nh)
    v = formants(src, spec)
    v = v / (np.max(np.abs(v)) + 1e-9)
    amp = np.clip(t / 0.006, 0, 1) * np.clip((dur - t) / 0.015, 0, 1)
    v *= amp
    if onset_noise:
        v[: int(0.008 * SR)] += bp(noise(0.008), *band) * onset_noise * np.linspace(1, 0, int(0.008 * SR))
    return v


@seeded
def sfx_cluck():
    """Cute stylised chicken: 'bk-bk-bawk'."""
    x = np.zeros(int(0.55 * SR))
    spec = [(950, 5, 1.0), (1900, 7, 0.55), (3100, 9, 0.2)]
    place(x, voice_syll(0.055, 640, 520, spec, onset_noise=0.6) * 0.7, 0.0)
    place(x, voice_syll(0.055, 620, 500, spec, onset_noise=0.6) * 0.65, 0.09)
    t = t_axis(0.16)
    aw = voice_syll(0.16, 560, 840, [(1000, 4, 1.0), (1700, 6, 0.7), (3000, 9, 0.25)], onset_noise=0.5)
    aw *= 1 + 0.25 * np.sin(2 * np.pi * 30 * t)
    place(x, aw, 0.2)
    return write_wav("cluck", reverb(x, 0.1, 0.4), fout=0.06, length=0.45)


@seeded
def sfx_moo():
    """Cute cartoony cow moo: 'mmm-OOO' with a pitch arc and opening mouth."""
    d = 0.72
    t = t_axis(d)
    contour = 1 + 0.22 * np.sin(np.pi * np.clip(t / 0.35, 0, 1)) - 0.18 * np.clip((t - 0.35) / 0.37, 0, 1)
    vib = 1 + 0.015 * np.sin(2 * np.pi * 6 * t) * np.clip((t - 0.15) / 0.2, 0, 1)
    f = 175 * contour * vib
    src = saw(f, 40)
    mouth = 320 + 900 * np.sin(np.pi * np.clip((t - 0.06) / 0.62, 0, 1)) ** 0.8
    v = svf_lp(src, mouth, 1.6)
    v = v + 0.5 * formants(v, [(380, 4, 1.0), (850, 6, 0.6), (2400, 8, 0.12)])
    amp = np.clip(t / 0.05, 0, 1) * np.clip((d - t) / 0.12, 0, 1)
    breath = bp(noise(d), 600, 3000) * amp * 0.02
    x = lp((v / (np.max(np.abs(v)) + 1e-9)) * amp, 2600) + breath
    return write_wav("moo", reverb(x, 0.12, 0.6), fout=0.08, length=0.8)


@seeded
@seeded
def sfx_hammer(i):
    """A builder's hammer on a wooden beam: bright knock + woody body + tiny ring."""
    d = 0.2
    t = t_axis(d)
    f = [520, 470][i]
    body = (np.sin(2 * np.pi * f * t) * np.exp(-t / 0.03)
            + 0.5 * np.sin(2 * np.pi * f * 2.3 * t) * np.exp(-t / 0.018)
            + 0.18 * np.sin(2 * np.pi * f * 5.1 * t) * np.exp(-t / 0.05))
    knock = bp(noise(0.01), 1500, 6500) * env_exp(0.01, 0.002) * 0.9
    thud = sine_sweep(d, 180, 90) * env_exp(d, 0.025, 0.001) * 0.5
    x = mix(body * 0.8 + thud, knock)
    return write_wav("hammer_%d" % (i + 1), reverb(x, 0.1, 0.4, 5000), fout=0.06, length=0.22)


def sfx_step(i):
    """Very soft footstep on grass: muffled thud + tiny rustle."""
    d = 0.1
    t = t_axis(d)
    thud = np.sin(2 * np.pi * np.cumsum(150 * np.exp(-t / 0.02) + 70) / SR) * env_exp(d, 0.018, 0.003)
    n = int(d * SR)
    grains = (rng.random(n) < 0.03).astype(float) * rng.uniform(0.2, 1, n)
    rustle = bp(grains + 0.15 * noise(d), 1800 + 400 * i, 7000) * env_exp(d, 0.03, 0.008)
    x = thud * 0.9 + rustle * 0.7
    return write_wav("step_%d" % (i + 1), lp(x, 6000), fout=0.02)


# --------------------------------------------------------------------------- music
KEY = 0   # semitone offset applied to the whole tune (0 = C major)
BPM = 104
BEAT = 60.0 / BPM
BAR = BEAT * 4

C_ = (48, [60, 64, 67])
AM = (45, [57, 60, 64])
F_ = (41, [57, 60, 65])
G_ = (43, [55, 59, 62])
G7 = (43, [53, 59, 62])
EM = (40, [55, 59, 64])
DM = (38, [57, 62, 65])
CHORDS = [
    C_, AM, F_, G_, C_, AM, F_, G_,     # A: bouncy theme
    F_, G_, EM, AM, DM, G_, C_, C_,     # B: lilting answer
    AM, EM, F_, C_, DM, G_, C_, G7,     # C: calmer, airy (G7 turns back to the top)
]
LOOP = BAR * len(CHORDS)

MELODY = [  # (bar, beat, midi, beats) - marimba lead
    (0, 0.0, 76, .5), (0, 0.5, 79, .5), (0, 1.0, 84, 1), (0, 2.5, 79, .5), (0, 3.0, 76, 1),
    (1, 0.0, 76, 1), (1, 1.0, 72, .5), (1, 1.5, 69, 1.5), (1, 3.5, 72, .5),
    (2, 0.0, 77, .5), (2, 0.5, 76, .5), (2, 1.0, 72, 1), (2, 2.5, 69, .5), (2, 3.0, 72, 1),
    (3, 0.0, 74, 1.5), (3, 2.0, 71, .5), (3, 2.5, 74, .5), (3, 3.0, 79, 1),
    (4, 0.0, 76, .5), (4, 0.5, 79, .5), (4, 1.0, 84, 1), (4, 2.5, 86, .5), (4, 3.0, 84, 1),
    (5, 0.0, 81, 1.5), (5, 2.0, 79, .5), (5, 2.5, 76, .5), (5, 3.0, 72, 1),
    (6, 0.0, 77, 1), (6, 1.0, 81, .5), (6, 1.5, 79, 1), (6, 3.0, 77, .5), (6, 3.5, 76, .5),
    (7, 0.0, 74, 2), (7, 3.0, 71, .5), (7, 3.5, 74, .5),
    (8, 0.0, 77, .5), (8, 0.5, 76, .5), (8, 1.0, 77, .5), (8, 1.5, 81, 1.5), (8, 3.0, 84, 1),
    (9, 0.0, 83, 1), (9, 1.0, 79, .5), (9, 1.5, 74, 1.5), (9, 3.0, 79, 1),
    (10, 0.0, 79, .5), (10, 0.5, 76, .5), (10, 1.0, 79, .5), (10, 1.5, 83, 1.5), (10, 3.0, 79, 1),
    (11, 0.0, 81, 2), (11, 2.5, 76, .5), (11, 3.0, 72, 1),
    (12, 0.0, 74, .5), (12, 0.5, 77, .5), (12, 1.0, 81, 1), (12, 2.5, 77, .5), (12, 3.0, 74, 1),
    (13, 0.0, 79, 1), (13, 1.0, 83, .5), (13, 1.5, 86, 1.5), (13, 3.0, 83, 1),
    (14, 0.0, 84, 1.5), (14, 2.0, 79, .5), (14, 2.5, 76, .5), (14, 3.0, 79, 1),
    (15, 0.0, 72, 2),
    (16, 0.0, 76, 1.5), (16, 2.0, 72, 1), (16, 3.0, 76, 1),
    (17, 0.0, 79, 2), (17, 3.0, 76, 1),
    (18, 0.0, 77, 1.5), (18, 2.0, 81, 1), (18, 3.0, 77, 1),
    (19, 0.0, 76, 2), (19, 3.0, 72, 1),
    (20, 0.0, 74, 1), (20, 1.0, 77, .5), (20, 1.5, 81, 1.5), (20, 3.0, 79, 1),
    (21, 0.0, 79, 1), (21, 1.0, 77, .5), (21, 1.5, 74, 1.5), (21, 3.0, 71, 1),
    (22, 0.0, 72, 1), (22, 1.0, 76, .5), (22, 1.5, 79, 1), (22, 3.0, 84, 1),
    (23, 0.0, 83, 1), (23, 1.0, 77, .5), (23, 1.5, 74, 1.5), (23, 3.0, 77, .5), (23, 3.5, 74, .5),
]

GLOCK_FILLS = {  # bar -> [(beat, midi)] little sparkles at phrase ends
    3: [(2.0, 86), (2.5, 91), (3.0, 98)],
    7: [(2.0, 91), (2.5, 95), (3.0, 98), (3.5, 103)],
    11: [(2.0, 88), (2.5, 93), (3.0, 96)],
    15: [(2.0, 91), (2.5, 96), (3.0, 100), (3.5, 103)],
    19: [(2.0, 88), (2.5, 91), (3.0, 96)],
    23: [(2.0, 95), (2.5, 98), (3.0, 101), (3.5, 103)],
}


@seeded
def music():
    """Bright, bouncy lo-fi electronic idle loop: electric piano lead, synth
    plucks, a warm pad, soft drums. Seamless: everything that rings past the
    end (note tails, reverb) is folded back onto the start."""
    k = KEY
    n = int(round(LOOP * SR))
    total = n + int(3 * SR)
    lead = np.zeros(total)
    plk = np.zeros(total)
    bass = np.zeros(total)
    perc = np.zeros(total)
    shk = np.zeros(total)
    glk = np.zeros(total)
    pads = np.zeros(total)

    def hum():
        return rng.uniform(0.0, 0.006)

    for b, (root, triad) in enumerate(CHORDS):
        t0 = b * BAR
        sec = b // 8
        # bass: bouncy root / fifth
        fifth = root + 7
        place(bass, soft_bass(midi_hz(root + k), BEAT * 1.1, 0.85), t0)
        place(bass, soft_bass(midi_hz(fifth + k), BEAT * 0.9, 0.6), t0 + 2 * BEAT)
        if b % 2 == 1:
            place(bass, soft_bass(midi_hz(root + 12 + k), BEAT * 0.5, 0.4), t0 + 3.5 * BEAT)
        # a warm pad holding the chord
        place(pads, synth_pad([midi_hz(m + k - 12) for m in triad], BAR * 1.05, 0.5), t0)
        # synth-pluck offbeat chord stabs
        stabs = [(1.0, 0.75), (2.5, 0.35), (3.0, 0.65)] if sec != 2 else [(1.0, 0.6), (3.0, 0.55)]
        for beat, vel in stabs:
            for j, m in enumerate(triad):
                place(plk, synth_pluck(midi_hz(m + k), 0.3, vel * 0.42 * rng.uniform(0.9, 1.05)),
                      t0 + beat * BEAT + j * 0.006 + hum())
        # pizz counter-line in the calmer section (keeps it moving without drums)
        if sec == 2:
            for beat, m in [(0.5, triad[2] + 12), (1.5, triad[1] + 12), (2.0, triad[0] + 12)]:
                place(plk, synth_pluck(midi_hz(m + k), 0.28, 0.25), t0 + beat * BEAT + hum())
        # drums: soft kick, light claps, swung shaker
        place(perc, kick(0.55 if sec != 2 else 0.35), t0)
        place(perc, kick(0.4 if sec != 2 else 0.25), t0 + 2 * BEAT)
        if sec >= 1:
            place(perc, clap(0.22), t0 + 1 * BEAT + hum())
            place(perc, clap(0.26), t0 + 3 * BEAT + hum())
        for e in range(8):
            swing = 0.018 if e % 2 else 0.0
            v = (0.42 if e % 2 else 0.24) * (0.8 if sec == 2 else 1.0)
            place(shk, shaker(v * rng.uniform(0.85, 1.1)), t0 + e * BEAT / 2 + swing + hum())
        for beat, m in GLOCK_FILLS.get(b, []):
            place(glk, glock(midi_hz(m + k), 0.7, 0.3), t0 + beat * BEAT + hum())

    for bar, off, m, ln in MELODY:
        at = bar * BAR + off * BEAT + hum()
        v = 0.55 * rng.uniform(0.92, 1.05)
        place(lead, epiano(midi_hz(m + k), max(0.6, ln * BEAT * 1.6), v), at)
        if bar >= 16:  # glock doubles the calmer section an octave up, very softly
            place(glk, glock(midi_hz(m + 12 + k), 0.6, 0.09), at)

    pans = [(lead, 0.62), (plk, 0.35), (bass, 0.5), (perc, 0.5), (shk, 0.7), (glk, 0.6), (pads, 0.45)]
    gains = [1.0, 0.7, 0.95, 0.75, 0.32, 0.75, 0.5]
    left = np.zeros(total)
    right = np.zeros(total)
    for (sig, p), g in zip(pans, gains):
        left += sig * g * np.cos(p * np.pi / 2) * 1.41
        right += sig * g * np.sin(p * np.pi / 2) * 1.41
    # reverb on the long buffer, then fold the overhang back to the head = seamless loop
    left = fold_loop(reverb(left, 0.22, 1.5, 4500), n)
    right = fold_loop(reverb(right, 0.22, 1.55, 4500), n)
    st = np.stack([left, right], axis=1)
    st = st - st.mean(axis=0)
    st = soft_clip(st / np.max(np.abs(st)) * 1.05, 1.1)
    write_ogg("music", st, -8.0, 4)


def bird_chirp():
    """One small bird phrase: 2-4 quick chirps."""
    calls = rng.integers(2, 5)
    base = rng.uniform(2800, 4200)
    out = np.zeros(int(0.8 * SR))
    at = 0.0
    for c in range(calls):
        d = rng.uniform(0.04, 0.09)
        t = t_axis(d)
        kind = rng.integers(0, 3)
        if kind == 0:
            f = base * (1.3 - 0.45 * t / d)
        elif kind == 1:
            f = base * (0.8 + 0.5 * np.sin(np.pi * t / d))
        else:
            f = base * (1 + 0.12 * np.sin(2 * np.pi * 40 * t))
        ch = osc(f) * np.sin(np.pi * t / d) ** 2
        place(out, ch * rng.uniform(0.6, 1.0), at)
        at += d + rng.uniform(0.03, 0.08)
    return out[: int((at + 0.05) * SR)]


@seeded
def ambience():
    """Gentle factory/farm bed: far machinery hum + soft chunks, breeze, birds."""
    d = 30.0
    n = int(d * SR)
    xf = int(2.0 * SR)
    m = n + xf
    t = np.arange(m) / SR
    # hum: integer cycles per 30 s so the tonal part is exactly periodic
    hum = (np.sin(2 * np.pi * 60 * t) * 0.5 + np.sin(2 * np.pi * 120 * t) * 0.25
           + np.sin(2 * np.pi * 180 * t) * 0.08)
    hum *= 0.8 + 0.2 * np.sin(2 * np.pi * t * 3 / d)
    rumble = lp(brown(m / SR), 160) * 0.8
    breeze = bp(pink(m / SR), 300, 2500) * (0.5 + 0.5 * np.sin(2 * np.pi * t * 2 / d + 1.0)) * 0.12
    bed = loop_xfade(hum * 0.18 + rumble * 0.5 + breeze, n, xf)
    left = bed.copy()
    right = np.roll(bed, int(0.017 * SR)) * 0.9 + bed * 0.1
    # distant machinery: soft periodic chunk-chunk (20 per loop, exactly periodic)
    mach = np.zeros(n)
    for k in range(20):
        dd = 0.3
        tt = t_axis(dd)
        ch = np.sin(2 * np.pi * np.cumsum(90 * (1 + 0.3 * np.exp(-tt / 0.02))) / SR) * np.exp(-tt / 0.06)
        ch += bp(noise(dd), 300, 1500) * np.exp(-tt / 0.02) * 0.3
        place_wrap(mach, ch * (0.5 if k % 2 else 0.35), k * 1.5)
        place_wrap(mach, ch * 0.18, k * 1.5 + 0.42)
    mach = lp(mach, 700)
    # occasional soft steam puffs
    for at in [6.2, 19.4]:
        dd = 0.9
        tt = t_axis(dd)
        puff = bp(noise(dd), 1200, 4000) * np.clip(tt / 0.08, 0, 1) * np.exp(-tt / 0.25) * 0.07
        place_wrap(mach, puff, at)
    mach = fold_loop(reverb(np.concatenate([mach, np.zeros(int(1.6 * SR))]), 0.5, 1.6, 2500), n)
    left += mach * 0.55
    right += mach * 0.45
    # birds, panned, with some air around them
    bl = np.zeros(n + int(1.5 * SR))
    br = np.zeros(n + int(1.5 * SR))
    times = sorted(rng.uniform(0, d, 9))
    for at in times:
        ch = bird_chirp() * rng.uniform(0.08, 0.16)
        p = rng.uniform(0.15, 0.85)
        place(bl, ch * np.cos(p * np.pi / 2), at)
        place(br, ch * np.sin(p * np.pi / 2), at)
    bl = fold_loop(reverb(hp(bl, 1500), 0.4, 1.3), n)
    br = fold_loop(reverb(hp(br, 1500), 0.4, 1.35), n)
    left += bl
    right += br
    st = np.stack([left, right], axis=1)
    st = np.stack([circ_filter(lambda v: hp(v, 30), st[:, c]) for c in range(2)], axis=1)
    write_ogg("ambience", st, -16.0, 4)


# --------------------------------------------------------------------------- report
def _read_any(path):
    """Decode any file via ffmpeg to float32 interleaved; returns (data, channels)."""
    probe = subprocess.run(["ffprobe", "-v", "error", "-select_streams", "a:0", "-show_entries",
                            "stream=channels", "-of", "csv=p=0", path],
                           capture_output=True, text=True, check=True)
    ch = int(probe.stdout.strip().split(",")[0])
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", path, "-f", "f32le", "-acodec", "pcm_f32le", "-"],
                         capture_output=True, check=True).stdout
    data = np.frombuffer(raw, dtype=np.float32).reshape(-1, ch)
    return data, ch


def report():
    names = sorted(f for f in os.listdir(OUT) if f.endswith((".wav", ".ogg")))
    print("\n%-16s %7s %3s %9s %9s %10s" % ("file", "dur(s)", "ch", "peak dB", "rms dB", "edge/seam"))
    print("-" * 60)
    for f in names:
        data, ch = _read_any(os.path.join(OUT, f))
        dur = len(data) / SR
        peak = 20 * np.log10(np.max(np.abs(data)) + 1e-12)
        rms = 20 * np.log10(np.sqrt(np.mean(data.astype(np.float64) ** 2)) + 1e-12)
        if f.endswith(".ogg"):
            # seam jump relative to typical sample-to-sample step
            jump = np.max(np.abs(data[0] - data[-1]))
            typ = np.percentile(np.abs(np.diff(data, axis=0)), 99)
            edge = "seam %.2fx" % (jump / (typ + 1e-12))
        else:
            edge = "%.4f" % max(abs(data[0, 0]), abs(data[-1, 0]))
        print("%-16s %7.3f %3d %9.2f %9.2f %10s" % (f, dur, ch, peak, rms, edge))


SFX = [
    lambda: [sfx_pop(i) for i in range(3)],
    lambda: [sfx_drop(i) for i in range(2)],
    lambda: [sfx_coin(i) for i in range(2)],
    sfx_cash, sfx_whoosh, sfx_plop, sfx_dispense, sfx_oven_ding, sfx_horn, sfx_engine,
    sfx_build, sfx_upgrade, sfx_levelup, sfx_hire, sfx_click,
    lambda: [sfx_swoosh(True), sfx_swoosh(False)],
    sfx_deny, sfx_pay_tick,
    lambda: [sfx_step(i) for i in range(2)],
    lambda: [sfx_hammer(i) for i in range(2)],
]


def main():
    os.makedirs(OUT, exist_ok=True)
    for gen in SFX:
        gen()
    music()
    ambience()
    print("audio written to", OUT)
    report()


if __name__ == "__main__":
    if len(sys.argv) > 1:
        os.makedirs(OUT, exist_ok=True)
        for name in sys.argv[1:]:
            if name == "report":
                report()
                continue
            fn = globals()[name]
            if name in ("sfx_pop", "sfx_step", "sfx_hammer"):
                [fn(i) for i in range(3 if name == "sfx_pop" else 2)]  # pop has 3 variants
            elif name in ("sfx_drop", "sfx_coin"):
                [fn(i) for i in range(2)]
            elif name == "sfx_swoosh":
                fn(True), fn(False)
            else:
                fn()
    else:
        main()
