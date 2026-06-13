!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine negativepressure(ne0,ne,mi,stx,pressureratio)
!
!     calculating the ratio of the smallest pressure to the
!     largest pressure for face-to-face contact
!     if the pressure is somewhere negative, this ratio will
!     be negative
!
      implicit none
!
      integer ne0,ne,mi(*),i
!
      real*8 stx(6,mi(1),*),presmin,presmax,pressureratio
!
      presmax=0.d0
      presmin=0.d0
!
      do i=ne0+1,ne
         if(stx(4,1,i).gt.presmax) then
            presmax=stx(4,1,i)
         elseif(stx(4,1,i).lt.presmin) then
            presmin=stx(4,1,i)
         endif
      enddo
      pressureratio=presmin/presmax
!
      return
      end
