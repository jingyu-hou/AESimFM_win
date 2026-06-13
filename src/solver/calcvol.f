      SUBROUTINE calcvol ( ie0, nip, lakon, kon, co, ipkon, volume)
      IMPLICIT NONE
      INTEGER :: ie0            ! element number
      INTEGER :: nip            ! max number of ip
      CHARACTER*8 lakon(*)      ! element label
      INTEGER :: kon(*)         ! kon contains the topology of all elements.
      INTEGER :: ipkon(*)       ! location in kon of the first node in the element connectivity
!     list of element i)-1
      INTEGER :: indexe
      REAL*8  :: volume         ! element volume
      REAL*8 co(3,*)
      

      INTEGER :: iflag, nelem
      INTEGER :: ip, jj, kl, ki, ilayer, j, k, nope
      INTEGER :: konl(20)
      REAL*8 xi, et, ze, weight
      REAL*8 xl(3,20), shp(4, 20 ), xsj, gs(8,4), a
      INTEGER :: mint3d         ! total number of ips of element nelem

      include "gauss.f"
      
      volume = 0.0
      ilayer = 0
      iflag = 2
      nelem = ie0 + 1

      if(lakon(nelem)(1:5).eq.'C3D8I') then
         nope=11
      elseif (lakon(nelem)(4:4).eq.'2') then
         nope=20
      elseif(lakon(nelem)(4:4).eq.'8') then
         nope=8
      elseif(lakon(nelem)(4:5).eq.'10') then
         nope=10
      elseif(lakon(nelem)(4:4).eq.'4') then
         nope=4
      elseif(lakon(nelem)(4:5).eq.'15') then
         nope=15
      elseif(lakon(nelem)(4:5).eq.'6') then
         nope=6
      else
         nope=0
      end if

      indexe=ipkon(nelem)
      do j=1,nope
         konl(j)=kon(indexe+j)  ! kon contains the topology of all elements.
         do k=1,3
            xl(k,j)=co(k,konl(j)) ! co coordinate matrix
         enddo
      enddo



!     determine mint3d
      if(lakon(nelem)(4:5).eq.'8R') then
         mint3d=1
      elseif(lakon(nelem)(4:7).eq.'20RB') then
         if((lakon(nelem)(8:8).eq.'R').or.
     &      (lakon(nelem)(8:8).eq.'C')) then
            mint3d=50
         else
!     to be finished
         endif
      elseif((lakon(nelem)(4:4).eq.'8').or.
     &        (lakon(nelem)(4:6).eq.'20R')) then
         if(lakon(nelem)(7:8).eq.'LC') then
!     to be finished
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
         if(lakon(nelem)(7:8).eq.'LC') then
!     to be finished
         else
            mint3d=9
         endif
      elseif(lakon(nelem)(4:5).eq.'6') then
         mint3d=2
      else
!     to be finished
         mint3d=0
      endif
      nip = mint3d 

      do jj = 1, mint3d
         if(lakon(nelem)(4:5).eq.'8R') then
            xi=gauss3d1(1,jj)
            et=gauss3d1(2,jj)
            ze=gauss3d1(3,jj)
            weight=weight3d1(jj) ! contained in gauss.f
         elseif(lakon(nelem)(4:7).eq.'20RB') then
c     to be finished
         elseif((lakon(nelem)(4:4).eq.'8').or.
     &           (lakon(nelem)(4:6).eq.'20R'))
     &           then
            if(lakon(nelem)(7:8).ne.'LC') then
               xi=gauss3d2(1,jj)
               et=gauss3d2(2,jj)
               ze=gauss3d2(3,jj)
               weight=weight3d2(jj)
            else
c     to be finished
            endif
         elseif(lakon(nelem)(4:4).eq.'2') then
            xi=gauss3d3(1,jj)
            et=gauss3d3(2,jj)
            ze=gauss3d3(3,jj)
            weight=weight3d3(jj)
         elseif(lakon(nelem)(4:5).eq.'10') then
            xi=gauss3d5(1,jj)
            et=gauss3d5(2,jj)
            ze=gauss3d5(3,jj)
            weight=weight3d5(jj)
         elseif(lakon(nelem)(4:4).eq.'4') then
            xi=gauss3d4(1,jj)
            et=gauss3d4(2,jj)
            ze=gauss3d4(3,jj)
            weight=weight3d4(jj)
         elseif(lakon(nelem)(4:5).eq.'15') then
            if(lakon(nelem)(7:8).ne.'LC') then
               xi=gauss3d8(1,jj)
               et=gauss3d8(2,jj)
               ze=gauss3d8(3,jj)
               weight=weight3d8(jj)
            else
c     to be finished
            endif
         else
            xi=gauss3d7(1,jj)
            et=gauss3d7(2,jj)
            ze=gauss3d7(3,jj)
            weight=weight3d7(jj)
         endif


         if(lakon(nelem)(1:5).eq.'C3D8R') then
            call shape8hr(xl,xsj,shp,gs,a)
         elseif(lakon(nelem)(1:5).eq.'C3D8I') then
            call shape8hu(xi,et,ze,xl,xsj,shp,iflag)
         elseif(nope.eq.20) then
            call shape20h(xi,et,ze,xl,xsj,shp,iflag)
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
         volume=volume+weight*xsj

      end do



      END SUBROUTINE calcvol
