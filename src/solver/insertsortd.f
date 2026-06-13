!
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine insertsortd(dx,n)
!
!     simple insertion sort routine for very small n
!
!     https://en.wikipedia.org/wiki/Insertion_sort
!
!     Author: Lukas Mayrhofer
!      
      implicit none
!
      integer n
      real*8 dx(*)
!
      integer i,j
      real*8 xtmp
!
      do i=2,n
         xtmp=dx(i)
         do j=i-1,1,-1
            if(xtmp.lt.dx(j)) then
               dx(j+1)=dx(j)
            else
               exit
            endif
         enddo
         dx(j+1)=xtmp
      enddo
!
      return
      end
