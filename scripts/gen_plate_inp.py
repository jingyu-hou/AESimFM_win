"""Generate a multi-element plate tension INP file."""
n = 10       # elements per side
h = 0.01     # thickness
L = 1.0      # plate side
out = "D:/AESimFM_win/test/inputs/plate_tension.inp"

lines = []
lines.append("*HEADING")
lines.append(f"{n}x{n} C3D8R plate tension")
lines.append("*NODE")

node_id = 1
for k in range(2):   # z=0 and z=h layers
    z = k * h
    for j in range(n + 1):
        for i in range(n + 1):
            x = i * L / n
            y = j * L / n
            lines.append(f"{node_id}, {x:.6f}, {y:.6f}, {z:.6f}")
            node_id += 1

total_nodes = node_id - 1
nxy = n + 1
offset2 = nxy * nxy

lines.append("*ELEMENT, TYPE=C3D8R, ELSET=EALL")
elem_id = 1
for j in range(n):
    for i in range(n):
        n00 = j * nxy + i + 1
        n10 = j * nxy + i + 2
        n11 = (j + 1) * nxy + i + 2
        n01 = (j + 1) * nxy + i + 1
        t00 = n00 + offset2
        t10 = n10 + offset2
        t11 = n11 + offset2
        t01 = n01 + offset2
        lines.append(f"{elem_id}, {n00}, {n10}, {n11}, {n01}, {t00}, {t10}, {t11}, {t01}")
        elem_id += 1

total_elems = elem_id - 1

# Node sets
left_bot = [j * nxy + 1 for j in range(n + 1)]
left_top = [nid + offset2 for nid in left_bot]
left_all = left_bot + left_top
right_bot = [j * nxy + n + 1 for j in range(n + 1)]
right_top = [nid + offset2 for nid in right_bot]
right_all = right_bot + right_top

def nset_lines(name, ids):
    lines_out = [f"*NSET, NSET={name}"]
    for chunk in range(0, len(ids), 16):
        lines_out.append(", ".join(str(x) for x in ids[chunk:chunk+16]))
    return lines_out

lines.extend(nset_lines("NLEFT", left_all))
lines.extend(nset_lines("NRIGHT", right_all))

lines.append("*MATERIAL, NAME=MA1")
lines.append("*ELASTIC")
lines.append("210e9, 0.3")
lines.append("*SOLID SECTION, ELSET=EALL, MATERIAL=MA1")

lines.append("*BOUNDARY")
for nid in left_all:
    lines.append(f"{nid}, 1, 1, 0.0")
    lines.append(f"{nid}, 3, 3, 0.0")
for nid in right_all:
    lines.append(f"{nid}, 1, 1, 0.002")
    lines.append(f"{nid}, 3, 3, 0.0")

lines.append("*STEP")
lines.append("*STATIC")
lines.append("*NODE FILE")
lines.append("U")
lines.append("*EL FILE")
lines.append("S")
lines.append("*END STEP")

with open(out, "w") as f:
    f.write("\n".join(lines))

print(f"Generated {out}: {total_nodes} nodes, {total_elems} elements")
