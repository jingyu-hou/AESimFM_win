!
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine phys2con_cast(inomat,node,vold,ntmat_,shcon,nshcon,
     &  physcon,compressible,vcon,rhcon,nrhcon,flcon,nflcon,
     &  srhocp,nsrhocp,lh,ithermal,mi)
!
!     applies temperature and velocity boundary conditions for
!     incompressible fluids (liquids)
!
      implicit none
!
      integer inomat(*),node,ntmat_,nshcon(*),compressible,nrhcon(*),
     &  nflcon(*),nsrhocp(*),ithermal(*),mi(*),imat,k
!
      real*8 rhcon(0:1,ntmat_,*),shcon(0:3,ntmat_,*),
     &  flcon(0:1,ntmat_,*),srhocp(0:1,2*ntmat_,*),vold(0:mi(2),*),
     &  vcon(0:4,*),physcon(*),temp,cp,r,rho,entha,lh   
!
      imat=inomat(node)
      temp=vold(0,node)
      call materialdata_cp_sec(imat,ntmat_,temp,shcon,nshcon,
     &     cp,physcon)
!     
      if(compressible.eq.1) then
!     
!        gas
!     
         r=shcon(3,1,imat)
         rho=vold(4,node)/(r*(vold(0,node)-physcon(1)))
         vcon(0,node)=rho*(cp*(temp-physcon(1))+
     &        (vold(1,node)**2+vold(2,node)**2+vold(3,node)**2)
     &        /2.d0)-vold(4,node)
         vcon(4,node)=rho
      else
!     
!        liquid 
!     
         call materialdata_rho(rhcon,nrhcon,imat,rho,
     &        temp,ntmat_,ithermal)
!*******************************TEST*******************************
         if(ithermal(1).gt.1) then
c            fl=0.d0
c            call materialdata_temp2fl(flcon,nflcon,imat,fl,
c     &           temp,ntmat_,ithermal)
c            vcon(0,node)=rho*(cp*(temp-physcon(1))+lh*fl+
c     &        (vold(1,node)**2+vold(2,node)**2+vold(3,node)**2)
c     &        /2.d0)
            call materialdata_temp2h(nsrhocp,srhocp,nflcon,flcon,
     &           nrhcon,rhcon,nshcon,shcon,lh,entha,
     &           imat,temp,ntmat_,ithermal)
            vcon(0,node)=entha
c            print *,"phys2con:  T=",temp,"fl=",fl
         endif
!******************************************************************
      endif
!     
      do k=1,3
         vcon(k,node)=rho*vold(k,node)
      enddo
!     
      return
      end
      
