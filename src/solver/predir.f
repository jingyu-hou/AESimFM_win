!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine predir(n,b,x,nelt,ia,ja,a,isym,itol,tol,itmax,iter,
     &  err,ierr,iunit,r,z,dz,rwork,iwork)
!
      implicit none
!
      integer n,nelt,ia(*),ja(*),isym,itol,itmax,iter,ierr,
     &  iunit,iwork(*)
!
      real*8 b(*),x(*),a(*),tol,err,r(*),z(*),dz(*),
     &  rwork(*)
!
      external matvec,msolve
!
      call dir(n,b,x,nelt,ia,ja,a,isym,matvec,msolve,itol,tol,itmax,
     &  iter,err,ierr,iunit,r,z,dz,rwork,iwork)
!
      return
      end
