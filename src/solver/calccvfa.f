!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine calccvfa(nface,vfa,shcon,nshcon,ielmat,ntmat_,
     &  mi,ielfa,cvfa,physcon)
!
!     calculation of the secant heat capacity at constant pressure/volume
!     at the face centers (incompressible media)
!
      implicit none
!
      integer nface,i,nshcon(2,*),imat,ntmat_,mi(*),
     &  ielmat(mi(3),*),ielfa(4,*)
!
      real*8 t1l,vfa(0:7,*),shcon(0:3,ntmat_,*),cvfa(*),physcon(*)
!     
      do i=1,nface
         t1l=vfa(0,i)
!
!        take the material of the first adjacent element
!
         imat=ielmat(1,ielfa(1,i))
         call materialdata_cp_sec(imat,ntmat_,t1l,shcon,nshcon,cvfa(i),
     &       physcon)
      enddo
!            
      return
      end
