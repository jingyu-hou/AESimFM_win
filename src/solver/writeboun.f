!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine writeboun(nodeboun,ndirboun,xboun,typeboun,nboun)
!
!     writes an MPC to standard output (for debugging purposes)
!
      implicit none
!
      character*1 typeboun(*)
      integer nodeboun(*),ndirboun(*),nboun,i
      real*8 xboun(*)
!
      write(*,*)
      write(*,'(''SPC '')') 
      do i=1,nboun
         write(*,'(i5,1x,i10,1x,i5,1x,e11.4,1x,a1)') i,nodeboun(i),
     &             ndirboun(i),xboun(i),typeboun(i)
      enddo
!
      return
      end

