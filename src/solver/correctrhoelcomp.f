!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine correctrhoelcomp(nef,vel,shcon,ielmat,ntmat_,
     &  mi)
!
!     calculation of rho in the element centers (compressible
!     fluids)
!
      implicit none
!
      integer nef,i,imat,ntmat_,mi(*),
     &  ielmat(mi(3),*)
!
      real*8 t1l,vel(nef,0:7),shcon(0:3,ntmat_,*)
!     
c$omp parallel default(none)
c$omp& shared(nef,vel,ielmat,shcon)
c$omp& private(i,t1l,imat)
c$omp do
      do i=1,nef
         t1l=vel(i,0)
         imat=ielmat(1,i)
         vel(i,5)=vel(i,5)+vel(i,4)/(shcon(3,1,imat)*t1l)
c         vel(i,5)=vel(i,5)+0.2*vel(i,4)/(shcon(3,1,imat)*t1l)
      enddo
c$omp end do
c$omp end parallel
!            
      return
      end
