!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine init(nktet,inodfa,ipofa,netet_);
!
      implicit none
!
      integer nktet,i,netet_,inodfa(4,*),ipofa(*)
!
!     initialization of ipofa and inodfa
!
      do i=1,nktet
         ipofa(i)=0
      enddo
      do i=1,4*netet_
         inodfa(4,i)=i+1
      enddo
      inodfa(4,4*netet_)=0
!
      return
      end
