# AESimFM_win

Windows-native AESimFM solver workspace.

This project is solver-first and CLI-only. The GUI is an external consumer. Every
solver change must be verifiable from PowerShell or the MSYS2 build shell.

## First Read

For any new AI or developer session, read these in order:

1. `AGENTS.md`
2. `docs\architecture.md`
3. `docs\windows_solver_completion_gap_plan.md`
4. Task-specific docs:
   - INP keywords and SDV rules: `docs\inp_keywords_reference.md`
   - CLI contract: `docs\solver_api.md`
   - HDF5/checkpoint format: `docs\h5_format_spec.md`
   - Process chain: `docs\process_chain_guide.md`
   - Remesh architecture: `docs\windows_remesh_architecture.md`
   - Capability baseline: `docs\windows_solver_capability_baseline.md`

## Current Development Direction

The confirmed first-stage target is:

- `SPOOLES + FRD` stable CLI solver baseline first.
- Single-INP CLI solver completion before process-chain or automatic remesh.
- Portable runtime package with required MSYS2/UCRT64 DLLs next to `solver.exe`.
- Globally discoverable `solver` wrapper command so users can run `solver disk`
  from the directory containing `disk.inp`.
- Single-machine multicore support first; cluster/HPC support is a later
  MUMPS/MPI extension target.

Do not claim MUMPS, HDF5, process-chain, automatic remesh, or cluster support
until the corresponding implementation and regression evidence are committed.

## Build Pattern

```powershell
& "D:\msys64\usr\bin\bash.exe" -lc "cd /d/AESimFM_win && cmake -B build -G 'MSYS Makefiles' && cmake --build build -j8"
```

Current generated build state observed during planning:

- `USE_SPOOLES=ON`
- `USE_MUMPS=OFF`
- `OUTPUT_FRD=ON`
- `OUTPUT_HDF5=OFF`
- `ENABLE_AUTO_REMESH=OFF`
- `ENABLE_OPENMP=ON`

Treat those as observed state, not final product promises.
