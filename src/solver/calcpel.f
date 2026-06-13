!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine calcpel(ne,nactdoh,vel,b,nef)
!
!     stores the pressure into field vel
!
      implicit none
!
      integer ne,nactdoh(*),i,nef
!
      real*8 vel(nef,0:7),b(*)
!
      do i=1,ne
         vel(i,4)=vel(i,4)+b(i)
c         write(*,*) i
c         write(*,*) nactdoh(i)
c         write(*,*) b(nactdoh(i))
c         write(*,*) 'calcpel ',i,vel(i,4)
      enddo
c      write(*,*) 'calcpel ',vel(1600,4)
c      write(*,*)
!     
      return
      end
