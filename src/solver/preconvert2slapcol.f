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
      subroutine preconvert2slapcol(irow,ia,jq,ja,nzs,nef)
!
      implicit none
!
      integer irow(*),ia(*),jq(*),ja(*),nzs,nef,i,j,k
!
!     converting the WeICME format into the SLAP column format
!
      k=nzs+nef
!
      do i=nef,1,-1
         do j=jq(i+1)-1,jq(i),-1
            ia(k)=irow(j)
            k=k-1
         enddo
         ia(k)=i
         k=k-1
      enddo
!
      ja(1)=1
      do i=2,nef+1
         ja(i)=jq(i)+i-1
      enddo
!
      return
      end
