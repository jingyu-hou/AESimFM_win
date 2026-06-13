!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine meannode(nk,inum,v)
!
!     taking the mean at the nodes
!
      implicit none
!
      integer nk,inum(*),i,j
!
      real*8 v(0:4,*)
!
      do i=1,nk
         if(inum(i).ne.0) then
            inum(i)=abs(inum(i))
            do j=0,4
               v(j,i)=v(j,i)/inum(i)
            enddo
         endif
         write(*,*) 'meannode ',i,(v(j,i),j=1,3)
      enddo
!  
      return
      end
