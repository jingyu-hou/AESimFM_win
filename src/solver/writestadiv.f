!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine writestadiv(istep,j,icutb,l,ttime,time,dtime,inext)
!
      implicit none
!
!     writes increment statistics in the .sta file
!     the close and open guarantees that the computer buffer is
!     emptied each time a new line is written. That way the file
!     is always up to data (also during the calculation)
!
!     this version of writesummary is meant for increments which did
!     not converge
!
      integer istep,j,icutb,l,inext
      real*8 ttime,time,dtime
!
      write(8,100) istep,j,icutb+1,l,ttime+time-dtime,time-dtime,dtime,
     &   inext 
      flush(8)
!
 100  format(1x,i5,1x,i10,1x,i5,'U',1x,i4,3(1x,e13.6),1x,i5)
!
      return
      end
