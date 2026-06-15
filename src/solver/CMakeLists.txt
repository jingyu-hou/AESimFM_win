# ============================================
# AESimFM Solver Extension Library
# ============================================
#
# ARCHITECTURE:
#   libaesim_solver_ext.a = OVERRIDE layer (AESimFM-modified CalculiX files)
#   libcalculix_base.a    = CalculiX 2.15 core (from D:\ccx\src)
#
# File list mirrors Linux: D:\AESimFM\code\test\all\solver\Makefile.inc
#

# Fortran override sources (matching SCCXF from Makefile.inc)
set(AESIM_SOLVER_EXT_F
  bmatrix.f calcgradtemp_cast.f htchart.f initialh.f
  insertsortd.f insertsorti.f integratelinesproduct.f integraterhocp.f
  lump.f materialdata_dtdh.f materialdata_h2temp.f materialdata_me.f
  materialdata_temp2h.f materialdata_th_h.f materialdata_th_h2.f
  nystar2flcr.f nystarflcrchart.f openfilefluid.f phys2con_cast.f
  postprocess_cast.f preparenycalc.f smoothshock.f templiquidussolidus.f
  time2solidus.f addimd.f bsort.f calccvel.f calccvfa.f calchcel.f calchcfa.f
  calcinitialflux.f calcmechstrain.f calcpel.f calcrespfluid.f calcrestfluid.f
  calcresvfluid1.f calcresvfluid2.f calcrhoel.f calcrhoelcomp.f calcrhofa.f
  calcumel.f calcumfa.f calcvel.f cd_lichtarowicz.f cd_Mcgreehan_Schotsch.f
  cd_own_albers.f cd_pk_albers.f cident.f cident20.f cident80.f
  closefile.f closefilefluid.f convert2slapcol.f correctrhoelcomp.f
  correctvel.f creepsoftenings.f creep_softening_model.f createialnk.f
  damage.f damages.f damagecal.f dattime.f dKdX.f drx.f srx_mrx_k90.f
  drx_hip_weicme.f drx_weicme.f dynamicrecrystallizations.f edg.f
  elemperorien.f eplane.f fcrit.f flowstress.f fsub.f fsuper.f
  gasmechbc.f getversion.f init.f inputerror.f inputinfo.f inputwarning.f
  intersectionpoint.f invariant.f lab_straight_ppkrit.f matvec.f meannode.f
  metalpowders.f metal_powder.f modf.f msolve.f msolve_struct.f multvec.f
  negativepressure.f nident.f nident2.f nidentk.f nidentll.f norm.f
  op.f opas.f op_corio.f pk_cdc_cl3.f pk_cdi_r.f pk_cdi_rl.f pk_cdi_se.f
  pop.f posttransition.f preconvert2slapcol.f predir.f push.f
  randomval.f ratedependentplastics.f rdplas.f reorderampl.f reorderlhs.f
  reorderrhs.f sensitivity_glob.f stop.f thermmodel.f transformation.f
  triloc.f uamplitude.f uhard.f uhardening.f uexpan.f velsolve.f
  writeboun.f writebv.f writedesi.f writeevcomplex.f writehe.f writeim.f
  writemac.f writemaccs.f writempc.f writerandomfield.f writere.f
  writesta.f writestadiv.f writevfa.f calcvol.f calcvol2.f calinput.f
  readphaseinf.f phasetransition.f phasetransition1.f phaseother.f
)

# C override sources (matching SCCXC from Makefile.inc + Windows compat)
# NOTE: frd.c and hdf5_writer.c are linked directly (not via static lib)
# to ensure they override symbols in calculix_base.a
set(AESIM_SOLVER_EXT_C
  readxstateini.c getSystemCPUs.c stof.c stoi.c
  strcmp2.c strcpy1.c v_betrag.c v_prod.c v_result.c
  plasticwork.c drxc.c output_mtx.c itinerate_print.c random_print.c
  win_compat.c
)

# HDF5 writer sources (conditional)
if(OUTPUT_HDF5)
  set(HDF5_WRITER_SRC hdf5_writer.c)
  set(HDF5_ROOT "D:/msys64/ucrt64")
  set(HDF5_INCLUDE_DIR "${HDF5_ROOT}/include")
  set(HDF5_LIBRARY "${HDF5_ROOT}/lib/libhdf5.dll.a")
else()
  set(HDF5_WRITER_SRC "")
  set(HDF5_INCLUDE_DIR "")
  set(HDF5_LIBRARY "")
endif()

# Extra Fortran sources not in override list but needed for linking
set(AESIM_SOLVER_EXT_F_EXTRA
  lsame.f xerbla.f
)

# Build AESimFM solver extension static library (override layer)
add_library(aesim_solver_ext STATIC ${AESIM_SOLVER_EXT_F} ${AESIM_SOLVER_EXT_F_EXTRA} ${AESIM_SOLVER_EXT_C} ${HDF5_WRITER_SRC})
target_include_directories(aesim_solver_ext PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}
  ${EXTERNAL_HEADERS}
  ${HDF5_INCLUDE_DIR}
)
target_link_libraries(aesim_solver_ext PRIVATE OpenMP::OpenMP_C OpenMP::OpenMP_Fortran)
set_target_properties(aesim_solver_ext PROPERTIES
  Fortran_MODULE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/modules
)

# ============================================
# Main Solver Executable
# ============================================
# frd.c linked directly (not via static lib) to override frd() in calculix_base.a
add_executable(solver solver.c frd.c)
target_include_directories(solver PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}
  ${EXTERNAL_HEADERS}
)

# All solver libraries inside --start-group for circular dependency resolution.
# All numerical libs are now native COFF (rebuilt from source), so ld handles them correctly.
target_link_libraries(solver PRIVATE
  -Wl,--start-group
  aesim_solver_ext
  calculix_base
  spoolesMT
  spooles
  arpack
  lapack
  blas
  -Wl,--end-group
  OpenMP::OpenMP_C
  OpenMP::OpenMP_Fortran
  ${CMAKE_THREAD_LIBS_INIT}
  m
  ${HDF5_LIBRARY}
)

set_target_properties(solver PROPERTIES OUTPUT_NAME solver)
