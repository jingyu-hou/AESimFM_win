!
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine smoothshock(adb,aub,adl,addiv,sol,aux,icol,irow,jq,
     &  neq,nzl,sa)
!
!     smoothing the finite element solution
!
!     Ref: The Finite Element Method for Fluid Dynamics,
!          O.C. Zienkiewicz, R.L. Taylor & P. Nithiarasu
!          6th edition (2006) ISBN 0 7506 6322 7
!          p. 61
!
      implicit none
!
      integer icol(*),irow(*),jq(*),neq,nzl,i,j,k
!
      real*8 adb(*),aub(*),adl(*),sol(*),aux(*),p,sa(*),addiv(*)
!
!     multiplying M-ML with the solution
!
c      call op(neq,p,sol,aux,adb,aub,icol,irow,nzl)
      call op(neq,sol,aux,adb,aub,jq,irow)
!
!     smoothing the solution
!
      do i=1,neq
         sol(i)=sol(i)+sa(i)*aux(i)*adl(i)
      enddo
!
      return
      end
