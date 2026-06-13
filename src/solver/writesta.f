!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine writesta(istep,j,icutb,l,ttime,time,dtime,inext)
      implicit none
!
!     writes increment statistics in the .sta file
!     the close and open guarantees that the computer buffer is
!     emptied each time a new line is written. That way the file
!     is always up to date (also during the calculation)
!
      integer istep,j,icutb,l,inext
!     integer iostat
      real*8 ttime,time,dtime
!
      write(8,100) istep,j,icutb+1,l,ttime+time,time,dtime,inext
c      call flush(8)
      flush(8)
!
!     for some unix systems flush has two arguments
!
!     call flush(8,iostat)
!     if(iostat.lt.0) then
!        write(*,*) '*ERROR in writesummary: cannot flush buffer'
!        call exit(201)
!     endif
!
 100  format(1x,i5,1x,i10,2(1x,i5),3(1x,e13.6),1x,i5)
!
      return
      end
