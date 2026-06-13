!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine reorderlhs(au,am,iamorig,nz_numa,nz_numb)
!
!     reorders matrix elements into compressed row format
!
      implicit none
!
      integer iamorig(*),nz_numa,nz_numb,i
!
      real*8 au(*),am(*)
!
!
!
      do i=nz_numa,nz_numb
         am(i)=au(iamorig(i))
      enddo
!
      return
      end
