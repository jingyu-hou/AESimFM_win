!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine calcrhofa(nface,vfa,rhcon,nrhcon,ielmat,ntmat_,
     &  ithermal,mi,ielfa)
!
!     calculation of the density at the face centers
!     (incompressible fluids)
!
      implicit none
!
      integer nface,i,nrhcon(*),imat,ithermal(*),ntmat_,mi(*),
     &  ielmat(mi(3),*),ielfa(4,*)
!
      real*8 t1l,vfa(0:7,*),rhcon(0:1,ntmat_,*) 
!     
      do i=1,nface
         t1l=vfa(0,i)
!
!        take the material of the first adjacent element
!
         imat=ielmat(1,ielfa(1,i))
         call materialdata_rho(rhcon,nrhcon,imat,vfa(5,i),t1l,ntmat_,
     &            ithermal)
      enddo
!            
      return
      end
