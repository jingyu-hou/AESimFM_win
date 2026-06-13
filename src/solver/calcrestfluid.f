!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
!     Calculating the residual in CFD-calculations
!
      subroutine calcrestfluid(n,a,b,au,ia,ja,x,res,xmin,xmax)
!
      implicit none
!
      integer i,j,n,ia(*),ja(*)
!
      real*8 xmax,xmin,a(*),b(*),au(*),x(*),res,resi
!
      xmax=0.d0
      xmin=0.d0
      res=0.d0
!
      do i=1,n
         resi=a(ja(i)+1)*x(ia(ja(i)+1))
         do j=ja(i)+2,ja(i+1)
            resi=resi+a(j)*x(ia(j))
         enddo
         res=res+((resi-b(i))/au(i))**2
         xmax=max(xmax,x(i))
         xmin=min(xmin,x(i))
      enddo
!
      return
      end
