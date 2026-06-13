! ifport compatibility module for gfortran (MinGW)
! Provides Intel Fortran IFPORT subroutines as wrappers
MODULE IFPORT
  IMPLICIT NONE
  CONTAINS

  INTEGER FUNCTION MAKEDIRQQ(dirname)
    CHARACTER(LEN=*), INTENT(IN) :: dirname
    CHARACTER(LEN=256) :: cmd
    INTEGER :: stat
    cmd = 'mkdir "' // TRIM(dirname) // '"'
    CALL EXECUTE_COMMAND_LINE(TRIM(cmd), WAIT=.TRUE., EXITSTAT=stat)
    MAKEDIRQQ = stat
  END FUNCTION MAKEDIRQQ

END MODULE IFPORT
