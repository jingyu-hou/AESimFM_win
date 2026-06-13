!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine intersectionpoint(pa,pb,xcp,t,xinters)
!     
      implicit none
!
      integer k
!     
      real*8 pa(*),pb(*),xcp(*),t,xinters(*),diff,pab(3),
     &     eplane,tnull
!     
      do k=1,3
         pab(k)=pb(k)-pa(k)
      enddo
      diff=0.d0
      if(abs(eplane(pab,xcp,0.d0)).lt.1.d-13)then
         write(*,*) 'SH: IP no intersection point can be found'
         write(*,*) 'SH: IP pab paralell to plane! '
         call exit(201)
      else 
         tnull=0.d0
         diff=-eplane(pa, xcp,t)/eplane(pab,xcp,tnull)
      endif  
      do k=1,3
         xinters(k)=pa(k)+diff*pab(k)
      enddo
      return
      end       
      
