!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
!     y=A*x for real sparse symmetric matrices
!
!     storage of the matrix:
!        au: first lower triangle
!        ad: diagonal terms
!
      subroutine convert2slapcol(au,ad,jq,nzs,nef,aua)
!
      implicit none
!
      integer jq(*),nzs,nef,i,j,k
      real*8 au(*),ad(*),aua(*)
!
!     converting the WeICME format into the SLAP column format
!
      k=nzs+nef
!
      do i=nef,1,-1
         do j=jq(i+1)-1,jq(i),-1
            aua(k)=au(j)
            k=k-1
         enddo
         aua(k)=ad(i)
         k=k-1
      enddo
!
      return
      end
