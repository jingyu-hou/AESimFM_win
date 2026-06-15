# Windows Solver Interface Contract

This document defines the stable boundary between the Windows-native solver and future callers such as the Windows GUI, batch scripts, regression harnesses, and multi-process orchestration.

## 1. Scope

The first Windows solver target is a CLI solver. GUI code is out of scope, but the CLI must be stable enough for a future Windows GUI to call without embedding solver internals.

The Windows solver must preserve the current WSL solver user contract before adding new output formats or acceleration:

```text
working directory = directory containing the selected input deck
command           = solver.exe -i jobname
input             = jobname.inp
legacy outputs    = jobname.dat, jobname.frd, jobname.sta, jobname.cvg when applicable
exit code 0       = completed calculation and wrote valid expected outputs
nonzero exit      = failure; reason must be visible in stdout/stderr and jobname.dat or jobname.log
```

Do not remove the legacy `-i jobname` contract during migration. New options may be added, but they must not break existing scripts or GUI launch logic.

## 2. Required CLI

Minimum accepted interface:

```powershell
.\solver.exe -i disk
.\solver.exe --version
.\solver.exe --help
```

Recommended extension interface:

```powershell
.\solver.exe -i disk --threads 8
.\solver.exe -i disk --config process.json
.\solver.exe -i disk --output-format frd
.\solver.exe -i disk --output-format hdf5 --legacy-frd on
.\solver.exe -i disk --restart-from disk_restart_state
.\solver.exe -i disk --remesh on --remesh-config remesh.json
```

Rules:

- `-i` always accepts a job name without `.inp`.
- Relative paths resolve from the process working directory.
- If an input path option is later added, the solver must still set the job working directory to the input file directory before resolving includes and output paths.
- All command-line options must be echoed to the log at startup.
- Unknown options must fail early with a clear error.

## 3. File Contract

Required legacy compatibility:

| File | Producer | Consumer | Requirement |
|---|---|---|---|
| `jobname.inp` | GUI/user/process chain | solver | Abaqus/CalculiX-compatible input plus AESimFM keywords |
| `jobname.dat` | solver | user/QA | warnings, errors, material and step messages |
| `jobname.sta` | solver | GUI/progress monitor | append-only status and increment progress |
| `jobname.frd` | solver | legacy post-processing/remesh | valid FRD for baseline tests |
| `jobname.cvg` | solver | user/QA | convergence history when nonlinear analysis is active |

Future native format:

- HDF5 may become the primary high-performance result/checkpoint format.
- FRD must remain available during transition as a legacy output and verification bridge.
- HDF5 result names must map back to FRD labels and SDV names so old and new output can be compared.

## 4. Status And Progress

The `.sta` file is the GUI-safe status channel. It must be append-only and readable while the solver is running.

Minimum events:

```text
JOB_START job=disk version=<version> threads=<n>
STEP_START step=<n> time_start=<t0> time_end=<t1>
INC_DONE step=<n> inc=<n> time=<t> dt=<dt> iterations=<n> cutbacks=<n>
REMESH_START step=<n> inc=<n> reason=<reason> min_jac=<value>
REMESH_END step=<n> inc=<n> old_nodes=<n> new_nodes=<n> old_elems=<n> new_elems=<n>
JOB_DONE status=success wall_time=<seconds>
JOB_FAILED status=failure code=<code> message=<short reason>
```

Do not rely on GUI polling stdout only. The solver should write enough state to disk for crash diagnosis and resume decisions.

## 5. Restart And State Contract

Restart must be treated as a solver feature, not as a GUI workaround.

Required restart state categories:

- Mesh: nodes, elements, sets, surfaces, element types, material assignment.
- Mechanical fields: displacement, stress, strain, plastic strain, contact state where supported.
- Thermal fields: temperature, heat flux state where supported.
- Process/model state: SDV, phase fractions, grain size, recrystallization state, porosity/density, creep softening state.
- Time state: global process time, step time, increment number, previous timestep history used by models.
- Boundary/contact state: active tooling, dies, contact pairs, friction and heat-transfer settings.

If a field is not restart-safe yet, document it as unsupported and block multi-process chaining that depends on it.

## 6. Error Contract

Every failure should produce:

- Nonzero process exit code.
- One-line terminal error.
- Detailed log entry in `jobname.dat` or `jobname.log`.
- No silent empty FRD success.

Specific classes:

| Class | Required behavior |
|---|---|
| Invalid INP keyword | fail before allocation or solve |
| Unsupported element/model | fail with exact keyword/type |
| Missing include/file | print resolved attempted path |
| Numerical non-convergence | preserve last safe checkpoint if available |
| Remesh failure | preserve pre-remesh checkpoint and return clear status |
| Output write failure | fail instead of reporting success |

## 7. Compatibility Gate

Before changing this contract, verify:

1. `solver.exe -i disk` still works.
2. The working directory rule is unchanged.
3. `jobname.sta`, `jobname.dat`, and `jobname.frd` are still produced for legacy cases.
4. Future GUI can launch with `QProcess` or equivalent without solver-specific IPC.
5. Batch tests can run without GUI.

