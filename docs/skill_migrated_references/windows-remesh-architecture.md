# Windows Remesh Architecture

This document adapts `D:\AESimFM\AutoRemesh_Design.md` and `D:\AESimFM\ExistingRemesh_Summary.md` into the Windows-native solver migration plan.

## 1. Current Evidence

Existing manual remesh behavior:

- Manual chain: WeICME GUI -> RMesh.exe -> gmsh.exe -> Abaqus/CAE repair -> WeICME GUI restart.
- RMesh extracts deformed surface and field files from FRD.
- Generated field files include `.TEMP`, `.STRESS`, `.SDV`, `.DISP`, then mapped `.nt`, `.st`, `.stdv`.
- `disk-remeshed.inp` is a mesh/intermediate file and may not contain a complete analysis step.
- `disk-restart.inp` is the restart input assembled from old tooling, new billet mesh, mapped fields, and remaining step definition.

Target automatic remesh behavior:

- The solver detects mesh distortion.
- The solver writes a checkpoint and remesh signal.
- A CLI remesh pipeline runs without GUI interaction.
- Fields are mapped to the new mesh.
- The solver resumes from the new mesh/state without requiring the user to restart manually.

## 2. Windows-Specific Principle

Automatic remesh is part of solver capability, but it should be modular:

```text
solver.exe
  -> detects distortion
  -> writes checkpoint/state
  -> calls remesh CLI or internal remesh library
  -> validates remeshed mesh and mapped fields
  -> resumes or fails with preserved checkpoint
```

Avoid hard-binding to a Python-only runtime if the long-term Windows product needs simple deployment. A Python orchestrator is acceptable for early implementation, but define a stable CLI so it can later be replaced by a native executable or library.

## 3. Remesh CLI Contract

Minimum CLI:

```powershell
.\remesh_orchestrator.exe --job disk --input disk.inp --state disk_state --config remesh.json
```

Python prototype equivalent:

```powershell
python remesh_orchestrator.py disk --config remesh.json
```

Inputs:

- original or current INP,
- current FRD or native checkpoint,
- remesh signal/config,
- workpiece element set name,
- tooling geometry or mesh,
- field list to map.

Outputs:

- remeshed mesh,
- mapped fields,
- restart/state package,
- remesh report JSON,
- optional legacy `disk-remeshed.inp`, `disk-restart.inp`, `.nt`, `.st`, `.stdv`.

Exit codes:

| Code | Meaning |
|---:|---|
| 0 | remesh success |
| 1 | input/config error |
| 2 | surface extraction failed |
| 3 | mesh generation failed |
| 4 | field mapping failed |
| 5 | validation failed |

## 4. Trigger Rules

Supported triggers:

- minimum Jacobian below threshold,
- element aspect ratio above threshold,
- repeated nonlinear cutbacks,
- contact penetration or severe surface distortion,
- user-specified maximum increment interval,
- manual trigger for testing.

Every trigger must write the reason and measured values to `.sta` and the remesh report.

## 5. Mesh Generation Strategy

The existing design prefers TetGen for 3D tetrahedral remeshing because it is CLI-friendly and avoids manual Abaqus repair. For Windows migration, keep the engine abstract:

| Engine | Role |
|---|---|
| existing Gmsh/RMesh chain | historical compatibility and file-format reference |
| TetGen | first 3D CLI candidate |
| Gmsh CLI | fallback/prototype, especially for 2D |
| future native mesher | long-term product option |

Do not make the solver depend on a GUI mesh repair step.

## 6. Field Mapping

Required mapped fields:

- temperature,
- displacement or deformed coordinates,
- stress,
- plastic strain and equivalent plastic strain,
- SDV namespaces for forging, heat treatment, porous media, and creep softening,
- phase fractions and grain-size related state when active,
- carbon concentration when carburizing support is added.

Mapping validation:

| Check | Requirement |
|---|---|
| Node/element count | report old/new counts |
| Mesh quality | no invalid Jacobian or degenerate elements |
| Temperature | min/max within physical tolerance |
| Phase fractions | bounded and sum-valid |
| SDV | count and namespace match next solver step |
| Volume | change within documented tolerance; existing target is less than 3% |
| Restart | first post-remesh increment converges on smoke case |

## 7. 2D And 3D

Do not design only for the current 2D `disk` case.

| Dimension | Initial route |
|---|---|
| 2D axisymmetric | preserve current disk remesh conventions, support CAX elements |
| 3D | TetGen/native tetrahedral route first |
| Hex-dominant | future work; do not block tetrahedral route |

2D and 3D can share orchestration, checkpoint, field mapping, logging, and validation. They may use different mesh generators.

## 8. Failure Handling

On remesh failure:

1. Stop before corrupting in-memory solver state.
2. Preserve pre-remesh checkpoint.
3. Write `REMESH_FAILED` to `.sta`.
4. Write a report JSON with reason and file paths.
5. Return nonzero from solver unless configured for a documented fallback.

Do not continue with a partially remeshed or partially mapped state.

## 9. Acceptance

Minimum acceptance:

- Manual remesh reference files are parsed and understood.
- A remesh CLI can produce a report for the disk case.
- Field mapping writes complete temperature/stress/SDV output.
- The restart input/state passes parser validation.

Product acceptance:

- Solver-triggered remesh occurs without GUI intervention.
- Solver resumes after remesh.
- More than one remesh cycle is supported.
- First post-remesh increment convergence rate is measured.
- Remesh overhead and volume preservation meet the performance plan.

