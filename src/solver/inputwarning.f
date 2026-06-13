!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine inputwarning(inpc,ipoinpc,iline,text)
!
!     input error message subroutine
!
      implicit none
!
      character*1 inpc(*)
      character*(*) text
!
      integer ipoinpc(0:*),iline,i
!
      write(*,*) '*WARNING reading ',text(1:index(text,'%')-1),
     &      '. Card image:'
      write(*,'(10x,1320a1)') 
     &       (inpc(i),i=ipoinpc(iline-1)+1,ipoinpc(iline))
      write(*,*)
!
      return
      end
