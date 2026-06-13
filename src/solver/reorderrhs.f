!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine reorderrhs(a,b,vold,neighblock,nneighblock)
!
!     reorders matrix elements into compressed row format
!
      implicit none
!
      integer neighblock(3,*),nneighblock,i,j,indexf,iel
!
      real*8 a(*),b(*),vold(*)
!
!
!
      do j=1,nneighblock
!
!        location in au/auv
!
         indexf=neighblock(1,j)
!
!        neighboring block element number
!
         iel=neighblock(2,j)
!
!        equation number
!
         i=neighblock(3,j)
!
         b(i)=b(i)-a(indexf)*vold(iel)
!
      enddo
!
      return
      end
