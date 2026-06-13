!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine calcrhoel(nef,vel,rhcon,nrhcon,ielmat,ntmat_,
     &  ithermal,mi)
!
!     calculation of rho in the element centers (incompressible
!     fluids)
!
      implicit none
!
      integer nef,i,nrhcon(*),imat,ithermal(*),ntmat_,mi(*),
     &  ielmat(mi(3),*)
!
      real*8 t1l,vel(nef,0:7),rhcon(0:1,ntmat_,*)
!     
      do i=1,nef
         t1l=vel(i,0)
         imat=ielmat(1,i)
         call materialdata_rho(rhcon,nrhcon,imat,vel(i,5),t1l,ntmat_,
     &            ithermal)
      enddo
!            
      return
      end
