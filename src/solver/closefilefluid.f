!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine closefilefluid()
!
      implicit none
!
!     closing the fluid frd file
!
      close(13);
!
!     closing the cvg file
!
      close(12);
!
      return
      end
