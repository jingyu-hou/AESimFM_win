!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine materialdata_th_h(cocon,ncocon,imat,iorien,pgauss,orab,
     &  ntmat_,coconloc,mattyp,t1l,rhcon,nrhcon,rho,shcon,nshcon,sph,
     &  xstiff,iint,iel,istiff,mi,xstateini,nstate_,nelcon,flcon,nflcon,
     &  lh)
!
      implicit none
!
!     effective conductivity coefficients is calculated other than the
!     physical ones, distinguishing this subroutine from
!     materialdata_th.f ---2021.6.16 by Ye
!
!     determines the density, the specific heat and the conductivity 
!     in an integration point with coordinates pgauss
!
      integer ncocon(2,*),imat,iorien,k,mattyp,mi(*),
     &  ntmat_,id,two,four,seven,nrhcon(*),nshcon(*),
     &  iint,iel,ncond,istiff,ncoconst,nelcon(2,*),nstate_,nflcon(*)
!
      real*8 cocon(0:6,ntmat_,*),orab(7,*),coconloc(6),t1l,
     &  pgauss(3),rhcon(0:1,ntmat_,*),
     &  shcon(0:3,ntmat_,*),rho,sph,xstiff(27,mi(1),*),
     &  xstateini(nstate_,mi(1),*),flcon(0:1,ntmat_,*),lh(*),
     &  fl,drho,dfl,dentha,slope1,slope2
!
      two=2
      four=4
      seven=7
!
      if(istiff.eq.1) then
!
         ncond=ncocon(1,imat)
         if((ncond.le.-100).or.(iorien.ne.0)) ncond=6
!     
!        determining the conductivity coefficients
!
         do k=1,6
            coconloc(k)=xstiff(21+k,iint,iel)
         enddo
!     
!        determining the type: isotropic, orthotropic or anisotropic
!
         if(ncond.le.1) then
            mattyp=1
         elseif(ncond.le.3) then
            mattyp=2
         else
            mattyp=3
         endif
!
      else
!
         ncoconst=ncocon(1,imat)
         if(ncoconst.le.-100) ncoconst=-ncoconst-100
!
!        calculating the density and its derivative with temperature
!        (needed for the capacity matrix)
!
         call ident2(rhcon(0,1,imat),t1l,nrhcon(imat),two,id)
         if(nrhcon(imat).eq.0) then
            continue
         elseif(nrhcon(imat).eq.1) then
            rho=rhcon(1,1,imat)
            drho=0.d0
         elseif(id.eq.0) then
            rho=rhcon(1,1,imat)
            drho=0.d0
         elseif(id.eq.nrhcon(imat)) then
            rho=rhcon(1,id,imat)
            drho=0.d0
         else
            rho=rhcon(1,id,imat)+
     &           (rhcon(1,id+1,imat)-rhcon(1,id,imat))*
     &           (t1l-rhcon(0,id,imat))/
     &           (rhcon(0,id+1,imat)-rhcon(0,id,imat))
            drho=(rhcon(1,id+1,imat)-rhcon(1,id,imat))/
     &           (rhcon(0,id+1,imat)-rhcon(0,id,imat))
c            if((rhcon(0,id+1,imat)-t1l).lt.0.1d0) then
c               if(id.eq.(nrhcon(imat)-1)) then
c                  slope2=0
c               else
c                  slope2=(rhcon(1,id+2,imat)-rhcon(1,id+1,imat))/
c     &                   (rhcon(0,id+2,imat)-rhcon(0,id+1,imat))
c               endif
c               slope1=(rhcon(1,id+1,imat)-rhcon(1,id,imat))/
c     &                (rhcon(0,id+1,imat)-rhcon(0,id,imat))
c               drho=slope1+(slope2-slope1)/0.1d0
c     &                     *(t1l-rhcon(0,id+1,imat)+0.1d0)
c            else
c               drho=(rhcon(1,id+1,imat)-rhcon(1,id,imat))/
c     &          (rhcon(0,id+1,imat)-rhcon(0,id,imat))
c            endif
         endif
!     
!        calculating the specific heat (needed for the capacity matrix)
!     
         call ident2(shcon(0,1,imat),t1l,nshcon(imat),four,id)
         if(nshcon(imat).eq.0) then
            continue
         elseif(nshcon(imat).eq.1) then
            sph=shcon(1,1,imat)
         elseif(id.eq.0) then
            sph=shcon(1,1,imat)
         elseif(id.eq.nshcon(imat)) then
            sph=shcon(1,id,imat)
         else
            sph=shcon(1,id,imat)+
     &           (shcon(1,id+1,imat)-shcon(1,id,imat))*
     &           (t1l-shcon(0,id,imat))/
     &           (shcon(0,id+1,imat)-shcon(0,id,imat))
         endif
!
!        calculating the liquid fraction and its derivative with
!        temperature
!
         call ident2(flcon(0,1,imat),t1l,nflcon(imat),two,id)
         if(nflcon(imat).eq.0) then
            continue
         elseif(nflcon(imat).eq.1) then
            fl=flcon(1,1,imat)
            dfl=0.d0
         elseif(id.eq.0) then
            fl=flcon(1,1,imat)
            dfl=0.d0
         elseif(id.eq.nflcon(imat)) then
            fl=flcon(1,id,imat)
            dfl=0.d0
         else
            fl=flcon(1,id,imat)+
     &           (flcon(1,id+1,imat)-flcon(1,id,imat))*
     &           (t1l-flcon(0,id,imat))/
     &           (flcon(0,id+1,imat)-flcon(0,id,imat))
            dfl=(flcon(1,id+1,imat)-flcon(1,id,imat))/
     &          (flcon(0,id+1,imat)-flcon(0,id,imat))
c            if((flcon(0,id+1,imat)-t1l).lt.0.1d0) then
c               if(id.eq.(nflcon(imat)-1)) then
c                  slope2=0
c               else
c                  slope2=(flcon(1,id+2,imat)-flcon(1,id+1,imat))/
c     &                   (flcon(0,id+2,imat)-flcon(0,id+1,imat))
c               endif
c               slope1=(flcon(1,id+1,imat)-flcon(1,id,imat))/
c     &                (flcon(0,id+1,imat)-flcon(0,id,imat))
c               dfl=slope1+(slope2-slope1)/0.1d0
c     &                     *(t1l-flcon(0,id+1,imat)+0.1d0)
c            else
c               dfl=(flcon(1,id+1,imat)-flcon(1,id,imat))/
c     &             (flcon(0,id+1,imat)-flcon(0,id,imat))
c            endif
         endif
c         dentha=rho*sph+(rho*fl)*lh(imat)
         dentha=rho*sph+(drho*fl+rho*dfl)*lh(imat)
c          dentha=1.d0
c         if(t1l.lt.1011.d0)
c     &   print *,"materialdata_th_h:",t1l,rho,drho,fl,dfl,dentha
!     
!     calculating the effective conductivity coefficients
!
         call ident2(cocon(0,1,imat),t1l,ncocon(2,imat),seven,id)
         if(ncocon(2,imat).eq.0) then
            do k=1,6
               coconloc(k)=0.d0
            enddo
            continue
         elseif(ncocon(2,imat).eq.1) then
            do k=1,ncoconst
               coconloc(k)=cocon(k,1,imat)/dentha
            enddo
         elseif(id.eq.0) then
            do k=1,ncoconst
               coconloc(k)=cocon(k,1,imat)/dentha
            enddo
         elseif(id.eq.ncocon(2,imat)) then
            do k=1,ncoconst
               coconloc(k)=cocon(k,id,imat)/dentha
            enddo
         else
            do k=1,ncoconst
               coconloc(k)=(cocon(k,id,imat)+
     &              (cocon(k,id+1,imat)-cocon(k,id,imat))*
     &              (t1l-cocon(0,id,imat))/
     &              (cocon(0,id+1,imat)-cocon(0,id,imat)))
               coconloc(k)=coconloc(k)/dentha
            enddo
         endif
      
         if (nelcon(1,imat).eq.-70) then
            coconloc(1)=coconloc(1)*(2.d0*xstateini(1,iint,iel)/
     &         (3.d0-xstateini(1,iint,iel)))
         endif
c         print *,"materialdata_th_h:",t1l,fl,dfl,dentha,coconloc(1)
      endif
!
      return
      end



