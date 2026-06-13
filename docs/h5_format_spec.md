# HDF5 Format Specification

This document defines the planned AESimFM Windows-native HDF5 result/checkpoint format. FRD remains the legacy compatibility output until this format is fully validated against current WSL results and remesh consumers.

## 1. Goals

The HDF5 format must:

1. Reduce output size and write time compared with ASCII FRD.
2. Preserve a one-to-one mapping to legacy result names where possible.
3. Store enough state for process chains, restart, and automatic remesh.
4. Be readable without GUI dependencies.
5. Carry version, units, solver settings, and provenance.

## 2. File Naming

Default result file:

```text
jobname.h5
```

Optional state/checkpoint package:

```text
jobname_state.h5
```

During transition, the solver may write both:

```text
jobname.frd
jobname.h5
```

## 3. Top-Level Layout

```text
/
  attrs:
    format_name = "AESimFM-H5"
    format_version = "0.1"
    solver_version
    source_job
    created_utc
    units
    command_line

  /mesh
    /nodes
    /elements
    /sets
    /surfaces

  /steps
    /step_0001
      attrs: type, time_start, time_end
      /inc_000001
        attrs: time, dt, converged, iterations
        /node
        /element
        /integration_point

  /state
    /sdv
    /material
    /process
    /restart

  /logs
    sta
    dat_summary
    warnings

  /provenance
    input_deck
    includes
    build
    dependencies
```

## 4. Mesh Groups

### `/mesh/nodes`

Datasets:

| Dataset | Shape | Type | Notes |
|---|---:|---|---|
| `ids` | `[nnode]` | int64 | original node ids |
| `coordinates` | `[nnode,3]` | float64 | initial or current reference coordinates |

### `/mesh/elements`

Datasets:

| Dataset | Shape | Type | Notes |
|---|---:|---|---|
| `ids` | `[nelem]` | int64 | original element ids |
| `type` | `[nelem]` | string or enum | e.g. `CAX4R`, `C3D8` |
| `connectivity` | variable or padded | int64 | node ids or node indices; document choice in attrs |
| `material` | `[nelem]` | string or int | material assignment |

### `/mesh/sets` And `/mesh/surfaces`

Required named sets for remesh and process chains:

- `ALLOY_NODE`
- `ALLOY_ELEMENT`
- `ALLOY_SURF` when present

Store both names and membership arrays. Preserve original case.

## 5. Result Naming

Use stable names. Do not expose only internal Fortran variable names.

| Legacy/Concept | HDF5 name | Location |
|---|---|---|
| displacement | `U` | node |
| temperature | `TEMP` | node |
| stress | `S` | integration point or element |
| strain | `E` | integration point or element |
| equivalent plastic strain | `PEEQ` | integration point |
| state variables | `SDV` | integration point |
| phase fractions | `PHASE` or named SDV mapping | integration point |
| grain size | `GRAIN_SIZE` or named SDV mapping | integration point |
| hardness | `HARDNESS` | integration point or element |

Each dataset must have attributes:

```text
units
location
components
source_legacy_label
valid_min
valid_max
```

## 6. Increment Layout

Example:

```text
/steps/step_0001/inc_000010/node/U
/steps/step_0001/inc_000010/node/TEMP
/steps/step_0001/inc_000010/integration_point/S
/steps/step_0001/inc_000010/integration_point/SDV
```

Increment attributes:

| Attribute | Meaning |
|---|---|
| `time` | total analysis/process time |
| `step_time` | time within current step |
| `dt` | increment size |
| `converged` | boolean |
| `iterations` | nonlinear iterations |
| `cutbacks` | cutback count |
| `remesh_index` | remesh count active at this increment |

## 7. SDV Metadata

SDV values are not enough. Store names and namespaces:

```text
/state/sdv/names
/state/sdv/namespaces
/state/sdv/descriptions
```

Required namespace separation:

- forging/recrystallization,
- heat treatment/phase transition,
- porous forming,
- creep softening,
- remesh/restart metadata if added.

If a dataset stores raw `SDV[:, n]`, it must also store a mapping table that tells downstream tools what each index means.

## 8. Restart And Process Chain State

For restart-capable HDF5, store:

- mesh and set definitions,
- last converged increment,
- temperature,
- stress,
- strain/plastic strain,
- SDV with metadata,
- material parameters needed by continuation,
- process-chain step id,
- boundary/contact reset requirements.

Do not mark a file restart-capable unless all required fields for the next process are present and validated.

## 9. Remesh Support

Remesh metadata:

```text
/state/remesh
  attrs:
    remesh_count
    last_trigger_reason
    min_jacobian
    old_node_count
    new_node_count
    old_element_count
    new_element_count
```

For mapped fields, store mapping report:

```text
/state/remesh/mapping_report
```

The report must include min/max before and after mapping for temperature, stress, and SDV fields used by the next step.

## 10. Compression

Preferred compression:

- zstd when available and packaged,
- gzip as portable fallback,
- uncompressed allowed for debugging.

The file must record compression in dataset attributes or file metadata.

## 11. Validation Checklist

For every HDF5 writer change:

1. File opens with a generic HDF5 reader.
2. Top-level `format_name` and `format_version` exist.
3. Mesh node/element counts match solver memory.
4. Result dataset shapes match node/element/integration-point counts.
5. SDV count and metadata match solver model.
6. Legacy FRD and HDF5 scalar ranges are compared on at least one smoke case.
7. Process-chain/restart fields are either complete or explicitly marked unavailable.

