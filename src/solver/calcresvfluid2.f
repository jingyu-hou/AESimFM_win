!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
!     Calculating the residual in CFD-calculations
!
      subroutine calcresvfluid2(n,x,xmax,nef)
!
      implicit none
!
      integer i,n,nef
!
      real*8 xmax,x(*),vel
!
      xmax=0.d0
!
      do i=1,n
         vel=dsqrt(x(i)**2+x(nef+i)**2+x(2*nef+i)**2)
         if(vel.gt.xmax) xmax=vel
      enddo
!
      return
      end
