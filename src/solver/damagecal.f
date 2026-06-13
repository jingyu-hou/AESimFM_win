!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine damagecal(nea,neb,lakon,ipkon,mi,list,ilist,
     &   pressx,pressn,stx,co,kon,xstate,nstate_,dtime,inum,nk,ne,
     &   orab,ielorien,vold,ielmat,thicke,ielprop,prop)
!
!     calculates stresses and the material tangent at the integration
!     points and the internal forces at the nodes
!
      implicit none
!
!
      character*8 lakon(*),lakonl
      character*1 cflag
!
      integer mi(*),nea,neb,list,ilist(*),ipkon(*),kon(*),nstate_,nk,
     &   ne,ielmat(mi(3),*),ielprop(*),inum(*)
      integer i,j,k,jj,m,iflag,i1,indexe,konl(26),criteria,nope,mint3d,
     &   nfield,ndim,force,iorienloc
!
      real*8 dtime,pressx(mi(1),*),stx(6,mi(1),*),pressn(*),co(3,*),
     &   xstate(nstate_,mi(1),*),orab(7,*),ielorien(mi(3),*),
     &   vold(0:mi(2),*),prop(*),thicke(mi(3),*)
      real*8 xi,et,ze,xl(3,26),xsj,shp(4,26),weight,gs(8,4),a,press1,
     &   damag0,damag,c,dprop(2),stress(6),eqplas,deqpl,press0 
!
!      intent(in) pressn
!
!      intent(inout) pressx
!
      include "gauss.f"
!
      iflag=3
c
c calculate the pressure in the integration points
c
      do m=nea,neb
!
         if(list.eq.1) then
            i=ilist(m)
         else
            i=m
         endif
!
         lakonl=lakon(i)
         indexe=ipkon(i)
!
         if(lakonl(4:5).eq.'8R') then
            mint3d=1
         elseif(lakonl(4:7).eq.'20RB') then
            mint3d=50
         elseif((lakonl(4:4).eq.'8').or.
     &          (lakonl(4:6).eq.'20R')) then
            mint3d=8
         elseif(lakonl(4:4).eq.'2') then
            mint3d=27
         elseif(lakonl(4:5).eq.'10') then
            mint3d=4
         elseif(lakonl(4:4).eq.'4') then
            mint3d=1
         elseif(lakonl(4:5).eq.'15') then
            mint3d=9
         elseif(lakonl(4:4).eq.'6') then
            mint3d=2
         elseif(lakonl(1:1).eq.'E') then
            mint3d=0
         endif
!
         do jj=1,mint3d
            pressx(jj,i)=(stx(1,jj,i)+stx(2,jj,i)+stx(3,jj,i))/3.d0
         enddo
!
!
      enddo

      iorienloc=0
      cflag=" "
      force=1
      ndim=1
      nfield=1
      
c
c average the pressure in nodes
c
      call extrapolate(pressx,pressn,ipkon,inum,kon,lakon,nfield,nk,
     &     ne,mi(1),ndim,orab,ielorien,co,iorienloc,cflag,
     &     vold,force,ielmat,thicke,ielprop,prop)

c
c interpolate the node pressure to the integration
c
      do m=nea,neb
!
         if(list.eq.1) then
            i=ilist(m)
         else
            i=m
         endif
!
         lakonl=lakon(i)
         indexe=ipkon(i)
!
         if(lakonl(1:5).eq.'C3D8I') then
            nope=11
         elseif(lakonl(4:5).eq.'20') then
            nope=20
         elseif(lakonl(4:4).eq.'8') then
            nope=8
         elseif(lakonl(4:5).eq.'10') then
            nope=10
         elseif(lakonl(4:4).eq.'4') then
            nope=4
         elseif(lakonl(4:5).eq.'15') then
            nope=15
         elseif(lakonl(4:4).eq.'6') then
            nope=6
         endif
!
         if(lakonl(4:5).eq.'8R') then
            mint3d=1
         elseif(lakonl(4:7).eq.'20RB') then
            mint3d=50
         elseif((lakonl(4:4).eq.'8').or.
     &          (lakonl(4:6).eq.'20R')) then
            mint3d=8
         elseif(lakonl(4:4).eq.'2') then
            mint3d=27
         elseif(lakonl(4:5).eq.'10') then
            mint3d=4
         elseif(lakonl(4:4).eq.'4') then
            mint3d=1
         elseif(lakonl(4:5).eq.'15') then
            mint3d=9
         elseif(lakonl(4:4).eq.'6') then
            mint3d=2
         elseif(lakonl(1:1).eq.'E') then
            mint3d=0
         endif
!         
         do j=1,nope
            konl(j)=kon(indexe+j)
            do k=1,3
               xl(k,j)=co(k,konl(j))
            enddo
         enddo
!
         do jj=1,mint3d
            if(lakonl(4:5).eq.'8R') then
               xi=gauss3d1(1,jj)
               et=gauss3d1(2,jj)
               ze=gauss3d1(3,jj)
               weight=weight3d1(jj)
            elseif(lakonl(4:7).eq.'20RB') then
               xi=gauss3d13(1,jj)
               et=gauss3d13(2,jj)
               ze=gauss3d13(3,jj)
               weight=weight3d13(jj)
            elseif((lakonl(4:4).eq.'8').or.
     &             (lakonl(4:6).eq.'20R'))
     &        then
               xi=gauss3d2(1,jj)
               et=gauss3d2(2,jj)
               ze=gauss3d2(3,jj)
               weight=weight3d2(jj)
            elseif(lakonl(4:4).eq.'2') then
               xi=gauss3d3(1,jj)
               et=gauss3d3(2,jj)
               ze=gauss3d3(3,jj)
               weight=weight3d3(jj)
            elseif(lakonl(4:5).eq.'10') then
               xi=gauss3d5(1,jj)
               et=gauss3d5(2,jj)
               ze=gauss3d5(3,jj)
               weight=weight3d5(jj)
            elseif(lakonl(4:4).eq.'4') then
               xi=gauss3d4(1,jj)
               et=gauss3d4(2,jj)
               ze=gauss3d4(3,jj)
               weight=weight3d4(jj)
            elseif(lakonl(4:4).eq.'6') then
               xi=gauss3d7(1,jj)
               et=gauss3d7(2,jj)
               ze=gauss3d7(3,jj)
               weight=weight3d7(jj)
            endif
!
            if(lakonl(1:5).eq.'C3D8R') then
               call shape8hr(xl,xsj,shp,gs,a)
            elseif(lakonl(1:5).eq.'C3D8I') then
               call shape8hu(xi,et,ze,xl,xsj,shp,iflag)
            elseif(nope.eq.20) then
               if(lakonl(7:7).eq.'A') then
                  call shape20h_ax(xi,et,ze,xl,xsj,shp,iflag)
               elseif((lakonl(7:7).eq.'E').or.
     &                (lakonl(7:7).eq.'S')) then
                  call shape20h_pl(xi,et,ze,xl,xsj,shp,iflag)
               else
                  call shape20h(xi,et,ze,xl,xsj,shp,iflag)
               endif
            elseif(nope.eq.8) then
               call shape8h(xi,et,ze,xl,xsj,shp,iflag)
            elseif(nope.eq.10) then
               call shape10tet(xi,et,ze,xl,xsj,shp,iflag)
            elseif(nope.eq.4) then
               call shape4tet(xi,et,ze,xl,xsj,shp,iflag)
            elseif(nope.eq.15) then
               call shape15w(xi,et,ze,xl,xsj,shp,iflag)
            else
               call shape6w(xi,et,ze,xl,xsj,shp,iflag)
            endif
!
            press1=0.d0
            if((lakonl(4:5).eq.'8 ').or.
     &         (lakonl(4:5).eq.'8I')) then
               do i1=1,8
                  press1=press1+pressn(konl(i1))/8.d0
!                  press1=press1+shp(4,i1)*pressn(konl(i1))
               enddo
            else
               do i1=1,nope
                  press1=press1+shp(4,i1)*pressn(konl(i1))
               enddo
            endif
            
            pressx(jj,i)=press1
c        
c damage 
c
            press0=(stx(1,jj,i)+stx(2,jj,i)+stx(3,jj,i))/3.d0
            stress(1)=stx(1,jj,i)-press0+press1
            stress(2)=stx(2,jj,i)-press0+press1
            stress(3)=stx(3,jj,i)-press0+press1
            stress(4)=stx(4,jj,i)
            stress(5)=stx(5,jj,i)
            stress(6)=stx(6,jj,i)
            damag0=xstate(16,jj,i)
            eqplas=xstate(1,jj,i)
            deqpl=xstate(8,jj,i)*dtime
            damag=damag0
            criteria=1
            c=1.d100
            dprop(1)=0.d0
            dprop(2)=0.d0
            call damage(stress,eqplas,deqpl,criteria,damag,dprop)
            xstate(16,jj,i)=damag
            if ((damag-c)*(damag0-c).lt.0.d0) then
              if (damag.gt.c) then
                xstate(17,jj,i)=eqplas
              else
                xstate(17,jj,i)=-eqplas
              endif
            endif
            xstate(19,jj,i)=press0
            xstate(20,jj,i)=press1
!
!
         enddo
!
      enddo
!
      return
      end
