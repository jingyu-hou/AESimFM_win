# Windows Solver Capability Baseline

This document defines what the Windows-native solver must preserve from the current WSL solver before it can be considered an upgrade.

## 1. Baseline Principle

Windows migration is not successful when the code merely compiles on Windows. It is successful only when the Windows solver:

1. Runs the current WSL solver's accepted input classes.
2. Produces equivalent legacy outputs for the same short cases.
3. Preserves AESimFM model semantics and SDV layout.
4. Improves performance on agreed benchmark cases.
5. Adds a path for process chaining and automatic remeshing without breaking single-process runs.

## 2. Source Of Truth

Use these inputs before claiming capability parity:

| Source | Purpose |
|---|---|
| `D:\AESimFM\code\test\all\solver` | current WSL solver source baseline |
| `D:\AESimFM\solver_source_classification.csv` | source ownership and model inventory |
| `D:\AESimFM\inp_test_batch_results.json` | current known INP run outcomes |
| `D:\AESimFM\INP_test_repair_report.md` | known valid/invalid input conclusions |
| `D:\AESimFM\AutoRemesh_Design.md` | target automatic remesh design |
| `D:\AESimFM\ExistingRemesh_Summary.md` | existing manual remesh behavior and file formats |

Do not infer support from file names alone. Verify through parser paths, material dispatch, build linkage, and at least one short run.

## 3. Required Functional Areas

| Area | Windows parity requirement |
|---|---|
| Static/nonlinear solve | at least current valid WSL short cases finish |
| Thermal and coupled thermal-mechanical input | existing heat-treatment/forging keywords parse and run where WSL runs |
| Dynamic recrystallization | existing DRX path and SDV layout preserved |
| SRX/MRX | `rdplas.f -> drx.f -> srx_mrx_k90.f` behavior preserved |
| TTT/CCT phase transition | `thermmodel.f -> phasetransition.f` behavior preserved |
| Powder/porous forming | current porosity/densification state preserved |
| Creep softening | independent and powder-coupled SDV namespaces preserved |
| Legacy output | FRD/DAT/STA remain available |
| Restart | current restart-compatible cases remain restartable |
| Remesh inputs | `disk.frd`, `disk-remeshed.inp`, `disk-restart.inp`, `.nt`, `.st`, `.stdv` conventions understood |

## 4. SDV And Model Namespace Rules

Windows migration must not merge SDV namespaces casually. Keep separate namespaces for:

- forging/recrystallization,
- heat treatment/phase transition,
- porous media/densification,
- creep softening,
- remesh/restart mapping metadata if added.

Any change to SDV numbering requires:

1. A mapping table.
2. FRD output label update.
3. Restart migration rule.
4. Regression on old cases.

## 5. Baseline Test Matrix

Create or maintain a machine-readable test matrix with these columns:

```text
case_id
source_inp
process_type
element_types
keywords_under_test
expected_wsl_status
expected_windows_status
must_write_frd
must_write_dat
must_write_sta
sdv_labels_checked
numeric_tolerance
runtime_baseline_seconds
runtime_windows_seconds
notes
```

Minimum starter set:

| Case class | Required purpose |
|---|---|
| `disk.inp` | forging + DRX/TTT smoke and legacy GUI-compatible run |
| remesh `disk-restart.inp` | restart/remesh file compatibility |
| minimal CAX elements | element parser and output smoke |
| minimal C3D elements | 3D element parser and output smoke |
| CREEP_SOFTENING minimal | creep SDV namespace |
| SRX/MRX minimal | recrystallization conversion path |
| heat treatment minimal | phase transition and thermal state |
| porous/HIP minimal | powder and porosity state |

## 6. Equivalence Criteria

For smoke migration:

- Exit status matches WSL for cases expected to run.
- FRD exists and contains requested fields.
- DAT contains no new fatal warning class.
- No NaN, Inf, or segmentation fault.
- Key scalar ranges are within tolerance, not necessarily bitwise identical.

For release-quality migration:

- Same physical trend on benchmark cases.
- Same SDV meaning and result labels.
- Restart state survives process boundary.
- Remesh and process chaining do not corrupt fields.
- Performance targets in `windows-solver-performance-plan.md` are met or documented as deferred.

