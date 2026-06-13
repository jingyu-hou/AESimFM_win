# Windows Solver Completion Gap Plan

This document records the current gap between the existing `D:\AESimFM_win`
workspace and a complete Windows-native AESimFM solver. It is based on local
inspection on 2026-06-12.

## 1. Current Confirmed State

| Area | Current state | Evidence |
|---|---|---|
| Repository | Git initialized, files not yet committed | `.git` exists; `git status` shows untracked project files |
| Build artifact | `solver.exe` exists | `build\src\solver\solver.exe` |
| Actual CMake config | SPOOLES ON, MUMPS OFF, HDF5 OFF, FRD ON, auto-remesh OFF, OpenMP ON | `build\CMakeCache.txt` |
| Source layout | Solver source present; remesh has only one source file | `src\solver`, `src\remesh` |
| Test tree | `test` has no committed test inputs or runner | `test` directory contains no files |
| Ad-hoc run output | A `disk` run output exists under `test_run` | `disk.inp`, `.frd`, `.sta`, `.cvg`, `.dat`, `spooles.out` |
| Runtime dependency | `solver.exe` requires MSYS2 UCRT64 DLLs on PATH | `ldd` reports missing `libgfortran-5.dll`, `libgcc_s_seh-1.dll`, `libgomp-1.dll`, `libwinpthread-1.dll` without MSYS2 path |
| CLI | Legacy `-i`, `-v`, `-o` path exists; `--help`/`--version` are not implemented | `src\solver\solver.c` |
| Documentation | Main architecture, keyword reference, HDF5 spec, solver API, remesh/process docs exist | `docs\*.md` |

## 2. Immediate Blocking Gaps

These are blockers before claiming the Windows solver is deliverable.

| Priority | Gap | Why it blocks completion | Proposed fix |
|---|---|---|---|
| P0 | No committed smoke test deck or runner | Current success depends on `test_run`, which is generated/ad-hoc | Move a minimal accepted deck into `test\inputs`; add `test\run_tests.ps1` or Python runner |
| P0 | Runtime DLL discovery is not packaged | Bare PowerShell execution fails unless MSYS2 UCRT64 is on PATH | Add a run wrapper, dependency check script, and packaging/copy-DLL policy |
| P0 | CLI contract and implementation differ | Docs require `--help`/`--version`; code only has `-v` and weak argument handling | Implement stable CLI shim while preserving legacy `-i jobname` |
| P0 | Build defaults conflict | `build.ps1` says default MUMPS/HDF5, but CMake defaults SPOOLES/FRD | Decide default target and align script, CMake, docs |
| P0 | No automated pass/fail criteria | Existing `disk` outputs are not automatically checked | Check exit code, `.sta`, `.frd` EOF, `.dat`/log errors, selected SDV/result ranges |

## 3. Feature Completion Gaps

These are required for the full Windows v2.0 architecture, but can be staged.

| Area | Current gap |
|---|---|
| MUMPS backend | CMake option exists, but no imported MUMPS library configuration or verified build path was observed |
| HDF5 output | Spec exists, `OUTPUT_HDF5` option exists, but no active HDF5 writer integration was verified |
| Process chain | Design docs exist, but no chain runner, JSON parser, or state package implementation was verified |
| Auto remesh | Design docs exist and `ENABLE_AUTO_REMESH` option exists, but build config is OFF and no end-to-end remesh test exists |
| SDV metadata | SDV namespace rules are documented, but no machine-readable metadata file or HDF5 mapping implementation is verified |
| Element matrix | Docs list CAX/C3D families, but committed minimal cases and regression results are missing |
| Keyword matrix | Parser contains AESimFM extensions, but no automated keyword smoke suite exists |
| Packaging | No release layout, DLL manifest, or install/run script was verified |
| Baseline comparison | No recorded WSL-vs-Windows result comparison table is committed |

## 4. Recommended Work Order

### Phase 0: Freeze The Current Baseline

Goal: make the current working solver reproducible.

1. Commit the current imported source, docs, build scripts, and library layout.
2. Add a dependency check that reports missing MSYS2 runtime DLLs.
3. Add a packaging step that copies the required MSYS2/UCRT64 runtime DLLs next to `solver.exe`.
4. Add a globally discoverable user-facing wrapper command named `solver` so users can run `solver disk` from the INP directory.
5. Move one short `disk` smoke input into `test\inputs`.
6. Add a smoke test runner that builds nothing first; it only runs the packaged solver and checks outputs.

Exit criteria:

- A fresh shell can run `solver disk` from the INP directory and produce `.sta`, `.frd`, `.cvg`.
- The test runner returns nonzero on missing DLLs, missing input, missing FRD EOF, or solver crash.

### Phase 1: Align CLI And Build Contracts

Goal: make docs and executable behavior match.

1. Add `--help` and `--version` while preserving `-i`, `-v`, and legacy positional job name.
2. Validate argument errors before opening files.
3. Decide whether the default build is `SPOOLES+FRD` or `MUMPS+HDF5`.
4. Update `build.ps1`, `CMakeLists.txt`, `docs\solver_api.md`, and `docs\architecture.md` to match.

Exit criteria:

- `solver.exe --help` prints usage and returns success.
- `solver.exe --version` prints a version string and returns success.
- Bad arguments fail clearly without crashing.

### Phase 2: Build The Regression Matrix

Goal: stop relying on one disk run.

1. Add element smoke cases for CAX and C3D families.
2. Add keyword smoke cases for:
   - `*RATE-DEPENDENTPLASTIC`
   - `*DYNAMICRECRYSTALLIZATION`
   - `*CREEP-SOFTENING`
   - `*PHASECURVE` and companion `*PHASE*` keywords
3. Add SDV namespace checks for forging, heat treatment, and porous forming.
4. Add FRD parsing checks that handle adjacent scientific notation fields.

Exit criteria:

- Test output states which element/keyword/process passed or failed.
- C3D20R is tested directly and not inferred from C3D8R.
- SDV labels are interpreted by namespace, not by global index alone.

### Phase 3: Implement Modern Output/State

Goal: make HDF5/checkpoint real, not just documented.

1. Add HDF5 dependency configuration.
2. Implement HDF5 writer for mesh, sets, increments, and SDV metadata.
3. Compare HDF5 ranges with FRD on at least one smoke case.
4. Define restart-capable state package fields.

Exit criteria:

- HDF5 opens with a generic reader.
- SDV names/namespaces/descriptions are present.
- FRD and HDF5 selected scalar ranges match within a documented tolerance.

### Phase 4: Add Process Chain And Remesh

Goal: close the v2.0 workflow promises.

1. Implement process-chain JSON parsing.
2. Write and validate state packages between steps.
3. Implement remesh trigger and stable remesh CLI contract.
4. Verify field mapping and first post-remesh increment.

Exit criteria:

- A forge -> heat treatment or rough -> finish chain runs from one command.
- Remesh failure preserves the pre-remesh checkpoint and exits clearly.
- A successful remesh resumes and converges at least one increment.

## 5. User Decisions Recorded

The following requirements were confirmed by the user before implementation work:

| Decision | Confirmed requirement |
|---|---|
| First delivery target | `SPOOLES + FRD` stable baseline first. MUMPS/HDF5 remains a later performance/output target. |
| First regression input source | Use the current `test_run\disk.inp` and/or copy from `D:\AESimFM\inp\disk.inp`; do not start with synthetic smoke decks unless the real disk case is too slow or unstable for short regression. |
| Completion scope for this stage | CLI single-INP solver first. Process chain and automatic remesh are later stages and are not required before declaring this stage complete. |
| Runtime packaging style | Copy the required MSYS2/UCRT64 runtime DLLs next to `solver.exe` for a portable solver package. Do not require users to type or manage `D:\msys64\ucrt64\bin` in normal use. |
| User command discoverability | Provide a globally discoverable wrapper command named `solver`, preferably under `C:\Users\12725\.local\bin` or another user PATH directory, so PowerShell can find it from any INP working directory. |
| Thread count behavior | Solver thread count should default to either the running machine's available logical CPU count or a conservative default. Users can explicitly set it with `solver --threads N`. The accepted upper bound must not exceed the available logical CPU count on the current machine. If `N` exceeds that bound, the solver must either warn and clamp to the maximum available value or fail with a clear error. |
| Cluster computing | Current stage requires single-machine multicore support only. Cluster computing is a later HPC extension target, preferably through a MUMPS/MPI backend. Do not claim cluster support until MPI/MUMPS build, node deployment, shared/distributed file handling, scheduler launch scripts, logging, failure handling, and benchmark validation are complete. |

User-facing invocation goal:

```powershell
solver disk
```

from the directory containing `disk.inp`.

The wrapper or launcher may also preserve legacy compatibility:

```powershell
solver -i disk
```

Wrapper requirements:

1. The command name must be `solver`.
2. It must be discoverable from a normal PowerShell session without typing the full `D:\AESimFM_win\build\src\solver\solver.exe` path.
3. It must run from the current INP directory and pass the job name to the packaged solver.
4. It must not require the user to type or manage `D:\msys64\ucrt64\bin`.
5. It should support both `solver disk` and `solver -i disk`.

Threading requirements:

1. The default thread policy must be deterministic and documented.
2. `solver --threads N` is the planned user-facing control.
3. The implementation must inspect the running machine's available logical CPU count.
4. The implementation must not silently accept a requested thread count above the machine limit.
5. Thread count selection must be reflected in startup/status output, for example `threads=<n>`.
6. For the current `SPOOLES + FRD` baseline, threading may map to `OMP_NUM_THREADS` and related solver environment variables. MUMPS-specific threading/MPI behavior remains a later performance-stage requirement.

HPC and cluster-computing requirements:

1. The current completion scope is single-machine multicore execution, not cluster execution.
2. Preserve architecture room for MPI startup and distributed sparse solving.
3. Prefer MUMPS/MPI as the first cluster-capable backend candidate.
4. A future cluster mode must define its launch contract, for example an `mpiexec`/scheduler wrapper rather than overloading simple `solver disk` semantics.
5. Cluster mode must define how input decks, include files, restart/checkpoint files, FRD/HDF5 outputs, and logs are visible to all nodes.
6. Cluster mode must define failure behavior for node failure, MPI launch failure, missing shared paths, and partial result output.
7. Do not state that Windows solver supports cluster computing until at least one multi-process or multi-node benchmark has been built, run, and documented.

Do not implement this wrapper yet in this planning step. Record the requirement only.
