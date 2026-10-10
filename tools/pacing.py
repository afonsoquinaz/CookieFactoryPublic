#!/usr/bin/env python3
"""Rough long-game pacing model for Cookie Empire (mirrors core/bal.gd).

A sensible player: buys whatever adds the most income per coin among
line upgrades, new lines for better recipes, research, and keeps farms and
logistics in step (modelled as an overhead share of income). Prints the
time to each empire level and palace stage.

    python3 tools/pacing.py [--logistics 0.7]
"""
import math, re, sys, argparse

ROOT = __file__.rsplit('/tools/', 1)[0]
defs = open(ROOT + '/core/defs.gd').read()

RECIPES = []
for m in re.finditer(r'\{"id": "(\w+)", "name": "[^"]+", "ings": \[([^\]]*)\], "price": ([0-9.]+)\}', defs):
    ings = [x.strip().strip('"') for x in m.group(2).split(',') if x.strip()]
    RECIPES.append((m.group(1), ings, float(m.group(3))))
B = {}
for m in re.finditer(r'"(\w+)": \{"name": "[^"]+", "cat": "(\w+)"[^\n]*?"lvl": (\d+), "cost": ([0-9.e]+), "growth": ([0-9.]+), "up": ([0-9.e]+), "max": (\d+)', defs):
    B[m.group(1)] = dict(cat=m.group(2), lvl=int(m.group(3)), cost=float(m.group(4)), growth=float(m.group(5)), up=float(m.group(6)), max=int(m.group(7)))
for m in re.finditer(r'"(\w+)": \{"name": "[^"]+", "cat": "farm", "icon": "\w+", "crop": "(\w+)"', defs):
    B[m.group(1)]['crop'] = m.group(2)
PRODUCER = {}
for k, d in B.items():
    if 'crop' in d:
        PRODUCER[d['crop']] = k
for m in re.finditer(r'"(\w+)": \{[^\n]*"cat": "kitchen"[^\n]*\n\t\t"in": \{([^}]*)\}, "out": \{"(\w+)"', defs):
    PRODUCER[m.group(3)] = m.group(1)
    B[m.group(1)]['in'] = [x.split(':')[0].strip().strip('"') for x in m.group(2).split(',')]
STAGES = [float(x) for x in re.findall(r'\{"name": "[^"]+", "cost": ([0-9.e]+), "need": \d+\}', defs)]

def snap(v):
    if v < 100: return round(v)
    mag = 10 ** (math.floor(math.log10(v)) - 1)
    return round(v / mag) * mag
def up_cost(kind, l):
    g = {'farm': 1.28, 'line': 1.3, 'kitchen': 1.3, 'pack': 1.32, 'sell': 1.32}.get(B[kind]['cat'], 1.3)
    return snap(B[kind]['up'] * g ** (l - 1))
def build_cost(kind, n): return snap(B[kind]['cost'] * B[kind]['growth'] ** n)
def mixer_interval(l): return max(0.45, 2.4 * 0.95 ** (l - 1))
def bake_time(l): return max(0.8, 3.0 * 0.95 ** (l - 1))
def batch(l): return 3 + (l - 1) // 3
def xp_needed(l): return round(50 * 1.55 ** (l - 1))
def research_cost(l): return snap(200 * 1.72 ** l)

def ing_level(i):
    p = PRODUCER.get(i)
    if not p: return 1
    l = B[p]['lvl']
    for j in B[p].get('in', []): l = max(l, ing_level(j))
    return l

def recipe_level(r): return max([1] + [ing_level(i) for i in r[1]])

ap = argparse.ArgumentParser()
ap.add_argument('--logistics', type=float, default=0.65, help='share of production value that gets sold (staff/vans keep up)')
ap.add_argument('--hours', type=float, default=400)
args = ap.parse_args()

class Line:
    def __init__(s, r): s.r = r; s.lm = 1; s.lo = 1
    def rate(s):  # cookies / s
        return batch(s.lo) * min(1 / mixer_interval(s.lm), 1.5 / bake_time(s.lo))   # ~1 chef

money, level, xp, t = 0.0, 1, 0.0, 0.0
lines = [Line(RECIPES[0])]
counts = {'mixer': 1, 'oven': 1, 'hopper': 0}
have_producers = {'wheat'}
recipe_research = 0
palace = -1
report = {}
dt = 10.0

def price_mult(): return 1.1 ** recipe_research
def income():
    v = sum(l.rate() * l.r[2] for l in lines) * price_mult()
    # boxes/gifts/channels later in the game
    bonus = 1.0
    if level >= 9: bonus *= 1.2
    if level >= 14: bonus *= 1.1
    if level >= 20: bonus *= 1.35
    if level >= 30: bonus *= 1.3
    return v * bonus * args.logistics

def best_recipe():
    best = RECIPES[0]
    for r in RECIPES:
        if recipe_level(r) <= level: best = r
    return best

def new_line_cost(r):
    c = build_cost('mixer', counts['mixer']) + build_cost('oven', counts['oven'])
    for k in range(len(r[1])): c += build_cost('hopper', counts['hopper'] + k)
    # producers: two farms / kitchens per ingredient, plus their upgrades (~3x)
    for i in ['wheat'] + r[1]:
        p = PRODUCER.get(i, 'farm_wheat')
        c += 3 * build_cost(p, 0) * (1.0 if i in have_producers else 2.0)
    return c

while t < args.hours * 3600:
    inc = income()
    money += inc * dt
    xp += inc * dt
    while xp >= xp_needed(level) and level < 60:
        xp -= xp_needed(level); level += 1
        money += snap(xp_needed(level - 1) * 0.15)
        report.setdefault('L%d' % level, t)
    # candidates: (gain/cost, cost, action)
    cands = []
    for l in lines:
        base = inc
        for which in ('m', 'o'):
            lv = l.lm if which == 'm' else l.lo
            if lv >= 50: continue
            c = up_cost('mixer' if which == 'm' else 'oven', lv)
            old = (l.lm, l.lo)
            if which == 'm': l.lm += 1
            else: l.lo += 1
            g = income() - base
            l.lm, l.lo = old
            c *= 1.6   # matching farm / hopper / van upgrades
            cands.append((g / c, c, ('up', l, which)))
    r = best_recipe()
    c = new_line_cost(r)
    nl = Line(r)
    g = nl.rate() * r[2] * price_mult() * args.logistics
    cands.append((g / c, c, ('line', r)))
    rc = research_cost(recipe_research)
    cands.append((inc * 0.1 / rc, rc, ('research',)))
    if level >= 35 and palace < len(STAGES) - 1:
        pc = STAGES[palace + 1]
        if money >= pc:
            money -= pc; palace += 1
            report['palace%d' % palace] = t
            if palace == len(STAGES) - 1: break
            continue
        # save for the palace once it's within an hour of income
        if pc < inc * 3600: continue
    cands.sort(key=lambda x: -x[0])
    for ratio, cost, act in cands[:1]:
        if money >= cost:
            money -= cost
            if act[0] == 'up':
                if act[2] == 'm': act[1].lm += 1
                else: act[1].lo += 1
            elif act[0] == 'line':
                lines.append(Line(act[1])); counts['mixer'] += 1; counts['oven'] += 1; counts['hopper'] += len(act[1][1])
                for i in act[1][1]: have_producers.add(i)
            else:
                recipe_research += 1
    t += dt

for k, v in report.items():
    if k.startswith('L') and int(k[1:]) % 5 == 0 or k.startswith('palace'):
        print('%-8s %6.1f h' % (k, v / 3600))
print('lines', len(lines), [l.r[0] for l in lines][-5:], 'research', recipe_research, 'income/min %.3g' % (income() * 60))
