!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine lab_straight_ppkrit (n,ppkrit)
!
      implicit none
!
      integer n
!
      real*8 fppkrit(9),ppkrit
!
      data fppkrit
     &     /0.47113022d0,0.37968106d0,0.32930492d0,0.29569704d0,
     &      0.27105479d0,0.25191791d0,0.23646609d0,0.22363192d0,
     &      0.21274011d0/
!
      ppkrit=fppkrit(n)
!     
      return
      end
