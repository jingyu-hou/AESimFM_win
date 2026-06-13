!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine thermmodel(amat,iel,iint,kode,coconloc,vkl,
     &  dtime,time,ttime,mi,nstate_,xstateini,xstate,qflux,xstiff,
     &  iorien,pgauss,orab,t1l,t1lold,vold,co,lakonl,konl,ipompc,
     &  nodempc,coefmpc,nmpc,ikmpc,ilmpc,nmethod,iperturb,ithermal,
     &  imat,kstep,kinc,pphase,cphase,phaseother,nphase,phase_inf,
     &  t1lold1)
! 
      implicit none
!
      character*8 lakonl
      character*80 amat
!
      integer iel,iint,kode,mi(*),nstate_,iorien,ntgrd,ncoconst,
     &  layer,kspt,kstep,kinc,kal(2,6),konl(20),ipompc(*),nmethod,
     &  nodempc(3,*),nmpc,ikmpc(*),ilmpc(*),j3,j2,j4,jj,j,i,j1,
     &  iperturb(*),ithermal(2)
!
      real*8 coconloc(*),vkl(0:3,3),dtime,time,ttime,cond(6),
     &  xstateini(nstate_,mi(1),*),xstate(nstate_,mi(1),*),qflux(3),
     &  pgauss(3),orab(7,*),abqtime(2),u,dudt,dudg(3),dfdt(3),
     &  dfdg(3,3),dtemp,dtemdx(3),predef(1),dpred(1),pnewdt,
     &  skl(3,3),t1lold,xstiff(27,mi(1),*),xa(3,3),vold(0:mi(2),*),
     &  co(3,*),coefmpc(*),t1l

      integer phase_inf(4),nphase(11,*)

      integer NTTCT_Point(phase_inf(2),phase_inf(1)),
     & AIncubationtime_Point(phase_inf(1)),pointnumber(2,phase_inf(1)),
     & phaseequilibrium_point(phase_inf(1)),dstatev(phase_inf(1)),
     & TempZBF_Point(phase_inf(4),phase_inf(1))

      integer imat,III2

      real*8 pphase(2,phase_inf(3),7+phase_inf(4),phase_inf(1),*),
     & cphase(13+phase_inf(4),phase_inf(1),*),
     & phaseother(15+phase_inf(1)*phase_inf(4),*),
     & phase_equilibrium(2*phase_inf(3),phase_inf(1)),
     & hardness(phase_inf(1))

      real*8 cond1,dkdt,t1lold1,d,dA0,YS0,M,A2,Tau,Gammaapb,
     & BVector,Omega,YS1,YS2,hard1
      real*8 phase_sum

C      open(unit=10000,file='10000.dat')
      kal=reshape((/1,1,2,2,3,3,1,2,1,3,2,3/),(/2,6/))
!
      hard1=0.d0
      if(kode.eq.1.and.nphase(4,imat).ne.1.and.nphase(4,imat).ne.2.and.
     &     nphase(4,imat).ne.3)then
!
!         linear isotropic
!
         do i=1,3
            cond(i)=coconloc(1)
         enddo
         do i=4,6
            cond(i)=0.d0
         enddo
!
         do i=1,3
            qflux(i)=-coconloc(1)*vkl(0,i)
         enddo
!
      elseif((kode.eq.3).or.(kode.eq.6).and.nphase(4,imat).ne.1.and.
     &  nphase(4,imat).ne.2.and.nphase(4,imat).ne.3) then
         if((kode.eq.3).and.(iorien.eq.0)) then
!
!           orthotropic
!
            do i=1,3
               cond(i)=coconloc(i)
            enddo
            do i=4,6
               cond(i)=0.d0
            enddo
!     
            do i=1,3
               qflux(i)=-coconloc(i)*vkl(0,i)
            enddo
!
         else
            if(iorien.ne.0) then
!
!              transformation due to special orientation
!
!              calculating the transformation matrix
!
               call transformatrix(orab(1,iorien),pgauss,skl)
!
!              modifying the conductivity constants
!
               if(kode.eq.3) then
                  do j=4,6
                     coconloc(j)=0.d0
                  enddo
               endif
!     
               xa(1,1)=coconloc(1)
               xa(1,2)=coconloc(4)
               xa(1,3)=coconloc(5)
               xa(2,1)=coconloc(4)
               xa(2,2)=coconloc(2)
               xa(2,3)=coconloc(6)
               xa(3,1)=coconloc(5)
               xa(3,2)=coconloc(6)
               xa(3,3)=coconloc(3)
!
               do jj=1,6
                  coconloc(jj)=0.d0
                  j1=kal(1,jj)
                  j2=kal(2,jj)
                  do j3=1,3
                     do j4=1,3
                        coconloc(jj)=coconloc(jj)+
     &                       xa(j3,j4)*skl(j1,j3)*skl(j2,j4)
                     enddo
                  enddo
               enddo
            endif
!
!           anisotropy
!
            do i=1,6
               cond(i)=coconloc(i)
            enddo
!     
            qflux(1)=-coconloc(1)*vkl(0,1)-coconloc(4)*vkl(0,2)-
     &           coconloc(5)*vkl(0,3)
            qflux(2)=-coconloc(4)*vkl(0,1)-coconloc(2)*vkl(0,2)-
     &           coconloc(6)*vkl(0,3)
            qflux(3)=-coconloc(5)*vkl(0,1)-coconloc(6)*vkl(0,2)-
     &           coconloc(3)*vkl(0,3)
!
         endif
      elseif(nphase(4,imat).ge.1.and.nphase(4,imat).le.3)then

C********************************************************************************
C                                 开始相变的计算
C*********************************************************************************


C**********************************************************************************
C                        开始相变数据的赋值，高维数组运算速度较慢
C**********************************************************************************
        if(phase_inf(2).eq.2)then
            NTTCT_Point(1:2,2:phase_inf(1))=
     &       nint(cphase(6:7,2:phase_inf(1),imat))
        elseif(phase_inf(2).eq.3)then
            NTTCT_Point(1:3,2:phase_inf(1))=
     &       nint(cphase(6:8,2:phase_inf(1),imat))
        endif

        if(nphase(7,imat).eq.1)then
         AIncubationtime_Point(2:phase_inf(1))=
     &       nint(cphase(10,2:phase_inf(1),imat))
        endif

        if(nphase(10,imat).eq.1)then
         phaseequilibrium_point(1:phase_inf(1))=
     &       nint(cphase(9,1:phase_inf(1),imat))

          do III2=2,phase_inf(1)
             phase_equilibrium(1:phaseequilibrium_point(III2),III2)=
     &         pphase(1,1:phaseequilibrium_point(III2),4,III2,imat)
             phase_equilibrium(phaseequilibrium_point(III2)+1:2*
     &         phaseequilibrium_point(III2),III2)=
     &         pphase(2,1:phaseequilibrium_point(III2),4,III2,imat)
          enddo
        endif

         if(phase_inf(4).gt.0.and.phase_inf(4).lt.100)then
            TempZBF_Point(1:phase_inf(4),2:phase_inf(1))=
     &        nint(cphase(13:13+phase_inf(4)-1,2:phase_inf(1),imat))
         endif

         if(nphase(6,imat).eq.1)then
            pointnumber(1:2,1:phase_inf(1))=
     &        nint(cphase(11:12,1:phase_inf(1),imat))
         endif

         if(nphase(9,imat).eq.1)then
           dA0=phaseother(4,imat)
           YS0=phaseother(9,imat)
           M=phaseother(10,imat)
           A2=phaseother(11,imat)
           Tau=phaseother(12,imat)
           GammaAPB=phaseother(13,imat)
           BVector=phaseother(14,imat)
           Omega=phaseother(15,imat)
         endif

        if(nphase(11,imat).eq.1)then
          hardness(1:phase_inf(1))=
     &        cphase(13,1:phase_inf(1),imat)
C        write(10000,*)hardness(1:phase_inf(1))
C        write(10000,*)cphase(13,1:phase_inf(1),imat)
        endif
C**********************************************************************************
C                        相变数据的赋值结束
C**********************************************************************************

C         do iiii=1,phase_inf(1)
C             do jjjj=1,2
C              write(10000,*)'第',iiii,'个相','jjjj=',jjjj
C              write(10000,*)nttct_point(jjjj,iiii)
C             enddo
C         enddo

         dfdg=0.d0
         abqtime(1)=time-dtime
         abqtime(2)=ttime+time-dtime

         ntgrd=3
         dtemp=t1l-t1lold
         do i=1,3
           dtemdx(i)=vkl(0,i)
         enddo

!考虑塑性变形之后xstate前面14个位置留空                                
         if(nstate_.ge.13)then
             iii2=15
         else
             iii2=1
         endif

         do i=III2,nstate_
           xstate(i,iint,iel)=xstateini(i,iint,iel)
         enddo

         phase_sum=0.d0
         do i=1,phase_inf(1)
            phase_sum=phase_sum+dabs(xstate(III2+i-1,iint,iel))
         enddo
         if(phase_sum.le.1.d-12)then
            xstate(III2,iint,iel)=1.d0
         endif
C********************************************************************************
C                          以下几行用于相变的计算
C********************************************************************************
         call phasetransition(xstate(III2:III2+phase_inf(1)-1,iint,iel),
     &      t1lold1,
     &     t1lold+dtemp,abqtime(2),abqtime(2)+dtime,NTTCT_Point,
     &     phaseequilibrium_point,AIncubationtime_Point,
     &     TempZBF_Point,cphase(1:12+phase_inf(4),1:phase_inf(1),imat),
     &     phase_inf,nphase(1:10,imat),
     &     pphase(1:2,1:phase_inf(3),1:7+phase_inf(4),
     &     1:phase_inf(1),imat),
     &     phaseother(1:15+phase_inf(1)*phase_inf(4),imat),d,
     &     phase_equilibrium)
C********************************************************************************
C                          以上几行用于相变的计算
C********************************************************************************


C********************************************************************************
C                          以下几行用于屈服强度/硬度的计算
C********************************************************************************
          if(nphase(9,imat).eq.1)then
              if(d.gt.dA0)d=dA0
              xstate(III2+phase_inf(1),iint,iel)=d
              YS1=YS0+M*GammaAPB/2.d0/BVector*
     &       (A2*(GammaAPB*d*xstate(2,iint,iel)/Tau)**0.5d0-
     &       xstate(2,iint,iel))
 
              YS2=YS0+1.72d0*M*Tau*xstate(2,iint,iel)**0.5d0/2.d0/
     &       BVector/d*(1.28d0*GammaAPB*d/Omega/Tau-1.d0)**0.5d0
 
              if(YS1.gt.YS2)then
                xstate(III2+phase_inf(1)+1,iint,iel)=YS2
              else
                xstate(III2+phase_inf(1)+1,iint,iel)=YS1
              endif
          endif

          if(nphase(11,imat).eq.1)then
            do i=1,phase_inf(1)
               hard1=hard1+
     &         xstate(III2+i-1,iint,iel)*hardness(i)
            enddo
            xstate(III2+phase_inf(1)+2,iint,iel)=hard1
          endif
C********************************************************************************
C                          以上几行用屈服强度/硬度的计算
C********************************************************************************
C         if(iel.eq.1.and.iint.eq.1)then 
C              write(10000,*)'Time(1)=',abqtime(2)
C              write(10000,*)'Time(2)=',abqtime(2)+dtime
C              write(10000,*)'********************'
C              write(10000,*)'dtime=',dtime
C              write(10000,*)'Temp1=',t1lold1
C              write(10000,*)'Temp2=',t1lold+dtemp
C              write(10000,*)'********************'
C              write(10000,*)'statev1=(迭代)',xstate(2:4,iint,iel)
C         endif
C********************************************************************************
C                          以下几行用于热物参数的获取
C********************************************************************************
         if(nphase(6,imat).eq.1)then
           call phaseprop(pphase(1:2,1:phase_inf(3),6:7,
     &       1:phase_inf(1),imat),pointnumber(1:2,1:phase_inf(1)),
     &       t1l,DUDT,COND1,DKDT,
     &       xstate(III2:III2+phase_inf(1)-1,iint,iel),phase_inf)
         else
            cond1=coconloc(1)
         endif
C********************************************************************************
C                          以上几行用于热物参数的获取
C********************************************************************************

C********************************************************************************
C                          以下几行用于潜热的计算
C********************************************************************************
C         if(nphase(5,imat).eq.1)then
C             call phaselatentheat(u,dudt,dstatev,phase_inf(1),
C     &       cphase(2,1:phase_inf(1),imat),t1lold,dtemp,dtime)
C         endif
C********************************************************************************
C                          以上几行用于潜热的计算
C********************************************************************************
         do i=1,ntgrd
             qflux(i)=-cond1*dtemdx(i)
             dfdg(i,i)=-cond1
         enddo    

         cond(1)=-dfdg(1,1)
         cond(2)=-dfdg(2,2)
         cond(3)=-dfdg(3,3)
         cond(4)=-dfdg(1,2)
         cond(5)=-dfdg(1,3)
         cond(6)=-dfdg(2,3)
C*******************************************************************************
C                               相变的计算结束
C*******************************************************************************
      else
!
!        user material
!
         ncoconst=-kode-100
         
         if ( ithermal(1) .lt. 3) then
           do i=1,nstate_
              xstate(i,iint,iel)=xstateini(i,iint,iel)
           enddo
         endif

!
         abqtime(1)=time-dtime
         abqtime(2)=ttime+time-dtime
!
         ntgrd=3
         dtemp=t1l-t1lold
         do i=1,3
            dtemdx(i)=vkl(0,i)
         enddo
!
         call umatht(u,dudt,dudg,qflux,dfdt,dfdg,xstate(1,iint,iel),
     &     t1lold,dtemp,
     &     dtemdx,abqtime,dtime,predef,dpred,amat,ntgrd,nstate_,
     &     coconloc,ncoconst,pgauss,pnewdt,iel,iint,layer,kspt,
     &     kstep,kinc,vold,co,lakonl,konl,
     &     ipompc,nodempc,coefmpc,nmpc,ikmpc,ilmpc,mi)
!
         cond(1)=dfdg(1,1)
         cond(2)=dfdg(2,2)
         cond(3)=dfdg(3,3)
         cond(4)=dfdg(1,2)
         cond(5)=dfdg(1,3)
         cond(6)=dfdg(2,3)
!
      endif
!
      if(((nmethod.ne.4).or.(iperturb(1).ne.0)).and.
     &    (nmethod.ne.5)) then
         do i=1,6
            xstiff(21+i,iint,iel)=cond(i)
         enddo
      endif
!
      return
      end
