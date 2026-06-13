!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine writerandomfield(d,nev,abserr,relerr)
!
!     writes the eigenvalues and the error measures of 
!     the randomfield in the .dat file
!
      implicit none
!
      integer iobject,i,nev
      real*8 d(*),abserr,relerr
!
      write(5,*)
      write(5,*) 'EIGENVALUES OF MODESHAPES OF RANDOMFIELD'  
      write(5,*)
      do i=nev,1,-1
         write(5,'(7x,e14.7)') d(i)
      enddo
!
      write(5,*)
      write(5,*) 'ABSOLUTE ERROR W.R.T. THE VARIANCE OF THE RANDOMFIELD'
      write(5,*)
      write(5,'(7x,e14.7)') abserr
      write(5,*)
      write(5,*) 'RELATIVE ERROR W.R.T. THE VARIANCE OF THE RANDOMFIELD'
      write(5,*)
      write(5,'(7x,e14.7)') relerr

      return
      end

