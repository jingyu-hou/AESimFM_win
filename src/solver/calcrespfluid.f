!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
!     Calculating the residual in CFD-calculations: 
!     special case: dp-equation (change in pressure)
!
      subroutine calcrespfluid(n,b,au,x,res)
!
      implicit none
!
      integer i,n,nflnei
!
      real*8 xmax,xmin,b(*),au(*),x(*),res
!
      xmax=0.d0
      xmin=0.d0
      res=0.d0
!
      do i=1,n
         res=res+(b(i)/au(i))**2
         xmax=max(xmax,x(i))
         xmin=min(xmin,x(i))
      enddo
      res=dsqrt(res/n)/(xmax-xmin)
!
      return
      end
