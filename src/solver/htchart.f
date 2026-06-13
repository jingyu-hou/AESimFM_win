!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!  
      subroutine htchart(nrhcon,rhcon,nshcon,shcon,nflcon,flcon,
     &  nsrhocp,srhocp,nhtcon,htcon,lh,nmat,templiq,tempsol,
     &  physcon,ntmat_,ithermal)
!
!     generate the enthalpy-temperature chart where enthalpy is
!     htcon(0,..,..) enthalpy
!     htcon(1,..,..) temperature
!
      implicit none
!
      integer nrhcon(*),nshcon(*),nflcon(*),nhtcon(*),nsrhocp(*),
     &        ithermal(*),nmat,ntmat_,imat,j,n,nthermchart,
     &        idliq,idsol,two
!
      real*8 rhcon(0:1,ntmat_,*),shcon(0:3,ntmat_,*),
     &       flcon(0:1,ntmat_,*),htcon(0:1,nhtcon(1),*),
     &       srhocp(0:1,2*ntmat_,*),templiq,tempsol,
     &       lh(*),physcon(*),temp,tmin,tmax,dt,entha
!
      two=2
!
      do imat=1,nmat
        if(nrhcon(imat).lt.0) cycle
        tmin=1.d9
        tmax=-1.d9
        nthermchart=0
        if(nrhcon(imat).gt.1) then
            tmin=min(tmin,rhcon(0,1,imat))
            tmax=max(tmax,rhcon(0,nshcon(imat),imat))
            nthermchart=nthermchart+1
        endif
        if(nshcon(imat).gt.1) then
            tmin=min(tmin,shcon(0,1,imat))
            tmax=max(tmax,shcon(0,nshcon(imat),imat))
            nthermchart=nthermchart+1
        endif
        if(nflcon(imat).gt.1) then
            tmin=min(tmin,flcon(0,1,imat))
            tmax=max(tmax,flcon(0,nflcon(imat),imat))
            nthermchart=nthermchart+1
        endif
!
!       in case that each thermal property defines only one data point
!
        if(nthermchart.eq.0) then
            tmin=0.d0
            tmax=2000.d0
        endif
c        print *,"non const thermal properties:",nthermchart
!
        dt=(tmax-tmin)/real(nhtcon(imat)-1)
        temp=tmin
c        print *,"htchart:",tmax,tmin,dt,nhtcon(imat),lh(imat)
        print *,"mat id:",imat,"latant heat",lh(imat)
        if(nflcon(imat).le.1) then
            do j=1,nhtcon(imat)
                call materialdata_temp2h(nsrhocp,srhocp,nflcon,flcon,
     &               nrhcon,rhcon,nshcon,shcon,lh,entha,
     &               imat,temp,ntmat_,ithermal)
                htcon(0,j,imat)=entha
                htcon(1,j,imat)=temp
                print *,"chart point",j,htcon(0,j,imat),htcon(1,j,imat)
                temp=temp+dt
            enddo
        else
            call ident2(flcon(0,1,imat),templiq,
     &                  nflcon(imat),two,idliq)
            call ident2(flcon(0,1,imat),tempsol,
     &                  nflcon(imat),two,idsol)
            n=(nhtcon(imat)-idliq+idsol-1)
     &           *((tempsol-tmin)/(tmax-templiq+tempsol-tmin))
            print *,"region below solidus:"
            dt=(tempsol-tmin)/real(n)
            temp=tmin
            do j=1,n
                call materialdata_temp2h(nsrhocp,srhocp,nflcon,flcon,
     &               nrhcon,rhcon,nshcon,shcon,lh,entha,
     &               imat,temp,ntmat_,ithermal)
                htcon(0,j,imat)=entha
                htcon(1,j,imat)=temp
                print *,"chart point",j,htcon(0,j,imat),htcon(1,j,imat)
                temp=temp+dt
            enddo
!
            print *,"region between solidus and liquidus:"
            do j=n+1,n+idliq-idsol+1
                temp=flcon(0,j-n-1+idsol,imat)
                call materialdata_temp2h(nsrhocp,srhocp,nflcon,flcon,
     &               nrhcon,rhcon,nshcon,shcon,lh,entha,
     &               imat,temp,ntmat_,ithermal)
                htcon(0,j,imat)=entha
                htcon(1,j,imat)=temp
                print *,"chart point",j,htcon(0,j,imat),htcon(1,j,imat)    
            enddo
!
            print *,"region above liquidus:"
            dt=(tmax-templiq)/real(nhtcon(imat)-n-idliq+idsol-1)
            temp=templiq+dt
            do j=n+idliq-idsol+2,nhtcon(imat)
                call materialdata_temp2h(nsrhocp,srhocp,nflcon,flcon,
     &               nrhcon,rhcon,nshcon,shcon,lh,entha,
     &               imat,temp,ntmat_,ithermal)
                htcon(0,j,imat)=entha
                htcon(1,j,imat)=temp
                print *,"chart point",j,htcon(0,j,imat),htcon(1,j,imat)
                temp=temp+dt                
            enddo
        endif
c        nhtcon(imat)=nsrhocp(imat)
c        do j=1,nhtcon(imat)
c            temp=srhocp(0,j,imat)
c            call materialdata_temp2h(nsrhocp,srhocp,nflcon,flcon,
c     &           nrhcon,rhcon,nshcon,shcon,lh,entha,
c     &           imat,temp,ntmat_,ithermal)
c            htcon(0,j,imat)=entha
c            htcon(1,j,imat)=temp
c            print *,"chart point",j,htcon(0,j,imat),htcon(1,j,imat)  
c        enddo
      enddo
!
      return
      end
!