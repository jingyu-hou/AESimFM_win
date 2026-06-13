!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine op(n,x,y,ad,au,jq,irow)
!
      implicit none
!
      integer irow(*),n,j,l,i,jq(*)
!
      real*8 y(*),x(*),au(*),ad(*)
!
      intent(in) n,x,ad,au,jq,irow
!
      intent(inout) y
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
            y(j)=y(j)+au(l)*x(i)
         enddo
      enddo
!
      return
      end
