!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine materialdata_temp2h(nsrhocp,srhocp,nflcon,flcon,
     &  nrhcon,rhcon,nshcon,shcon,lh,entha,imat,t1l,ntmat_,ithermal)
!
      implicit none
!
!     determines the density of the material
!
      integer nsrhocp(*),nflcon(*),nrhcon(*),nshcon(*),
     &        imat,two,ntmat_,id,ithermal
!
      real*8 srhocp(0:1,2*ntmat_,*),flcon(0:1,ntmat_,*),
     &       rhcon(0:1,ntmat_,*),shcon(0:1,ntmat_,*),
     &       t1l,rho,cp,fl,integral,entha,lh(*),
     &       temp0,rho0,cp0
!
      two=2
!
c      if(ithermal.eq.0) then
c         entha=srhocp(1,1,imat)
c      else
         call materialdata_rho(rhcon,nrhcon,imat,rho,
     &        t1l,ntmat_,ithermal)
         call materialdata_cp(imat,ntmat_,t1l,shcon,nshcon,cp)
         call materialdata_temp2fl(flcon,nflcon,imat,fl,
     &        t1l,ntmat_,ithermal)
         call ident2(srhocp(0,1,imat),t1l,nsrhocp(imat),two,id)
!
         if(nsrhocp(imat).eq.0) then
            continue
         elseif(nsrhocp(imat).eq.1) then
            entha=rho*(cp*t1l+fl*lh(imat))
         elseif(id.eq.0) then
            entha=rho*(cp*t1l+fl*lh(imat))
         else
            temp0=srhocp(0,id,imat)
            call materialdata_rho(rhcon,nrhcon,imat,rho0,
     &           temp0,ntmat_,ithermal)
            call materialdata_cp(imat,ntmat_,temp0,shcon,nshcon,cp0)
            call integratelinesproduct(rho0,rho,cp0,cp,
     &           temp0,t1l,t1l,integral)
            entha=srhocp(1,id,imat)+integral+rho*fl*lh(imat)
         endif
         entha=entha/1.d0
c      endif
!
      return
      end
!     
