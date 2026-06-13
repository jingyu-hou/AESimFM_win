!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine writedesi(norien,orname)
!
!     writes the orientation design variables in the .dat file
!
      implicit none
!
      character*80 orname(*)
!
      integer j,norien
!
      intent(in) norien,orname
!     
      write(5,*)
      write(5,*) '    D E S I G N   V A R I A B L E S'
      write(5,*)
      write(5,'(a8,1x,a11,62x,a15)') 'VARIABLE','ORIENTATION',
     &    'ROTATION VECTOR'
      write(5,*)
!
      do j=1,norien
         write(5,'(i5,4x,a80,1x,a5)') (j-1)*3+1,orname(j)(1:80),'Rx   '
         write(5,'(i5,4x,a80,1x,a5)') (j-1)*3+2,orname(j)(1:80),'Ry   '
         write(5,'(i5,4x,a80,1x,a5)') (j-1)*3+3,orname(j)(1:80),'Rz   '
      enddo
!
      return
      end

