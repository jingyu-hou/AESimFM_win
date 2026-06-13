!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine writempc(ipompc,nodempc,coefmpc,labmpc,mpc)
!
!     writes an MPC to standard output (for debugging purposes)
!
      implicit none
!
      character*20 labmpc(*)
      integer ipompc(*),nodempc(3,*),mpc,index,node,idir
      real*8 coefmpc(*),coef
!
      write(*,*)
      write(*,'(''MPC '',i10,1x,a20)') mpc,labmpc(mpc)
      index=ipompc(mpc)
      do
         node=nodempc(1,index)
         idir=nodempc(2,index)
         coef=coefmpc(index)
         write(*,'(i10,1x,i5,1x,e11.4)') node,idir,coef
         index=nodempc(3,index)
         if(index.eq.0) exit
      enddo
!
      return
      end

