cmake_minimum_required(VERSION 3.15)
project(AESimFM VERSION 2.0.0 LANGUAGES C Fortran)

# ============================================
# Build Options
# ============================================
option(USE_MUMPS "Use MUMPS sparse solver" OFF)
option(USE_SPOOLES "Use SPOOLES sparse solver (legacy)" ON)
option(OUTPUT_HDF5 "Output HDF5 result format" OFF)
option(OUTPUT_FRD "Output FRD result format (legacy)" ON)
option(ENABLE_AUTO_REMESH "Enable auto remeshing" OFF)
option(ENABLE_OPENMP "Enable OpenMP parallelism" ON)

# ============================================
# Paths (must be defined before compiler settings)
# ============================================
set(LIB_DIR ${CMAKE_SOURCE_DIR}/lib)
set(SPOOLES_DIR ${LIB_DIR}/spooles)
set(ARPACK_DIR ${LIB_DIR}/arpack)
set(LAPACK_DIR ${LIB_DIR}/lapack_blas)
set(CALCULIX_DIR ${LIB_DIR}/calculix)
set(EXTERNAL_HEADERS ${CMAKE_SOURCE_DIR}/src/solver/external_headers)

# ============================================
# Compiler Settings (MinGW UCRT64)
# ============================================
set(CMAKE_C_STANDARD 11)
set(CMAKE_Fortran_STANDARD 2008)

# K&R C tolerance for legacy CalculiX C code
# -include pthread.h: needed because WeICME.h declares pthread_* without including pthread.h
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-int-conversion -Wno-implicit-int -Wno-incompatible-pointer-types -Wno-implicit-function-declaration -Wno-return-mismatch")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -include pthread.h")
set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -fallow-argument-mismatch -g -fbacktrace")
set(CMAKE_C_FLAGS_DEBUG "-g -O0")
set(CMAKE_Fortran_FLAGS_DEBUG "-g -O0 -fcheck=all -fbacktrace")

if(ENABLE_OPENMP)
  find_package(OpenMP REQUIRED)
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${OpenMP_C_FLAGS}")
  set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} ${OpenMP_Fortran_FLAGS}")
endif()

# Architecture definitions
add_compile_definitions(ARCH=Linux)

if(USE_SPOOLES)
  add_compile_definitions(SPOOLES MATRIXSTORAGE USE_MT=1)
endif()
if(USE_MUMPS)
  add_compile_definitions(MUMPS)
endif()
if(ENABLE_AUTO_REMESH)
  add_compile_definitions(AUTO_REMESH)
endif()

# ============================================
# Numerical Libraries (imported)
# ============================================
add_library(spooles STATIC IMPORTED)
set_target_properties(spooles PROPERTIES IMPORTED_LOCATION ${SPOOLES_DIR}/spooles.a)

add_library(spoolesMT STATIC IMPORTED)
set_target_properties(spoolesMT PROPERTIES IMPORTED_LOCATION ${SPOOLES_DIR}/spoolesMT.a)

add_library(arpack STATIC IMPORTED)
set_target_properties(arpack PROPERTIES IMPORTED_LOCATION ${ARPACK_DIR}/libarpack.a)

add_library(blas STATIC IMPORTED)
set_target_properties(blas PROPERTIES IMPORTED_LOCATION ${LAPACK_DIR}/libblas.a)

add_library(lapack STATIC IMPORTED)
set_target_properties(lapack PROPERTIES IMPORTED_LOCATION ${LAPACK_DIR}/liblapack.a)

add_library(calculix_base STATIC IMPORTED)
set_target_properties(calculix_base PROPERTIES IMPORTED_LOCATION ${CALCULIX_DIR}/libcalculix_base.a)

# ============================================
# Solver Target
# ============================================
add_subdirectory(src/solver)
