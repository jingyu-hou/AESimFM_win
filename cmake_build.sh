#!/bin/bash
# CMake configure and build for AESimFM v2.0 Windows solver
set -e

export PATH="/ucrt64/bin:$PATH"
cd /d/AESimFM_win

BUILD_DIR="build"
BUILD_TYPE="Release"

echo "=== CMake Configure ==="
cmake -B ${BUILD_DIR} \
  -G "MSYS Makefiles" \
  -DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
  2>&1

echo "=== CMake Build ==="
cmake --build ${BUILD_DIR} -j8 2>&1

echo "=== Build Complete ==="
ls -la ${BUILD_DIR}/src/solver/solver.exe 2>&1 || echo "solver.exe not found, checking..."
find ${BUILD_DIR} -name "solver*" -type f 2>&1
