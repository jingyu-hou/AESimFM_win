!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine writeevcomplex(x,nx,fmin,fmax)
!
!     writes the eigenvalues in the .dat file
!
      implicit none
!
      integer j,nx
      real*8 pi,fmin,fmax
      complex*16 x(nx)
!     
      pi=4.d0*datan(1.d0)
!
      write(5,*)
      write(5,*) '    E I G E N V A L U E   O U T P U T'
      write(5,*)
      write(5,*) 'MODE NO                     FREQUENCY          
     &  '
      write(5,*) '                     REAL PART         IMAGINARY PART'
      write(5,*) '            (RAD/TIME)   (CYCLES/TIME)   (RAD/TIME)'
      write(5,*)
      do j=1,nx
         write(5,'(i7,4(2x,e14.7))') j,dreal(x(j)),
     &        dreal(x(j))/(2.d0*pi),dimag(x(j))
      enddo
!
      return
      end

