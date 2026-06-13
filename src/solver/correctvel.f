!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine correctvel(adv,nef,volume,gradpcel,vel,nefa,nefb)
!
!     correction of the velocity at the element centers due to the
!     pressure change (balance of mass)
!
!     the solution is stored in field bv.
!
      implicit none
!
      integer i,k,nef,nefa,nefb
!
      real*8 adv(*),volume(*),gradpcel(3,*),vel(nef,0:7)
!
!
!
      do i=nefa,nefb
         do k=1,3
            vel(i,k)=vel(i,k)-volume(i)*gradpcel(k,i)/adv(i)
         enddo
      enddo
!  
      return
      end
