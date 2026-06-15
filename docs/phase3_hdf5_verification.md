# Phase 3 HDF5 Output Verification Report

Date: 2026-06-15

## Exit Criteria Status

| Criterion | Status | Evidence |
|-----------|--------|----------|
| HDF5 opens with generic reader | PASS | h5dump successfully reads all datasets |
| SDV names/namespaces/descriptions present | PASS | /state/sdv/{names,namespaces,descriptions} populated |
| FRD and HDF5 scalar ranges match within documented tolerance | PASS | Identical values; component 5-6 swap documented |

## 1. HDF5 File Structure

```
/
  ATTRIBUTE format_name     = "AESimFM-H5"
  ATTRIBUTE format_version  = "0.1"
  ATTRIBUTE solver_version  = "AESimFM v2.0"
  ATTRIBUTE source_job      = "<jobname>"
  ATTRIBUTE created_utc     = "<ISO8601>"
  /mesh/
    /nodes/    ids, coordinates
    /elements/ ids, connectivity, material
    /sets/     named element/node sets
  /state/
    /sdv/      names, namespaces, descriptions
  /steps/
    /step_XXXX/
      /inc_XXXXXX/
        ATTRIBUTE time, converged
        /node/U, /node/TEMP
        /integration_point/S, /integration_point/SDV
```

## 2. FRD vs HDF5 Comparison

### 2.1 Test Case: cax4_elastic (linear elastic, 1 CAX4 element)

**Stress components (4 integration points):**

| Component | FRD Index | HDF5 Index | Match |
|-----------|-----------|------------|-------|
| SXX | 1 | 1 | Exact |
| SYY | 2 | 2 | Exact |
| SZZ | 3 | 3 | Exact |
| SXY | 4 | 4 | Exact |
| SYZ | 5 | 6 | Exact (swapped) |
| SZX | 6 | 5 | Exact (swapped) |

**Component ordering convention:**
- FRD (CalculiX): SXX, SYY, SZZ, SXY, SYZ, SZX
- HDF5 (Abaqus internal): SXX, SYY, SZZ, SXY, SXZ, SYZ

The HDF5 writer stores data directly from the Fortran `sti` array, which uses Abaqus convention (SXZ before SYZ). The FRD output reorders to CalculiX convention (SYZ before SZX). The values are identical — readers should swap components 5 and 6 when comparing FRD stress with HDF5 stress.

**Tolerance:** Values are bit-identical for components 1-4. Components 5-6 are identical after accounting for the convention swap. No floating-point differences observed.

### 2.2 Test Case: phase_ttt_minimal (phase transition, 1 element)

- H5 size: 7,893 bytes
- SDV dataset: (1, 40) — 5 state variables * 8 integration points
- Temperature: (8,) — present (ithermal active)
- SDV metadata: 5 entries populated

### 2.3 Test Case: srx_minimal (forging with DRX/SRX)

- H5 size: 27,280 bytes
- 2 steps, multiple increments
- SDV metadata: 50 entries populated (full forging + creep_softening namespace)
- Covers SDV 1-43 (forging/recrystallization) and SDV 44-50 (creep_softening)

## 3. SDV Metadata

The `/state/sdv/` group contains three parallel arrays indexed by SDV number:

- `names` (H5T_STRING, 32 chars): Machine-readable SDV identifier
- `namespaces` (H5T_STRING, 48 chars): Domain namespace
- `descriptions` (H5T_STRING, 72 chars): Human-readable description

**Namespaces covered:**
- `forging/recrystallization` — SDV 1-43 (plasticity, DRX, SRX/MRX, grain growth)
- `creep_softening` — SDV 44-53 (creep strain, softening, relaxation)

**Note:** Heat treatment (`heat_treatment/phase_transition`) and porous forming (`porous_forming/densification`) namespaces use different SDV index mappings. The current implementation defaults to the forging namespace. Namespace-aware metadata selection is deferred to future work.

## 4. Connectivity Fix

**Before:** `max_nc` calculated using `start + 27` fallback for the last element, overestimating connectivity width.
**After:** Uses `nkon + 1` (actual kon array bound) for the last element's end index.

| Test case | Before | After |
|-----------|--------|-------|
| cax4_elastic (1 elem) | (1, 27) | (1, 13) |

The 13 entries for cax4_elastic represent: 8 expanded C3D8 nodes + 4 original CAX4 nodes + 1 zero-pad.

## 5. Known Limitations

1. **SDV namespace detection**: Currently defaults to forging namespace. Heat treatment and porous forming cases use forging labels. Future: detect active namespace from material model keywords.
2. **Stress component order**: HDF5 stores SXZ-before-SYZ (Abaqus convention). Readers must swap components 5 and 6 when comparing with FRD.
3. **Crash-on-exit**: Solver crashes with signal 11 during Fortran cleanup (pre-existing, not HDF5-specific). HDF5 data is flushed via signal handler.
