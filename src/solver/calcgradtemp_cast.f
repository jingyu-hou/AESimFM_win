!
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine calcgradtemp_cast(co,kon,lakon,ipkon,
     &  mi,ielmat,vold,ne,gradtempi)
!
!     calculate temperature gradient on gauss points, which is needed
!     for calculation of temperature gradient on nodes
!
      character*8 lakon(*)
!
      integer kon(*),ipkon(*),mi(*),ielmat(mi(3),*),ne,
     &        konl(20),nelem,nope,mint3d,indexe,ii,jj,kk,iflg
!
      real*8 co(3,*),vold(0:mi(2),*),shp(4,26),gradtempi(3,mi(1),*),
     &       xi,et,ze,xl(3,26),xsj
!
      include "gauss.f"
!
      iflag=3
      do nelem=1,ne
!
         if(ipkon(nelem).lt.0) cycle
         if((lakon(nelem)(1:2).eq.'ES')
     &            .and.(lakon(nelem)(7:7).ne.'A')) cycle
         if((lakon(nelem)(1:2).eq.'D ')) cycle
c         if(lakon(nelem)(1:1).ne.'F') cycle
         indexe=ipkon(nelem)
!     
         imat=ielmat(1,nelem)
!     
         if(lakon(nelem)(4:5).eq.'20') then
            nope=20
         elseif(lakon(nelem)(4:4).eq.'8') then
            nope=8
         elseif(lakon(nelem)(4:5).eq.'10') then
            nope=10
         elseif(lakon(nelem)(4:4).eq.'4') then
            nope=4
         elseif(lakon(nelem)(4:5).eq.'15') then
            nope=15
         elseif(lakon(nelem)(4:4).eq.'6') then
            nope=6
         else
            cycle
         endif
!
         if(lakon(nelem)(4:5).eq.'8R') then
            mint3d=1
         elseif((lakon(nelem)(4:4).eq.'8').or.
     &          (lakon(nelem)(4:6).eq.'20R')) then
            if(lakon(nelem)(6:7).eq.'RA') then
               mint3d=4
            else
               mint3d=8
            endif
         elseif(lakon(nelem)(4:4).eq.'2') then
            mint3d=27
         elseif(lakon(nelem)(4:5).eq.'10') then
            mint3d=4
         elseif(lakon(nelem)(4:4).eq.'4') then
            mint3d=1
         elseif(lakon(nelem)(4:5).eq.'15') then
            mint3d=9
         elseif(lakon(nelem)(4:4).eq.'6') then
            mint3d=2
         else
            mint3d=0
         endif
!     
         do jj=1,nope
            konl(jj)=kon(indexe+jj) 
            do ii=1,3
               xl(ii,jj)=co(ii,konl(jj))
            enddo
         enddo 
!
         do kk=1,mint3d
!
            if(lakon(nelem)(4:5).eq.'8R') then
               xi=gauss3d1(1,kk)
               et=gauss3d1(2,kk)
               ze=gauss3d1(3,kk)
               weight=weight3d1(kk)
            elseif((lakon(nelem)(4:4).eq.'8').or.
     &             (lakon(nelem)(4:6).eq.'20R'))
     &        then
               xi=gauss3d2(1,kk)
               et=gauss3d2(2,kk)
               ze=gauss3d2(3,kk)
               weight=weight3d2(kk)
            elseif(lakon(nelem)(4:4).eq.'2') then
               xi=gauss3d3(1,kk)
               et=gauss3d3(2,kk)
               ze=gauss3d3(3,kk)
               weight=weight3d3(kk)
            elseif(lakon(nelem)(4:5).eq.'10') then
               xi=gauss3d5(1,kk)
               et=gauss3d5(2,kk)
               ze=gauss3d5(3,kk)
               weight=weight3d5(kk)
            elseif(lakon(nelem)(4:4).eq.'4') then
               xi=gauss3d4(1,kk)
               et=gauss3d4(2,kk)
               ze=gauss3d4(3,kk)
               weight=weight3d4(kk)
            elseif(lakon(nelem)(4:5).eq.'15') then
               xi=gauss3d8(1,kk)
               et=gauss3d8(2,kk)
               ze=gauss3d8(3,kk)
               weight=weight3d8(kk)
            elseif(lakon(nelem)(4:4).eq.'6') then
               xi=gauss3d7(1,kk)
               et=gauss3d7(2,kk)
               ze=gauss3d7(3,kk)
               weight=weight3d7(kk)
            endif
!
            if(nope.eq.20) then
               if(lakon(nelem)(7:7).eq.'A') then
                  call shape20h_ax(xi,et,ze,xl,xsj,shp,iflag)
               elseif((lakon(nelem)(7:7).eq.'E').or.
     &                (lakon(nelem)(7:7).eq.'S')) then
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
            do ii=1,3
               gradtempi(ii,kk,nelem)=0.d0
            enddo
!
            do jj=1,nope
               do ii=1,3
                  gradtempi(ii,kk,nelem)=
     &            gradtempi(ii,kk,nelem)+shp(ii,jj)*vold(0,konl(jj))
               enddo
            enddo
!
         enddo
      enddo
!     
      return
      end