!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine multvec(n,x,y,dot)
!
!     calculates the dot product of two vectors x and y of length n
!
      implicit none
!
      integer i,n
!
      real*8 x(*),y(*),dot
!
      dot=0.d0
      do i=1,n
         dot=dot+x(i)*y(i)
      enddo
!
      return
      end
