!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
!     y=A*x for real sparse antisymmetric matrices,
!     i.e. the transpose is the negative matrix: A^T=-A
!
!     storage of the matrix:
!        au: first lower triangle
!        ad: diagonal terms
!
      subroutine op_corio(n,x,y,ad,au,jq,irow)
!
      implicit none
!
      integer irow(*),n,j,l,i,jq(*)
      real*8 y(*),x(*),au(*),ad(*)
!
!     diagonal terms
!
      do i=1,n
         y(i)=ad(i)*x(i)
      enddo
!
!     off-diagonal terms
!
      do j=1,n
         do l=jq(j),jq(j+1)-1
            i=irow(l)
            y(i)=y(i)+au(l)*x(j)
            y(j)=y(j)-au(l)*x(i)
         enddo
      enddo
!
      return
      end
