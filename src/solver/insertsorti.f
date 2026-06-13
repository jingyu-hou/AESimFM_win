!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine insertsorti(ix,n)
!
!     simple insertion sort routine for very small n
!
!     https://en.wikipedia.org/wiki/Insertion_sort
!
!     Author: Lukas Mayrhofer
!      
      implicit none
!
      integer n,ix(*)
!
      integer i,j,itmp
!
      do i=2,n
         itmp=ix(i)
         do j=i-1,1,-1
            if(itmp.lt.ix(j)) then
               ix(j+1)=ix(j)
            else
               exit
            endif
         enddo
         ix(j+1)=itmp
      enddo
!
      return
      end
