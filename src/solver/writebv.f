!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine writebv(x,nx)
!
!     writes the buckling force factor to unit 5
!
      implicit none
!
      integer j,nx
      real*8 x(nx),pi
!
      pi=4.d0*datan(1.d0)
!
      write(5,*)
      write(5,*) '    B U C K L I N G   F A C T O R   O U T P U T'
      write(5,*)
      write(5,*) 'MODE NO       BUCKLING'
      write(5,*) '               FACTOR'
      write(5,*)
      do j=1,nx
         write(5,'(i7,2x,e14.7)') j,x(j)
      enddo
!
      return
      end

