!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine calcumel(nef,vel,shcon,nshcon,ielmat,ntmat_,
     &  ithermal,mi,umel)
!
!     calculation of the dynamic viscosity in the element centers
!
      implicit none
!
      integer nef,i,nshcon(*),imat,ithermal(*),ntmat_,mi(*),
     &  ielmat(mi(3),*)
!
      real*8 t1l,vel(nef,0:7),dvi,shcon(0:3,ntmat_,*),umel(*)
!     
      do i=1,nef
         t1l=vel(i,0)
         imat=ielmat(1,i)
         call materialdata_dvi(shcon,nshcon,imat,dvi,t1l,ntmat_,
     &            ithermal)
         umel(i)=dvi
      enddo
!            
      return
      end
