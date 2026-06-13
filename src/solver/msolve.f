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
      subroutine msolve(n,r,z,nelt,ia,ja,a,isym,rwork,iwork)
!
      implicit none
!
      integer n,nelt,ia(*),ja(*),isym,iwork(*),i,nd
!
      real*8 r(*),z(*),a(*),rwork(*)
!
      do i=1,n
         z(i)=r(i)*rwork(i)
      enddo
!
      return
      end
