# 现有网格重划分功能总结

> 本文档描述 WeICME/AESimFM 现有手动网格重划分的完整流程、工具原理、文件格式、编号约定和接口，
> 以及 Simufact Forming 15 商业软件的自动重划分架构分析。

---

## 1. 概述

锻造大变形仿真中，网格随材料流动逐渐畸变。当网格质量恶化到一定程度（通常以雅可比行列式判断），需要中断计算、重划分网格、将旧网格上的温度/应力/状态变量映射到新网格，然后以重启方式继续求解。

当前（2025R1）全部由**人工操作**完成，依赖以下工具链：

```
WeICME GUI → RMesh.exe (Python tkinter) → gmsh.exe → Abaqus/CAE → WeICME GUI
```

---

## 2. 工具链组成

### 2.1 RMesh.exe

**位置：** `D:\WeICME\WeICMECAE\RMesh\RMesh.exe`

**技术特征：**

| 项目 | 详情 |
|------|------|
| 打包方式 | PyInstaller 4.7 |
| Python 版本 | 3.9 (64-bit) |
| GUI 框架 | tkinter (内置 `_tkinter.pyd`, `tcl86t.dll`, `tk86t.dll`) |
| 关键依赖 | numpy (内置 `libopenblas`), OpenCASCADE (`TK*.dll` 在上级目录) |
| 命令行接口 | **无**（`RMesh.exe -h`, `--help`, `/?` 均无输出，直接弹窗） |
| 进程模型 | 单进程 GUI，阻塞用户交互 |
| 自动调用 | **不可行**（无 CLI，无管道/IPC 接口） |

**在手动流程中的功能：**

1. 读取 solver 输出的 `disk.frd`（选用最后一个变形步 + 最后一步场量）
2. 提取锻件变形外表面轮廓 → 输出 Gmsh `.geo` 几何文件
3. 从 FRD 结集中提取场量 → 输出 `.DISP`, `.TEMP`, `.STRESS`, `.SDV` 文件
4. Gmsh 重划分 → Abaqus 修复后，读入新网格进行场量插值 → 输出 `.nt`, `.st`, `.stdv`
5. 组装重启文件 `disk-restart.inp`（合并模具、新锻件网格、场量映射、分析步）

**依赖链：** RMesh.exe 运行时调用同目录的 `gmsh.exe` 和上级目录的 OpenCASCADE DLL（`TKernel.dll`, `TKMesh.dll` 等）。

### 2.2 gmsh.exe

**位置：** `D:\WeICME\WeICMECAE\gmsh.exe`

**角色：** 读取 RMesh 输出的 `.geo` 几何文件（变形表面 BSpline 轮廓），生成三角形/四边形面网格 → 导出 `disk-Gmesh.inp`。

**问题：**
- Gmsh 生成的 2D 网格质量不够好（含退化的三角形单元 T3D2）
- 需要在 Abaqus/CAE 中手动修复（删除坏单元、节点重编号、翻转法向、合并重复节点）

### 2.3 Abaqus/CAE

**角色：** 对 Gmsh 输出的网格做后处理修复（不是重划分本身，而是质量清理）：
- 删除退化单元（T3D2 零面积单元）
- 重编号节点（从 1 开始）
- 翻转法向一致性
- 合并重合节点

输出修复后的 `disk-remeshed.inp`，包含锻件的新 2D 网格。

### 2.4 求解器（WeICME GUI 内嵌）

**角色：**
- 原始求解：读入原始 `disk.inp`，输出 `disk.frd`
- 重启求解：读入人工生成的 `disk-restart.inp` + 场量文件，续算

---

## 3. 完整手动操作流程

### 3.1 阶段一：原始求解

```
用户操作：
1. 在 WeICME GUI 中提交 disk.inp 求解
2. 全程盯屏，观察 .sta 输出或求解日志
3. 凭经验判断网格畸变程度（如某增量步不收敛、连续 cutback）
4. 当判断需要重划分时 → 在 GUI 中手动终止求解器 (Kill)
```

### 3.2 阶段二：提取变形表面（RMesh 操作 step a）

```
RMesh 操作：
1. 选择 jobname.frd 文件
2. 自动读取最后一个 DISP 增量步 → 得到变形后节点坐标
3. 用户手动指定锻件单元集（如 ALLOY_ELEMENT）
4. 提取锻件变形外表面 → 生成 jobname.geo（Gmsh 几何文件）

输出：jobname.geo
内容：Gmsh Point/Line/Spline 语句，描述变形后锻件的 2D 外轮廓
```

### 3.3 阶段三：Gmsh 网格重划分（RMesh 操作 step b）

```
Gmsh 操作（通过 RMesh 调用）：
1. 打开 jobname.geo
2. 设置网格参数：
   - 网格尺寸：0.001~0.003（根据几何曲率自适应）
   - Recombine all triangular meshes（三角形合并为四边形）
   - 1D 网格 → 2D 网格
3. 导出为 Abaqus INP 格式 → disk-Gmesh.inp
   - 选项：Save all elements, Save groups of nodes

输出：disk-Gmesh.inp
注意：Gmsh 此时输出的单元类型可能是 CPS4/CPS3 和 T3D2 混合，包含退化单元
```

### 3.4 阶段四：Abaqus 网格修复（RMesh 操作 step c）

```
Abaqus 操作（手动）：
1. File → Import → Model → disk-Gmesh.inp
2. Mesh 模块 → Part → Remove Selected → 选择退化单元 (Element) → Delete
3. Edit Mesh → Node → Delete → 删除未使用的孤立节点
4. Edit Mesh → Node → Renumber → Method: By Start → Label: 1
   → Domin: Nodes → Select Edit → OK
   （节点从 1 开始重新连续编号）
5. Tools → Query → Element → 检查单元数、节点数 → 确认无坏单元
6. Edit Mesh → Element → Flip normal → 统一法向
7. 导出为 disk-remeshed.inp
```

**关键约定：** 修复后的 `disk-remeshed.inp` 必须满足：
- 节点编号从 1 开始连续
- 单元编号从 1 开始连续
- 法向一致
- 无退化/孤立节点

### 3.5 阶段五：场量提取 (RMesh 操作 step d)

```
RMesh 操作：
1. 从 jobname.frd 中根据用户选择的 STEP/INC 提取场量
2. 输出 4 个场量文件：
   - disk.TEMP   → 节点温度 (node_id, T)
   - disk.STRESS → 节点应力 (node_id, SXX,SYY,SZZ,SXY,SYZ,SZX)
   - disk.SDV    → 节点状态变量 (node_id, SDV1,SDV2,...SDV25)
   - disk.DISP   → 节点位移 (node_id, DX,DY,DZ)
```

### 3.6 阶段六：场量插值与重启组装 (RMesh 操作 step e)

```
RMesh 操作：
1. 读入原始 disk.inp → 提取模具节点和单元（不在 ALLOY_ELEMENT 中的都是模具）
2. 读入 disk.frd → 更新模具节点坐标为变形后位置
3. 读入 disk-remeshed.inp → 提取新锻件节点和单元
4. 按编号约定将模具 + 锻件拼合：
   - 模具节点在前（保持原始编号）
   - 新锻件节点续接在后
   - 模具单元在前（保持原始编号）
   - 新锻件单元续接在后
5. 场量插值：将旧网格的 TEMP/STRESS/SDV 映射到新网格节点
   - 输出 disk.nt   (node_id, T)
   - 输出 disk.st   (node_id, SXX,SYY,SZZ,SXY,SYZ,SZX)
   - 输出 disk.stdv (node_id, SDV1,...,SDV25)
6. 组装 disk-restart.inp，包含：
   - 模具节点（变形后坐标）
   - 新锻件节点
   - 模具单元
   - 新锻件单元
   - 模具集合（NSET, ELSET, SURFACE）
   - 锻件集合（ALLOY_NODE, ALLOY_ELEMENT, ALLOY_SURF, ALLOY_SYMMETRY 等）
   - 材料定义、边界条件、接触定义
   - 新分析步（时长 = 总时长 - 已完成时长）
   - *INITIAL CONDITIONS 通过 *INCLUDE 引用场量文件：
     *INITIAL CONDITIONS, TYPE = TEMPERATURE
     *INCLUDE, INPUT=disk.nt
     *INITIAL CONDITIONS, TYPE = STRESS
     *INCLUDE, INPUT=disk.st
     *INITIAL CONDITIONS, TYPE = SOLUTION
     *INCLUDE, INPUT=disk.stdv
```

### 3.7 阶段七：重启续算

```
用户操作：
在 WeICME GUI 中提交 disk-restart.inp → 求解器加载新网格和映射场量 → 继续计算
```

---

## 4. 关键文件格式

### 4.1 原始 INP (`disk.inp`)

标准的 Abaqus/CalculiX INP 格式。

**结构：**
```
*Heading
...
*Node                  ← 所有节点（模具 + 锻件）
 node_id, x, y, z
...
*Element, type=...     ← 所有单元
 elem_id, node1, node2, ...
...
*Nset, nset=ALLOY_NODE    ← 锻件节点集
*Elset, elset=ALLOY_ELEMENT ← 锻件单元集（关键标识）
*Solid Section, elset=ALLOY_ELEMENT, material=alloy
*Nset, nset=ALLOY_SYMMETRY ← 锻件对称面节点
*Elset, elset=_ALLOY_SURF_S1 ← 锻件表面 S1 面
*Elset, elset=_ALLOY_SURF_S4 ← 锻件表面 S4 面
*Surface, type=ELEMENT, name=ALLOY_SURF
 _ALLOY_SURF_S1, S1
 _ALLOY_SURF_S4, S4
...
*Material, name=alloy   ← 锻件材料
*Material, name=die     ← 模具材料
...
*STEP                   ← 分析步定义
...
*END STEP
```

**锻件与模具的区分：** 通过 `*Elset, elset=ALLOY_ELEMENT` 集合名识别。**不在 ALLOY_ELEMENT 中且不在任何锻件集合中的单元是模具单元。**

### 4.2 结果 FRD (`disk.frd`)

CalculiX 的标准结构化文本结果格式，2 字符记录类型 ID。

**记录结构：**
```
1C    model header
1U    user header (key-value pairs)
2C    nodal coordinates header
-1    node: id, x, y, z
-3    end of nodes
3C    element header
-1    element group header: type, grp, mat
-2    element connectivity: nodes
-3    end of elements
1P    step header
100C  result header: time, nodes, format
-4    attribute header: name, components
-5    component names: SXX, SYY, ...
-1    data: node_id, val1, val2, ...
-3    end of data
9999  end of file
```

**场量名称（attr_name）：** DISP, STRESS, NDTEMP, FLUX, TOSTRAIN, ERROR, SDV, etc.

**STRESS 特殊情况：** 除 6 个应力分量外，附加 5 个派生量（Mises, 主应力 x3, 静水压力），共 11 列。

**TOSTRAIN 特殊情况：** 除 6 个应变分量外，附加 1 个等效塑性应变，共 7 列。

### 4.3 Gmsh 几何文件 (`disk.geo`)

Gmsh 原生脚本格式，由 RMesh 从变形网格表面提取。

**特征：**
```
lc = 0.5e-2;
Point(1347) = {0.0451693743, 0.129998496, 1.00044e-19, lc};
Point(1348) = {0.0475398163, 0.129998477, 1.78824e-19, lc};
...
Spline(1350)= {1347, 1348, ...};
Line Loop(...)= {...};
Plane Surface(...)= {...};
```

- 节点坐标使用变形后位置
- 外表面用 BSpline 曲线拟合（从变形的离散表面点重建连续轮廓）
- lc (characteristic length) 控制网格密度
- 坐标来源：FRD 最后一个 DISP 步的节点坐标（原始坐标 + 位移）

### 4.4 Remeshed INP (`disk-remeshed.inp`)

Abaqus 修复后的新锻件网格，**仅包含锻件**。

**关键约定：**
- 节点编号从 1 开始，连续无间断
- 单元编号从 1 开始，连续无间断
- 包含 `*Nset, nset=ALLOY_NODE` 和 `*Elset, elset=ALLOY_ELEMENT` 等集合定义
- 集合定义的名必须和原始 INP 一致
- 包含表面集合 `_ALLOY_SURF_s1` 到 `_ALLOY_SURF_s4` 和 `ALLOY_SURF`
- 单元类型：CPS3(三角形)/CPS4(四边形) 用于 2D；C3D4(四面体)/C3D6(棱柱)/C3D8(六面体) 用于 3D

### 4.5 场量映射文件

**disk.nt（温度）：**
```
node_id, T,
1, 380.001,
2, 380.0,
...
```

**disk.st（应力）：**
```
node_id, SXX, SYY, SZZ, SXY, SYZ, SZX,
1, 0.000183614, 0.000428432, 0.000183614, 0.000113869, 6.97247e-21, 6.4727e-19,
2, 0.000140913, 0.000328797, 0.000140913, 7.39259e-05, 1.70804e-05, 4.75023e-19,
...
```

**disk.stdv（状态变量 — 25 列）：**
```
node_id, SDV1, SDV2, ..., SDV25,
1, 0.0, 0.0, 0.0, ..., 0.0,
...
```

**disk.DISP（位移 — 3 列）：**
```
node_id, DX, DY, DZ,
1, 0.0, -0.111, 0.0,
...
```

**注意：** 这些文件均按**新网格的节点编号**索引。RMesh 通过形函数插值将旧网格节点上的值映射到新网格节点。

### 4.6 重启 INP (`disk-restart.inp`)

完整的重启输入文件，包含模具 + 新锻件 + 场量初始条件 + 新分析步。

**编号顺序：**

1. 模具节点（保持原始 INP 中的编号，坐标来自 FRD 变形后的位置）
2. 新锻件节点（续接在模具最大节点号之后）
3. 模具单元（保持原始编号）
4. 新锻件单元（续接在模具最大单元号之后）

**集合映射：**

- `ALLOY_NODE`：更新为新锻件节点 ID 列表
- `ALLOY_ELEMENT`：更新为新锻件单元 ID 列表
- `ALLOY_SYMMETRY`：重新识别对称面上的节点
- `_ALLOY_SURF_s1` ~ `_ALLOY_SURF_s4`：重新提取表面
- 模具的各集合保持不变

**场量初始条件：**
```inp
*INITIAL CONDITIONS, TYPE = TEMPERATURE
*INCLUDE, INPUT=disk.nt
*INITIAL CONDITIONS, TYPE = STRESS
*INCLUDE, INPUT=disk.st
*INITIAL CONDITIONS, TYPE = SOLUTION
*INCLUDE, INPUT=disk.stdv
```

**分析步时间：** 总时间减去已完成时间（从 .sta 或 FRD 推断）。

---

## 5. 数据依赖关系

```
disk.inp ──────────────┐
                       ├──→ solver ──→ disk.frd ──→ RMesh ──→ disk.geo ──→ gmsh
                       │                                    │
                       │                                    ├──→ disk.TEMP
                       │                                    ├──→ disk.STRESS
                       │                                    ├──→ disk.SDV
                       │                                    └──→ disk.DISP
                       │
                       │  disk-Gmesh.inp ──→ Abaqus ──→ disk-remeshed.inp
                       │                                         │
                       │  disk.TEMP + STRESS + SDV + DISP ────→  │
                       │  disk-remeshed.inp ──────────────────→  │
                       │  disk.inp ──────────────────────────→  │
                       │                                         ↓
                       │                                    RMesh 插值 + 组装
                       │                                         │
                       │                    disk.nt + disk.st + disk.stdv
                       │                    disk-restart.inp
                       │                                         │
                       └─────────────────────────────────────────┘
                                                                  ↓
                                                            solver 续算
```

---

## 6. RMesh 插值算法

RMesh.exe 内置的场量插值方法（因无源代码，根据行为推断）：

**推测方法：反距离加权 (IDW) 或最近邻插值**

- 对每个新网格节点，在旧网格中搜索最近的 N 个节点
- 按距离反比加权平均场量值
- 截断距离：超过旧网格特征尺寸一定倍数则使用最近邻

**局限性：**
- IDW 不保形——应力/应变场的梯度精度下降
- 不利用形函数信息——浪费了 FEM 网格的拓扑结构
- 对累积量（等效塑性应变）不保单调性

---

## 7. 为什么现有方案无法自动化

| 障碍 | 原因 |
|------|------|
| RMesh.exe 无 CLI | PyInstaller 打包的 tkinter GUI，所有操作依赖按钮点击和文件对话框 |
| Gmsh 网格质量差 | 需 Abaqus 手动修复单元和节点，无法在脚本中完成 |
| 人工判断畸变时机 | 用户目视 .sta 输出，没有程序化的雅可比计算 |
| 进程分离 | GUI Kill solver → 手动 RMesh → 手动重启，三段完全独立 |
| 二进制黑盒 | RMesh.exe 无源码，无法修改或集成 |

---

## 8. 自动化方案的替代设计

针对以上问题，自动化方案的核心决策：

### 8.1 替代 RMesh.exe

用 Python CLI 脚本完全重新实现 RMesh 的功能：
- `frd_reader.py` → 解析 FRD（**已完成**）
- `inparser.py` → 解析 INP，区分模具/锻件
- `surface_extract.py` → 提取变形表面 STL（带 Taubin 光顺 + 接触面投影）
- `tetgen_inp.py` → TetGen 输出转换 INP + 集合命名
- `die_penetration.py` → 模具干涉检测与节点修正
- `field_mapping.py` → 形函数插值（替代 IDW）
- `restart_builder.py` → 组装 restart INP
- `remesh_orchestrator.py` → 总调度 CLI 入口

### 8.2 替代 Gmsh → TetGen

- TetGen 生成 Delaunay 四面体网格，质量远好于 Gmsh
- 无需 Abaqus 修复步骤
- 纯命令行接口，可脚本化

### 8.3 求解器深度绑定

- 畸变检测（最小雅可比）在 solver.c 主循环中实现
- 检测到畸变 → `system("python remesh_orchestrator.py")` → 加载新网格续算
- 求解器进程不退出，重划分是内部的一步操作

### 8.4 场量映射升级

- IDW → 形函数插值（利用旧单元形函数在新节点局部坐标处精确求值）
- 对积分点场量先外推再插值
- 边界外节点投影 + 面形函数插值

---

## 9. 商业软件对标：Simufact Forming 15 自动重划分架构分析

> 安装路径：`D:\simufact\SimufactForming15\`（基于 MSC Marc 求解器 + Simufact 专有网格/映射工具）

### 9.1 整体架构

Simufact Forming 的自动重划分采用**求解器 + 独立网格工具 + 场量映射 + 自动重启**的架构：

```
sfForming.exe (GUI, Qt5)
  │ 配置 .ini → 提交求解
  ▼
sf_exeauto.exe (自动重启编排器, 200KB)
  │ -au 1 模式：循环执行以下:
  │
  ├─→ sfmarc.exe (MSC Marc 求解器, 95MB)
  │     运行 N 个增量步 → 检测网格畸变/达到重划周期
  │     → 暂停分析 → 保存 checkpoint
  │
  ├─→ sfHexMesh.exe / sfMultiMesh.exe (网格重划分)
  │     .bat 包装脚本传递参数 (-p volumeTol, -p attempts...)
  │     调用底层网格引擎: tetmesh.dll (Simmetrix) / mg-tetra.dll (MeshGems/Distene)
  │     → 输出新网格
  │
  ├─→ sfRemap.exe (场量映射, 201KB)
  │     sfRemap_x64.dll 核心算法
  │     旧网格 → 新网格: 应力、应变、温度、损伤等状态变量
  │
  └─→ sfmarc.exe 重启续算
       → 循环直到: 网格再次畸变 或 求解完成
```

**关键洞察：** 架构和我们设计的 `solver → system("python remesh_orchestrator") → 加载续算` 完全一致。Simufact 用 `sf_exeauto.exe` 做编排器，我们直接用 solver 自身做编排器——**更深的绑定**。

### 9.2 核心组件清单

#### 求解器层（`sfMarc\bin\win64i8\`）

| 文件 | 大小 | 功能 |
|------|------|------|
| `sfmarc.exe` | 95 MB | MSC Marc 求解器（含接触、材料、非线性） |
| `sf_exeauto.exe` | 200 KB | **自动重启编排器** —— 监控求解、触发重划分、重启 |
| `sf_exeddm.exe` | - | DDM 并行域分解执行器 |

**命令行参数（`run_sfMarc.bat` 中提取）：**

```
-au y|n      启用自动重启（auto-restart），默认 n
-me <mesh>   指定网格器类型（手动控制重划分）
-b <jobname> 作业名
```

当 `-au 1` 时，`sf_exeauto.exe` 接管流程：
```batch
set run_job="%BINDIR%\sf_exeauto" %run_job0% "%execnm%" ... -me "%mesh%"
```

#### 网格层（`sfTools\sfMeshing\bin\win64\`）

| 文件 | 大小 | 用途 |
|------|------|------|
| `sfHexMesh.exe` | 1.0 MB | **六面体网格重划分**（锻造默认） |
| `sfMultiMesh.exe` | 301 KB | **多策略网格器** —— 一种策略失败时自动切换另一种 |
| `sfQuadMesh.exe` | 434 KB | 四边形面网格划分 |
| `sfMesher.exe` | 490 KB | 通用网格引擎入口 |
| `afmesh2d.exe` | 4.5 MB | MSC Advancing Front 2D |
| `afmesh3d.exe` | 5.3 MB | MSC Advancing Front 3D |

**底层网格引擎 DLL：**

| DLL | 大小 | 来源 | 用途 |
|-----|------|------|------|
| `tetmesh.dll` | 6.6 MB | Simmetrix | 四面体网格引擎 |
| `mg-tetra.dll` | 3.3 MB | Distene (MeshGems) | 高质量四面体网格 |
| `meshgems.dll` | 461 KB | Distene | MeshGems 接口 |
| `tetadapt.dll` | 2.0 MB | - | 自适应四面体细化 |

**关键发现：Simufact 使用两个商业网格引擎——Simmetrix 和 MeshGems(Distene)——和我们用 TetGen 的决策一致，都是为获得高质量网格。**

#### 映射层（`sfTools\sfMeshing\bin\win64\`）

| 文件 | 大小 | 用途 |
|------|------|------|
| `sfRemap.exe` | 201 KB | 场量映射主程序 |
| `sfRemap_x64.dll` | 404 KB | 映射核心算法库 |
| `sfRemap.bat` | ~500B | 批处理包装脚本 |

**sfHexMesh 参数（来自 `sfHexmesh.bat`）：**

```
-p verboseMode <level>     调试输出 (100 = 最大)
-p force 1                 即使网格质量差也强制输出
-p volumeTol <number>      体积容差 (0.0~1.0, 如 0.005 = 0.5%)
-p attempts <number>       重试次数（逐步放宽容差）
-p refine_sym 1            抑制对称面细化
-p ring_center_is_origin 1 环形轧制中心在原点
```

**sfQuadMesh 模具附近细化参数（来自 `sfQuadmesh.bat`）：**

```
-p refine_tool_<N> <toolId>          细化目标模具 ID
-p refine_tool_level_<N> <level>     细化级别
-p refine_tool_distance_<N> <distance> 细化距离
```

### 9.3 重划分触发机制

通过 `sfForming\settings\` 中的 INI 配置文件控制：

**开关：**
```ini
[Process]
AutomaticTetRemesh=1     ; 1=启用自动四面体重划分

[Fe]
; 重划分间隔（负数 = 每 N 增量步）
hex/ControlNumberOfCycles=-20      ; 六面体: 每 20 步
tet/ControlNumberOfCycles=-50      ; 四面体: 每 50 步
solidshell/ControlNumberOfCycles=-20
quad/ControlNumberOfCycles=-20

; 自适应步长触发条件
StepDistortion=0.5        ; 变形率 > 0.5 触发
StepStrain=0.05           ; 应变增量 > 0.05 触发
StepTemperature=100       ; 温度增量 > 100 触发
StepDisplacement=0.0      ; 位移触发（关闭）

; 网格器类型选择
3D/MesherType=5           ; 5=Hex, 6=Tet, 10=Quadtree, 11=Patran, 12=MOM, 13=RET
2D/MesherType=2           ; 2=AdvancingFrontQuad
3D/MeshElementType=7      ; 7=Hex, 8=Tet

; 折叠检测 / Flowmesh
FlowmeshSurfaceDistanceFactor=0.1
FlowmeshMaxElementCountFactor=10.0
```

**重划分失败处理：**

```ini
RepeatFailedRemeshing=1    ; 重划分失败时自动重试
```

### 9.4 场量映射（sfRemap）

`sfRemap.exe` 负责所有状态变量从旧网格到新网格的传递：

- 应力张量（6 分量）
- 应变张量 / 塑性应变
- 温度场
- 损伤变量
- 所有用户定义的状态变量

底层实现通过 `sfRemap_x64.dll`（404KB），推测算法为**形函数插值或体积加权插值**（与 DEFORM 类似的 FEM-based 方法）。

### 9.5 对本项目自动化的关键启示

| Simufact 做法 | 我们的对应方案 | 启示 |
|---------------|---------------|------|
| `sf_exeauto.exe` 外部编排器 | solver 内部 `system()` 调用 | 更深绑定，更简单 |
| 多网格器策略（Hex/Tet/Quad） | TetGen（专注四面体） | 第一期专注 Tet 即可 |
| `sfMultiMesh` 多策略回退 | die_penetration 三层防线 | 失败→回退→修正机制 |
| `.ini` 配置控制所有重划分参数 | 环境变量 `AESIM_REMESH_*` | 可考虑 INI/JSON 配置文件 |
| `ControlNumberOfCycles` 步数 + 变形双重触发 | 雅可比阈值触发 | 更精确（每步检查 Jacobian） |
| `volumeTol` 体积保持约束 | 光顺体积变化 < 3% | 已纳入方案 |
| `refine_tool_distance` 模具附近细化 | 接触面投影 + 局部细化 | 可增强方向 |
| 两个商业网格引擎 | TetGen 开源替代 | 质量需验证 |
| Batch 包装脚本（参数通过 `-p` 传递） | Python CLI（argparse 参数传递） | 更好维护 |
| 分布式 MPI 并行（Intel MPI runtime） | 单进程 | 后续可扩展 |

---

## 10. 最终目标：实现 DEFORM / Simufact Forming 级别的自动重划分

### 10.1 对标产品能力

DEFORM 和 Simufact Forming 是锻造仿真领域的行业标杆，其自动网格重划分是核心竞争力：

| 能力 | DEFORM | Simufact Forming |
|------|--------|------------------|
| 畸变检测 | 自动（每一步/每N步检查） | 自动 |
| 重划分触发 | 无需人工干预 | 无需人工干预 |
| 网格划分 | 内置四面体网格器 | 内置四面体网格器 |
| 场量映射 | 自动形函数/体积加权插值 | 自动 |
| 续算 | 自动重启 | 自动重启 |
| 重划分次数 | 不限（全自动闭环） | 不限 |
| 用户操作 | 提交作业即可 | 提交作业即可 |

### 10.2 本软件的目标

实现与 DEFORM/Simufact Forming **同等水平的全自动网格重划分闭环**：

```
用户提交一次 disk.inp
       │
       ▼
  ┌─────────────────────────────────────────────┐
  │          全自动闭环（无需人工干预）             │
  │                                             │
  │  求解 → 畸变检测 → 表面提取 → 网格重划分       │
  │    ↑                                ↓       │
  │    └──── 续算 ← 场量映射 ← 重启组装 ←─┘       │
  │                                             │
  │  可循环 N 次，直到求解完成或达到最大次数        │
  └─────────────────────────────────────────────┘
       │
       ▼
  GUI 显示"计算完成"（用户全程无需盯屏）
```

### 10.3 核心技术指标

| 指标 | 目标值 |
|------|--------|
| 重划分时间占比 | < 10% 的总求解时间 |
| 场量插值精度 | 与旧网格对比偏差 < 5% |
| 网格质量 | 新网格最小雅可比 > 0.3 |
| 首次成功率 | 重划分后首步收敛率 > 90% |
| 连续重划分 | 支持 20 次以上自动循环 |
| 体积保持 | 光顺 + 重划后体积变化 < 3% |
| 模具穿透 | 零穿透（三层防线保障） |

---

## 11. 参考算例

**位置：** `D:\AESimFM\INP_test\4BXYB-GN001-001(大变形、大应变求解功能测试)\`

**关键文件：**

| 文件 | 说明 |
|------|------|
| `disk.inp` | 原始锻造 INP（包含模具 + 锻件 ALLOY_ELEMENT） |
| `disk.frd` | 一次完整求解的结果（约 162MB） |
| `disk.geo` | RMesh 从变形网格提取的 Gmsh 几何文件 |
| `disk-remeshed.inp` | Abaqus 修复后的新锻件网格 |
| `disk-restart.inp` | 重启文件（模具 + 新锻件 + 场量映射） |
| `disk.TEMP` | 旧网格温度场（节点值） |
| `disk.STRESS` | 旧网格应力场（6 分量） |
| `disk.SDV` | 旧网格状态变量（25 列） |
| `disk.DISP` | 旧网格位移（3 分量） |
