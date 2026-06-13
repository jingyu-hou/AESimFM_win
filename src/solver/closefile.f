!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine closefile()
      implicit none
!
!     closes files at the end of the calculation
!
      logical rout
!
!     closing the .inp file
!
      close(1)
!
!     closing the .dat file
!
      close(5)
!
!     closing the .sta file
!
      close(8)
!
!     closing the .cvg file
!
      close(11)
!
!     closing the .rout file
!
      inquire(15,opened=rout)
      if(rout) close(15)
!     
      return
      end
