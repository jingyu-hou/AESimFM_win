# AESimFM_win Work Handoff

Use this note when continuing the Windows-native solver work in `D:\AESimFM_win`.

## 1. Current Handoff Status

This handoff was prepared from `D:\AESimFM` documentation. No Windows project source files were changed in this pass.

Confirmed local Windows project path:

```text
D:\AESimFM_win
```

Use this exact path spelling in commands and handoffs unless the user explicitly creates a different directory.

Observed `D:\AESimFM_win\docs` currently contains `architecture.md`. The project architecture document already covers Windows CLI, MUMPS/HDF5 direction, process chains, and automatic remesh at a high level, so the documents from this handoff should be merged as supporting requirements rather than copied over the existing architecture blindly.

## 2. Documents Created Or Updated

Source Skill documents in `D:\AESimFM`:

```text
D:\AESimFM\.claude\skills\aesimfm-simulation-maintenance\SKILL.md
D:\AESimFM\.claude\skills\aesimfm-simulation-maintenance\references\architecture.md
D:\AESimFM\.claude\skills\aesimfm-simulation-maintenance\references\windows-solver-interface-contract.md
D:\AESimFM\.claude\skills\aesimfm-simulation-maintenance\references\windows-solver-capability-baseline.md
D:\AESimFM\.claude\skills\aesimfm-simulation-maintenance\references\windows-solver-performance-plan.md
D:\AESimFM\.claude\skills\aesimfm-simulation-maintenance\references\windows-process-chain-state-transfer.md
D:\AESimFM\.claude\skills\aesimfm-simulation-maintenance\references\windows-remesh-architecture.md
D:\AESimFM\.claude\skills\aesimfm-simulation-maintenance\references\aesimfm-win-handoff.md
```

Existing remesh references:

```text
D:\AESimFM\AutoRemesh_Design.md
D:\AESimFM\ExistingRemesh_Summary.md
```

## 3. Recommended Sync Into Windows Project

Suggested target layout:

```text
D:\AESimFM_win\docs\architecture.md
D:\AESimFM_win\docs\solver_api.md
D:\AESimFM_win\docs\capability_baseline.md
D:\AESimFM_win\docs\performance_plan.md
D:\AESimFM_win\docs\process_chain_state_transfer.md
D:\AESimFM_win\docs\remesh_architecture.md
D:\AESimFM_win\docs\handoff_from_AESimFM.md
```

Do not blindly overwrite existing `D:\AESimFM_win\docs` files. Compare first and merge because `D:\AESimFM_win` already contains a docs directory and may have its own newer architecture/API documents.

When merging into `D:\AESimFM_win\docs\architecture.md`, add the DLL-first component rule to the development principles or third-party component section:

```text
Third-party and numerical components should be consumed as DLL dependencies with minimal public headers and manifest records. Static libraries are allowed only as a temporary transition or when dynamic linking is not technically/licensing feasible; record the reason, license, link mode, runtime DLL path, and replacement plan.
```

## 4. First Read Order In AESimFM_win

1. `D:\AESimFM\CLAUDE.md`, especially Windows Native Rules.
2. `D:\AESimFM_win\docs\architecture.md` if present.
3. This handoff.
4. The interface contract.
5. The capability baseline.
6. The performance plan.
7. The process-chain and remesh docs.
8. Existing Windows source build files: `CMakeLists.txt`, `build.ps1`, `src`, `test`.

## 5. Immediate Next Work

Start with documentation alignment, not coding:

1. Compare current `D:\AESimFM_win\docs\architecture.md` with the updated Skill `architecture.md`.
2. Compare current `D:\AESimFM_win\docs\solver_api.md` with `windows-solver-interface-contract.md`.
3. If `h5_format_spec.md` exists, align it with the output/checkpoint parts of the interface and process-chain docs.
4. Create a test matrix from `windows-solver-capability-baseline.md`.
5. Record the exact Windows build command that currently works or fails.

Then implement in phases:

| Phase | Goal | Verification |
|---|---|---|
| 0 | inventory current Windows solver state | build command, executable, supported options |
| 1 | preserve `solver.exe -i jobname` contract | run a minimal INP and write DAT/STA/FRD |
| 2 | WSL capability parity | selected matrix cases match expected WSL outcomes |
| 3 | performance backend | benchmark SPOOLES/MUMPS or selected solver backend |
| 4 | process state package | forge -> heat treatment smoke state transfer |
| 5 | automatic remesh | disk remesh CLI, mapping, restart, solver-triggered loop |

## 6. Guardrails

- Do not port GUI first. Keep solver CLI independent.
- Do not remove FRD while the remesh and validation pipeline still depends on it.
- Do not change Fortran model semantics to make Windows build easier.
- Prefer third-party and numerical components as DLL dependencies with minimal headers and manifests; static libraries are only a documented transition path.
- Do not merge SDV namespaces.
- Do not claim performance improvement without WSL baseline timing.
- Do not accept remesh success from mesh generation alone; field mapping and first post-remesh increment must be checked.
- Do not overwrite Windows docs without diffing existing content.

## 7. Useful Commands

Inspect Windows project:

```powershell
Get-ChildItem D:\AESimFM_win
Get-ChildItem D:\AESimFM_win\docs
Get-Content D:\AESimFM_win\docs\architecture.md -Encoding UTF8
```

Build command pattern from current project rules:

```powershell
& "D:\msys64\usr\bin\bash.exe" -lc "cd /d/AESimFM_win && <command>"
```

Do not install dependencies until local MSYS2, CMake, compilers, and existing project libraries have been checked.
