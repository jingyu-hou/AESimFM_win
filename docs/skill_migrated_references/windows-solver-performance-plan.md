# Windows Solver Performance Plan

This document turns "higher efficiency than WSL" into measurable engineering work.

## 1. Performance Principle

Do not claim performance improvement from compiler choice alone. Measure the same cases, same input, same output request, same thread count, and comparable storage location.

Use WSL ext4 and Windows local NTFS separately:

- WSL ext4 tests show current best Linux-side behavior.
- Windows NTFS tests show real Windows user behavior.
- Windows tests on paths under WSL mounts are not representative.

## 2. Benchmark Levels

| Level | Purpose | Example |
|---|---|---|
| L0 parser/build smoke | catch broken CLI and parser fast | minimal element cases |
| L1 short physics smoke | compare fields and runtime quickly | `disk.inp` short version |
| L2 medium industrial | compare nonlinear solve, contact, output cost | forging/heat treatment medium cases |
| L3 remesh/process chain | evaluate automatic remesh and restart overhead | disk remesh loop, forge -> heat treatment |
| L4 long industrial | final acceptance only | user-selected full process case |

Every benchmark record should include:

```text
git revision or source snapshot
compiler and version
build type and flags
CPU model and core count
thread count
input path and filesystem
case name
wall time
solver assembly time if available
linear solver time if available
output write time if available
peak memory
exit status
output files checked
```

## 3. Target Metrics

Initial migration acceptance:

- Windows solver builds reproducibly.
- L0/L1 cases match WSL output expectations.
- Windows L1 runtime is not slower than WSL by more than 10% before optimization.

Performance upgrade target:

- L1/L2 Windows native runtime is at least 20% faster than current WSL baseline on the same machine.
- Multi-thread mode shows monotonic improvement from 1 to practical core count for supported cases.
- Output format changes reduce output time without losing FRD compatibility.
- Remesh overhead is below 10% of total solve time for cases where remesh is required, using the target from existing remesh analysis.

Do not hide slower runs by changing output frequency, convergence tolerance, timestep controls, or requested variables unless the benchmark explicitly documents that change.

## 4. Optimization Tracks

### 4.1 Build And Compiler

Windows target currently indicated by project rules:

```powershell
& "D:\msys64\usr\bin\bash.exe" -lc "cd /d/AESimFM_win && <command>"
```

Recommended build checks:

- Debug and Release are separate.
- Release uses optimization flags consistently for C and Fortran.
- OpenMP runtime is packaged and version-locked.
- No accidental debug I/O remains in hot loops.

### 4.1.1 Component Linking Policy

Prefer dynamic libraries on Windows:

- Third-party and numerical dependencies should be consumed as `.dll` plus import library when needed.
- Keep only minimal public headers in the source tree; full SDK/source trees belong in an external dependency area.
- Record each dependency in a manifest with version, source, license, link mode, runtime DLL path, and packaging note.
- Static `.a`/`.lib` linkage is a temporary fallback unless there is a documented technical or licensing reason.
- Do not hide AESimFM self-developed solver/model code inside binary libraries to make the source tree look smaller.

### 4.2 Linear Solver

Treat sparse linear solver choice as the main performance lever.

Required comparison:

| Solver backend | Role |
|---|---|
| SPOOLES | legacy compatibility baseline |
| MUMPS or equivalent | Windows native primary candidate if already selected in AESimFM_win |
| PARDISO/MKL | optional high-performance candidate if licensing and distribution are acceptable |

Acceptance requires numerical comparison and packaging/licensing notes, not only compile success.

### 4.3 Parallelism

Parallelism must be explicit:

- Thread count controlled by CLI or config.
- OpenMP regions measured around assembly, material loops, contact search, and solver backend where applicable.
- Avoid nested oversubscription between OpenMP and numerical libraries.
- Record CPU utilization and memory growth.

### 4.4 Output And Checkpoint I/O

FRD ASCII is useful for compatibility but expensive for large results. HDF5 can be introduced as primary Windows output only if:

- FRD legacy export remains available.
- HDF5 datasets map to existing result labels and SDV names.
- Restart/remesh can consume either HDF5 or a documented checkpoint format.
- Output tests compare field counts and scalar ranges against FRD.

### 4.5 Remesh Performance

Automatic remesh must be measured separately:

- distortion detection cost,
- checkpoint write cost,
- mesh generation cost,
- field mapping cost,
- restart load cost,
- first post-remesh increment convergence cost.

The first optimization target is reliability and field correctness; only then reduce remesh time.

## 5. Reporting Template

Use this table in performance records:

| Case | WSL time | Windows time | Threads | Speedup | Peak memory | Output mode | Status |
|---|---:|---:|---:|---:|---:|---|---|
| disk short | | | | | | FRD | |

Required conclusion format:

```text
PASS/FAIL:
Functional parity:
Performance:
Regression risk:
Next bottleneck:
```
