!
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

C!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
C     metal powder model with true true stress and true stran
C!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

c closest point method

      subroutine metal_powder(stress,statev,ddsdde,sse,spd,scd,
     1 rpl,ddsddt,drplde,drpldt,stran,dstran,time,dtime,temp,
     2 dtemp,temp0,predef,dpred,cmname,ndi,nshr,ntens,nstatv,
     3 elconloc,plconloc,mpconloc,coords,drot,pnewdt,
     4 celent,dfgrd0,dfgrd1,noel,npt,layer,kspt,jstep,kinc)
c
      implicit none
c      include 'aba_param.inc'
c
      character*80 cmname
      integer :: ntens,nshr,ndi,nstatv, noel, npt, 
     1 layer, kspt, jstep(4), kinc,densmax
      real*8 :: sse,spd,scd,rpl,drpldt,dtime,temp,dtemp,temp0, 
     1 pnewdt,celent
      real*8  stress(6),statev(nstatv),
     1 ddsdde(6,6),ddsddt(6),drplde(6),
     2 stran(6),dstran(6),time(2),predef(1),dpred(1),
     3 coords(3),drot(3,3),dfgrd0(3,3),dfgrd1(3,3),
     4 elconloc(21),plconloc(802),mpconloc(800)
      real*8 p,q,qa,d,r,tanb,qy,tanb0,r0,d0,py,pb,pb0,dens,dens0
      real*8 olds(6,1),s(6,1),ds(6,1),ds2(6,1),oldf1,oldf2,
     1       f,dqds(6,1),dqds2(6,6),dfds(6,1),dfdd
      real*8 dstrain(6,1),hv(6,1),pe(6,1),oldpe(6,1),ee(6,1)
      real*8 tp(1,1),tp6(6,1),tolerance
      real*8 dlamda,dlamda2,dd,dpb,h,pa,pa0
      real*8 denscels(6,6),dels(6,6),cels(6,6),densels(6,6)
      real*8 aftrot(3,3),befrot(3,3),z(6,1)
      real*8 b(7),a(7,7),resi(6,1),bb(7),aa(7,7),identi(6,6),
     1       residual,t_residual,e_vol0,e_vol,e_rate,work(6)
      real*8 t_s(6,1),t_ds(6,1),t_pe(6,1),t_dlamda,y(2),m_s(6,1),m_q,m
      integer i,j,k,kk,kkk,inc,vv(6+1),iflag,yflag,converge,
     1       lda,ipiv(6),info
      character*10 yield
      real*8, parameter :: pi=3.14159265359d0,one=1.0d0,zero=0.0d0,
     1        two=2.0d0, four=4.0d0, half=0.5d0
      real*8, external :: pressure, mises

c      elconloc(1): young's modulus
c      elconloc(2): poisson's reatio
c      elconloc(3): beta angle
c      elconloc(4): R
c      elconloc(5): d0
c      elconloc(6): d_th
c      elconloc(7): initial density
c      statev(1): relative density
c      statev(2): densification strain
c      statev(3): creep equivalent strain
c      statev(4): creep strain rate
c      statev(5): creep strain increment
c      statev(6): hydrostatic pressure
c      statev(7): Mises stress
c      statev(8): predicted stress
c      statev(9): creep equivalent stress
c      statev(10): creep pressure
c      statev(11): relaxed equivalent stress
c      statev(12): drx fraction
c      statev(13): drx grain size
c      statev(14): average grain size
c      statev(15): plastic strain 11
c      statev(16): plastic strain 22
c      statev(17): plastic strain 33
c      statev(18): plastic strain 12
c      statev(19): plastic strain 13
c      statev(20): plastic strain 23
c      statev(21): creep softening factor
c      statev(22): creep active flag
c      statev(23): creep model temperature (K)
c      statev(24): creep hold time
c      plconloc: plastic curve 
c      mpconloc: powder hardening curve
        
c input parameters and initial values
        tolerance = 10.d0
        k = 0
        inc = 0

        do i=2,800,2
          if (mpconloc(i).gt.mpconloc(i+2)) then
             densmax=i
             exit
          endif
        enddo

        do i = 1, 3
          do j = 1, 3
            befrot(i,j)=zero
          end do
        end do
        do i = 1, 3
          befrot(i,i)=statev(i+14)
        end do
        befrot(1,2)=statev(18)/two
        befrot(2,1)=statev(18)/two
        befrot(2,3)=statev(20)/two
        befrot(3,2)=statev(20)/two
        befrot(1,3)=statev(19)/two
        befrot(3,1)=statev(19)/two

        aftrot = matmul(drot,matmul(befrot,transpose(drot)))
        do i = 1, 3
          pe(i,1) = aftrot(i,i)
        end do
        pe(4,1) = aftrot(1,2)+aftrot(2,1)
        pe(6,1) = aftrot(2,3)+aftrot(3,2)
        pe(5,1) = aftrot(1,3)+aftrot(3,1)
        oldpe=pe
        e_vol0=dabs(pe(1,1)+pe(2,1)+pe(3,1))

        do i = 1, 6
          dstrain(i,1) = dstran(i)
        end do
        
        do i = 1, 3
          hv(i, 1) = -one
        end do
        do i = 4, 6
          hv(i, 1) = zero
        end do 

        tanb0 = tan(elconloc(3)/180d0*pi)
        r0 = elconloc(4)
        dens0 = elconloc(7)
        qy = plconloc(2)
        call fcoh(d0,dd,dens,elconloc,qy,mpconloc,densmax)
        call fpb(pb0,dpb,dens0,mpconloc,qy,densmax)
        tp = matmul(transpose(hv),pe)
        dens = dens0*exp(tp(1,1))
        pa0 = (pb0 - r0*d0)/(one + r0*tanb0)
        py = (qy-d0)/tanb0
        
c trial stress
        call elasticmatrix(dels,densels,dens,elconloc)

        do i = 1, 6
          ee(i,1) = stran(i)- pe(i,1)
        end do
        olds=matmul(dels,ee)

        ee=ee+dstrain
        s=matmul(dels,ee)
        
        yield = 'not yield'
        yflag = 0
        call yieldfun(f,dfds,dfdd,dqds2,s,dens,
     1    elconloc,qy,mpconloc,densmax,yflag,y,qa)
        dqds=dfds
        if (f.gt.tolerance) then
          yield="yield"
        endif
        
        dlamda=0.d0
        k=0

c stress update
        if (yield .eq. 'not yield') then
!        if (2.0d0 .gt. 1.0d0) then
          ddsdde = dels

        else
     
          call compliance(cels,denscels,dens,elconloc)
          ds=s-olds

          resi=dstrain-matmul(cels,ds)-dlamda*dqds
          residual=0.d0
          do i=1,6
            residual=residual+resi(i,1)**2.d0
          enddo
          residual=sqrt(residual)

          p=pressure(s)
          q=mises(s)
          m=1.d0
c return mapping

          do while ((residual .gt. 1.d-6).or.(dabs(f).gt.tolerance))

            kk=0
            converge=0
                
            t_s=s
            t_ds=ds
            t_dlamda=dlamda
            t_pe=pe

            do while ((residual .gt. 1.d-6).or.(dabs(f).gt.tolerance))
              if (kk.gt.1) then
                  oldf2=oldf1
                  oldf1=f
                elseif (kk.gt.0) then
                  oldf1=f
              endif

cc A matrix
              tp=dens*matmul(transpose(hv),dqds)
!            tp6=matmul(denscels,ds)*tp(1,1)
              do i=1,6
                do j=1,6
                  a(i,j)=cels(i,j)+dqds2(i,j)*dlamda
                enddo
!              a(i,7)=dqds(i,1)+tp6(i,1)
                a(i,7)=dqds(i,1)
                a(7,i)=dfds(i,1)
              
              enddo
              a(7,7)=dfdd*tp(1,1)
     
cc b matrix
              do i=1,6
                b(i)=resi(i,1)
              enddo
              b(6+1)=-f

cc solve Ax=b        
              call dgesv(7,1,a,7,vv,b,7,iflag)
            
cc update variable            
              do i=1,6
                ds2(i,1)=b(i)
              enddo
              dlamda2=b(7)
              
              s=s+ds2/m
              ds=ds+ds2/m
              dlamda=dlamda+dlamda2/m
              
              pe=pe-matmul(cels,ds2)
              tp = matmul(transpose(hv),pe)
              dens = dens0*exp(tp(1,1))
              
              call elasticmatrix(dels,densels,dens,elconloc)
              call compliance(cels,denscels,dens,elconloc)
              
              do i=1,6
                ee(i,1)=stran(i)+dstran(i)-pe(i,1)
              enddo
              call yieldfun(f,dfds,dfdd,dqds2,s,dens,
     1           elconloc,qy,mpconloc,densmax,yflag,y,qa)
              dqds=dfds   
            
              resi=dstrain-matmul(cels,ds)-dlamda*dqds
!              resi=pe-oldpe-dlamda*dqds
              residual=0.d0
              do i=1,6
                residual=residual+resi(i,1)**2.d0
              enddo
              residual=sqrt(residual)

              p=pressure(s)
              q=mises(s)

              kk=kk+1

              if ((kk.gt.2).and.(dabs(f-oldf2).lt.dabs(f*0.001d0)).and.
     1           (dabs(f).gt.dabs(oldf1))) then
                converge=yflag
                exit
              elseif (kk.gt.500) then
                converge=yflag
                exit
              endif
            enddo
              
            if (converge.eq.0) then
              if ((yflag.eq.2).and.(q.lt.y(1)))then
                m=m*2.d0
                s=t_s
                ds=t_ds
                dlamda=t_dlamda
                pe=t_pe
                tp = matmul(transpose(hv),pe)
                dens = dens0*exp(tp(1,1))
                do i=1,6
                  ee(i,1)=stran(i)+dstran(i)-pe(i,1)
                enddo
                call elasticmatrix(dels,densels,dens,elconloc)
                call compliance(cels,denscels,dens,elconloc)
                yflag=2
                call yieldfun(f,dfds,dfdd,dqds2,s,dens,
     1               elconloc,qy,mpconloc,densmax,yflag,y,qa)
                dqds=dfds
                resi=dstrain-matmul(cels,ds)-dlamda*dqds
                residual=0.d0
                do i=1,6
                  residual=residual+resi(i,1)**2.d0
                enddo
                residual=sqrt(residual)
              else
                m=1.d0
                yflag=0
                call yieldfun(f,dfds,dfdd,dqds2,s,dens,
     1               elconloc,qy,mpconloc,densmax,yflag,y,qa)
                dqds=dfds

                resi=dstrain-matmul(cels,ds)-dlamda*dqds
                residual=0.d0
                do i=1,6
                  residual=residual+resi(i,1)**2.d0
                enddo
                residual=sqrt(residual)
              endif
            elseif (converge.eq.3) then
              s=t_s
              ds=t_ds
              dlamda=t_dlamda
              pe=t_pe
              tp = matmul(transpose(hv),pe)
              dens = dens0*exp(tp(1,1))
              do i=1,6
                ee(i,1)=stran(i)+dstran(i)-pe(i,1)
              enddo
              call elasticmatrix(dels,densels,dens,elconloc)
              call compliance(cels,denscels,dens,elconloc)
              yflag=4
              call yieldfun(f,dfds,dfdd,dqds2,s,dens,
     1             elconloc,qy,mpconloc,densmax,yflag,y,qa)
              dqds=dfds
              resi=dstrain-matmul(cels,ds)-dlamda*dqds
              residual=0.d0
              do i=1,6
                residual=residual+resi(i,1)**2.d0
              enddo
              residual=sqrt(residual)
            else
              pnewdt=0.7d0
              return
            endif

            k=k+1

            if (k.gt.50) then
              pnewdt=0.7d0
              return
            endif
          enddo

c plastic stiffness matrix 
          dels=cels+dlamda*dqds2
          
cc matrix inverse
          call dgetrf(6,6,dels,6,ipiv,info)
          call dgetri(6,dels,6,ipiv,work,6,info)
          
          tp = matmul(transpose(dfds),matmul(dels, dqds))    
          tp = tp-matmul(transpose(dfds),matmul(densels,matmul(ee,
     1         matmul(transpose(hv),dqds))))*dens
          tp = tp-dens*dfdd*matmul(transpose(hv), dqds)
          h = tp(1,1)
          z=matmul(densels,matmul(ee,matmul(transpose(hv),dqds)))
     1       *dens-matmul(dels,dqds)
          z = z/h
          ddsdde=dels+matmul(z,matmul(transpose(dfds),dels))

        endif
!        ddsdde = matmul(olds,transpose(-hv))+ddsdde
        
c update variables
        
        if (isnan(s(1,1))) then
          pnewdt=0.7d0
        else
          do i = 1, 6
            stress(i) = s(i,1)
            statev(i+14) = pe(i,1)
          enddo 
          tp = matmul(transpose(hv),pe)
          statev(1) = dens0*exp(tp(1,1))

          p = pressure(s)
          q = mises(s)
          
          e_vol=dabs(pe(1,1)+pe(2,1)+pe(3,1))
          e_rate=dabs(e_vol-e_vol0)/dtime
          statev(2) = e_vol
          statev(6) = p
          statev(7) = q
           
          call drx_hip_weicme(e_vol,e_rate,temp+273.d0,dtime,statev,
     1     nstatv,kinc)
          
          statev(8) = qa/qy*(885.32d0/dsqrt(statev(14))+822.34d0)
        
        endif

      return
      end subroutine

C!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
C        Gradient and hessian matrix of pressure
C!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      subroutine dpressure(dpds,dpds2,s)
        implicit none
        integer i,j
        real*8 dpds(6,1),dpds2(6,6),s(6,1)
        
        do i=1,3
          dpds(i,1)=-1.d0/3.d0
        enddo
        do i=4,6
          dpds(i,1)=0.d0
        enddo

        do i=1,6
          do j=1,6
            dpds2(i,j)=0.d0
          enddo
        enddo

        return
      end

C!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
C        Gradient and hessian matrix of mises stress
C!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      subroutine dmises(dqds,dqds2,s)
        implicit none
        integer i,j
        real*8 dqds(6,1),dqds2(6,6),s(6,1),q
        real*8, external :: mises

        q=mises(s)
       
        if (q.gt.1.d0) then
          dqds(1,1)=0.5d0/q*(s(1,1)*2.d0-s(2,1)-s(3,1))
          dqds(2,1)=0.5d0/q*(s(2,1)*2.d0-s(3,1)-s(1,1))
          dqds(3,1)=0.5d0/q*(s(3,1)*2.d0-s(1,1)-s(2,1))
          do i = 4, 6
            dqds(i,1)=3.d0/q*s(i,1)
          end do

          dqds2(1,1)=1.d0/q-0.25d0*(s(1,1)*2.d0-s(2,1)-s(3,1))**2/
     1               q**3.d0
          dqds2(2,2)=1.d0/q-0.25d0*(s(2,1)*2.d0-s(3,1)-s(1,1))**2/
     1               q**3.d0
          dqds2(3,3)=1.d0/q-0.25d0*(s(3,1)*2.d0-s(1,1)-s(2,1))**2/
     1               q**3.d0
          dqds2(1,2)=-0.25d0*(s(1,1)*2.d0-s(2,1)-s(3,1))*
     1      (s(2,1)*2.d0-s(3,1)-s(1,1))/q**3.d0-0.5d0/q
          dqds2(2,1)=dqds2(1,2)
          dqds2(1,3)=-0.25d0*(s(1,1)*2.d0-s(2,1)-s(3,1))*
     1      (s(3,1)*2.d0-s(1,1)-s(2,1))/q**3.d0-0.5d0/q
          dqds2(3,1)=dqds2(1,3)
          dqds2(2,3)=-0.25d0*(s(2,1)*2.d0-s(3,1)-s(1,1))*
     1      (s(3,1)*2.d0-s(1,1)-s(2,1))/q**3.d0-0.5d0/q
          dqds2(3,2)=dqds2(2,3)
          
          dqds2(1,4)=-1.5d0*s(4,1)*(s(1,1)*2.d0-s(2,1)-s(3,1))/q**3.d0
          dqds2(4,1)=dqds2(1,4)
          dqds2(1,5)=-1.5d0*s(5,1)*(s(1,1)*2.d0-s(2,1)-s(3,1))/q**3.d0
          dqds2(5,1)=dqds2(1,5)
          dqds2(1,6)=-1.5d0*s(6,1)*(s(1,1)*2.d0-s(2,1)-s(3,1))/q**3.d0
          dqds2(6,1)=dqds2(1,6)
          dqds2(2,4)=-1.5d0*s(4,1)*(s(2,1)*2.d0-s(3,1)-s(1,1))/q**3.d0
          dqds2(4,2)=dqds2(2,4)
          dqds2(2,5)=-1.5d0*s(5,1)*(s(2,1)*2.d0-s(3,1)-s(1,1))/q**3.d0
          dqds2(5,2)=dqds2(2,5)
          dqds2(2,6)=-1.5d0*s(6,1)*(s(2,1)*2.d0-s(3,1)-s(1,1))/q**3.d0
          dqds2(6,2)=dqds2(2,6)
          dqds2(3,4)=-1.5d0*s(4,1)*(s(3,1)*2.d0-s(1,1)-s(2,1))/q**3.d0
          dqds2(4,3)=dqds2(3,4)
          dqds2(3,5)=-1.5d0*s(5,1)*(s(3,1)*2.d0-s(1,1)-s(2,1))/q**3.d0
          dqds2(5,3)=dqds2(3,5)
          dqds2(3,6)=-1.5d0*s(6,1)*(s(3,1)*2.d0-s(1,1)-s(2,1))/q**3.d0
          dqds2(6,3)=dqds2(3,6)
          
          dqds2(4,4)=3.d0/q-9.d0*s(4,1)**2/q**3.d0
          dqds2(5,5)=3.d0/q-9.d0*s(5,1)**2/q**3.d0
          dqds2(6,6)=3.d0/q-9.d0*s(6,1)**2/q**3.d0
          dqds2(4,5)=-9.d0*s(4,1)*s(5,1)/q**3.d0
          dqds2(5,4)=dqds2(4,5)
          dqds2(4,6)=-9.d0*s(4,1)*s(6,1)/q**3.d0
          dqds2(6,4)=dqds2(4,6)
          dqds2(5,6)=-9.d0*s(5,1)*s(6,1)/q**3.d0
          dqds2(6,5)=dqds2(5,6)
        else
          dqds=0.d0
          dqds2=0.d0
          do i=1,3
            do j=1,3
              if (i.eq.j) then
                dqds2(i,j)=1.d0
              else
                dqds2(i,j)=-0.5d0
              endif
            enddo
          enddo
          do i=4,6
            dqds2(i,i)=3.d0
          enddo
        endif

        return
      end
      
C!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
C       Interpolation pb
C!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      subroutine fpb(pb,dpb,dens,mpconloc,qy,densmax)
        implicit none
        real*8 :: pb,dpb, dens,qy,a,b,c,d
        real*8 :: mpconloc(800)
        integer k,densmax
       
        if (dens .lt. mpconloc(2))then
          a=0.d0
          b=mpconloc(1)
          c=mpconloc(2)
          d=mpconloc(1)
        elseif (dens .gt. mpconloc(densmax))then
          a=mpconloc(densmax-2)
          b=mpconloc(densmax-3)
          c=mpconloc(densmax)
          d=mpconloc(densmax-1)
        else
          do k=1,400
            if ((dens-mpconloc(2*k+2))*(dens-mpconloc(2*k))
     1         .le. 0.d0 ) then
              a=mpconloc(2*k)
              b=mpconloc(2*k-1)
              c=mpconloc(2*k+2)
              d=mpconloc(2*k+1)
              exit
            endif
          enddo
        endif

        dpb = (d-b)/(c-a)*qy
        pb = b*qy+dpb*(dens-a)

        return
      end subroutine
      
C!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
C       Calculate the cohesion stress of Drucke Prager mdoel
C!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      subroutine fcoh(d,dd,dens,elconloc,qy,mpconloc,densmax)
        implicit none
        integer densmax
        real*8 elconloc(21),mpconloc(800),d0,d,dd,dens,denst,qy
        
        denst = elconloc(6)
        d0 = elconloc(5)

        if (dens .lt. denst) then
          d = d0*qy
          dd = 0.d0
        elseif (dens.ge.mpconloc(densmax)) then
          d=((mpconloc(densmax)-denst)/(1.d0-denst))*(qy-d0*qy)+d0*qy
          dd=0.d0
        else
          d = ((dens-denst)/(1.d0-denst))*(qy-d0*qy)+d0*qy
          dd = (qy-d0*qy)/(1.d0-denst)
        end if
          
!          d = d0*qy
!          dd = 0.d0

        return
      end subroutine
      
C!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
C       Calculate the Young's modulus
C!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      subroutine fyoung(ee,de,dens,elconloc)
        implicit none
        real*8 :: ee,de,dens,elconloc(21),a,b,c,d,e
        a = elconloc(1)
c     c, d and e are from Qu Zongjhong (瞿宗宏), Liu Jiantao (刘建涛), Zhang
c     Guoxing (张国星), et al. Ansactions of Materialsand Heat Treatment
c     [J], 2017, 38: 173
        c = 0.15d0
        d = 0.85d0
        e = 12.d0
        if (dens.lt.0.d0) then
          ee = a*c
          de = 0.d0
        elseif (dens.lt.1.d0) then
          ee = a*(c+d*dens**e)
          de=0.d0
!          de = a*(e*d*dens**(e-1.d0))
        else
          ee=a
          de=0.d0
        endif
        
        return
      end subroutine
      
C!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
C       Calculate the Poisson ratio
C!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      subroutine fpoisson(v,dv,dens,elconloc)
        implicit none
        real*8 :: v,dv,dens,elconloc(21),a,b,c,d,e
        a = elconloc(2)
        c = 3.d0
        d = -2.d0
        e = 0.5d0
        
        if (dens.lt. 0.d0) then
          v = 0.d0 
          dv = 0.d0
        elseif (dens.lt. 1.d0) then
          v = a*(dens/(c+d*dens))**e
          dv=0.d0
!          dv = a*(dens/(c+dens*d))**(-1.d0+e)*
!     1      (-dens*d/(c+dens*d)**2.d0+1.d0/(c+dens*d))*e
        else
          v=a
          dv=0.d0
        endif
        
        return
      end subroutine
      
C!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
C       Elastic Matrix
C!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      subroutine elasticmatrix(dels,densels,dens,elconloc)
        integer i,j
        real*8 dels(6,6),densels(6,6),
     1    elconloc(21),dens,e,de,v,dv
        real*8,parameter :: zero=0.0d0,one=1.d0,two=2.d0,four=4.d0,
     1    half=0.5d0   
        
        call fyoung(e,de,dens,elconloc)
        call fpoisson(v,dv,dens,elconloc)

        do i = 1,6
          do j = 1,6
            dels(i,j) = zero
            densels(i,j) = zero
          end do 
        end do
        do i = 1, 3
          do j = 1, 3
            if (i .eq. j) then
              dels(i,j) = e*(one-v)/(one+v)/(one-two*v)
              densels(i,j)=((de*(one-v)+e*(-dv))*(one+v)*(one-two*v)-
     1          e*(one-v)*(-dv-four*v*dv))/((one+v)**two*(one-two*v)
     2          **two)
            else
              dels(i,j) = e*v/(one+v)/(one-two*v)
              densels(i,j)=((de*v+e*dv)*(one+v)*(one-two*v)-e*v*
     1          (-dv-four*v*dv))/((one+v)**two*(one-two*v)**two)
            end if
          end do 
        end do
        do i = 4, 6
          dels(i,i) = e/(one+v)/2.d0
          densels(i,i)=(de*(one+v)-e*dv)/((one+v)**two)/two
        end do 
        
        return
      end subroutine

C!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
C       Comliance matrix
C!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      subroutine compliance(cels,denscels,dens,elconloc)

        integer i,j
        real*8 cels(6,6),denscels(6,6),
     1      elconloc(21),dens,temp,e,de,te,v,dv,tv
        
        call fyoung(e,de,dens,elconloc)
        call fpoisson(v,dv,dens,elconloc)

        do i = 1, 6
          do j = 1, 6
            cels(i,j) = 0.d0
            denscels(i,j) = 0.d0
          end do 
        end do
        do i = 1, 3
          do j = 1, 3
            if (i .eq. j) then
              cels(i,j) = 1.d0/e
              denscels(i,j)=-de/e**2.d0
            else
              cels(i,j) = -v/e
              denscels(i,j)=v*de/e**2.d0-dv/e
            end if
          end do 
        end do
        do i = 4, 6
          cels(i,i) = 2.d0*(1.d0+v)/e
          denscels(i,i)=-2.d0*(1.d0+v)*de/e**2.d0+2.d0*dv/e
        end do

        return
      end subroutine     

C!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
C       yield fun: 1 cap surface; 
c                  2 transition surface;
c                  3 drucker-prager surface;
c                  4 smooth surface on the tip of drucker prager surface
C!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
c yield funcion
      subroutine yieldfun(f,dfds,dfdd,dfds2,s,dens,
     1    elconloc,qy,mpconloc,densmax,yflag,y,qa)
        implicit none
        integer i,densmax,yflag
        real*8 f,dfds(6,1),dfdd,dfds2(6,6),s(6,1),dens,
     1         elconloc(21),qy,mpconloc(800),qa
        real*8 tanb0,r0,dens0,pb0,d0,pa0,py,pb,dpb,d,dd,tanb,dtanb,
     1    pa,dpa,r,dr,beta,dbeta,sinb,dsinb,cosb,dcosb,x(2),y(2),
     2    par(4,2),p,q
        real*8, parameter :: pi=3.14159265359d0,alpha=0.02d0
        real*8, external :: pressure, mises


        p = pressure(s)
        q = mises(s)
        tanb0 = tan(elconloc(3)/180.d0*pi)
        r0 = elconloc(4)
        dens0 = elconloc(7)
        call fpb(pb0,dpb,dens0,mpconloc,qy,densmax)
        call fcoh(d0,dd,dens0,elconloc,qy,mpconloc,densmax)
        py = (qy-d0)/tanb0
        pa0 = (pb0-r0*d0)/(1.d0+r0*tanb0)

        call fpb(pb,dpb,dens,mpconloc,qy,densmax)
        call fcoh(d,dd,dens,elconloc,qy,mpconloc,densmax)
        tanb = (qy-d)/py
        dtanb = -dd/py
        pa=pa0*pb*py/(pa0*pb+pb0*py-pa0*pb0)
        dpa=(pa0*pb0*py*(py-pa0)*dpb)/((pa0*pb+pb0*py-pa0*pb0)**2.d0)
        r = (pb-pa)/(pa*tanb+d)
        dr = ((dpb-dpa)*(pa*tanb+d)-(pb-pa)*(dpa*tanb+pa*dtanb+dd))
     1      /((pa*tanb+d)**2.d0)
        beta=atan(tanb)
        dbeta=-dd/py/(1.d0+tanb**2.d0) 
        sinb=sin(beta)
        cosb=cos(beta)
        dsinb=cosb*dbeta
        dcosb=-sinb*dbeta

        x(1)=pa
        y(1)=(d+pa*tanb)*(1.d0-alpha/cosb)
        x(2)=d/tanb*(alpha-1.d0)
        y(2)=0.d0
        
        qa=y(1)+alpha*(d+pa*tanb)

        if (yflag.eq.1) then
c yield in the cap
          yflag=1
          par(1,1)=pa
          par(2,1)=0.d0
          par(3,1)=r/(1+alpha-alpha/cosb)
          par(4,1)=r*(d+pa*tanb)
          par(1,2)=dpa
          par(2,2)=0.d0
          par(3,2)=(dr*(1+alpha-alpha/cosb)-r*alpha*dcosb/cosb**2.d0)/
     1             (1+alpha-alpha/cosb)**2.d0
          par(4,2)=dr*(d+pa*tanb)+r*(dd+dpa*tanb+pa*dtanb)
          call yieldcap(f,dfds,dfdd,dfds2,s,par)
  
        elseif (yflag.eq.2) then
c yield in the transition 
          yflag=2
          par(1,1)=x(1)
          par(2,1)=y(1)
          par(3,1)=1.d0
          par(4,1)=alpha*(d+pa*tanb)
          par(1,2)=dpa
          par(2,2)=-alpha*dcosb*(d+pa*tanb)/cosb**2.d0
     1             +(1-alpha/cosb)*(dd+dpa*tanb+pa*tanb)
          par(3,2)=0.d0
          par(4,2)=alpha*(dd+dpa*tanb+pa*dtanb)
          call yieldcap(f,dfds,dfdd,dfds2,s,par)
  
        elseif (yflag.eq.3) then
c yield in drucker-prager
          yflag=3
          call yielddp(f,dfds,dfdd,dfds2,s,tanb,dtanb,d,dd)

        elseif (yflag.eq.4) then
c yield in the point of drucker-preger
          yflag=4
          par(1,1)=x(2)
          par(2,1)=y(2)
          par(3,1)=1.d0
          par(4,1)=alpha*d*cosb
          par(1,2)=(alpha-1.d0)*(dd*tanb-d*dtanb)/(tanb**2.d0)
          par(2,2)=0.d0
          par(3,2)=0.d0
          par(4,2)=alpha*(dd*cosb+d*dcosb)
          call yieldcap(f,dfds,dfdd,dfds2,s,par)
        else
          if (p.gt.pa) then
c yield in the cap
            yflag=1
            par(1,1)=pa
            par(2,1)=0.d0
            par(3,1)=r/(1+alpha-alpha/cosb)
            par(4,1)=r*(d+pa*tanb)
            par(1,2)=dpa
            par(2,2)=0.d0
            par(3,2)=(dr*(1+alpha-alpha/cosb)-r*alpha*dcosb/cosb**2.d0)/
     1               (1+alpha-alpha/cosb)**2.d0
            par(4,2)=dr*(d+pa*tanb)+r*(dd+dpa*tanb+pa*dtanb)
            call yieldcap(f,dfds,dfdd,dfds2,s,par)
  
          elseif ((q-y(1))+(p-x(1))/tanb.gt.0.d0) then
c yield in the transition 
            yflag=2
            par(1,1)=x(1)
            par(2,1)=y(1)
            par(3,1)=1.d0
            par(4,1)=alpha*(d+pa*tanb)
            par(1,2)=dpa
            par(2,2)=-alpha*dcosb*(d+pa*tanb)/cosb**2.d0
     1               +(1-alpha/cosb)*(dd+dpa*tanb+pa*tanb)
            par(3,2)=0.d0
            par(4,2)=alpha*(dd+dpa*tanb+pa*dtanb)
            call yieldcap(f,dfds,dfdd,dfds2,s,par)
  
          elseif ((q-y(2))+(p-x(2))/tanb.gt.0.d0) then
c yield in drucker-prager
            yflag=3
            call yielddp(f,dfds,dfdd,dfds2,s,tanb,dtanb,d,dd)

          else
c yield in the point of drucker-preger
            yflag=4
            par(1,1)=x(2)
            par(2,1)=y(2)
            par(3,1)=1.d0
            par(4,1)=alpha*d*cosb
            par(1,2)=(alpha-1.d0)*(dd*tanb-d*dtanb)/(tanb**2.d0)
            par(2,2)=0.d0
            par(3,2)=0.d0
            par(4,2)=alpha*(dd*cosb+d*dcosb)
            call yieldcap(f,dfds,dfdd,dfds2,s,par)
          endif
        endif

        return
      end subroutine

C!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
C       Gradient and Hessian Matrix of Drucker-Prager criteria
C!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      subroutine yielddp(f,dfds,dfdd,dfds2,s,tanb,dtanb,d,dd)
        implicit none
        real*8 f,dfds(6,1),dfdd,dfds2(6,6),s(6,1),tanb,dtanb,d,dd,
     1    dpds(6,1),dpds2(6,6),dqds(6,1),dqds2(6,6),p,q
        real*8, external :: pressure, mises

        p=pressure(s)
        q=mises(s)
        call dmises(dqds,dqds2,s)
        call dpressure(dpds,dpds2,s)
        
        f=q-p*tanb-d

        dfds=dqds-dpds*tanb

        dfdd=-p*dtanb-dd
        
        dfds2=dqds2-dpds2*tanb

        return
      end subroutine

C!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
C       Gradient and Hessian Matrix of Cap/Transition/Smooth criteria
C!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      subroutine yieldcap(f,dfds,dfdd,dfds2,s,par)
        implicit none
        real*8 f,dfds(6,1),dfdd,dfds2(6,6),s(6,1),par(4,2),
     1    dpds(6,1),dpds2(6,6),dqds(6,1),dqds2(6,6),g,p,q
        real*8, external :: pressure, mises
        integer i,j
        
        p=pressure(s)
        q=mises(s)
        call dmises(dqds,dqds2,s)
        call dpressure(dpds,dpds2,s)

        g=sqrt((p-par(1,1))**2.d0+par(3,1)**2.d0*(q-par(2,1))**2.d0)
        f=g-par(4,1)
        
        dfds=0.5d0/g*(2.d0*(p-par(1,1))*dpds+
     1       2.d0*par(3,1)**2.d0*(q-par(2,1))*dqds)

        dfdd=0.5d0/g*(2.d0*(p-par(1,1))*(-par(1,2))+
     1       2.d0*par(3,1)*par(3,2)*(q-par(2,1))**2.d0+
     2       2.d0*par(3,1)**2.d0*(q-par(2,1))*(-par(2,2)))-
     3       par(4,2)
        
        do i=1,6
          do j=1,6
            if (q.gt.1.d-6) then
              dfds2(i,j)=-1.d0/g*dfds(i,1)*dfds(j,1)+0.5d0/g*(
     1                 2.d0*dpds(i,1)*dpds(j,1)+
     2                 2.d0*(p-par(1,1))*dpds2(i,j)+
     3                 2*par(3,1)**2.d0*dqds(i,1)*dqds(j,1)+
     4                 2*par(3,1)**2.d0*(q-par(2,1))*dqds2(i,j))
            else
              dfds2(i,j)=-1.d0/g*dfds(i,1)*dfds(j,1)+0.5d0/g*(
     1                 2.d0*dpds(i,1)*dpds(j,1)+
     2                 2.d0*(p-par(1,1))*dpds2(i,j)+
     3                 2*par(3,1)**2.d0*dqds(i,1)*dqds(j,1)+
     4                 2*par(3,1)**2.d0*dqds2(i,j))
            endif
          enddo
        enddo

        return
      end subroutine


