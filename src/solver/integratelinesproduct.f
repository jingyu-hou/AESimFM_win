!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!  
      subroutine integratelinesproduct(a1,a2,b1,b2,x1,x2,xs,s)
!
!     integrate exactly the product of two linear functions,
!      a and b, from x1 to x2
!
      implicit none
!
      real*8 a1,a2,b1,b2,x1,x2,xs,s,ka,kb
c      ka=(a2-a1)/(x2-x1+1.d-16)
c      kb=(b2-b1)/(x2-x1+1.d-16)
c      s=ka*kb*(xs-x1)**3.d0/3.d0
c     &  +(a1*kb+b1*ka)*(xs-x1)**2.d0/2.d0
c     &  +a1*b1*(xs-x1)
      s=(a1*b1+a2*b2)*(x2-x1)/2.d0
!
      return
      end
!