# AI 环境定位与调用指南

本文用于给后续 AI 或工程师快速定位本项目在 Ubuntu/WSL 中已经用过的 Qt、Fortran、GCC、依赖库和构建脚本。目标是避免反复出现“找不到 Qt、找不到 gfortran、找不到构建环境”的问题。

适用项目：

- 求解器源码：`D:\ccx`
- GUI 源码：`D:\AESgui_for_linux`
- 已安装参考包：`D:\WeICME`

重要原则：

- 本机已设置 AI 统一入口目录：`C:\Users\12725\.local\bin`。后续 AI 查找 WSL/Python 时优先执行 `where.exe python`、`where.exe py`、`where.exe wsl`、`where.exe ubuntu`，不要先假定缺失。
- Windows Python 固定入口：`C:\Users\12725\.local\bin\python.cmd` / `py.cmd`，当前包装到 `C:\Users\12725\AppData\Local\Programs\Python\Python312\python.exe`。
- WSL 固定入口：`C:\Users\12725\.local\bin\wsl.cmd`；Ubuntu 入口：`C:\Users\12725\.local\bin\ubuntu.cmd`。`ubuntu.cmd` 会优先使用 `WSL_DISTRO_NAME=Ubuntu`，如果当前环境枚举不到该发行版，则回退到默认 WSL。
- 若沙箱内 `wsl -d Ubuntu` 报发行版不存在，但 `ubuntu.cmd bash -lc "uname -a"` 或沙箱外 WSL 可运行，应判定为当前执行环境视图问题，不应报告“本机没有 WSL”。
- 机器级环境索引：`C:\Users\12725\AI_ENVIRONMENT_PATHS.md`，用户级环境变量 `AI_ENVIRONMENT_GUIDE` 指向该文件。
- Windows 路径 `D:\xxx` 在 WSL Ubuntu 中对应 `/mnt/d/xxx`。
- `wsl -d Ubuntu ...` 只在 Windows PowerShell 中执行，不要在 Ubuntu 终端里再次执行 `wsl -d Ubuntu`。
- AI 编码或编译前，先读 `D:\AESimFM\CLAUDE.md` 和 `D:\AESimFM\all_core_plan.md`，再按本文定位环境。
- 不要一遇到缺库、缺命令、缺 Qt 就下载；先查本机已有 WSL、Qt4、gcc/gfortran、make、项目脚本和本地组件库。
- GUI 侧先读 `D:\AESgui_for_linux\BUILD_PLAN.md` 和 `D:\AESgui_for_linux\env_qt4.sh`。
- 求解器侧先读 `D:\ccx\build_wsl.sh`、`D:\ccx\src\Makefile`、`D:\ccx\src\Makefile.inc`。
- 不要优先改系统环境变量。先使用项目已有脚本加载环境。

当前 all/core 工作区优先路径：

```text
D:\AESimFM\code\test\all
D:\AESimFM\code\test\core
```

如果任务是在 all/core 工作区编译，应优先使用该工作区内的 `build_all.sh`、`build_gui.sh`、`build_solver.sh`、`build_core.sh` 和组件路径；`D:\AESgui_for_linux`、`D:\ccx`、`D:\WeICME` 主要作为环境、原始源码或参考产物来源。

## 1. 从 Windows PowerShell 进入 Ubuntu/WSL

先确认 WSL 发行版名称：

```powershell
wsl -l -v
```

如果发行版名称是 `Ubuntu`，可直接从 PowerShell 执行 Ubuntu 命令：

```powershell
wsl -d Ubuntu -- bash -lc "lsb_release -a && uname -a"
```

进入 GUI 源码目录：

```powershell
wsl -d Ubuntu -- bash -lc "cd /mnt/d/AESgui_for_linux && pwd && ls"
```

进入求解器源码目录：

```powershell
wsl -d Ubuntu -- bash -lc "cd /mnt/d/ccx && pwd && ls"
```

## 2. GUI 的 Qt4 环境在哪里

GUI 使用 Qt4/qmake 工程，不是 Qt5/Qt6 工程。

已知 Qt4 路径：

```bash
/home/hjy/src/qt-everywhere-opensource-src-4.8.7
```

项目环境脚本：

```bash
/mnt/d/AESgui_for_linux/env_qt4.sh
```

该脚本设置了：

```bash
QTDIR=/home/hjy/src/qt-everywhere-opensource-src-4.8.7
QMAKESPEC=/home/hjy/src/qt-everywhere-opensource-src-4.8.7/mkspecs/linux-g++
PATH=/home/hjy/src/qt-everywhere-opensource-src-4.8.7/bin:$PATH
LD_LIBRARY_PATH=Qt4/VTK/vis/ChartDirector/FFmpeg/local_deps
```

验证 Qt4 的正确方式：

```powershell
wsl -d Ubuntu -- bash -lc "cd /mnt/d/AESgui_for_linux && source ./env_qt4.sh && which qmake && qmake --version && echo QTDIR=$QTDIR && echo QMAKESPEC=$QMAKESPEC"
```

预期 `qmake --version` 应显示 Qt 4.8.7。若只执行 `qmake --version` 找不到 qmake，先不要判断 Qt 缺失，应先 `source ./env_qt4.sh`。

## 3. GUI 如何编译和运行

GUI 主工程文件：

```bash
/mnt/d/AESgui_for_linux/trunk/QProject_x64.pro
```

一键编译脚本：

```bash
/mnt/d/AESgui_for_linux/build_gui_qt4.sh
```

从 PowerShell 调用编译：

```powershell
wsl -d Ubuntu -- bash -lc "cd /mnt/d/AESgui_for_linux && bash ./build_gui_qt4.sh"
```

手动重编：

```powershell
wsl -d Ubuntu -- bash -lc "cd /mnt/d/AESgui_for_linux/build && source ../env_qt4.sh && make clean && make -j$(nproc)"
```

运行 GUI：

```powershell
wsl -d Ubuntu -- bash -lc "cd /mnt/d/AESgui_for_linux/build && ./run.sh"
```

当前 GUI 产物位置：

```bash
/mnt/d/AESgui_for_linux/build/WeICME
```

当前启动脚本：

```bash
/mnt/d/AESgui_for_linux/build/run.sh
```

该脚本会设置 `LD_LIBRARY_PATH`、`LOCPATH`、`LC_ALL=zh_CN.GBK`、`LANG=zh_CN.GBK` 后启动 GUI。（all 工作区 GUI 已迁移为 UTF-8 编码，需使用 `zh_CN.UTF-8` locale。）

all 工作区 GUI 编译示例：

```powershell
wsl -d Ubuntu -- bash -lc "cd /mnt/d/AESimFM/code/test/all/gui && source /mnt/d/AESgui_for_linux/env_qt4.sh && qmake QProject_x64.pro && make -j$(nproc)"
```

all 工作区 GUI 运行示例：

```powershell
wsl -d Ubuntu -- bash -lc "cd /mnt/d/AESimFM/code/test/all/gui && source /mnt/d/AESgui_for_linux/env_qt4.sh && export LD_LIBRARY_PATH=/mnt/d/AESimFM/code/test/all/components/open_source/saribbon/lib:$LD_LIBRARY_PATH && ./WeICME"
```

GUI 验收不仅看能否启动，还必须看中文是否正确显示。若界面出现 `����` 或 `锟斤拷`，先查源码是否已经乱码，再查 `QTextCodec`、locale 和字体。详细处理见：

```text
D:\AESimFM\gui_encoding_solver_fix_plan.md
```

## 4. GUI 依赖库在哪里

GUI 不是只依赖系统库，还依赖项目内已有的本地库：

```bash
/mnt/d/AESgui_for_linux/vtk5.4.2-Qt4
/mnt/d/AESgui_for_linux/trunk/vis/lib_linux
/mnt/d/AESgui_for_linux/trunk/ChartDirector/libLinux
/mnt/d/AESgui_for_linux/ffmpeg_Build
/mnt/d/AESgui_for_linux/local_deps
```

本地兼容脚本：

```bash
/mnt/d/AESgui_for_linux/fix_vtk_sonames.sh
/mnt/d/AESgui_for_linux/fix_ffmpeg_sonames.sh
/mnt/d/AESgui_for_linux/fix_lzma_compat.sh
/mnt/d/AESgui_for_linux/fetch_local_x11_deps.sh
```

检查 GUI 是否缺动态库：

```powershell
wsl -d Ubuntu -- bash -lc "cd /mnt/d/AESgui_for_linux/build && source ../env_qt4.sh && ldd ./WeICME | grep 'not found' || true"
```

检查 GBK locale：

```powershell
wsl -d Ubuntu -- bash -lc "LOCPATH=/mnt/d/AESgui_for_linux/local_deps/locale LC_ALL=zh_CN.GBK locale charmap"
```

预期输出：

```text
GBK
```

## 5. 求解器的 Fortran/GCC 环境在哪里

求解器使用 Linux Makefile，关键文件：

```bash
/mnt/d/ccx/build_wsl.sh
/mnt/d/ccx/Makefile
/mnt/d/ccx/src/Makefile
/mnt/d/ccx/src/Makefile.inc
/mnt/d/ccx/src/Makefile_MT
/mnt/d/ccx/src/Makefile_ST
```

`/mnt/d/ccx/src/Makefile` 中当前工具链为：

```makefile
CC=cc
FC=gfortran
CFLAGS = -Wall -O3 -fopenmp -fno-pie ...
FFLAGS = -Wall -O3 -fopenmp -fallow-argument-mismatch
```

当前求解器主入口：

```bash
/mnt/d/ccx/src/WeICME.c
```

当前主要目标：

```bash
WeICME_MT
WeICME_MT.a
```

验证 Fortran/GCC 工具链：

```powershell
wsl -d Ubuntu -- bash -lc "which gcc g++ gfortran make ar ranlib perl cmake || true; gcc --version | head -n 1; gfortran --version | head -n 1; make --version | head -n 1"
```

如果 `gfortran` 找不到，不要改源码，应先安装或恢复 Ubuntu 编译工具链。需要 sudo 时应由用户确认：

```bash
sudo apt update
sudo apt install -y build-essential gfortran make perl cmake
```

## 6. 求解器如何编译

优先使用项目根目录已有脚本：

```powershell
wsl -d Ubuntu -- bash -lc "cd /mnt/d/ccx && bash ./build_wsl.sh"
```

也可以先做 dry-run，查看 Makefile 会执行什么：

```powershell
wsl -d Ubuntu -- bash -lc "cd /mnt/d/ccx/src && make -n"
```

手动编译：

```powershell
wsl -d Ubuntu -- bash -lc "cd /mnt/d/ccx/src && make"
```

注意：

- 当前 `src/Makefile` 的 `clean` 规则会删除当前目录下的 `*.o` 和 `*.a`，不要在不了解当前目录内容时随意执行。
- `D:\ccx\ARPACK`、`D:\ccx\lapack-3.2.1`、`D:\ccx\SPOOLES.2.2` 是求解器链接依赖，不要删除。

检查静态库格式：

```powershell
wsl -d Ubuntu -- bash -lc "cd /mnt/d/ccx/src && file ../ARPACK/libarpack_REDHAT.a ../lapack-3.2.1/liblapackREDHAT.a ../lapack-3.2.1/libblasREDHAT.a ../SPOOLES.2.2/spooles.a"
```

这些库是 Linux/ELF 方向的依赖，因此在 WSL/Linux 中编译更合理。不要把 Cygwin 目标文件和 Linux ELF 静态库混用。

## 7. 已安装版本可作为参考但不是源码

已安装目录：

```text
D:\WeICME
```

主要参考位置：

```text
D:\WeICME\Solver\WeICME.exe
D:\WeICME\WeICMECAE
D:\WeICME\WeICMECAE\RMesh
D:\WeICME\MaterialDataBase
```

注意：

- `D:\WeICME` 是安装后的产物目录，可用于观察实际软件布局和运行依赖。
- `D:\WeICME\WeICMECAE\RMesh` 更像打包后的 Python 运行时工具，不等同于源码目录。
- 若要修改 GUI 源码，应回到 `D:\AESgui_for_linux`。
- 若要修改求解器源码，应回到 `D:\ccx`。

## 8. 常见找不到环境的处理顺序

### 8.1 找不到 qmake

先执行：

```powershell
wsl -d Ubuntu -- bash -lc "cd /mnt/d/AESgui_for_linux && source ./env_qt4.sh && which qmake && qmake --version"
```

仍找不到时再检查：

```powershell
wsl -d Ubuntu -- bash -lc "cat /mnt/d/AESgui_for_linux/env_qt4.sh && find /home -path '*qt-everywhere-opensource-src-4.8.7/bin/qmake' 2>/dev/null"
```

### 8.2 找不到 Qt 库

先检查 `LD_LIBRARY_PATH`：

```powershell
wsl -d Ubuntu -- bash -lc "cd /mnt/d/AESgui_for_linux && source ./env_qt4.sh && echo $LD_LIBRARY_PATH"
```

再检查 GUI 产物缺库：

```powershell
wsl -d Ubuntu -- bash -lc "cd /mnt/d/AESgui_for_linux/build && source ../env_qt4.sh && ldd ./WeICME | grep 'not found' || true"
```

### 8.3 找不到 gfortran

先验证：

```powershell
wsl -d Ubuntu -- bash -lc "which gfortran || true; gfortran --version | head -n 1 || true"
```

如果没有安装，需要用户允许后在 Ubuntu 中安装：

```bash
sudo apt update
sudo apt install -y gfortran build-essential
```

### 8.4 找不到项目目录

确认 Windows 目录是否存在：

```powershell
Test-Path D:\ccx
Test-Path D:\AESgui_for_linux
Test-Path D:\WeICME
```

确认 WSL 挂载路径：

```powershell
wsl -d Ubuntu -- bash -lc "test -d /mnt/d/ccx && echo ccx_ok; test -d /mnt/d/AESgui_for_linux && echo gui_ok; test -d /mnt/d/WeICME && echo install_ok"
```

## 9. 后续 AI 的最小操作清单

如果只是定位环境，按以下顺序执行即可：

```powershell
wsl -l -v
wsl -d Ubuntu -- bash -lc "cd /mnt/d/AESgui_for_linux && source ./env_qt4.sh && qmake --version"
wsl -d Ubuntu -- bash -lc "cd /mnt/d/AESgui_for_linux && source ./env_qt4.sh && echo QTDIR=$QTDIR && echo QMAKESPEC=$QMAKESPEC"
wsl -d Ubuntu -- bash -lc "which gcc g++ gfortran make cmake || true"
wsl -d Ubuntu -- bash -lc "cd /mnt/d/ccx/src && make -n"
```

如果要编译 GUI：

```powershell
wsl -d Ubuntu -- bash -lc "cd /mnt/d/AESgui_for_linux && bash ./build_gui_qt4.sh"
```

如果要编译求解器：

```powershell
wsl -d Ubuntu -- bash -lc "cd /mnt/d/ccx && bash ./build_wsl.sh"
```

如果要运行 GUI：

```powershell
wsl -d Ubuntu -- bash -lc "cd /mnt/d/AESgui_for_linux/build && ./run.sh"
```

## 10. 不建议做的事

- 不要把本项目直接当 Qt5/Qt6 工程处理。
- 不要在没有加载 `env_qt4.sh` 的情况下判断 Qt 不存在。
- 不要把 `D:\WeICME` 当作源码目录直接修改。
- 不要在 Ubuntu 终端里再次执行 `wsl -d Ubuntu`。
- 不要随意删除 `D:\ccx\ARPACK`、`D:\ccx\lapack-3.2.1`、`D:\ccx\SPOOLES.2.2`。
- 不要混用 Cygwin 编译出的目标文件和 WSL/Linux 静态库。
- 不要为了临时编译而全局覆盖系统 Qt、系统 locale 或系统库路径，优先使用项目本地脚本。

## 11. D:\AESimFM\code\test 的 all/core 编译环境调用

本节用于后续 AI 在整改 `D:\AESimFM\code\test\all` 和 `D:\AESimFM\code\test\core` 时查找环境。原则仍然是：先查本地已有环境和项目脚本，确认缺失后再考虑下载或安装。

Windows 路径对应 WSL 路径：

```text
D:\AESimFM\code\test\all  -> /mnt/d/AESimFM/code/test/all
D:\AESimFM\code\test\core -> /mnt/d/AESimFM/code/test/core
```

### 11.1 编译前先做只读环境检查

```powershell
wsl -l -v
wsl -d Ubuntu -- bash -lc "which gcc g++ gfortran make qmake || true"
wsl -d Ubuntu -- bash -lc "gfortran --version | head -n 1 || true; gcc --version | head -n 1 || true"
wsl -d Ubuntu -- bash -lc "cd /mnt/d/AESgui_for_linux && source ./env_qt4.sh && qmake --version"
```

如果裸 `qmake` 找不到，不要直接安装 Qt。应先使用：

```powershell
wsl -d Ubuntu -- bash -lc "cd /mnt/d/AESgui_for_linux && source ./env_qt4.sh && which qmake && qmake --version"
```

### 11.2 all/core 包的构建入口

整体包：

```powershell
wsl -d Ubuntu -- bash -lc "cd /mnt/d/AESimFM/code/test/all && bash ./build_all.sh"
wsl -d Ubuntu -- bash -lc "cd /mnt/d/AESimFM/code/test/all && bash ./build_solver.sh"
wsl -d Ubuntu -- bash -lc "cd /mnt/d/AESimFM/code/test/all && bash ./build_gui.sh"
```

核心包：

```powershell
wsl -d Ubuntu -- bash -lc "cd /mnt/d/AESimFM/code/test/core && bash ./build_core.sh"
```

执行编译前，编码工程师必须确认当前操作不会和其他 Agent 写操作冲突。测试工程师默认不在原目录编译，除非主理人明确授权。

### 11.3 缺环境时的处理顺序

1. 先查 `D:\AESgui_for_linux\env_qt4.sh` 是否能加载 Qt4。
2. 再查 `D:\ccx\build_wsl.sh`、`D:\ccx\src\Makefile` 是否能说明求解器编译依赖。
3. 再查 `D:\AESimFM\code\test\all\build_*.sh`、`D:\AESimFM\code\test\core\build_core.sh` 当前脚本如何调用环境。
4. 再查本地库是否已在 `D:\AESgui_for_linux`、`D:\ccx`、`D:\AESimFM\code\test\*/components` 中存在。
5. 仍找不到时，记录缺失项、影响、建议安装命令，再请求用户确认。

### 11.4 不要做的事

- 不要在未加载 `env_qt4.sh` 前判断 Qt 缺失。
- 不要因为 `build_all.sh` 报缺库就复制第三方完整源码到源码区；应优先检查组件目录和链接路径。
- 不要为了测试在 `all` 或 `core` 原目录留下 `.o`、临时 `.a`、CMake build、debug/release 等最终需清理的产物而不记录。
- 不要让测试工程师和代码架构工程师直接修改 `D:\AESimFM\code\test`；实际修改应由编码工程师执行。



### all 工作区 GUI 当前确认可用启动入口（2026-05-23）

在 Windows PowerShell 中启动 `all/gui/WeICME` 时，优先使用 `--%`，避免 PowerShell 提前展开 Bash 里的 `$LD_LIBRARY_PATH`：

```powershell
wsl -d Ubuntu --% bash -lc "cd /mnt/d/AESimFM/code/test/all/gui; export LOCPATH=/mnt/d/AESgui_for_linux/local_deps/locale; export LC_ALL=zh_CN.UTF-8; export LANG=zh_CN.UTF-8; export LD_LIBRARY_PATH=/home/hjy/src/qt-everywhere-opensource-src-4.8.7/lib:/mnt/d/AESimFM/code/test/all/components/open_source/saribbon/lib:/mnt/d/AESimFM/code/test/all/components/open_source/vtk/lib/vtk-5.4:/mnt/d/AESimFM/code/test/all/components/commercial/vis/lib_linux:/mnt/d/AESimFM/code/test/all/components/commercial/chartdirector/libLinux:/mnt/d/AESimFM/code/test/all/components/open_source/ffmpeg/lib:/mnt/d/AESgui_for_linux/local_deps/root/usr/lib/x86_64-linux-gnu; ./WeICME"
```

在 Ubuntu 终端中启动时直接执行：

```bash
cd /mnt/d/AESimFM/code/test/all/gui
export LOCPATH=/mnt/d/AESgui_for_linux/local_deps/locale
export LC_ALL=zh_CN.UTF-8
export LANG=zh_CN.UTF-8
export LD_LIBRARY_PATH=/home/hjy/src/qt-everywhere-opensource-src-4.8.7/lib:/mnt/d/AESimFM/code/test/all/components/open_source/saribbon/lib:/mnt/d/AESimFM/code/test/all/components/open_source/vtk/lib/vtk-5.4:/mnt/d/AESimFM/code/test/all/components/commercial/vis/lib_linux:/mnt/d/AESimFM/code/test/all/components/commercial/chartdirector/libLinux:/mnt/d/AESimFM/code/test/all/components/open_source/ffmpeg/lib:/mnt/d/AESgui_for_linux/local_deps/root/usr/lib/x86_64-linux-gnu
./WeICME
```

注意：`qmake -query` 当前会返回 `/share/apps/Qt-4.8.7`，但实际可用 Qt4 头文件和库在 `/home/hjy/src/qt-everywhere-opensource-src-4.8.7`。`D:\AESimFM\code\test\all\build_gui.sh` 已在 qmake 后把 Makefile 中的 `/share/apps/Qt-4.8.7` 替换成实际路径，后续 AI 不要删除这段修正逻辑。

## 12. WSLg 窗口状态恢复

WSLg 通过 `msrdc.exe` 将 Linux X11 窗口桥接到 Windows 桌面。在反复编译、timeout 杀进程、手动关闭 GUI 时，Linux 侧 compositor 和 Windows 侧 msrdc 窗口状态可能不同步，表现为：

- WeICME 主窗口不可见但进程仍在
- 窗口停留在最小化状态无法恢复
- 模态窗口（文件选择框、关闭确认框）残留
- msrdc 桥接窗口未随 X11 窗口释放

### 恢复方法

在 Windows PowerShell 中执行：

```powershell
D:\AESimFM\restore_wslg_windows_strong.ps1
```

该脚本通过 Win32 API（`user32.dll`）直接操作 `msrdc.exe` 窗口句柄：
- `SetWindowPlacement` — 重置窗口为正常状态，清除最小化/离屏标记
- `ShowWindowAsync` — 强制显示窗口
- `SetWindowPos` + `BringWindowToTop` + `SetForegroundWindow` — 恢复窗口可见性和焦点

此脚本在以后出现窗口残留/不可见问题时直接执行即可，不需要重新编译或重启 WSL。
