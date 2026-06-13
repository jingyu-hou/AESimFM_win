!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine matvec(n,x,y,nelt,ia,ja,a,isym)
!
      implicit none
!
      integer ia(*),ja(*),i,j,n,nelt,isym,nflnei
      real*8 y(*),x(*),a(*)
!
      do i=1,n
         y(i)=a(ja(i)+1)*x(ia(ja(i)+1))
         do j=ja(i)+2,ja(i+1)
               y(i)=y(i)+a(j)*x(ia(j))
         enddo
      enddo
!
      return
      end
