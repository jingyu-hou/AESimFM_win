# AESimFM Windows INP Keyword Reference

本文档是 `D:\AESimFM_win` Windows 原生求解器的 INP 关键字契约。它不是完整 Abaqus/CalculiX 手册，而是记录 Windows 侧必须继承的 AESimFM/CalculiX 输入格式、当前 parser 已识别的 AESimFM 扩展关键字、未来新增关键字的准入规则，以及 SDV 编号解释规则。

主要参考：

- `D:\AESimFM\INP_FRD格式规范参考.md`
- `D:\AESimFM_win\src\solver\calinput.f`
- `D:\AESimFM_win\src\solver\readphaseinf.f`
- `D:\AESimFM_win\docs\h5_format_spec.md`
- `D:\AESimFM_win\docs\windows_solver_capability_baseline.md`

## 1. 基本兼容规则

Windows 求解器必须继续接受当前 AESimFM/CalculiX 风格输入：

```powershell
solver.exe -i jobname
```

其中 `jobname.inp` 在进程工作目录中解析。迁移到 Windows 不能改变关键字拼写、顺序规则、单位约定或 SDV 语义。如果某个关键字尚未实现，必须在 parser 阶段给出明确错误，包含关键字名和不支持原因。

INP 基础格式约束：

| 项目 | 规则 |
|---|---|
| 关键字 | 以 `*` 开头，大小写不敏感；文档统一写大写 |
| 注释 | `**` 开头 |
| 每行字段数 | 遵守 CalculiX `splitline` 限制，每行最多 16 个逗号分隔值 |
| 数值分隔 | 逗号、空格、制表符可作为分隔符；不要依赖多个空格表示字段 |
| 续行 | 数据物理行可跨多行，无特殊续行符 |
| INCLUDE 路径 | 相对路径以主 INP 所在目录/作业工作目录为基准 |
| 单位 | 当前基准为 SI：m, kg, s, Pa；温度输入通常为 degC，模型内部需要 K 时由物理常数转换 |

## 2. 关键字状态

| 状态 | 含义 |
|---|---|
| Required | Windows parity 必须支持，不能静默降级 |
| Legacy | 为兼容旧算例保留，不建议作为新 Windows 功能入口 |
| Planned | 架构需要，但实现可以分阶段进入 |
| Candidate | 可参考 CalculiX/Abaqus 语义规划，只有实现和测试后才能升为 Required |
| Unsupported | 必须明确报错，不能忽略 |

## 3. 新增关键字准入规则

Windows 侧求解器功能扩展时允许出现新关键字，但必须按以下顺序处理：

1. 优先沿用 CalculiX/Abaqus 已有关键字拼写和参数语义，例如标准材料、载荷、边界、输出、分析步控制。
2. 如果标准关键字无法表达 AESimFM 专有模型，再添加 AESimFM 扩展关键字。扩展关键字必须写入本文件，注明所有者、作用域、单位、默认值和错误处理。
3. 不要为了方便实现而给同一功能增加多个别名。确需兼容别名时，必须写明主拼写、别名、废弃策略和测试用例。
4. 新关键字如果影响 SDV、FRD、HDF5、restart、remesh 或 process chain，必须同时更新对应文档和最小算例。
5. Abaqus/CalculiX 中存在的关键字不等于本求解器已支持。只有 parser 分支、数据结构、最小 INP、求解运行、输出验证全部存在后，才能标为 Required。

新增关键字登记模板：

| 字段 | 必填内容 |
|---|---|
| Keyword | 主拼写，如 `*PHASECURVE` |
| Status | Required/Legacy/Planned/Candidate/Unsupported |
| Owner | mesh/material/step/output/remesh/process-chain |
| Placement | 全局、材料块内、分析步内、输出块内 |
| Data target | 写入的数据结构或 Fortran 子程序 |
| Units | 所有数值字段单位 |
| SDV impact | 无、读取、写入、扩展数量、命名空间 |
| Output impact | DAT/FRD/HDF5/restart 是否变化 |
| Minimal case | 最小验证 INP |

## 4. 网格、集合和材料基础关键字

| Keyword | Status | Placement | Notes |
|---|---|---|---|
| `*HEADING` | Required | global | 作业标题和注释，不参与物理计算 |
| `*NODE` | Required | global/include | `node_id, x, y, z` |
| `*ELEMENT` | Required | global/include | 必须区分 `*ELEMENT` 和 `*ELEMENT OUTPUT` |
| `*NSET` | Required | global/include | 每行最多 16 个 ID |
| `*ELSET` | Required | global/include | `ALLOY_ELEMENT` 是重网格/工件约定名 |
| `*SURFACE` | Required | global | contact、remesh、process chain 需要保留名称 |
| `*INCLUDE` | Required | global | include 文件可包含节点、单元、集合、材料等片段 |
| `*MATERIAL` | Required | global | 材料扩展关键字必须有材料上下文 |
| `*SOLID SECTION` | Required | global | 保留 elset/material 对应关系 |
| `*DENSITY` | Required | material | 温度相关表按 CalculiX 风格读取 |
| `*ELASTIC` | Required | material | `E, nu[, temperature]` |
| `*EXPANSION` | Required | material | 热膨胀 |
| `*CONDUCTIVITY` | Required | material | 热导率 |
| `*SPECIFIC HEAT` | Required | material | 比热 |
| `*PLASTIC` | Required | material | 标准塑性路径 |
| `*CREEP` | Required | material | legacy creep 路径，必须与 `*CREEP-SOFTENING` 隔离 |
| `*DEPVAR` | Required | material | 状态变量数量；不得小于激活模型所需数量 |

## 5. 边界、载荷和分析步关键字

| Keyword | Status | Placement | Notes |
|---|---|---|---|
| `*INITIAL CONDITIONS` | Required | global/step | 温度、应力、solution/SDV 初始场和 restart/remesh 输入 |
| `*BOUNDARY` | Required | step | `nset, dof_first, dof_last, value` |
| `*CLOAD` | Required | step | 集中载荷 |
| `*DLOAD` / `*DSLOAD` | Required | step | 分布载荷、面载荷 |
| `*DFLUX` | Required | step | 热通量 |
| `*TEMPERATURE` | Required | step | 步内温度边界 |
| `*AMPLITUDE` | Required | global | 边界/载荷时程 |
| `*STEP` | Required | global | `INC`, `NLGEOM` 等参数必须保留 |
| `*END STEP` | Required | step | 必须与 `*STEP` 匹配 |
| `*STATIC` | Required | step | 锻造非线性准静态基准 |
| `*DYNAMIC` | Required | step | 当前 parser 匹配 `*DYNAMIC ` 分支 |
| `*DYNAMIC, EXPLICIT` | Candidate | step | 架构需要，必须用最小显式算例验证后升级 |
| `*HEAT TRANSFER` / `*HEATTRANSFER` | Required | step | 热处理和热传导基准 |
| `*COUPLED TEMPERATURE-DISPLACEMENT` | Required | step | 热-力耦合 |
| `*RESTART` | Required | global/step | remesh 和 process chain 必需 |
| `*CONTROLS` | Required | step | 求解控制，保留 CalculiX 行为 |

## 6. 输出关键字

| Keyword | Status | Placement | Notes |
|---|---|---|---|
| `*OUTPUT` | Required | step | 不能破坏 FRD/DAT/STA legacy 输出 |
| `*EL FILE` | Required | step/output | `S`, `PEEQ`, `SDV` 写入 FRD |
| `*NODE FILE` | Required | step/output | `U`, `NT` 等节点结果 |
| `*EL PRINT` | Required | step/output | 写入 DAT；`FREQUENCY=0` 可能导致 DAT 无对应表 |
| `*NODE PRINT` | Required | step/output | 写入 DAT |
| `*ELEMENT OUTPUT` | Required | step/output | parser 必须与 `*ELEMENT` 区分 |
| `*NODE OUTPUT` | Required | step/output | HDF5 映射时需要保留结果标签 |

FRD 注意事项：

- `*EL FILE, SDV` 在 FRD 中通常是积分点 SDV 外推到节点后的结果，`num_entities` 可能等于节点数，不等于单元数。
- 外推后的 SDV 可能略超物理范围，例如分数大于 1。判定模型错误前应检查积分点原始值。
- FRD `6E12.5` 数值可能紧邻，例如 `1.0E-07-2.0E+05`，解析时不能只用空白分割。
- HDF5 中如果保存裸 `SDV[:, n]`，必须同时保存 `names`、`namespaces`、`descriptions` 映射。

## 7. AESimFM 扩展材料和工艺关键字

下表以当前 Windows 侧源代码为准。`calinput.f` 中已存在 parser 分支，`readphaseinf.f` 负责相变关键字的数据读取和部分 `nstate_` 扩展。

| Keyword | Status | Owner | Placement | SDV impact | Notes |
|---|---|---|---|---|---|
| `*RATE-DEPENDENTPLASTIC` | Required | forging/material | material | writes forging plastic state | AESimFM 扩展流动应力/Johnson-Cook 类参数 |
| `*DYNAMICRECRYSTALLIZATION` | Required | forging/material | material | forging SDV 11-43 | DRX + SRX/MRX 双列参数入口 |
| `*CREEP-SOFTENING` | Required | forging/material | material | forging SDV 44-53, porous SDV 21-24 | 时效/蠕变软化扩展，必须区分工艺命名空间 |
| `*PHYSICALCONSTANTS` | Required | global/material | global | none | 当前 parser 使用无空格拼写；与 `ABSOLUTE ZERO` 等物理常数相关 |
| `*SPECIFICGASCONSTANT` | Required | thermal/fluid | material/global | none | 保留当前 parser 行为 |
| `*FLUIDCONSTANTS` | Required | coupled/legacy | material/global | none | legacy coupled/fluid 数据 |
| `*PHASECURVE` | Required | heat treatment | material | sets phase count N and phase SDV range | `TYPE=TTT` 或 CCT 路径 |
| `*PHASEPROP` | Required | heat treatment | material | reads phase property data | 热导率/比热等相属性 |
| `*PHASEEQUILIBRIUM` | Required | heat treatment | material | phase model data | 平衡相数据 |
| `*INCUBATIONPERIOD` | Required | heat treatment | material | extends phase SDV storage | 孕育期模型，影响后续 SDV 偏移 |
| `*PHASELATENTHEAT` | Required | heat treatment | material | phase model data | 潜热 |
| `*PHASECTROL` | Required | heat treatment | material | phase model control | 保留现有拼写；不要静默改成 `*PHASECONTROL` |
| `*PHASEZBF` | Required | heat treatment | material | phase model data | 保留当前 parser 行为 |
| `*PHASEGS` | Required | heat treatment | material | no extra SDV count | 晶粒尺寸参数，读取 `phaseother(1..3)` |
| `*PHASEYS` | Required | heat treatment | material | extends YS storage | 屈服强度参数，读取 `phaseother(4..8)` |
| `*PHASEHARDNESS` | Required | heat treatment | material | extends hardness storage | 硬度混合输出 |

## 8. 单元类型基线

单元支持必须分清三层含义：parser 识别、组装/求解可运行、结果输出经回归验证。文档中列入不等于所有工艺都已验证。

| Family | Types to track | Status rule |
|---|---|---|
| 2D axisymmetric | `CAX3`, `CAX4`, `CAX4R`, `CAX6`, `CAX8`, `CAX8R` | 从最小 parser/求解/FRD smoke case 建立矩阵 |
| 3D tetra | `C3D4`, `C3D10` | 必须覆盖线性和二次单元 |
| 3D wedge | `C3D6`, `C3D15` | 必须覆盖楔形体映射 |
| 3D hex | `C3D8`, `C3D8R`, `C3D8I`, `C3D20`, `C3D20R` | 不能用 `C3D8R` 结果替代 `C3D20R` 结论 |

新增元素类型需要：

1. 最小 INP。
2. parser 识别证据。
3. 求解完成证据。
4. DAT/FRD/HDF5 输出映射。
5. 至少一个相关工艺场景的短算例，才能声明该工艺可用。

## 9. SDV 命名空间总规则

SDV 是工艺域内的状态变量，不是一张全局统一编号表。锻造、热处理、多孔介质塑性成形分别维护自己的 SDV 解释。同一个编号在不同模块中可以有不同含义，后处理必须先判断算例所属工艺域，再查对应表。

禁止事项：

- 不得把锻造 `SDV12 = D_DRX` 套用到多孔介质；多孔介质 `SDV12 = X_DREX`。
- 不得把锻造 `SDV44-53` 直接套用到热处理或多孔介质结果。
- 不得让新模型隐式复用已有 SDV 槽位，除非有明确兼容层、迁移表和旧算例回归。
- process chain 或 remesh 如果需要跨域携带 SDV，必须声明源命名空间、目标命名空间和转换规则。

新增或修改 SDV 编号必须同时提供：

1. SDV 编号、变量名、含义、单位、所属工艺域。
2. `*DEPVAR` 最低数量。
3. FRD 输出标签和 HDF5 metadata 映射。
4. restart/remesh/process-chain 迁移规则。
5. 旧算例回归结果。

## 10. 多孔介质塑性成形 SDV

适用：粉末冶金/HIP/多孔介质塑性成形路径，例如 `metal_powder.f`, `drx_hip_weicme.f`。

| SDV | Name | Meaning | Unit |
|---|---|---|---|
| 1 | RELATIVE_DENSITY | 相对密度 | 1 |
| 2 | DENSIFICATION_STRAIN | 致密化等效体积塑性应变 | 1 |
| 3 | CREEP_EQ | 累计等效蠕变应变 | 1 |
| 4 | CREEP_RATE | 当前等效蠕变应变率 | 1/s |
| 5 | CREEP_DINC | 当前增量步蠕变应变 | 1 |
| 6 | PRESSURE | 静水压力 | Pa |
| 7 | MISES | Mises 等效应力 | Pa |
| 8 | PRED_STRESS | 预测应力 | Pa |
| 9 | CREEP_QTILD | 蠕变修正前等效应力 | Pa |
| 10 | CREEP_PRESSURE | 蠕变计算静水压力 | Pa |
| 11 | RELAXED_STRESS_EQ | 松弛后等效应力 | Pa |
| 12 | X_DREX | HIP 动态再结晶分数 | 1 |
| 13 | D_DREX | HIP 动态再结晶晶粒尺寸 | um |
| 14 | D_AVE | 平均晶粒尺寸 | um |
| 15 | PE11 | 内部塑性应变 11 | 1 |
| 16 | PE22 | 内部塑性应变 22 | 1 |
| 17 | PE33 | 内部塑性应变 33 | 1 |
| 18 | PE12 | 内部塑性应变 12 | 1 |
| 19 | PE13 | 内部塑性应变 13 | 1 |
| 20 | PE23 | 内部塑性应变 23 | 1 |
| 21 | SOFTENING_FACTOR | 时效软化/松弛因子 | 1 |
| 22 | CREEP_ACTIVE_FLAG | 蠕变/软化激活标志 | flag |
| 23 | CREEP_TEMP_K | 蠕变模型温度 | K |
| 24 | CREEP_TIME_HOLD | 累计保持/松弛时间 | s |

## 11. 锻造 SDV

适用：热变形、DRX、SRX/MRX、晶粒长大、锻造蠕变软化路径，例如 `rdplas.f`, `drx.f`, `srx_mrx_k90.f`, `creep_softening_model.f`。

### 11.1 塑性和 DRX, SDV 1-21

| SDV | Name | Meaning | Unit |
|---|---|---|---|
| 1 | EQPLAS | 等效塑性应变 | 1 |
| 2 | EPLAS(1) | 塑性应变 11 | 1 |
| 3 | EPLAS(2) | 塑性应变 22 | 1 |
| 4 | EPLAS(3) | 塑性应变 33 | 1 |
| 5 | EPLAS(4) | 塑性应变 12 | 1 |
| 6 | EPLAS(5) | 塑性应变 13 | 1 |
| 7 | EPLAS(6) | 塑性应变 23 | 1 |
| 8 | EQPLASRT | 等效塑性应变率 | 1/s |
| 9 | SYIELD | 屈服应力 | Pa |
| 10 | PLASTIC_DISSIPATION | 塑性耗散 | Pa |
| 11 | X_DRX | 动态再结晶分数 | 1 |
| 12 | D_DRX | DRX 晶粒尺寸 | um |
| 13 | D_AVE | 平均晶粒尺寸 | um |
| 14 | T_AVE | DRX 平均温度 | degC |
| 15 | RATE_AVE | DRX 平均应变率 | 1/s |
| 16 | DAMAGE | 损伤值 | 1 |
| 17 | DAMAGE_INIT_STRAIN | 损伤起始应变 | 1 |
| 18 | UNUSED | 未使用/预留 | - |
| 19 | MEAN_STRESS_BEFORE | 平均前平均应力 | Pa |
| 20 | MEAN_STRESS_AFTER | 平均后平均应力 | Pa |
| 21 | TEMP_CURRENT | 当前温度 | degC |

### 11.2 SRX/MRX 和晶粒长大, SDV 22-43

| SDV | Name | Meaning | Unit |
|---|---|---|---|
| 22 | MRX_SIGN | MRX 激活标志 | flag |
| 23 | SRX_SIGN | SRX 激活标志 | flag |
| 24 | X_MRX | MRX 再结晶分数 | 1 |
| 25 | X_SRX | SRX 再结晶分数 | 1 |
| 26 | D_MRX | MRX 晶粒尺寸 | um |
| 27 | D_SRX | SRX 晶粒尺寸 | um |
| 28 | D_MIX | 混合平均晶粒尺寸 | um |
| 29 | EQV_RE | 当前回复等效塑性应变 | 1 |
| 30 | EQV_RE0 | 卸载起始回复等效塑性应变 | 1 |
| 31 | EQUER_MEAN | 变形阶段平均等效应变率 | 1/s |
| 32 | EQV05_DRX | 50% DRX 完成应变 | 1 |
| 33 | T05_MRX | 50% MRX 所需时间 | s |
| 34 | T05_SRX | 50% SRX 所需时间 | s |
| 35 | T_GROWTH0_MRX | MRX 晶粒长大开始时间 | s |
| 36 | D_GROWTH0_MRX | MRX 晶粒长大起始尺寸 | um |
| 37 | T_GROWTH0_SRX | SRX 晶粒长大开始时间 | s |
| 38 | D_GROWTH0_SRX | SRX 晶粒长大起始尺寸 | um |
| 39 | UNDEFORM_SIGN | 未变形状态标志 | flag |
| 40 | T_DEFORM | 累计变形时间 | s |
| 41 | D0_K90 | K90 初始晶粒尺寸 | um |
| 42 | N3_MRX_GG | MRX 晶粒长大完成标志 | 1 |
| 43 | N4_SRX_GG | SRX 晶粒长大完成标志 | 1 |

### 11.3 锻造蠕变软化, SDV 44-53

| SDV | Name | Meaning | Unit |
|---|---|---|---|
| 44 | CREEP_EQ | 累计等效蠕变应变 | 1 |
| 45 | CREEP_RATE | 当前等效蠕变应变率 | 1/s |
| 46 | CREEP_DINC | 当前增量步蠕变应变 | 1 |
| 47 | CREEP_QTILD | 蠕变修正前等效应力 | Pa |
| 48 | CREEP_PRESSURE | 蠕变计算静水压力 | Pa |
| 49 | SOFTENING_FACTOR | 时效软化/松弛因子 | 1 |
| 50 | RELAXED_STRESS_EQ | 松弛后等效应力 | Pa |
| 51 | CREEP_ACTIVE_FLAG | 蠕变/软化激活标志 | flag |
| 52 | CREEP_TEMP_K | 蠕变模型温度 | K |
| 53 | CREEP_TIME_HOLD | 累计保持/松弛时间 | s |

## 12. 热处理/相变 SDV

适用：热处理、TTT/CCT 相变、热-力耦合相变路径，例如 `thermmodel.f`, `phasetransition.f`, `phaseother.f`, `readphaseinf.f`。

相数量 `N = phase_inf(1)`，通常为 2-5。相变关键字对 `nstate_` 的影响：

| Keyword | Minimum nstate_ when mechanical reserve exists | Added state |
|---|---|---|
| `*PHASECURVE` | `14 + N` | 相分数，`SDV15` 到 `SDV(14+N)` |
| `*INCUBATIONPERIOD` | `14 + 2N + 2` | 孕育期相关状态，并使后续位置顺延 |
| `*PHASEYS` | `14 + N + 2` | 晶粒尺寸 + 屈服强度 |
| `*PHASEHARDNESS` | `14 + N + 3` | 硬度 |
| `*PHASEGS` | 不额外增加 | 从 `phaseother(1..3)` 读取晶粒尺寸参数 |

热-力耦合时，当前规则是前 14 个位置给力学/变形预留，相变从 `SDV15` 开始：

| SDV | Meaning when N=4 | General meaning | Unit |
|---|---|---|---|
| 1-14 | 力学/变形预留 | `transformation.f -> rdplas.f` 相关 | mixed |
| 15 | 奥氏体体积分数 | 母相体积分数 | 1 |
| 16 | 铁素体体积分数 | 第 2 相体积分数 | 1 |
| 17 | 珠光体体积分数 | 第 3 相体积分数 | 1 |
| 18 | 贝氏体体积分数 | 第 4 相体积分数 | 1 |
| `15+N` | 晶粒尺寸 | 相变后晶粒尺寸 | um |
| `16+N` | 屈服强度 | 需 `*PHASEYS` | MPa |
| `17+N` | 硬度 | 需 `*PHASEHARDNESS` | HV/HRC |

纯热处理如果没有力学预留，允许相分数从 `SDV1` 起存储；但 HDF5/后处理必须明确标注 namespace 为 `heat_treatment/phase_transition`，不能按锻造 SDV 解释。

## 13. Remesh 和 process chain 输入契约

重网格和工艺链控制优先放在 JSON/HDF5 metadata 中，不要藏在 INP 注释里。若未来确需 INP 关键字扩展，必须按第 3 节登记。

当前 remesh 约定名：

| Item | Role |
|---|---|
| `ALLOY_ELEMENT` | 工件 element set |
| `ALLOY_NODE` | 工件 node set |
| `ALLOY_SURF` | 工件 surface |
| `disk-remeshed.inp` | 重网格后的网格/中间 deck |
| `disk-restart.inp` | 含映射场和剩余 step 的 restart deck |
| `.nt` | 映射温度 |
| `.st` | 映射应力 |
| `.stdv` | 映射 SDV，必须带 namespace/count 说明 |

## 14. 验证清单

修改或新增关键字后，至少完成：

1. 更新本文件。
2. 添加最小 INP。
3. parser 能读到关键字并进入正确数据结构。
4. 运行一个受影响短算例。
5. 检查 DAT/STA/FRD 输出。
6. 如果影响 HDF5，更新 `docs/h5_format_spec.md` 并检查 SDV metadata。
7. 如果影响 restart/remesh/process chain，补充迁移规则和第一步重启验证。
