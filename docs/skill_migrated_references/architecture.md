# AESimFM 架构与 Windows 求解器迁移主干

本文件是 AESimFM 维护 Skill 的架构入口。它同时覆盖当前 WSL/Linux all-core 基线和后续 `D:\AESimFM_win` Windows 原生高性能求解器迁移方向。

如果任务只涉及当前 all/core 源码包，按第 1-7 节执行。如果任务涉及 Windows 侧新求解器、性能提升、多工艺连续仿真或自动网格重划分，必须同时阅读第 8 节列出的专题文档。

## 1. 项目定位与迁移目标

AESimFM 是面向航空发动机锻造、多孔介质塑性成形、热处理和组织性能预测的工艺仿真软件。当前沉淀的工程经验适用于以下技术组合：

- 求解核心：CalculiX 派生 C/Fortran 求解器。
- 自研模型：动态/静态/亚动态再结晶、相变、粉末致密化、蠕变软化、损伤、性能预测等 Fortran 模型。
- 桌面界面：Qt4/qmake GUI。
- 可视化后处理：VTK 5.x、FRD 结果读入、云图/网格/轮廓/未变形显示。
- 源码交付：`all` 全量源码包与 `core` 核心源码包。

Windows 迁移的目标不是简单把当前 WSL 求解器编译成 `.exe`。目标是形成 Windows 原生求解核心，在满足当前 WSL 求解器功能基线的前提下提升计算效率，并为后续 Windows 版软件调用提供稳定接口。新求解器必须逐步支持：

- 当前 WSL 求解器已验证的 INP、材料模型、SDV、FRD/DAT/STA 输出和重启能力。
- 更高效的 Windows 原生构建、数值库、并行和输出/checkpoint 路线。
- 多工艺连续仿真，如锻造 -> 热处理、渗碳 -> 回火、粗锻 -> 换模具 -> 精锻。
- 自动网格重划分、场量映射和续算闭环。
- 未来 Windows GUI 或批处理系统通过稳定 CLI/文件契约调用求解器。

## 2. 推荐分层

```text
GUI layer
  Qt4 menus, dialogs, tree views, preprocessing, job submission
  -> invokes packaged solver and reads INP/FRD/log outputs

Visualization layer
  FRD parser, result arrays, VTK actors, scalar lookup tables, outlines, legends
  -> owns display correctness and post-processing interaction state

Solver integration layer
  solver main, input parser, material dispatcher, result writer, build scripts
  -> links CalculiX base, AESimFM extension, and numerical libraries

AESimFM self-developed model layer
  recrystallization, phase transition, porous media, creep softening, damage
  -> uses explicit internal solver interfaces rather than Abaqus-only user-subroutine style

CalculiX base layer
  original or near-original CalculiX routines
  -> compile as open-source base component when boundary separation is required

External numerical/component layer
  SPOOLES, ARPACK, LAPACK/BLAS, VTK, FFmpeg, SARibbon, local runtime libraries
  -> manage as libraries/minimal headers plus manifest; do not mix full third-party source into final source package
```

## 3. all/core Target Shape

```text
D:\AESimFM\code\test\all
  gui\
  solver\
  components\
    open_source\
    manifests\
  build_all.sh
  build_gui.sh
  build_solver.sh

D:\AESimFM\code\test\core
  solver\
  process\
  components\
    open_source\
    manifests\
  build_core.sh
```

Use `D:\AESimFM\code\test` as the current repaired baseline. Treat `D:\AESimFM\externalized_components` as the current dependency source for Qt/VTK/FFmpeg/SARibbon-style externalized libraries. Treat `D:\AESgui_for_linux`, `D:\ccx`, `D:\ZZKK`, and `D:\WeICME` as historical environment, reference, or comparison sources unless the user explicitly changes the edit root.

## 4. Solver Boundary Model

Use the classification table approach from `solver_source_classification.csv`:

| Category | Meaning | Typical action |
|---|---|---|
| A | CalculiX original or near-original source | Open-source base component |
| B | CalculiX-derived AESimFM enhancement | Keep with explicit derivative notes |
| C | AESimFM self-developed process/model code | Self-developed solver extension |
| D | Historical Abaqus-style self-developed subroutine | Convert to internal solver interface before linking |
| E | Standalone research/program code | Do not link directly; refactor into callable library routine if needed |

Do not solve boundary issues by renaming files only. First classify origin and call role, then split libraries, then rename public artifacts.

## 5. Model Integration Pattern

Use this conversion route for Fortran models:

```text
paper/formula or Abaqus-style routine
  -> extract physics state and parameters
  -> define solver-native explicit interface
  -> allocate keyword parsing and material code path
  -> reserve SDV range and output names
  -> add minimal INP case
  -> run regression against DRX/TTT/powder/legacy paths
```

Existing proven anchors:

- TTT/CCT phase transition path: `thermmodel.f -> phasetransition.f`.
- SRX/MRX should follow deformation/recrystallization path: `rdplas.f -> drx.f -> srx_mrx_k90.f`.
- CREEP_SOFTENING uses distinct keyword, material `kode`, and SDV layout to avoid collisions with powder and DRX paths.

## 6. GUI and Visualization Architecture

GUI work must be evaluated as a closed workflow:

```text
Qt GUI starts
  -> Chinese UI and runtime config load correctly
  -> user imports INP
  -> GUI validates file and displays model
  -> GUI launches packaged solver from INP directory
  -> solver writes log/result files
  -> GUI imports FRD
  -> VTK shows scalar results, mesh/outline/cloud state, and step/result switching correctly
```

Common failure classes:

- Encoding defects: source mojibake, missing `QTextCodec`, wrong locale, broken runtime text.
- Startup defects: missing PlotOption/ReadResult/default config, blocking dialogs, wrong packaged path.
- Invocation defects: GUI calls historical `WeICME` or wrong `Solver` path instead of `solver/solver`.
- VTK defects: stale actor/interactor state, scalar array mismatch, legend color confused with fixed outline actor color, visibility reset leaves only one part visible.

## 7. Compliance Boundary Principles

- Commercial components must not be restored after replacement.
- Third-party SDKs should be external dependencies or component libraries with minimal headers.
- Self-developed business logic must not be hidden as a binary dependency to inflate code ratio.
- Every component claim needs evidence: path, version, license/source, link mode, whether source is included, and risk note.
- Code-ratio or open-source reports must use a documented classification method, not directory names alone.

## 8. Windows Solver Migration Architecture

Use `D:\AESimFM_win` as the Windows-native solver continuation project unless the user explicitly gives another root. GUI migration is not the first stage; the solver must remain a standalone CLI product that the future GUI can call.

Recommended Windows layering:

```text
Windows GUI or batch caller
  -> calls solver.exe through stable CLI and job directory contract

Solver CLI layer
  -> parses options, validates job directory, writes status/log files

Process-chain orchestration layer
  -> manages forging, heat treatment, carburizing, tempering, die-change chains

Solver kernel layer
  -> input parser, step manager, material dispatch, nonlinear solve, result writer

AESimFM model layer
  -> DRX/SRX/MRX, phase transition, porous forming, creep softening, damage, properties

Remesh/checkpoint layer
  -> distortion trigger, checkpoint, remesh CLI/library, field mapping, restart

Numerical backend layer
  -> sparse solver, BLAS/LAPACK, OpenMP/runtime, optional future accelerator backends

External component layer
  -> DLL-first third-party/runtime dependencies plus manifests
```

The Windows solver must preserve `solver.exe -i jobname` as the minimum compatibility interface. Additional JSON/HDF5/process-chain features can be added, but they must not break simple INP submission.

## 9. Windows Development Requirements

These requirements apply to Windows-native solver work under `D:\AESimFM_win`.

1. **Docs first**: new solver features must update the relevant document before implementation: interface, capability baseline, performance, process chain, or remesh.
2. **CLI first**: keep the solver callable without GUI. Do not require Qt, VTK, or user dialogs for solver execution.
3. **WSL parity first**: do not claim improvement until the Windows solver passes the selected WSL capability baseline.
4. **DLL-first components**: third-party and numerical components should be consumed as dynamic libraries (`.dll`) with minimal public headers and manifest records. Static libraries are acceptable only as a temporary bridge or when the component cannot reasonably be loaded dynamically; record the reason, license, link mode, and replacement plan.
5. **No third-party source trees in solver core**: do not copy full SDK/source trees into `src/solver` or other self-developed code directories. Keep dependencies in a component/dependency area and reference them through CMake/config.
6. **Stable output bridge**: FRD/DAT/STA remain available until the Windows result/checkpoint format is proven and all validation/remesh consumers have migrated.
7. **SDV namespaces stay separated**: forging, heat treatment, porous media, creep softening, and future remesh metadata must not be merged without a migration table and regression tests.
8. **Process-chain state is explicit**: every cross-process handoff must state which fields are carried, reset, mapped, or initialized.
9. **Remesh is validated by restart**: mesh generation alone is not success; field mapping and first post-remesh increment must be verified.
10. **Performance claims need baselines**: compare against current WSL runs with recorded case, compiler, thread count, filesystem, output mode, and wall time.

## 10. Windows Reference Documents

Use these references as the execution guide for `D:\AESimFM_win` work:

| Document | Purpose |
|---|---|
| `windows-solver-interface-contract.md` | CLI, files, status, errors, restart, and future GUI-call contract |
| `windows-solver-capability-baseline.md` | WSL solver parity checklist and required functional areas |
| `windows-solver-performance-plan.md` | benchmark levels, numerical backend route, threading and output performance |
| `windows-process-chain-state-transfer.md` | multi-process continuous simulation and state-transfer contract |
| `windows-remesh-architecture.md` | automatic remesh architecture derived from current manual/automatic remesh docs |
| `aesimfm-win-handoff.md` | handoff note for continuing work in `D:\AESimFM_win` |

Existing root-level remesh materials remain authoritative references:

- `D:\AESimFM\ExistingRemesh_Summary.md`: current manual remesh chain, file formats, numbering rules, Simufact comparison.
- `D:\AESimFM\AutoRemesh_Design.md`: target automatic remesh design and solver-triggered orchestration.

## 11. Windows Migration Acceptance Gates

Do not move to the next gate until the current one has evidence.

| Gate | Goal | Evidence |
|---|---|---|
| G0 | inventory current Windows project | build files, docs, source layout, existing executable/options |
| G1 | compile Windows solver | exact build command and produced `solver.exe` |
| G2 | preserve legacy CLI | `solver.exe -i jobname` runs from job directory |
| G3 | WSL capability parity | selected baseline matrix cases match expected WSL outcomes |
| G4 | performance improvement | documented benchmark speedup or bottleneck report |
| G5 | process-chain state | at least one forge -> heat treatment or rough -> finish forge smoke chain |
| G6 | automatic remesh | distortion trigger, remesh, field mapping, restart, first post-remesh increment |
| G7 | GUI-ready contract | future Windows GUI can call solver only through documented CLI/files |
