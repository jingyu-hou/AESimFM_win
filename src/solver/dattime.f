!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine dattime(date,clock)
!
!     gets date and time in FORTRAN
!
      implicit none
!
      character*8 date
      character*10 clock
!
      call date_and_time(date,clock)
!
      return
      end


