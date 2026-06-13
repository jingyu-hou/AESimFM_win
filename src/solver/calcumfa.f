!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine calcumfa(nface,vfa,shcon,nshcon,ielmat,ntmat_,
     &  ithermal,mi,ielfa,umfa)
!
!     calculation of the dynamic viscosity at the face centers
!
      implicit none
!
      integer nface,i,nshcon(*),imat,ithermal(*),ntmat_,mi(*),
     &  ielmat(mi(3),*),ielfa(4,*)
!
      real*8 t1l,vfa(0:7,*),dvi,shcon(0:3,ntmat_,*),umfa(*)
!     
      do i=1,nface
         t1l=vfa(0,i)
!
!        take the material of the first adjacent element
!
         imat=ielmat(1,ielfa(1,i))
         call materialdata_dvi(shcon,nshcon,imat,dvi,t1l,ntmat_,
     &            ithermal)
         umfa(i)=dvi
c         write(*,*) 'calcumfa ',umfa(i)
      enddo
!            
      return
      end
