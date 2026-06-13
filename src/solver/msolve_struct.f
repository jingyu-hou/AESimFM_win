!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
!     matrix preconditioning: used in dgmres.f
!
      subroutine msolve_struct(n,r,z,nelt,ia,ja,a,isym,rwork,iwork)
!
      implicit none
!
      integer n,nelt,ia(*),ja(*),isym,iwork(*),i,nd
!
      real*8 r(*),z(*),a(*),rwork(*)
!
c$omp parallel default(none)
c$omp& shared(n,z,r,rwork)
c$omp& private(i)
c$omp do
      do i=1,n
         z(i)=r(i)*rwork(i)
      enddo
c$omp end do
c$omp end parallel
!
      return
      end
