!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine calchcel(vel,cocon,ncocon,ielmat,ntmat_,
     &  mi,hcel,nef)
!
!     calculation of the heat conduction in the element centers
!
      implicit none
!
      integer nef,i,ncocon(2,*),imat,ntmat_,mi(*),
     &   ielmat(mi(3),*)
!
      real*8 t1l,vel(nef,0:7),cocon(0:6,ntmat_,*),hcel(*)
!     
      do i=1,nef
         t1l=vel(i,0)
         imat=ielmat(1,i)
         call materialdata_cond(imat,ntmat_,t1l,cocon,ncocon,hcel(i))
      enddo
!            
      return
      end
