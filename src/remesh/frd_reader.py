"""
FRD file parser for CalculiX/WeICME result files.
Format: structured text with 2-character record type IDs.
"""
import os
import struct
import numpy as np


class FrdData:
    """Container for parsed FRD data."""
    def __init__(self):
        self.user_header = {}       # {key: value}
        self.nodes = {}             # {node_id: (x, y, z)} original coords
        self.deformed_nodes = {}    # {node_id: (x, y, z)} last-step deformed coords
        self.elements = []          # [(elem_id, elem_type, [node_ids])]
        self.steps = []             # list of StepResult

    def get_node_count(self):
        return len(self.nodes)

    def get_element_count(self):
        return len(self.elements)


class StepResult:
    """Container for one output step."""
    def __init__(self):
        self.step_num = 0
        self.inc_num = 0
        self.time_val = 0.0
        self.num_nodes = 0
        self.attr_name = ""     # DISP, STRESS, NDTEMP, FLUX, etc.
        self.attr_num = 0       # components per node
        self.component_names = []  # ["SXX","SYY",...] or ["T"]
        self.data = {}          # {node_id: [values]}


def _read_line_simplified(f):
    """Read next non-empty line, strip trailing whitespace but keep leading spaces."""
    while True:
        line = f.readline()
        if not line:
            return ""
        s = line.rstrip('\r\n')
        if s:
            return s


def _parse_frd_line(line):
    """Split an FRD data line by spaces, handling the fixed-width format.
    Returns list of tokens."""
    return line.split()


def parse_frd(filepath):
    """Parse a CalculiX .frd file. Returns FrdData object."""
    with open(filepath, 'r', encoding='utf-8', errors='replace') as f:
        return _parse_frd_stream(f)


def _parse_frd_stream(f):
    data = FrdData()

    # --- Model Header (1C) ---
    line = _read_line_simplified(f)
    if not line.startswith('1C'):
        raise ValueError(f"Expected '1C' model header, got: {line[:20]}")
    # skip 1C line content

    # --- User Headers (1U) until 2C ---
    while True:
        line = _read_line_simplified(f)
        if line.startswith('2C'):
            break
        if line.startswith('1U'):
            rest = line[2:].strip()
            # key is first word, value is rest
            parts = rest.split(None, 1)
            if len(parts) >= 1:
                key = parts[0]
                val = parts[1] if len(parts) > 1 else ""
                data.user_header[key] = val

    # --- Nodal Points (2C) ---
    tokens = _parse_frd_line(line)
    if len(tokens) < 3:
        raise ValueError(f"Invalid 2C header: {line}")
    num_nodes = int(tokens[1])
    node_format = int(tokens[2])

    line = _read_line_simplified(f)
    while line.startswith('-1'):
        tokens = _parse_frd_line(line)
        if len(tokens) >= 4:
            nid = int(tokens[0])
            x = float(tokens[1])
            y = float(tokens[2])
            z = float(tokens[3])
            data.nodes[nid] = (x, y, z)
        line = _read_line_simplified(f)
    # line should be '-3' ending node section

    # --- Element Blocks (3C) ---
    line = _read_line_simplified(f)
    if not line.startswith('3C'):
        raise ValueError(f"Expected '3C' element header, got: {line[:20]}")
    tokens = _parse_frd_line(line)
    num_blocks = int(tokens[1])
    elem_format = int(tokens[2])

    current_elem_id = 0
    current_elem_type = 0
    current_elem_grp = 0
    current_elem_mat = 0

    line = _read_line_simplified(f)
    while not line.startswith('-3'):
        tokens = _parse_frd_line(line)

        if line.startswith('-1'):
            if len(tokens) >= 5:
                current_elem_id = int(tokens[1])
                current_elem_type = int(tokens[2])
                current_elem_grp = int(tokens[3])
                current_elem_mat = int(tokens[4])

        elif line.startswith('-2'):
            node_ids = []
            for t in tokens[1:]:
                node_ids.append(int(t))
            # Check if there's a continuation line (element type 4/5 = 2-line connectivity)
            if current_elem_type in (4, 5):
                pos = f.tell()
                next_line = _read_line_simplified(f)
                next_tokens = _parse_frd_line(next_line)
                if next_tokens and next_tokens[0].lstrip('-').isdigit():
                    for t in next_tokens:
                        node_ids.append(int(t))
                else:
                    # Not a continuation, rewind
                    f.seek(pos)
            data.elements.append((current_elem_id, current_elem_type, node_ids))

        line = _read_line_simplified(f)
    # line is '-3'

    # --- Result Steps ---
    line = _read_line_simplified(f)
    if not line:
        return data

    while line != '9999':
        if not line.startswith('1P'):
            line = _read_line_simplified(f)
            if not line:
                break
            continue

        # 1PSTEP step_num total_steps inc_num last-digit
        tokens = _parse_frd_line(line)
        if len(tokens) < 4:
            line = _read_line_simplified(f)
            continue

        step = StepResult()
        step.step_num = int(tokens[2])
        step.inc_num = int(tokens[3])

        # 100C header
        line = _read_line_simplified(f)
        if not line or not line.startswith('100C'):
            line = _read_line_simplified(f)
            continue

        tokens = _parse_frd_line(line)
        if len(tokens) < 7:
            line = _read_line_simplified(f)
            continue

        step.time_val = float(tokens[2])
        step.num_nodes = int(tokens[3])
        result_format = int(tokens[6])

        # -4 attribute header
        line = _read_line_simplified(f)
        if not line.startswith('-4'):
            line = _read_line_simplified(f)
            continue

        tokens = _parse_frd_line(line)
        if len(tokens) < 3:
            line = _read_line_simplified(f)
            continue

        step.attr_name = tokens[1]

        # STRESS gets 5 additional derived quantities (Mises, principal stresses, hydrostatic)
        if step.attr_name == "STRESS":
            step.attr_num = int(tokens[2]) + 5
        elif step.attr_name == "TOSTRAIN":
            step.attr_num = int(tokens[2]) + 1
        else:
            step.attr_num = int(tokens[2])

        # -5 component headers (one per real component)
        line = _read_line_simplified(f)
        real_comps = step.attr_num
        if step.attr_name == "STRESS":
            real_comps -= 5
        elif step.attr_name == "TOSTRAIN":
            real_comps -= 1

        while line.startswith('-5'):
            tokens = _parse_frd_line(line)
            if len(tokens) >= 2:
                step.component_names.append(tokens[1])
            line = _read_line_simplified(f)

        # -1 data records
        data_count = 0
        while line.startswith('-1') and data_count < step.num_nodes:
            tokens = _parse_frd_line(line)
            if len(tokens) >= 2:
                nid = int(tokens[0])
                values = [float(t) for t in tokens[1:]]
                # Pad or truncate to match attr_num
                while len(values) < step.attr_num:
                    values.append(0.0)
                values = values[:step.attr_num]
                step.data[nid] = values
                data_count += 1

            pos = f.tell()
            line = _read_line_simplified(f)
            if not line:
                break

        data.steps.append(step)

    # Build deformed nodes from last step's DISP data
    _build_deformed_nodes(data)

    return data


def _build_deformed_nodes(data):
    """Apply last DISP step to get deformed coordinates."""
    last_disp = None
    for step in reversed(data.steps):
        if step.attr_name == "DISP":
            last_disp = step
            break

    if last_disp is None:
        data.deformed_nodes = dict(data.nodes)
        return

    for nid, coords in data.nodes.items():
        if nid in last_disp.data:
            disp = last_disp.data[nid]
            dx = disp[0] if len(disp) > 0 else 0.0
            dy = disp[1] if len(disp) > 1 else 0.0
            dz = disp[2] if len(disp) > 2 else 0.0
            data.deformed_nodes[nid] = (
                coords[0] + dx,
                coords[1] + dy,
                coords[2] + dz
            )
        else:
            data.deformed_nodes[nid] = coords


def get_last_step_stress(data):
    """Get stress from the last STRESS step, returned as {node_id: [SXX,SYY,SZZ,SXY,SYZ,SZX]}"""
    for step in reversed(data.steps):
        if step.attr_name == "STRESS":
            return step.data
    return {}


def get_last_step_temperature(data):
    """Get temperature from the last NDTEMP step."""
    for step in reversed(data.steps):
        if step.attr_name == "NDTEMP":
            return step.data
    return {}


def get_last_step_state_vars(data):
    """Get state variables from the last SDV step."""
    for step in data.steps:
        if "SDV" in step.attr_name.upper() or "SOLUTION" in step.attr_name.upper():
            pass  # scan for SDV
    # Try to find by component name
    for step in reversed(data.steps):
        for comp in step.component_names:
            if comp.upper().startswith("SDV"):
                return step.data
    return {}


if __name__ == "__main__":
    import sys
    if len(sys.argv) < 2:
        print("Usage: python frd_reader.py <file.frd>")
        sys.exit(1)

    frd = parse_frd(sys.argv[1])
    print(f"Nodes: {frd.get_node_count()}")
    print(f"Elements: {frd.get_element_count()}")
    print(f"Steps: {len(frd.steps)}")
    for s in frd.steps:
        print(f"  Step {s.step_num} Inc {s.inc_num}: {s.attr_name} "
              f"({s.attr_num} comps) time={s.time_val:.1f} n={s.num_nodes}")
    print(f"Deformed nodes: {len(frd.deformed_nodes)}")
