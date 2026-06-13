!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!  
      subroutine preparenycalc(nk,vold,vini,mi,coolingrate,gtemp,
     &  gradtempn,dtime,fl_ny,fl_nystar,flcon,nflcon,ntmat_,ithermal)
!
!     calculate cooling rate and  temperature gradient
!
      implicit none
!
      integer nk,mi(*),nflcon(*),ithermal(*),ntmat_,imat,i
!
      real*8 vold(0:mi(2),*),vini(0:mi(2),*),coolingrate(2,*),
     &       gtemp(2,*),gradtempn(3,*),dtime,fl_ny,fl_nystar,
     &       flcon(0:1,ntmat_,*),temp,fl
!
      do i=1,nk
        if((coolingrate(1,i).gt.-1.d-10).and.
     &              (coolingrate(2,i).gt.-1.d-10)) cycle
!
        imat=1
        temp=vold(0,i)
        call materialdata_temp2fl(flcon,nflcon,imat,fl,
     &       temp,ntmat_,ithermal)
c        print *,"preparenycalc:",coolingrate(1,i),
c     &        coolingrate(1,i),fl,temp
!
        if((coolingrate(1,i).lt.-1.d-10).and.
     &                      (fl.lt.fl_ny)) then
           coolingrate(1,i)=(vini(0,i)-temp)/dtime
           gtemp(1,i)=(gradtempn(1,i)**2.d0
     &               +gradtempn(2,i)**2.d0
     &               +gradtempn(3,i)**2.d0)**0.5d0
        endif
!
        if((coolingrate(2,i).lt.-1.d-10).and.
     &                      (fl.lt.fl_nystar)) then
            coolingrate(2,i)=(vini(0,i)-temp)/dtime
            gtemp(2,i)=(gradtempn(1,i)**2.d0
     &                +gradtempn(2,i)**2.d0
     &                +gradtempn(3,i)**2.d0)**0.5d0
         endif
      enddo
!
      return
      end
!