# 网格自动重划分——详细方案设计

## 1. 背景与目标

### 1.1 现状问题

锻造大变形仿真中，网格随材料流动逐渐畸变。当前流程：

- 用户必须**全程盯屏**，凭经验判断畸变时机
- 手动中断 → 手动导入 FRD → 手动操作 RMesh → 手动 Gmsh → 手动插值 → 手动提交续算
- 如果人不在，网格畸变后求解器继续算，效率极低甚至发散浪费机时
- RMesh.exe 是闭源 tkinter GUI，无命令行接口，无法自动化

### 1.2 目标

实现**网格畸变自动检测 → 自动重划分 → 自动场量映射 → 自动续算**闭环，用户提交一次作业后无需人工干预。

---

## 2. 现有代码架构回顾

### 2.1 求解器（solver/）

- **主循环**：[solver.c:193-1649](code/test/all/solver/solver.c) — `while(istat>=0)` 每次迭代处理一个 STEP
- **关键数据结构**：`co[3*nk]` 节点坐标，`kon[nkon]` 单元连接，`sti[6*mi[0]*ne]` 应力，`xstate[...]` 状态变量
- **重启机制**：[solver.c:1622-1647](code/test/all/solver/solver.c) 每步结束时调用 `restartwrite_`
- **链接库**：libcalculix_base.a（CalculiX 核心） + libaesim_solver_ext.a（AES 覆盖层），无网格库
- **编译**：C/Fortran 混合，Makefile 构建，产物 `solver/solver`

### 2.2 GUI（gui/）

- **提交求解**：[mainwindow.cpp:3351](code/test/all/gui/src/mainwindow.cpp) `HIPSolveActOpenSlot()` — 创建 QProcess，启动 solver
- **进度监控**：[mainwindow.cpp:3606](code/test/all/gui/src/mainwindow.cpp) `UpdateSolverStatusFromSta()` — 每 2 秒轮询 .sta 文件
- **终止求解**：[mainwindow.cpp:3436](code/test/all/gui/src/mainwindow.cpp) `HIPSolveActKillSlot()` — QProcess::kill() 硬杀
- **结果加载**：用户在 QPostWigFile 手动导入 .frd
- **FRD 解析**：[QFrdDataPro.cpp:18](code/test/all/gui/src/QFrdDataPro.cpp) `ReadFileData()` — 标准 CalculiX FRD 格式

### 2.3 现有 Windows 工具（D:\WeICME\WeICMECAE\）

| 工具 | 作用 | 自动化可行？ |
|------|------|-------------|
| RMesh.exe | tkinter GUI：提取表面(.geo) + 场量(.temp/.stress/.disp) + 场量插值(.nt/.st/.stdv) + 组装 restart.inp | **否**，无 CLI |
| gmsh.exe | 读 .geo，网格划分，输出 .inp | **是**，有 CLI |
| OpenCASCADE(TK*.dll) | 几何内核，被 RMesh.exe 调用 | 间接 |

---

## 3. 总体架构设计

### 3.1 设计原则：深度绑定

重划分不是求解器的"外部工具"，而是求解器的**内置能力**。遵循以下原则：

1. **求解器主导**：畸变检测在求解器内部，重划分调用也由求解器发起，GUI 不参与调度循环
2. **统一数据格式**：求解器输出 checkpoint → 重划分工具消费 → 求解器读入 restart，全程使用 FRD + INP 作为交换格式（求解器已有的原生格式）
3. **同进程内闭环**：求解器检测到畸变 → 调用 system() 执行重划分脚本 → 脚本返回后求解器立即加载新网格续算，**求解器进程不退出**
4. **Python 重划分模块作为求解器的子进程**：不是独立工具，而是求解器在特定条件下激活的功能分支

### 3.2 为什么要替代 RMesh.exe

1. RMesh.exe 是 tkinter GUI，**无命令行接口**，无法被求解器自动调用
2. RMesh.exe 依赖 Gmsh，Gmsh 网格质量差，需 Abaqus 辅助——这一步也**无法自动化**
3. PyInstaller 打包的闭源 exe，跨平台部署不可能（WSL Linux 侧无法运行）

### 3.3 为什么用 TetGen 而不是 Gmsh

1. TetGen 网格质量远好于 Gmsh（Delaunay 四面体优化），**无需 Abaqus 修复步骤**
2. 纯命令行，输入 STL/PLC，输出 .node/.ele，可直接集成
3. 学术免费，源码可编译

### 3.4 架构图：深度绑定

```
┌─────────── GUI (Qt4/C++) ───────────────────────────┐
│                                                      │
│  用户提交 disk.inp (一次性)                            │
│    ↓                                                 │
│  QProcess 启动 solver -i disk                        │
│    ↓                                                 │
│  QTimer 每 2 秒轮询 .sta 显示进度                     │
│    ↓                                                 │
│  QProcess::finished → 通知用户"计算完成"               │
│                                                      │
│  GUI 只负责：提交作业 + 显示进度 + 显示结果             │
│  重划分是整个过程的内部实现细节，GUI 不参与调度          │
└──────────────────────────────────────────────────────┘
         │ 启动
         ▼
┌─────────── solver (C/Fortran) ──────────────────────┐
│                                                      │
│  main loop (while istat >= 0)                        │
│    │                                                 │
│    ├─ calinput_() 读入 step 定义                      │
│    ├─ 矩阵组装                                       │
│    ├─ nonlingeo_() 非线性迭代求解                     │
│    ├─ results_() 写结果                               │
│    │                                                 │
│    ├─ ★ 网格畸变检测 ★                                │
│    │   min_jac = compute_min_jacobian(co, kon, ...)   │
│    │   if (min_jac < threshold) {                     │
│    │     ┌──────────────────────────────────┐        │
│    │     │  ① 写 checkpoint FRD              │        │
│    │     │  ② 写信号文件(.remesh_signal)      │        │
│    │     │  ③ system("python remesh_orch...")│        │
│    │     │     ↓ 子进程执行:                  │        │
│    │     │     frd_reader → surface_extract │        │
│    │     │     → tetgen → tetgen_inp        │        │
│    │     │     → field_mapping              │        │
│    │     │     → restart_builder            │        │
│    │     │     → 输出 disk-restart.inp       │        │
│    │     │  ④ 检查是否成功                   │        │
│    │     │  ⑤ 读入新网格(co,kon,ipkon...)   │        │
│    │     │  ⑥ 读入映射场量(sti,xstate...)   │        │
│    │     │  ⑦ 重建稀疏矩阵结构               │        │
│    │     │  ⑧ goto 继续计算                  │        │
│    │     └──────────────────────────────────┘        │
│    │   }                                             │
│    │                                                 │
│    └─ restartwrite_() 写重启文件                      │
│                                                      │
│  关键：solver 进程始终存活，重划分是它内部的一步操作    │
└──────────────────────────────────────────────────────┘
         │ system() 调用
         ▼
┌─────────── remesh_orchestrator.py (Python CLI) ─────┐
│                                                      │
│  输入：jobname.frd + jobname.inp + .remesh_signal     │
│                                                      │
│  ① frd_reader.py     → 解析 FRD                       │
│  ② inparser.py       → 解析 INP，区分模具/锻件         │
│  ③ surface_extract.py → 提取锻件变形表面 STL           │
│  ④ tetgen (system)   → 四面体网格重划分                │
│  ⑤ tetgen_inp.py     → TetGen 输出 → disk-remeshed.inp│
│  ⑥ field_mapping.py  → 旧网格场量插值到新网格           │
│  ⑦ restart_builder.py → 组装 disk-restart.inp          │
│                                                      │
│  输出：disk-restart.inp + disk.nt + disk.st + disk.stdv│
│  退出码：0=成功，非 0=失败（求解器据此决定是否重试或退出）│
└──────────────────────────────────────────────────────┘
```

### 3.5 数据流（重划分触发时）

```
求解器内存中                           Python 子进程                   求解器内存中
  co, kon, sti, xstate, ...                                          (重新加载后)
       │                                                               ▲
       │ 写入                           处理                            │
       ▼                                                               │
  jobname.frd ─────────────────→ frd_reader ─┐                        │
  jobname.inp ─────────────────→ inparser    │                        │
       │                                     ├→ surface_extract       │
       │                                     │     ↓                  │
       │                                     │  surface.stl            │
       │                                     │     ↓                  │
       │                                     │  tetgen                 │
       │                                     │     ↓                  │
       │                                     │  surface.1.node + .ele  │
       │                                     │     ↓                  │
       │                                     │  tetgen_inp             │
       │                                     │     ↓                  │
       │                                     │  disk-remeshed.inp      │
       │                                     │     ↓                  │
       │                                     ├→ field_mapping          │
       │                                     │     ↓                  │
       │                                     │  disk.nt, disk.st,      │
       │                                     │  disk.stdv              │
       │                                     │     ↓                  │
       │                                     └→ restart_builder        │
       │                                           ↓                  │
       │                                     disk-restart.inp ────→ 加载
       │                                      + .nt .st .stdv
```

重划分只是 `while(istat>=0)` 主循环中的一段特殊处理逻辑——检测到畸变 → 触发重划分 → 重新分配内存 → 加载新网格 → 重建矩阵 → 继续下一增量步。用户看到的是一个连续的计算过程。

### 3.6 2D 轴对称 vs 3D 的区别处理

当前参考算例 `disk` 是 2D 轴对称（CAX4/CAX3 单元），但重划分框架对 2D 和 3D **统一设计，仅在网格生成环节分流**。

| 环节 | 2D 轴对称 | 3D 实体 |
|------|----------|--------|
| FRD 解析 | 相同（`frd_reader.py` 自动适配） | 相同 |
| INP 解析 | 相同（`inparser.py` 自动适配） | 相同 |
| 变形表面提取 | 提取 2D 边界轮廓曲线（边缘判定） | 提取 3D 自由面 STL（面判定） |
| 表面光顺 | 2D Taubin 曲线光顺 | 3D Taubin 曲面光顺 |
| 网格划分 | **Triangle** 或 Gmsh 2D（三/四边形） | **TetGen**（四面体） |
| 模具穿透检测 | 2D 到模具曲线有向距离 | 3D 到模具面有向距离 |
| 场量映射 | 相同形函数插值（2D 形函数 vs 3D） | 相同 |
| 重启组装 | 相同编号约定 | 相同 |

**关键：** 二维轴对称本质上还是 2D 平面问题（r-z 平面），网格划分不需要四面体。TetGen 换成 Triangle（开源 2D Delaunay 三角形网格器，MIT 许可证）。其他模块全部复用。

---

## 4. 详细接口设计

### 4.1 求解器侧

**畸变检测位置：** solver.c，每个增量步结束后、restartwrite 之前（约第 1622 行附近）

**条件：** 仅非线性大变形分析（`nmethod == 1 && iperturb[0] >= 2`）

**检测逻辑（伪代码）：**

```c
if (nmethod == 1 && iperturb[0] >= 2) {
    min_jac = compute_min_jacobian(co, kon, ipkon, lakon, ne);
    if (min_jac < jacobian_threshold) {
        // ① 写入 checkpoint FRD（包含当前所有步的结果）
        FORTRAN(writefrd, ...);
        // ② 写入信号文件（当前步号、时间、剩余时长等）
        write_remesh_signal_file();
        // ③ 同步调用 Python 重划分流水线
        ret = system("python remesh_orchestrator.py jobname");
        if (ret != 0) { /* 重划分失败，退出报错 */ exit(1); }
        // ④ 读取新网格 co, kon, ipkon, lakon
        read_new_mesh_from_restart("jobname-restart.inp");
        // ⑤ 读取映射场量 sti, eme, xstate
        read_mapped_fields("jobname.nt", "jobname.st", "jobname.stdv");
        // ⑥ 重建稀疏矩阵结构（ne/nk 已变）
        icascade = 1;
        // ⑦ 回到主循环顶部继续计算
        continue;
    }
}
```

**求解器进程始终存活。** 重划分是主循环内的一段分支，不 exit。

**信号文件（JSON）：** `.jobname.remesh_signal`

```json
{
  "step_number": 384,
  "total_time": 15.0,
  "step_time": 3.5,
  "remaining_time": 11.5,
  "element_set": "ALLOY_ELEMENT",
  "min_jacobian": 0.07
}
```

**.sta 文件扩展：** solver 在重划分前后向 .sta 写入标记行，GUI 据此更新显示：

```
REMESH 1 START min_jac=0.07
REMESH 1 END success nodes=4521 elems=18084
```

### 4.2 Python 重划分流水线

#### 4.2.1 frd_reader.py — FRD 解析器

**已完成。** 功能：

- `parse_frd(filepath) → FrdData`：解析 .frd 文件
- 读取：节点坐标、单元连接、每步结果（DISP/STRESS/NDTEMP/FLUX/TOSTRAIN/ERROR）
- `deformed_nodes`：最后一个 DISP 步的变形后节点坐标
- `get_last_step_stress / temperature / state_vars()`：提取最后一步场量

#### 4.2.2 surface_extract.py — 表面提取器

**输入：** FrdData + 锻件单元集合名（如 ALLOY_ELEMENT）

**输出：** surface.stl（二进制 STL 格式变形体外表面）+ 表面节点 ID 列表

**算法：**

1. 遍历锻件单元的所有面
2. 判断每个面是否为**自由面**（只被一个单元引用，或被锻件单元和非锻件单元共享）
3. 将自由面的三角形/四边形转为 STL 三角面片
4. 使用变形后节点坐标（`FrdData.deformed_nodes`）

```python
def extract_surface(frd_data, element_set_name, inp_path):
    """从 FRD 变形网格中提取指定单元集的表面
    Returns: (surface_stl_path, surface_node_ids)
    """
```

#### 4.2.3 inparser.py — INP 文件解析器

**功能：** 解析 INP 文件，通过单元集合名区分锻件和模具。**不在指定集合中的都是模具。**

```python
class InpData:
    def __init__(self):
        self.nodes = {}           # {id: (x,y,z)}
        self.elements = {}        # {id: (type_str, [node_ids])}
        self.nsets = {}           # {name: [node_ids]}
        self.elsets = {}          # {name: [elem_ids]}
        self.surfaces = {}        # {name: (elset, face)}
        self.materials = {}       # 材料原始文本块
        self.steps = []           # 分析步原始文本块
        self.boundaries = []      # *BOUNDARY 原始文本
        self.amplitudes = []      # *AMPLITUDE 原始文本
        self.physical_constants = ""
        self.initial_conditions = []
        self.die_nodes = []       # 模具节点 ID 列表
        self.die_elements = []    # 模具单元 ID 列表
        self.billet_nodes = []    # 锻件节点 ID 列表
        self.billet_elements = [] # 锻件单元 ID 列表

def parse_inp(filepath, billet_elset_name) -> InpData:
    """解析 INP，区分模具和锻件"""
```

#### 4.2.4 field_mapping.py — 场量插值映射

**算法：形函数插值（Shape Function Interpolation）**

不使用简单距离加权，而是用旧单元形函数精确插值——这是 DEFORM 和 Abaqus 使用的方法。

**流程：**

1. 对每个新网格节点，用 KD-Tree 定位其落在旧网格哪个单元内
2. 用重心坐标判断是否在四面体内，并计算局部坐标 (ξ,η,ζ)
3. 用旧单元形函数在该局部坐标处插值
4. 对积分点场量（应力/应变/SDV），先外推到节点再插值
5. 边界外节点投影到最近旧单元面，用面形函数插值
6. 插值后做一步零增量步自平衡迭代恢复平衡

**输出：** disk.nt、disk.st、disk.stdv、disk.disp（每行 `node_id, values...`）

```python
def map_fields(old_nodes, old_fields, new_nodes, output_dir):
    """
    old_nodes: {node_id: (x,y,z)} 变形后坐标
    old_fields: {field_name: {node_id: [values]}}
    new_nodes: {new_node_id: (x,y,z)}
    Outputs: disk.nt, disk.st, disk.stdv, disk.disp in output_dir
    Returns: dict of {field_name: {new_node_id: [values]}}
    """
```

#### 4.2.5 restart_builder.py — 重启文件构建器

**这是最关键的模块，需严格遵守原始 RMesh 的编号约定。**

**流程：**

1. 读取原始 disk.inp → 提取模具节点/单元、所有集合、材料、边界条件等
2. 从 disk.frd 更新模具节点坐标为变形后位置
3. 写入 disk-restart.inp：
   - 先写模具节点（保持原始编号）
   - 再写模具单元（保持原始编号和集合）
   - 保留模具相关的 \*NSET、\*ELSET、\*SURFACE
   - 保留材料定义、物理常数、幅值曲线、边界条件
   - **不写初始温度**（锻件温度由 .nt 文件提供）
   - 写新的分析步（时长 = 剩余时长）
4. 读取 disk-remeshed.inp（TetGen 生成的新锻件网格）→ 提取节点坐标和单元连接
5. **按编号顺序**将锻件节点/单元追加到 restart.inp：
   - 新锻件节点续接在模具节点编号之后
   - 新锻件单元续接在模具单元编号之后
6. 写入初始条件：
   ```inp
   *INITIAL CONDITIONS, TYPE = TEMPERATURE
   *INCLUDE, INPUT=disk.nt
   *INITIAL CONDITIONS, TYPE = STRESS
   *INCLUDE, INPUT=disk.st
   *INITIAL CONDITIONS, TYPE = SOLUTION
   *INCLUDE, INPUT=disk.stdv
   ```

```python
def build_restart(inp_path, frd_data, remeshed_inp_path,
                  billet_elset_name, field_files, remaining_time,
                  output_path):
    """
    inp_path: 原始 disk.inp
    frd_data: FrdData 对象
    remeshed_inp_path: TetGen 生成的新锻件 inp (disk-remeshed.inp)
    billet_elset_name: 锻件单元集合名 (如 ALLOY_ELEMENT)
    field_files: {'.nt': path, '.st': path, '.stdv': path}
    remaining_time: 剩余模拟时长
    output_path: 输出 restart.inp 路径
    """
```

#### 4.2.6 remesh_orchestrator.py — 总调度脚本

**命令行：** `python remesh_orchestrator.py jobname [--elset ALLOY_ELEMENT]`

**流程：**

```
1. 读取 .remesh_signal 信号文件
2. frd_reader.py 解析 jobname.frd
3. inparser.py 解析 jobname.inp，提取模具信息
4. surface_extract.py 从锻件变形轮廓提取表面，光顺后输出 STL
5. tetgen -pq1.4a200 surface.stl → 生成 surface.1.node + surface.1.ele
6. tetgen_inp.py 将 TetGen 输出转为 disk-remeshed.inp
7. die_penetration.py 检测模具干涉 → 修正穿透节点
8. field_mapping.py 形函数插值场量映射
9. restart_builder.py 组装 disk-restart.inp
10. 输出完成标志 → solver 检测后加载新网格续算
```

---

## 5. GUI 修改设计

### 5.1 修改文件：`gui/src/mainwindow.cpp`

由于采用深度绑定（重划分在 solver 内部完成），GUI 改动量很小：

**改动点 1：** 解析 .sta 中的重划分信息

solver 在重划分时在 .sta 中追加 `REMESH_START` / `REMESH_END` 行。GUI 在 `UpdateSolverStatusFromSta()` 中识别这些行，更新信息窗口。

**改动点 2：** INP 写入时标记锻件集合

`CRWManage` 写入 INP 时在锻件集合名后添加注释标记：

```inp
*Elset, elset=ALLOY_ELEMENT  **REMESH_BILLET**
```

Python 解析器据此自动识别锻件集合，而非依赖硬编码名称。

### 5.2 新增配置对话框

在 `QHPSubmissionDlg` 增加：

- "启用自动重划分" 复选框
- "最大重划分次数" 输入框（默认 20）
- "雅可比阈值" 输入框（默认 0.1）

这些参数通过环境变量传递给 solver：

- `AESIM_REMESH=1` — 启用
- `AESIM_REMESH_MAX=20` — 最大次数
- `AESIM_REMESH_JAC=0.1` — 阈值

---

## 6. 求解器修改设计

### 6.1 修改文件：`solver/solver.c`

**改动点 1：** 新增雅可比计算函数

调用 Fortran 中已有的 Jacobian 计算逻辑（在 `results.f` 的非线性迭代中已计算）。封装为：

```c
static double compute_min_jacobian(double *co, ITG *kon, ITG *ipkon,
                                    char *lakon, ITG ne);
```

**改动点 2：** 畸变检测 + 重划分触发（深度绑定，不退出）

在 `solver.c` 的 `while(istat>=0)` 循环中，增量步收敛后：

```c
int remesh_enabled = getenv_int("AESIM_REMESH", 1);
double remesh_jac = getenv_double("AESIM_REMESH_JAC", 0.1);
int remesh_max = getenv_int("AESIM_REMESH_MAX", 20);

static int remesh_count = 0;

if (remesh_enabled && nmethod == 1 && iperturb[0] >= 2) {
    double min_jac = compute_min_jacobian(co, kon, ipkon, lakon, ne);

    if (min_jac < remesh_jac && remesh_count < remesh_max) {
        remesh_count++;
        printf("[REMSH] Remesh #%d triggered (min_jac=%.4f < %.4f)\n",
               remesh_count, min_jac, remesh_jac);

        // ① 写 checkpoint FRD
        FORTRAN(writefrd, (&istep, &nset, co, kon, ipkon, lakon, ...));
        // ② 写信号文件
        write_remesh_signal(jobname, istep, total_time, &remesh_count);
        // ③ 调用 Python 重划分流水线（同步等待）
        char cmd[1024];
        snprintf(cmd, sizeof(cmd),
                 "python %s/scripts/remesh_orchestrator.py %s",
                 aesim_scripts_dir, jobname);
        int ret = system(cmd);
        if (ret != 0) {
            printf("[REMSH] ERROR: orchestrator failed with code %d\n", ret);
            exit(1);
        }
        // ④ 加载新网格（重新分配 + 读取）
        reload_mesh_from_restart(jobname, &co, &kon, &ipkon, &lakon,
                                 &ne, &nk, &nkon);
        // ⑤ 加载映射场量
        reload_fields_from_restart(jobname, sti, eme, xstate, ener, ne);
        // ⑥ 重建稀疏矩阵
        icascade = 1;

        printf("[REMSH] Remesh #%d complete. New mesh: %d nodes, %d elements\n",
               remesh_count, nk, ne);
        continue;
    }
}
```

---

## 7. 完整自动化流程

```
用户提交 disk.inp（一次性操作）
     │
     ▼
GUI 启动 solver -i disk (QProcess)
     │
     ▼
┌─ solver while(istat>=0) ──────────────────────────────────┐
│     │                                                      │
│     ▼                                                      │
│  每增量步收敛后检查雅可比                                    │
│     │                                                      │
│     ├── 正常 → 写结果 → 继续下一增量步                       │
│     │                                                      │
│     ├── 畸变 → 触发重划分（求解器不退出！）                  │
│     │     │                                                │
│     │     ├─ ① 写 checkpoint FRD                           │
│     │     ├─ ② 写 .remesh_signal                           │
│     │     ├─ ③ system("python remesh_orchestrator.py")     │
│     │     │      ↓ 子进程执行:                              │
│     │     │      frd_reader → inparser → surface_extract   │
│     │     │      → tetgen → tetgen_inp → die_penetration   │
│     │     │      → field_mapping → restart_builder         │
│     │     ├─ ④ 读取 disk-restart.inp → 新网格              │
│     │     ├─ ⑤ 读取 .nt .st .stdv → 映射场量               │
│     │     ├─ ⑥ icascade=1 重建稀疏矩阵                     │
│     │     └─ ⑦ continue → 继续下一增量步                    │
│     │                                                      │
│     └─ istat<0 → 正常结束                                  │
└────────────────────────────────────────────────────────────┘
     │
     ▼
QProcess::finished → GUI 显示"计算完成"
（重划分在求解器内部闭环，GUI 只需在 .sta 中增加重划分进度行）
```

### 7.1 表面光顺处理

**问题：** 网格畸变意味着单元严重扭曲，提取的表面轮廓锯齿状、带尖角。直接用此表面重划，新网格会继承缺陷——尖角处网格质量差，甚至穿透模具。

**方案：分表面类型处理**

**自由面（不与模具接触）：**
- 使用 Taubin 光顺（λ=0.5, μ=-0.53），保留体积的特征保持滤波
- 迭代 5-10 次消除锯齿，不收缩体积

**接触面（与模具接触）：**
- 从 FRD 中利用接触压力 >0 的单元面识别接触面
- 光顺后按模具几何法向投影回模具表面
- 模具几何来源：原始 INP 中模具初始网格面（模具不变形，网格面即几何面）

**光顺强度控制：**
- 最大光顺位移 = 旧网格特征长度的 5%
- 畸变严重（jac < 0.05）时允许 10%
- 光顺后体积变化 < 3%

```
自由面处理：变形轮廓提取 → Taubin 光顺 → 输出 STL
接触面处理：变形轮廓提取 → 识别接触区 → 投影到模具面 → 输出 STL
模具面获取：原始 INP 中模具表面 → 构建 KD-Tree 用于投影查询

合体：自由面 STL + 接触面 STL → 缝合 → 完整锻件表面 → TetGen
```

### 7.2 模具干涉检测与修正

**三层防线：**

**第一层 — TetGen 划分时约束（预防）：** 将模具接触面作为 TetGen 的 PLC 约束面传入，TetGen 不允许节点出现在约束面的模具侧。

**第二层 — 重划分后检测（检测）：** 对每个新锻件节点 P，计算其到模具面的有向距离：

```
d = signed_distance(P, die_surface)
if d < 0:  P 在模具内部 → 标记为穿透节点
```

有向距离 = (P - Q) · n，其中 Q 是 P 在模具面上的最近点，n 是 Q 处指向锻件侧的向外法向。

**第三层 — 穿透节点修正（修正）：** 对穿透节点执行法向投影 `P_corrected = Q + n × ε`，其中 ε 为间隙容差（取单元特征长度的 0.1%，最小 0.001mm）。仅修正法向分量，不做切向滑移。

**特殊情况处理：**

| 情况 | 处理 |
|------|------|
| 单个节点穿透 | 直接投影 |
| 连续多个节点穿透 | 投影后局部 Laplacian 光顺 1-2 次 |
| 尖角/棱边处穿透 | 先投影到最近模具面，再沿棱边法向调整 |
| 穿透深度 > 单元尺寸 | 警告，回退使用保守映射 |
| 修正后产生新穿透 | 迭代修正（最多 3 次），仍失败则标记该区域用更细网格重划 |

### 7.3 精度保障措施汇总

1. **KD-Tree 加速**：大规模网格（>10 万节点）时点定位从 O(n) 降到 O(log n)
2. **保单调性**：SDV 累积量（如等效塑性应变）插值后保证单调不减
3. **边界处理**：边界外节点用投影 + 面插值，不随意外推
4. **一致性检查**：插值后统计 max/min/mean，与旧网格对比偏差 >5% 时发出警告
5. **接触面保形**：接触区表面光顺后投影回模具面，确保不穿透
6. **体积保持**：光顺 + 重划后检查体积变化，超过 3% 则调整
7. **三层防穿透**：TetGen 约束 → 有向距离检测 → 节点投影修正

---

## 8. 网格密度控制与自适应加密减密

### 8.1 问题陈述

重划分的网格密度**不必与初始网格保持一致**。实际锻造仿真中：

- **接触面区域**：材料在模具间流动，变形后期工件材料要往更小的空隙填充，接触面附近需要**更细的网格**来捕捉几何特征和接触状态
- **内部区域**：工件内部变形梯度相对平缓，可以用**较粗的网格**以节约计算资源
- **变形后期矛盾**：若全局使用粗网格，则微小间隙无法填充 → 可能每个增量步都需要重划分 → 严重影响效率；若全局使用细网格 → 总节点数爆炸 → 求解时间长

因此需要**自适应加密减密**——在需要精度的地方加密，在不需要的地方减密，在给定总开销约束下最大化求解精度。

### 8.2 设计目标

1. 用户可以通过 INP 关键字或命令行参数指定重划分的网格密度策略
2. 支持两种用户控制模式：**指定目标单元尺寸** 或 **指定目标单元数量**
3. 系统自动在锻件轮廓内进行自适应加密/减密，优先加密接触面和曲率大的区域
4. 网格密度场在空间上平滑过渡，避免尺寸突变
5. 自适应算法基于几何特征（曲率、到接触面距离、局部变形梯度）自动计算密度分布

### 8.3 用户接口

#### 8.3.1 INP 关键字扩展

```
*REMESH, DENSITY=MODE
<mode_params>
```

| 参数 | 类型 | 说明 |
|------|------|------|
| `DENSITY` | 枚举 | `SIZE`（按单元尺寸）或 `COUNT`（按单元数量） |

**模式 A：用户指定目标单元尺寸**

```
*REMESH, DENSITY=SIZE
base_size, min_size, max_size, grad_rate
```

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `base_size` | float | 初始网格平均尺寸 | 基准单元尺寸（内部粗网格区的目标尺寸） |
| `min_size` | float | base_size × 0.25 | 最小允许单元尺寸（接触面/高曲率区的最细网格） |
| `max_size` | float | base_size × 2.0 | 最大允许单元尺寸（内部粗网格区的上限） |
| `grad_rate` | float | 1.3 | 相邻单元尺寸比最大增长率（>1.0），控制密度过渡平滑性 |

**模式 B：用户指定目标单元数量**

```
*REMESH, DENSITY=COUNT
target_count, min_size, grad_rate
```

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `target_count` | int | 初始网格单元数 | 目标单元总数（系统自动计算全局尺寸场使最终单元数接近此值） |
| `min_size` | float | 接触面特征尺寸 × 0.3 | 最小允许单元尺寸（防止局部过度加密） |
| `grad_rate` | float | 1.3 | 相邻单元尺寸比最大增长率 |

两种模式都支持可选参数 `refine_contact`（是否在接触面加密，默认 ON）和 `refine_curvature`（是否在高曲率处加密，默认 ON）。

#### 8.3.2 命令行覆盖

```bash
solver -i disk --remesh-density SIZE:0.5,0.1,1.0,1.2
solver -i disk --remesh-density COUNT:5000,0.08,1.3
```

命令行参数格式：`MODE:param1,param2,...`。命令行值覆盖 INP 中的对应参数。

#### 8.3.3 信号文件扩展

`.remesh_signal` 文件中扩展 `density` 字段：

```json
{
  "density": {
    "mode": "SIZE",
    "base_size": 0.5,
    "min_size": 0.1,
    "max_size": 1.0,
    "grad_rate": 1.3,
    "refine_contact": true,
    "refine_curvature": true
  }
}
```

### 8.4 自适应加密减密算法

#### 8.4.1 核心思想：基于度量场的尺寸控制

不直接指定每个单元的尺寸，而是构建一个**空间连续的尺寸度量场** `h(x)`，表示位置 `x` 处的期望单元边长。TetGen 或 Triangle 等网格划分器根据此度量场生成符合尺寸分布的网格。

#### 8.4.2 尺寸场构建

对每个新网格节点的候选位置 `x`，其期望单元边长由以下因素加权决定：

```
h(x) = base_size × w_contact(x) × w_curvature(x) × w_deformation(x)
```

其中各权重因子 ∈ (0, 1]，越接近 0 表示越需要加密。

**权重 1：接触面距离因子 `w_contact`**

```
d = signed_distance(x, die_surface)  // 到最近模具接触面的距离
w_contact = clamp(d / contact_band_width, 0, 1)
// contact_band_width = 3 × base_size（可配）
// 接触面上 w_contact → 0（最细），距接触面 ≥ contact_band_width 处 w_contact = 1（无加密）
```

在接触面上，单元尺寸趋近 `min_size`；远离接触面的内部区域恢复到 `base_size`。

**权重 2：曲率因子 `w_curvature`**

```
κ = mean_curvature(x)  // 通过表面局部拟合计算
w_curvature = clamp(1 / (1 + α × κ × base_size), w_min, 1)
// α = 2.0（灵敏度系数），w_min = min_size / base_size
```

高曲率区域（如尖角、棱边）自动加密；平坦区域不额外加密。

**权重 3：变形梯度因子 `w_deformation`**（可选，从旧网格场量推算）

```
F = deformation_gradient(x)  // 从旧网格的位移场插值
J = det(F)                    // 局部体积变化比
λ_max = max_singular_value(F) // 最大拉伸
w_deformation = clamp(1 / max(J, λ_max), w_min, 1)
```

变形剧烈区域（材料拉伸或压缩大）自动加密。

#### 8.4.3 从 COUNT 模式反算 base_size

当用户指定 `DENSITY=COUNT` 时，系统需要求解合适的 `base_size` 使最终单元数接近 `target_count`：

```
1. 估计锻件体积 V_average = Σ(单元体积)
2. 计算平均加权因子 w_avg = (1/V) ∫ w_contact(x) × w_curvature(x) dV
3. 目标平均单元体积 v_target = V_average / target_count
4. base_size = (v_target / w_avg³)^(1/3)  // 3D 四面体
   base_size = (v_target / w_avg²)^(1/2)  // 2D 三角形
5. clamp base_size 到 [min_size / w_min, max_size]
```

由于 `base_size` 又通过加权因子影响最终网格，需要 1-2 次迭代修正：
- 初算 `base_size₀` → 构建尺寸场 → TetGen 划分 → 检查实际单元数 `N_actual`
- 若 `|N_actual - target_count| / target_count > 10%` → 调整 `base_size *= (N_actual / target_count)^(1/3)` → 重新划分

#### 8.4.4 尺寸场离散化与平滑

尺寸场在实际实现中以**背景网格节点上的离散值**表示，通过以下步骤保证平滑：

1. **表面节点采样**：在锻件变形表面 STL 上，对每个顶点计算期望单元尺寸
2. **Taubin 光顺**：对表面节点上的尺寸值做 2-3 次 Taubin 迭代（λ=0.5, μ=-0.53），消除局部跳变
3. **体积内传播**：从表面向内部，通过求解 Laplace 方程 `∇²h(x) = 0`（Dirichlet 边界条件为表面值）传播尺寸场到内部节点
4. **梯度限幅**：最终检查相邻节点尺寸比，超过 `grad_rate` 的进行局部修正

最终得到一个在空间上平滑、在接触面和曲率处加密的尺寸度量场，传递给 TetGen/Triangle 进行约束 Delaunay 划分。

### 8.5 模式选择建议

| 场景 | 推荐模式 | 原因 |
|------|----------|------|
| 初次仿真，网格需求不明确 | `SIZE` | 直观，与物理尺寸对应 |
| 已知初始网格效果，希望重划分后结果可比 | `COUNT` | 单元数一致，计算开销可预测 |
| 批量参数化仿真 | `COUNT` | 不同几何下求解时间基本一致，便于调度 |
| 模具间隙特别小的精锻 | `SIZE` + 小 `min_size` | 必须用足够细的网格捕捉流动细节 |
| 粗锻/预锻阶段 | `SIZE` + 大 `base_size` | 精度要求低，优先效率 |

### 8.6 与现有设计的整合

1. **表面提取（surface_extract.py）**：扩展为同时输出每个表面顶点的曲率估计值，供尺寸场构建使用
2. **TetGen 调用**：通过 `-m` 标志传入背景网格尺寸场，或通过 `-a` 标志设置全局最大体积约束 + 区域标记实现差异密度
3. **field_mapping**：场量映射时，若旧网格密度场与新网格差异大，自动启用保守的 RBF 插值（而非形函数插值）以保证精度
4. **求解器侧**：`*REMESH` 关键字在 `calinput_()` 中解析，密度参数存入全局变量，重划分时写入 `.remesh_signal`

---

## 10. 文件清单

### 新建文件

| 文件 | 功能 | 估计行数 |
|------|------|----------|
| `scripts/frd_reader.py` | FRD 格式解析 | ~200（已完成） |
| `scripts/inparser.py` | INP 解析，区分模具/锻件，提取集合 | ~400 |
| `scripts/surface_extract.py` | 表面提取 + Taubin 光顺 + 接触面投影，输出 STL | ~250 |
| `scripts/die_penetration.py` | 模具干涉检测与节点投影修正 | ~150 |
| `scripts/tetgen_inp.py` | TetGen 输出 → INP 转换，集合命名 | ~200 |
| `scripts/field_mapping.py` | 形函数插值场量映射 | ~300 |
| `scripts/restart_builder.py` | 组装 restart INP | ~350 |
| `scripts/remesh_orchestrator.py` | 总调度脚本（CLI 入口） | ~250 |
| `scripts/mesh_density.py` | 尺寸场构建：接触面距离/曲率/变形梯度因子 + COUNT 模式反算 | ~350 |

### 修改文件

| 文件 | 修改内容 | 改动量 |
|------|----------|--------|
| `solver/solver.c` | 雅可比检测 + system() 调用重划分脚本 + 加载新网格续算 | ~80 行 |
| `solver/solver.h` | 声明新增函数 | ~10 行 |
| `gui/src/mainwindow.cpp` | 解析 .sta 中的 REMESH 标记，更新信息窗口 | ~60 行 |

---

## 11. 实现顺序

| 步骤 | 内容 | 验证方式 |
|------|------|----------|
| 1 | `frd_reader.py` | 读取参考算例 disk.frd，打印节点数/单元数/步数 |
| 2 | `inparser.py` | 解析 disk.inp，打印模具/锻件节点数和集合名 |
| 3 | `surface_extract.py` | 提取 disk.frd 表面 STL + Taubin 光顺 + 接触面投影 |
| 4 | `tetgen_inp.py` | TetGen → INP，分配集合名，验证与原始 INP 一致 |
| 5 | `die_penetration.py` | 检测 + 修正新网格中的模具穿透节点 |
| 6 | `field_mapping.py` | 形函数插值，用旧网格自身验证误差 <1% |
| 7 | `restart_builder.py` | 生成 restart.inp，与参考 disk-restart.inp 对比 |
| 8 | `mesh_density.py` | 用参考算例表面验证尺寸场分布合理性，检查加密区/过渡区/粗化区 |
| 9 | 端到端测试 | 参考算例完整流水线，对比手工重划分结果 |
| 10 | `solver.c` 畸变检测 | 用已知畸变网格验证 system() 调用重划分 |
| 11 | `mainwindow.cpp` 调度 | 自动重划分循环功能验证 |

---

## 12. 风险与应对

| 风险 | 影响 | 应对 |
|------|------|------|
| TetGen 仅适用于 3D 实体单元 | 不能用于 2D 轴对称 | 仅用于 3D；2D 暂用手动 |
| 形函数插值精度不足 | 计算结果偏差 | 升级为 RBF / Kriging 插值 |
| 雅可比阈值设置不合理 | 误触发或不触发 | 默认 0.1，支持用户和环境变量配置 |
| 重划分后首步不收敛 | 新网格首步发散 | 保留 pre-remesh checkpoint，失败后人工介入 |
| TetGen Windows 编译依赖 | 部署复杂 | 预编译 tetgen.exe 随包分发 |
| 密度场计算开销大 | 大网格时尺寸场构建慢 | 在背景粗网格上计算尺寸场，插值到细分网格；KD-Tree 加速最近距离查询 |
| COUNT 模式迭代不收敛 | base_size 反算震荡 | 限幅 + 最多 3 次迭代，超限后用最后一次结果 |
| 加密接触面导致狭长单元 | 网格质量下降 | 设置 min_size 下限 + 限制相邻尺寸比 grad_rate |
| 大规模网格内存不足 | 重划分崩溃 | 支持稀疏存储 + 分块处理 |
