!
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!
!     Developed and maintained by Shenzhen Wedge Central
!     South Research Institute co., Ltd., Shenzhen, China
!
!     Copy Right 2019-2023.
!
      SUBROUTINE UEXPAN(EXPAN,TEMP0,TEMP1,STATEV,NSTATV,CMNAME)
C
      IMPLICIT NONE
C
      CHARACTER*80 CMNAME
C
      INTEGER :: I,NSTATV
      REAL*8 EXPAN(6),TEMP0,TEMP1,STATEV(NSTATV),PE(6,1)
      REAL*8 :: DENS0,DENS,ALPHA0,ALPHA1
C
      DO I = 1, 3
        PE(I,1) = STATEV(I)
      END DO
      DENS0=0.571D0
      DENS = DENS0*EXP(-PE(1,1)-PE(2,1)-PE(3,1))
C      ALPHA0 =(10.73D0+0.0044D0*TEMP0)*DENS0**(1.D0/3.D0)*(1.D-6)
C      ALPHA1 =(10.73D0+0.0044D0*TEMP1)*DENS0**(1.D0/3.D0)*(1.D-6)
      ALPHA0 =(10.73D0+0.0044D0*TEMP0)*(1.D-6)
      ALPHA1 =(10.73D0+0.0044D0*TEMP1)*(1.D-6)
      EXPAN(1) = ALPHA1*TEMP1-ALPHA0*TEMP0
      EXPAN(2) = EXPAN(1)
      EXPAN(3) = EXPAN(1)
      EXPAN(4) = 0.0D0
      EXPAN(5) = 0.0D0
      EXPAN(6) = 0.0D0
C
      RETURN
      END
