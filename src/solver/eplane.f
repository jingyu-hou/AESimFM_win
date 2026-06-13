!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      real*8 function eplane(x,n,t)
!     
      implicit none
!     
      real*8 x(*),n(*),t
!     
      eplane= x(1)*n(1)+x(2)*n(2)+x(3)*n(3)+t
!     
      return
      end
      
