!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine materialdata_th_h2(cocon,ncocon,imat,iorien,pgauss,
     &  orab,ntmat_,coconloc,mattyp,t1l,rhcon,nrhcon,rho,shcon,nshcon,
     &  sph,xstiff,iint,iel,istiff,mi,xstateini,nstate_,nelcon,
     &  flcon,nflcon,htcon,nhtcon,entha,lh)
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
     &  iint,iel,ncond,istiff,ncoconst,nelcon(2,*),nstate_,nflcon(*),
     &  nhtcon(*)
!
      real*8 cocon(0:6,ntmat_,*),orab(7,*),coconloc(6),t1l,
     &  pgauss(3),rhcon(0:1,ntmat_,*),htcon(0:1,nhtcon(1),*),
     &  shcon(0:3,ntmat_,*),rho,sph,xstiff(27,mi(1),*),
     &  xstateini(nstate_,mi(1),*),flcon(0:1,ntmat_,*),lh(*),
     &  entha,fl,drho,dfl,dentha,slope1,slope2
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
c            drho=(rhcon(1,id+1,imat)-rhcon(1,id,imat))/
c     &           (rhcon(0,id+1,imat)-rhcon(0,id,imat))
            if((rhcon(0,id+1,imat)-t1l).lt.0.1d0) then
               if(id.eq.(nrhcon(imat)-1)) then
                  slope2=0
               else
                  slope2=(rhcon(1,id+2,imat)-rhcon(1,id+1,imat))/
     &                   (rhcon(0,id+2,imat)-rhcon(0,id+1,imat))
               endif
               slope1=(rhcon(1,id+1,imat)-rhcon(1,id,imat))/
     &                (rhcon(0,id+1,imat)-rhcon(0,id,imat))
               drho=slope1+(slope2-slope1)/0.1d0
     &                     *(t1l-rhcon(0,id+1,imat)+0.1d0)
            else
               drho=(rhcon(1,id+1,imat)-rhcon(1,id,imat))/
     &          (rhcon(0,id+1,imat)-rhcon(0,id,imat))
            endif
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
         call ident2(htcon(0,1,imat),entha,nhtcon(imat),two,id)
         if(nflcon(imat).eq.0) then
            continue
c         elseif(nhtcon(imat).eq.1) then
c            dentha=
         elseif(id.eq.0) then
            dentha=(htcon(1,2,imat)-htcon(1,1,imat))/
     &             (htcon(0,2,imat)-htcon(0,1,imat))
         elseif(id.eq.nhtcon(imat)) then
            dentha=(htcon(1,id,imat)-htcon(1,id-1,imat))/
     &             (htcon(0,id,imat)-htcon(0,id-1,imat))
         else
c            dentha=(htcon(1,id+1,imat)-htcon(1,id,imat))/
c     &             (htcon(0,id+1,imat)-htcon(0,id,imat))
            if((htcon(0,id+1,imat)-entha).lt.0.1d0) then
               if(id.eq.(nhtcon(imat)-1)) then
                  slope2=0
               else
                  slope2=(htcon(1,id+2,imat)-htcon(1,id+1,imat))/
     &                   (htcon(0,id+2,imat)-htcon(0,id+1,imat))
               endif
               slope1=(htcon(1,id+1,imat)-htcon(1,id,imat))/
     &                (htcon(0,id+1,imat)-htcon(0,id,imat))
               dentha=slope1+(slope2-slope1)/0.1d0
     &                     *(entha-htcon(0,id+1,imat)+0.1d0)
            else
               dentha=(htcon(1,id+1,imat)-htcon(1,id,imat))/
     &                (htcon(0,id+1,imat)-htcon(0,id,imat))
            endif
c            print *,"calc dentha",htcon(0,id+1,imat),htcon(0,id,imat),
c     &               htcon(1,id+1,imat),htcon(1,id,imat)
         endif
c          dentha=dentha/1.d6
          dentha=1.d0
c         if(t1l.lt.1011.d0)
c         print *,"materialdata_th_h2:",t1l,dentha
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
               coconloc(k)=cocon(k,1,imat)*dentha
            enddo
         elseif(id.eq.0) then
            do k=1,ncoconst
               coconloc(k)=cocon(k,1,imat)*dentha
            enddo
         elseif(id.eq.ncocon(2,imat)) then
            do k=1,ncoconst
               coconloc(k)=cocon(k,id,imat)*dentha
            enddo
         else
            do k=1,ncoconst
               coconloc(k)=(cocon(k,id,imat)+
     &              (cocon(k,id+1,imat)-cocon(k,id,imat))*
     &              (t1l-cocon(0,id,imat))/
     &              (cocon(0,id+1,imat)-cocon(0,id,imat)))
               coconloc(k)=coconloc(k)*dentha
            enddo
         endif
      
         if (nelcon(1,imat).eq.-70) then
            coconloc(1)=coconloc(1)*(2.d0*xstateini(1,iint,iel)/
     &         (3.d0-xstateini(1,iint,iel)))
         endif
c         print *,"materialdata_th_h2:",t1l,dentha,coconloc(1)
      endif
!
      return
      end



