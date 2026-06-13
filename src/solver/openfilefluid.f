!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine openfilefluid(jobname)
!
      implicit none
!
      character*132 jobname,fnfrd,fncvg
      integer i
!
!     opening frd file
!
      do i=1,132
         if(jobname(i:i).eq.' ') exit
      enddo
      i=i-1
      if(i.gt.128) then
         write(*,*) 
     &     '*ERROR in openfilefluid: input file name is too long:'
         write(*,'(a132)') jobname(1:132)
         write(*,*) '       exceeds 128 characters'
         call exit(201)
      endif
!
      fnfrd=jobname(1:i)//'.frd'
      open(13,file=fnfrd(1:i+5),status='unknown',position='append')
!
      return
      end
