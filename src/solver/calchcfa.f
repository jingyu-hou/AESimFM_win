!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine calchcfa(nface,vfa,cocon,ncocon,ielmat,ntmat_,
     &  mi,ielfa,hcfa)
!
!     calculation of the thermal conductivity at the face centers
!
      implicit none
!
      integer nface,i,ncocon(2,*),imat,ntmat_,mi(*),
     &  ielmat(mi(3),*),ielfa(4,*)
!
      real*8 t1l,vfa(0:7,*),cond,cocon(0:6,ntmat_,*),hcfa(*)
!     
      do i=1,nface
         t1l=vfa(0,i)
!
!        take the material of the first adjacent element
!
         imat=ielmat(1,ielfa(1,i))
         call materialdata_cond(imat,ntmat_,t1l,cocon,ncocon,cond)
         hcfa(i)=cond
      enddo
!            
      return
      end
