!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine calcvel(ne,nactdoh,vel,bv,neq,nef)
!
!     stores the velocities into field vel
!
      implicit none
!
      integer ne,neq,nactdoh(*),i,j,nef
!
      real*8 vel(nef,0:7),bv(neq,3)
!
      do i=1,ne
         do j=1,3
            vel(i,j)=bv(i,j)
         enddo
c         write(*,*) 'calcvel ',i,(vel(i,j),j=1,3)
      enddo
!     
      return
      end
