#!/usr/bin/env python3
"""Generates data/dalen/function/build/colosseum.mcfunction: a round arena
with tiered stone seating, pillars, lanterns, banners and a grand gate,
centered on the existing boss arena at (-7066, 38, -1599). Re-run and
re-apply (via `function dalen:build/colosseum`) if the design changes --
don't hand-edit the generated file.
"""
import math

CX, CY, CZ = -7066, 38, -1599
FLOOR_R = 30          # the open fighting floor
WALL_R0 = 31          # inner face of the tiered seating wall
TIERS = 4             # seating rings, each stepping out and up
TIER_H = 3
TIER_W = 3
PILLAR_R = 30
N_PILLARS = 16
PILLAR_H = 14
GATE_HALF_WIDTH = 5   # gate opening spans this many blocks either side of south (+Z)

FLOOR = "minecraft:polished_deepslate"
FLOOR_EDGE = "minecraft:deepslate_bricks"
WALL = "minecraft:deepslate_bricks"
WALL_CRACKED = "minecraft:cracked_deepslate_bricks"
WALL_MOSSY = "minecraft:mossy_stone_bricks"
STAIR = "minecraft:polished_deepslate_stairs"
PILLAR_BLOCK = "minecraft:polished_blackstone_bricks"
GATE_BLOCK = "minecraft:chiseled_deepslate"
BANNER_COLOR = "black"

cmds = []


def fill(x1, y1, z1, x2, y2, z2, block):
    cmds.append(f"fill {x1} {y1} {z1} {x2} {y2} {z2} {block}")


def setblock(x, y, z, block):
    cmds.append(f"setblock {x} {y} {z} {block}")


def in_gate(x, z):
    """True if (x,z) falls inside the south-facing gate opening (+Z side)."""
    return abs(x - CX) <= GATE_HALF_WIDTH and z > CZ


# --- Floor: a flat stone disk, with a slightly darker ring marking the edge ---
cmds.append(f"# --- floor ---")
for dz in range(-FLOOR_R, FLOOR_R + 1):
    z = CZ + dz
    # Span of x at this z for a circle of radius FLOOR_R
    span = int(math.isqrt(max(0, FLOOR_R * FLOOR_R - dz * dz)))
    x1, x2 = CX - span, CX + span
    fill(x1, CY - 1, z, x2, CY - 1, z, FLOOR)
    fill(x1, CY, z, x2, CY + 3, z, "air")  # clear headroom above the floor
edge_span_prev = None
for deg in range(0, 360, 1):
    rad = math.radians(deg)
    x = CX + round(FLOOR_R * math.cos(rad))
    z = CZ + round(FLOOR_R * math.sin(rad))
    setblock(x, CY - 1, z, FLOOR_EDGE)

# --- Tiered seating wall: rings stepping outward and upward ---
cmds.append(f"# --- seating tiers ---")
for tier in range(TIERS):
    r_in = WALL_R0 + tier * TIER_W
    r_out = r_in + TIER_W
    y_base = CY + tier * TIER_H
    block = WALL if tier % 2 == 0 else WALL_MOSSY
    for deg in range(0, 360, 1):
        rad = math.radians(deg)
        for r in range(r_in, r_out + 1):
            x = CX + round(r * math.cos(rad))
            z = CZ + round(r * math.sin(rad))
            if in_gate(x, z) and tier == 0:
                continue  # leave the gate opening clear on the bottom tier
            fill(x, y_base, z, x, y_base + TIER_H - 1, z, block)
    # Stair-step facing inward along the top of this tier (the seating lip)
    for deg in range(0, 360, 2):
        rad = math.radians(deg)
        x = CX + round(r_in * math.cos(rad))
        z = CZ + round(r_in * math.sin(rad))
        facing = "south" if math.sin(rad) < -0.5 else "north" if math.sin(rad) > 0.5 else (
            "east" if math.cos(rad) < 0 else "west")
        if not in_gate(x, z):
            setblock(x, y_base + TIER_H, z, f"{STAIR}[facing={facing},half=bottom]")

# --- Pillars with lanterns + banners, evenly spaced, skipping the gate ---
cmds.append(f"# --- pillars ---")
for i in range(N_PILLARS):
    deg = i * (360 / N_PILLARS)
    rad = math.radians(deg)
    x = CX + round(PILLAR_R * math.cos(rad))
    z = CZ + round(PILLAR_R * math.sin(rad))
    if in_gate(x, z):
        continue
    fill(x, CY, z, x, CY + PILLAR_H, z, PILLAR_BLOCK)
    setblock(x, CY + PILLAR_H + 1, z, "minecraft:lantern[hanging=false]")
    # Banner on the inward-facing side, partway up
    dx, dz = CX - x, CZ - z
    facing = "south" if dz > 0 else "north" if dz < 0 else ("east" if dx > 0 else "west")
    bx = x + (1 if dx > 0 else -1 if dx < 0 else 0)
    bz = z + (1 if dz > 0 else -1 if dz < 0 else 0)
    setblock(bx, CY + 8, bz, f"minecraft:{BANNER_COLOR}_wall_banner[facing={facing}]")

# --- Grand gate: an arch on the south side (+Z), framing the entrance ---
cmds.append(f"# --- gate ---")
gx1, gx2 = CX - GATE_HALF_WIDTH, CX + GATE_HALF_WIDTH
gz = CZ + WALL_R0 + TIERS * TIER_W
fill(gx1 - 1, CY, gz, gx2 + 1, CY, gz, GATE_BLOCK)                  # threshold
fill(gx1 - 1, CY, gz, gx1 - 1, CY + 9, gz, GATE_BLOCK)              # left post
fill(gx2 + 1, CY, gz, gx2 + 1, CY + 9, gz, GATE_BLOCK)              # right post
fill(gx1 - 2, CY + 10, gz, gx2 + 2, CY + 12, gz, GATE_BLOCK)        # lintel/arch cap
fill(gx1, CY, gz, gx2, CY + 9, gz, "air")                           # keep the opening clear
setblock(gx1 - 1, CY + 11, gz, "minecraft:lantern[hanging=true]")
setblock(gx2 + 1, CY + 11, gz, "minecraft:lantern[hanging=true]")

with open("data/dalen/function/build/colosseum.mcfunction", "w") as f:
    f.write("\n".join(cmds) + "\n")

print(f"wrote {len(cmds)} commands")
