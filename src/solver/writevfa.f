!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine writevfa(vfa,nface,nactdohinv,ielfa)
!
!     writing facial values
!
      implicit none
!
      integer nface,nactdohinv(*),ielfa(4,*),i,iel
!
      real*8 vfa(0:7,*)
!
      do i=1,nface
         if(ielfa(2,i).ge.0) cycle
         iel=ielfa(1,i)
         iel=nactdohinv(iel)
         write(*,*) 'writevfa ',iel,ielfa(4,i),
     &      vfa(0,i),vfa(1,i),vfa(2,i),vfa(3,i)
      enddo
!     
      return
      end
