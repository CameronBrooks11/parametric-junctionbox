"""Render each part and probe the box's holes, checking pieces and sizes.

usage: python3 tests/test_junctionbox.py [OPENSCAD]

Each render uses --hardwarnings. A binary STL's separate solids are counted
(triangles sharing a vertex belong to the same solid), and sizes are checked
to within 0.01 mm. tests/probe.scad shows where the box isn't inside one wall
or the floor, so each hole there is one piece; an empty render is no holes.
"""

import os
import struct
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BOX = os.path.join(ROOT, "junctionbox.scad")
PROBE = os.path.join(ROOT, "tests", "probe.scad")


def measure(path):
    data = open(path, "rb").read()
    (n,) = struct.unpack_from("<I", data, 80)
    parent = {}
    zs = []

    def find(v):
        while parent[v] != v:
            parent[v] = parent[parent[v]]
            v = parent[v]
        return v

    for i in range(n):
        v = struct.unpack_from("<9f", data, 84 + i * 50 + 12)
        corners = [v[0:3], v[3:6], v[6:9]]
        for c in corners:
            parent.setdefault(c, c)
        root = find(corners[0])
        for c in corners[1:]:
            parent[find(c)] = root
    solids = len({find(v) for v in parent})
    size = [max(p[i] for p in parent) - min(p[i] for p in parent) for i in range(3)]
    bottom = min(p[2] for p in parent)
    return solids, size, bottom


def render(openscad, scad, out, defines):
    """Return (solids, size, bottom z), or None when the render is empty."""
    cmd = [openscad, "--hardwarnings", "--export-format", "binstl", "-o", out]
    for name, value in defines.items():
        cmd += ["-D", f"{name}={value}"]
    result = subprocess.run(cmd + [scad], capture_output=True, text=True)
    if "empty" in result.stderr.lower():
        return None
    if result.returncode != 0:
        errors = [l for l in result.stderr.splitlines() if "WARNING" in l or "ERROR" in l]
        raise RuntimeError(f"openscad exited {result.returncode}: {'; '.join(errors)}")
    return measure(out)


# (label, defines, solids, x, y, z). Each part also has to sit on z = 0.
PARTS = [
    ("box", {"part": '"box"'}, 1, 100, 100, 50),
    ("lid", {"part": '"lid"'}, 1, 100, 100, 3),
    ("bushing", {"part": '"bushing"'}, 1, 12, 12, 30),
    ("blocker", {"part": '"blocker"'}, 1, 26.5, 26.5, 5.99),
    ("box 150 x 80 x 60", {"junctionbox_width": 150, "junctionbox_height": 80,
                           "junctionbox_thickness": 60}, 1, 150, 80, 60),
]

# Holes per side follow nh, sh, wh and eh, including eh, which the old main
# section ignored.
HOLES = {"nh": 1, "sh": 2, "wh": 3, "eh": 0}
SIDES = {"north": "nh", "south": "sh", "west": "wh", "east": "eh"}


def main():
    openscad = sys.argv[1] if len(sys.argv) > 1 else "openscad"
    failures = []

    def report(label, ok, got):
        print(f"{'ok  ' if ok else 'FAIL'} {label}: {got}")
        if not ok:
            failures.append(label)

    with tempfile.TemporaryDirectory() as tmp:
        out = os.path.join(tmp, "case.stl")

        for label, defines, want_solids, *want_size in PARTS:
            got = render(openscad, BOX, out, defines)
            if got is None:
                report(label, False, "empty")
                continue
            solids, size, bottom = got
            ok = (solids == want_solids and abs(bottom) <= 0.001
                  and all(abs(a - b) <= 0.01 for a, b in zip(size, want_size)))
            report(label, ok, f"{solids} solids, {' x '.join(f'{s:.2f}' for s in size)} mm, from z = {bottom:.2f}")

        for side, var in SIDES.items():
            want = HOLES[var]
            got = render(openscad, PROBE, out, {**HOLES, "PROBE": f'"{side}"'})
            holes = 0 if got is None else got[0]
            report(f"{side} wall, {var} = {want}", holes == want, f"{holes} holes")

        # The four mounting holes are 3 mm across, junctionbox_mountoffset in
        # from each edge, so together they span 100 - 2 x offset + 3.
        for offset in (20, 25):
            got = render(openscad, PROBE, out, {"PROBE": '"floor"', "junctionbox_mountoffset": offset})
            want_span = 100 - 2 * offset + 3
            ok = got is not None and got[0] == 4 and abs(got[1][0] - want_span) <= 0.01
            report(f"floor, junctionbox_mountoffset = {offset}", ok,
                   "no holes" if got is None else f"{got[0]} holes spanning {got[1][0]:.2f} mm")

        result = subprocess.run([openscad, "-D", 'part="nope"', "-o", out, BOX],
                                capture_output=True, text=True)
        report("unknown part is refused", "must be box, lid, bushing, blocker or none" in result.stderr,
               "assertion" if result.returncode else f"exit {result.returncode}")

    print("all checks passed" if not failures else f"{len(failures)} failed")
    sys.exit(1 if failures else 0)


main()
