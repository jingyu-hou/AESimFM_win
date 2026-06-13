!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine dKdX(x,u,uprime,rpar,ipar)
!
      implicit none
      integer ipar
      real*8 x,u(1),uprime(1),rpar(*),zk0,phi
!
!     defining the parameters
      phi=rpar(1)
      zk0=rpar(3)

      uprime(1)=datan(1.d0)*0.315d0/(phi)*x**1.6d0*
     &    ((zk0*u(1))**1.75d0-
     &    (dabs(1.d0-u(1)))**1.75d0*(1.d0-u(1))/dabs(1.d0-u(1)))
     &    -2.d0*u(1)/x
!
      return
!     
      end
!
