# AESimFM Windows Solver Architecture

本文档是 `D:\AESimFM_win` 的主架构说明。当前项目目标是 Windows 原生求解器，不是 GUI 迁移项目。GUI、批处理系统、工艺链编辑器和后处理程序都应通过稳定 CLI 和文件契约调用求解器。

## 1. 定位

AESimFM Windows v2.0 的目标不是简单把 WSL/Linux 求解器编译成 `.exe`，而是在保持当前 AESimFM/CalculiX 基线能力的前提下，形成可验证、可扩展、可被未来 Windows GUI 调用的原生求解核心。

必须保留的基线：

- `solver.exe -i jobname` 单 INP 提交流程。
- 当前 WSL 求解器已验证的 INP 关键字、材料模型、SDV 语义、FRD/DAT/STA 输出和 restart 能力。
- CalculiX 风格的网格、材料、边界、分析步和输出关键字。
- AESimFM 扩展模型：锻造 DRX/SRX/MRX、热处理 TTT/CCT 相变、多孔介质塑性成形、蠕变软化、损伤和性能预测。

Windows 侧新增方向：

- 更稳定的 CLI 和作业目录契约。
- MUMPS 等更高性能稀疏求解后端。
- HDF5/checkpoint 结果格式，同时保留 FRD legacy 桥接。
- 多工艺连续仿真和显式状态转移。
- 自动重网格、场量映射和 restart 闭环。

## 2. 设计原则

1. **Solver first**: 求解器是产品核心；GUI 是外部消费者。
2. **CLI first**: 所有核心功能必须能通过命令行和文件完成，不依赖 Qt/VTK/对话框。
3. **Docs first**: 新关键字、输出格式、状态变量、工艺链或重网格变化必须先更新文档。
4. **WSL parity first**: Windows 版不能只以“能编译”为成功，必须通过选定 WSL 基线算例。
5. **Stable legacy bridge**: FRD/DAT/STA 在 HDF5/checkpoint 完全验证前不能删除。
6. **Separate SDV namespaces**: 锻造、热处理、多孔介质、蠕变软化、remesh metadata 必须分命名空间维护。
7. **DLL-first components**: 第三方和数值库优先作为 DLL 加最小 public headers 使用；静态库只能作为有记录的过渡。
8. **No third-party source trees in solver core**: 不把完整第三方 SDK/source tree 混入 `src\solver`。
9. **Explicit process state**: 每个工艺边界必须声明 carry、reset、map、initialize 的字段。
10. **Remesh validated by restart**: 生成新网格不算成功，必须完成场映射和重启后第一个增量步验证。

## 3. 分层架构

```text
Windows GUI / batch / process editor
  -> stable CLI and job directory contract

Solver CLI layer
  -> option parsing, job directory validation, status/log/error reporting

Process-chain orchestration layer
  -> forging, heat treatment, carburizing, tempering, die-change chains

Solver kernel layer
  -> INP parser, step manager, material dispatch, nonlinear solve, result writer

AESimFM model layer
  -> DRX/SRX/MRX, phase transition, porous forming, creep softening, damage

Remesh/checkpoint layer
  -> distortion trigger, checkpoint, remesh CLI/library, field mapping, restart

Numerical backend layer
  -> SPOOLES compatibility, MUMPS target, BLAS/LAPACK/OpenMP runtime

External component layer
  -> DLL dependencies, minimal headers, manifests, license records
```

## 4. Repository Layout

Current working root:

```text
D:\AESimFM_win
  .agents\skills\aesimfm-windows-dev\
  docs\
  src\
    solver\
    remesh\
  test\
  lib\
  build.ps1
  CMakeLists.txt
```

Key documents:

| Document | Role |
|---|---|
| `docs\architecture.md` | 本文件，主架构入口 |
| `docs\inp_keywords_reference.md` | INP 关键字、元素、SDV 命名空间契约 |
| `docs\solver_api.md` | CLI、文件、状态码、错误处理和 GUI 调用契约 |
| `docs\h5_format_spec.md` | HDF5/checkpoint 结果格式和 SDV metadata |
| `docs\process_chain_guide.md` | 多工艺连续仿真和状态转移 |
| `docs\windows_solver_capability_baseline.md` | WSL parity 能力基线 |
| `docs\windows_remesh_architecture.md` | 自动重网格架构 |
| `AutoRemesh_Design.md` | 源项目自动重网格设计参考 |
| `ExistingRemesh_Summary.md` | 源项目手动重网格行为参考 |

## 5. CLI Contract

最低兼容接口：

```powershell
.\solver.exe -i disk
.\solver.exe --version
.\solver.exe --help
```

兼容规则：

- 工作目录必须是输入 deck 所在目录，或所有相对路径都按作业工作目录解析。
- `-i disk` 对应 `disk.inp`。
- legacy 输出包括 `disk.dat`, `disk.frd`, `disk.sta`, `disk.cvg`，按算例实际请求生成。
- 非零退出码表示失败，失败原因必须出现在 stdout/stderr 和日志文件中。

规划扩展接口：

```powershell
.\solver.exe -i disk --threads 8
.\solver.exe -i disk --output-format hdf5 --legacy-frd on
.\solver.exe -i disk --config process.json
.\solver.exe -i disk --restart-from disk_state
.\solver.exe -i disk --remesh on --remesh-config remesh.json
```

任何扩展都不能破坏 `solver.exe -i jobname`。

## 6. INP Parser And Keywords

INP parser 继承 CalculiX 风格，并保留 AESimFM 扩展。关键规则：

- 每行最多 16 个逗号分隔值，避免触发 CalculiX `splitline` 错误。
- 标准关键字优先沿用 CalculiX/Abaqus 语义；AESimFM 专有功能才新增扩展关键字。
- Abaqus/CalculiX 中存在的关键字不等于本求解器已支持；必须有 parser 分支、数据结构、最小 INP 和运行验证。
- 新关键字若影响 SDV、FRD、HDF5、restart、remesh 或 process chain，必须同步更新相关文档。

当前必须跟踪的 AESimFM 扩展包括：

- `*RATE-DEPENDENTPLASTIC`
- `*DYNAMICRECRYSTALLIZATION`
- `*CREEP-SOFTENING`
- `*PHYSICALCONSTANTS`
- `*SPECIFICGASCONSTANT`
- `*FLUIDCONSTANTS`
- `*PHASECURVE`
- `*PHASEPROP`
- `*PHASEEQUILIBRIUM`
- `*INCUBATIONPERIOD`
- `*PHASELATENTHEAT`
- `*PHASECTROL`
- `*PHASEZBF`
- `*PHASEGS`
- `*PHASEYS`
- `*PHASEHARDNESS`

详细登记表见 `docs\inp_keywords_reference.md`。

## 7. Element Support Policy

元素支持必须分层说明：

1. parser 是否识别。
2. 组装/求解是否可运行。
3. DAT/FRD/HDF5 输出是否正确。
4. 是否在目标工艺中回归验证。

基线矩阵应覆盖：

| Family | Types |
|---|---|
| 2D axisymmetric | `CAX3`, `CAX4`, `CAX4R`, `CAX6`, `CAX8`, `CAX8R` |
| 3D tetra | `C3D4`, `C3D10` |
| 3D wedge | `C3D6`, `C3D15` |
| 3D hex | `C3D8`, `C3D8R`, `C3D8I`, `C3D20`, `C3D20R` |

不能用一个元素类型的成功替代另一个元素类型的结论，例如不能用 `C3D8R` 的 smoke test 证明 `C3D20R` 已支持。

## 8. Model Integration

Fortran 模型接入路线：

```text
paper/formula or Abaqus-style routine
  -> extract physics state and parameters
  -> define solver-native interface
  -> add keyword parsing and material dispatch
  -> allocate SDV namespace and result labels
  -> add minimal INP
  -> run regression against DRX/TTT/powder/legacy paths
```

现有模型锚点：

| Domain | Main path | Contract |
|---|---|---|
| Forging DRX/SRX/MRX | `rdplas.f -> drx.f -> srx_mrx_k90.f` | 锻造 SDV namespace |
| Heat treatment phase transition | `thermmodel.f -> phasetransition.f` | 相变 SDV namespace, `*PHASE*` keywords |
| Porous forming/HIP | `metal_powder.f`, `drx_hip_weicme.f` | 多孔介质 SDV namespace |
| Creep softening | `creep_softening_model.f`, `creepsoftenings.f` | 不得与 powder/DRX SDV 混用 |

## 9. SDV Namespace Architecture

SDV 不是全局统一编号表，而是工艺域内状态变量。后处理、HDF5、restart、remesh 和 process chain 必须记录 namespace。

Required namespaces:

- `forging/recrystallization`
- `heat_treatment/phase_transition`
- `porous_forming/densification`
- `creep_softening`
- `remesh/restart_metadata`, if added

规则：

- 同一 SDV 编号在不同工艺域可以有不同含义。
- 不得把锻造 `SDV12 = D_DRX` 解释成多孔介质 `SDV12 = X_DREX`，反之亦然。
- 热-力耦合时，力学预留区和相变区必须按 `docs\inp_keywords_reference.md` 的偏移规则记录。
- HDF5 中保存裸 SDV 数组时，必须保存 `names`, `namespaces`, `descriptions`。
- 修改 SDV 编号必须提供迁移表和旧算例回归。

## 10. Result And State Formats

Legacy outputs:

| File | Role |
|---|---|
| `.dat` | 文本结果和诊断 |
| `.sta` | 增量步/收敛进度 |
| `.cvg` | 收敛日志 |
| `.frd` | legacy 后处理和重网格桥接 |

HDF5 target:

```text
/metadata
/mesh
/sets
/steps/step_XXXX/inc_XXXX
/state/sdv/names
/state/sdv/namespaces
/state/sdv/descriptions
/state/remesh
```

HDF5 不能只保存数值数组。任何可被后处理、restart、remesh 或 process chain 使用的状态字段都必须带名称、单位、位置、namespace 和版本信息。

## 11. Process Chain Architecture

工艺链不是多个独立 INP 的列表，而是带状态转移的求解序列。每个工艺边界必须回答：

1. 哪些字段 carry forward。
2. 哪些字段 reset。
3. 哪些几何、网格、模具、接触定义改变。
4. 哪些材料状态变量仍然有效。
5. 哪个输出文件证明转移正确。

状态包至少应包含：

- mesh and sets
- temperature
- stress
- strain/plastic strain
- SDV with namespace metadata
- phase fractions and grain size
- process step id
- remesh/restart mapping report if applicable

缺字段时必须在下一步求解前失败，不能静默置零。

## 12. Remesh Architecture

自动重网格属于求解能力，但实现必须模块化：

```text
solver.exe
  -> detects distortion
  -> writes checkpoint and remesh signal
  -> calls remesh CLI or internal remesh library
  -> validates remeshed mesh and mapped fields
  -> resumes from restart state
```

当前约定：

- `ALLOY_ELEMENT`, `ALLOY_NODE`, `ALLOY_SURF` 标识工件。
- `disk-remeshed.inp` 是重网格中间 deck，不一定是完整求解 deck。
- `disk-restart.inp`, `.nt`, `.st`, `.stdv` 是 legacy restart/mapping 桥接。
- `.stdv` 必须说明 SDV count 和 namespace。

remesh 成功条件：

1. 触发原因和阈值记录到日志/report。
2. 新网格通过质量检查。
3. 温度、应力、SDV 映射完整。
4. restart deck/state package 可读。
5. 第一个 post-remesh 增量步收敛。

## 13. Numerical Backend

目标是保留 SPOOLES 兼容，同时引入更高性能后端。

| Backend | Role |
|---|---|
| SPOOLES | legacy compatibility |
| MUMPS | Windows v2.0 primary target |
| BLAS/LAPACK | dense/local numerical kernels |
| PARDISO/MKL | optional future route, license must be recorded |

后端切换必须通过统一 sparse solve 接口和 CMake 选项完成，不能散落在模型代码中。性能声明必须记录算例、编译器、线程数、文件系统、输出模式和 wall time。

## 14. Build And Verification

推荐构建入口：

```powershell
& "D:\msys64\usr\bin\bash.exe" -lc "cd /d/AESimFM_win && cmake -B build -G 'MSYS Makefiles' && cmake --build build -j8"
```

最低验证层级：

| Level | Goal |
|---|---|
| L0 | CLI starts, `--help`, `--version`, bad input error |
| L1 | mesh/parser/element smoke tests |
| L2 | material keyword and SDV smoke tests |
| L3 | WSL parity selected cases |
| L4 | process chain and remesh restart |
| L5 | performance benchmark |

## 15. Acceptance Gates

| Gate | Goal | Evidence |
|---|---|---|
| G0 | inventory current Windows project | source layout, build files, docs, executable/options |
| G1 | compile Windows solver | exact build command and produced `solver.exe` |
| G2 | preserve legacy CLI | `solver.exe -i jobname` works from job directory |
| G3 | parser/keyword parity | selected keyword matrix passes |
| G4 | SDV parity | namespace tables and output labels match expected |
| G5 | WSL capability parity | selected baseline cases match expected WSL outcomes |
| G6 | HDF5/checkpoint bridge | HDF5 result and metadata match FRD/DAT where applicable |
| G7 | process-chain state | at least one forge -> heat treatment or rough -> finish chain |
| G8 | automatic remesh | trigger, remesh, mapping, restart, first increment |
| G9 | GUI-ready contract | future GUI uses only documented CLI/files |

## 16. Non-Goals For This Stage

- 不优先移植 GUI。
- 不以 GUI 可启动作为求解器完成标准。
- 不删除 FRD legacy 输出。
- 不把完整第三方源码树并入 solver core。
- 不通过修改物理模型语义来绕过 Windows 编译问题。
- 不合并或重解释不同工艺域的 SDV 命名空间。
