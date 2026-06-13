!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine norm(vel,velnorm,nef)
!
!     calculation of the norm of all field components at
!     the element centers
!
      implicit none
!
      integer i,j,nef
!
      real*8 velnorm(0:4),vel(nef,0:7)
!     
c$omp parallel default(none)
c$omp& shared(velnorm,vel,nef)
c$omp& private(i,j)
c$omp do
      do i=1,nef
         do j=0,4
            velnorm(j)=velnorm(j)+vel(i,j)**2
         enddo
      enddo
c$omp end do
c$omp end parallel
!            
      return
      end
