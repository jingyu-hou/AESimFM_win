!
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
!
C!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
C     plastic flow stress
C!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

c closest point method

      subroutine flowstress(stress,statev,ddsdde,sse,spd,scd,
     1 rpl,ddsddt,drplde,drpldt,stran,dstran,time,dtime,temp,
     2 dtemp,temp0,predef,dpred,cmname,ndi,nshr,ntens,nstatv,
     3 elconloc,plconloc,mpconloc,coords,drot,pnewdt,
     4 celent,dfgrd0,dfgrd1,noel,npt,layer,kspt,jstep,kinc,stressini)
c
      implicit none
c      include 'aba_param.inc'
c
      character*80 cmname
      integer :: ntens,nshr,ndi,nstatv, noel, npt, 
     1 layer, kspt, jstep(4), kinc,densmax
      real*8 :: sse,spd,scd,rpl,drpldt,dtime,temp,dtemp,temp0, 
     1 pnewdt,celent
      real*8  stress(6),statev(nstatv),stressini(6),
     1 ddsdde(6,6),ddsddt(6),drplde(6),
     2 stran(6),dstran(6),time(2),predef(1),dpred(1),
     3 coords(3),drot(3,3),dfgrd0(3,3),dfgrd1(3,3),
     4 elconloc(21),plconloc(802),mpconloc(800)
      real*8 s_ini(6,1),s(6,1),ds(6,1),ds2(6,1),dfdep,dfdeprt,
     1       f,dqds(6,1),dqds2(6,6),dfds(6,1),sigy,ep,ep_ini,eprt
      real*8 dstrain(6,1),hv(6,1),pe(6,1),pe_ini(6,1),ee(6,1)
      real*8 tp(1,1),tp6(6,1),output(100,3)
      real*8 dlamda,dlamda2,h,dels(6,6),cels(6,6)
      real*8 aftrot(3,3),befrot(3,3),z(6,1)
      real*8 b(7),a(7,7),resi(6,1),residual,e_rate,work(6)
      real*8 t_f,t_s(6,1),t_ds(6,1),t_dlamda,t_pe(6,1),y(2),m
      integer i,j,k,kk,vv(6+1),iflag,lda,ipiv(6),info
      real*8, parameter :: pi=3.14159265359d0,one=1.0d0,zero=0.0d0,
     1        two=2.0d0,four=4.0d0,half=0.5d0,tolerance=1.d-6
      real*8, external :: pressure, mises

c      elconloc(1): young's modulus
c      elconloc(2): poisson's reatio
c      elconloc(3): beta angle
c      elconloc(4): R
c      elconloc(5): d0
c      elconloc(6): d_th
c      elconloc(7): initial density
c      plconloc: plastic curve 
c      mpconloc: powder hardening curve
        
c input parameters and initial values
        
        do i = 1, 3
          do j = 1, 3
            befrot(i,j)=zero
          end do
        end do
        do i = 1, 3
          befrot(i,i)=statev(i+1)
        end do
        befrot(1,2)=statev(5)/two
        befrot(2,1)=statev(5)/two
        befrot(1,3)=statev(6)/two
        befrot(3,1)=statev(6)/two
        befrot(2,3)=statev(7)/two
        befrot(3,2)=statev(7)/two

        aftrot = matmul(drot,matmul(befrot,transpose(drot)))
        do i = 1, 3
          pe(i,1) = aftrot(i,i)
        end do
        pe(4,1) = aftrot(1,2)+aftrot(2,1)
        pe(6,1) = aftrot(2,3)+aftrot(3,2)
        pe(5,1) = aftrot(1,3)+aftrot(3,1)
        pe_ini=pe
        ep=statev(1)
        ep_ini=ep

        do i = 1, 6
          dstrain(i,1) = dstran(i)
        end do
        
        do i = 1, 3
          hv(i, 1) = -one
        end do
        do i = 4, 6
          hv(i, 1) = zero
        end do 
        
c trial stress
        call dmatrix(dels,elconloc)

        do i = 1, 6
          ee(i,1)=stran(i)-pe(i,1)
          s_ini(i,1)=stressini(i)
          s(i,1)=stressini(i)
        end do
        s_ini=s_ini+matmul(dels,ee)
        ee=ee+dstrain
        s=s+matmul(dels,ee)
        
        dlamda=0.d0
        eprt=dlamda/dtime
        call yield(f,dfds,dqds2,dfdep,dfdeprt,s,ep,eprt,temp,sigy)
        dqds=dfds
        

c stress update
        if (f .lt. sigy*tolerance) then
!        if (2.0d0 .gt. 1.0d0) then
          ddsdde = dels

        else
     
          call cmatrix(cels,elconloc)
          ds=s-s_ini

          resi=dstrain-matmul(cels,ds)-dlamda*dqds
          residual=0.d0
          do i=1,6
            residual=residual+resi(i,1)**2.d0
          enddo
          residual=sqrt(residual)

c return mapping
          k=1
          do while ((residual .gt. tolerance).or.(abs(f).gt.
     1       sigy*tolerance))
cc A matrix
            do i=1,6
              do j=1,6
                a(i,j)=cels(i,j)+dqds2(i,j)*dlamda
              enddo
              a(i,7)=dqds(i,1)
              a(7,i)=dfds(i,1)
            enddo
            a(7,7)=dfdep+dfdeprt/dtime
     
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
            
            m=1.d0
            t_f=f
            t_s=s
            t_ds=ds
            t_dlamda=dlamda
            t_pe=pe
            
!            if ((noel.eq.1).and.(npt.eq.1))then
!               open(3333,file="f.txt")
!               write(3333,*)k,m,f,f/sigy,dlamda
!            endif
            
            do while (dabs(f).ge.dabs(t_f))
              s=t_s+ds2*m
              ds=t_ds+ds2*m
              dlamda=t_dlamda+dlamda2*m
              pe=t_pe-matmul(cels,ds2*m)
              ep=ep_ini+dlamda
              
              call dmatrix(dels,elconloc)
              call cmatrix(cels,elconloc)
              
              do i=1,6
                ee(i,1)=stran(i)+dstran(i)-pe(i,1)
              enddo
              eprt=dlamda/dtime
              call yield(f,dfds,dqds2,dfdep,dfdeprt,s,ep,eprt,temp,
     1            sigy)
              dqds=dfds  

              
              m=m/2.d0
              if (m.lt.0.5d0**10)then
                exit
              endif
            enddo

            resi=dstrain-matmul(cels,ds)-dlamda*dqds
            residual=0.d0
            do i=1,6
              residual=residual+resi(i,1)**2.d0
            enddo
            residual=sqrt(residual)

            k=k+1

            if (k.gt.100) then
              pnewdt=0.7d0
              return
            endif
          enddo

c plastic stiffness matrix
          dels=cels+dlamda*dqds2
          call dgetrf(6,6,dels,6,ipiv,info)
          call dgetri(6,dels,6,ipiv,work,6,info)
          tp=matmul(transpose(dfds),matmul(dels,dqds))
          h=dfdep+tp(1,1)
          ddsdde=dels-matmul(dels,matmul(dqds,matmul(transpose(dfds),
     1      dels)))/h

        endif
!        ddsdde = matmul(olds,transpose(-hv))+ddsdde
        
c update variables
        
        do i = 1, 6
          stress(i) = s(i,1)
          statev(i+1) = pe(i,1)
        enddo 
        statev(1)=ep
        statev(8)=eprt

        statev(9)=pressure(s)
        statev(10)=mises(s)
        statev(11)=k
        statev(12)=m
        

      return
      end subroutine

C!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
C        Gradient and hessian matrix of mises stress
C!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      subroutine yield(f,dfds,dfds2,dfdep,dfdeprt,s,ep,eprt,temp,sigy)
        implicit none
        integer i,j,id,n
        real*8 dfds(6,1),dfds2(6,6),dfdep,s(6,1),q,f,sigy,dsigy,ep,
     1    eprt,temp,plconloc(802),x(400),y(400),dfdeprt,hard(3),
     2    props(4)
        real*8, external :: mises

        n=int(plconloc(801))
        
        hard=0.d0
        props(1)=0.00705d0
        props(2)=5.07092d35
        props(3)=990460d0
        props(4)=3.3934d0
        call uhard(sigy,hard,ep,eprt,temp,4,props)
        dfdep=hard(1)
        dfdeprt=hard(2)
        
        dfdep=0.d0
        dfdeprt=0.d0
        sigy=100.d6

        q=mises(s)

        f=q-sigy
       
        if (q.gt.1.d0) then
          dfds(1,1)=0.5d0/q*(s(1,1)*2.d0-s(2,1)-s(3,1))
          dfds(2,1)=0.5d0/q*(s(2,1)*2.d0-s(3,1)-s(1,1))
          dfds(3,1)=0.5d0/q*(s(3,1)*2.d0-s(1,1)-s(2,1))
          do i = 4, 6
            dfds(i,1)=3.d0/q*s(i,1)
          end do

          dfds2(1,1)=1.d0/q-0.25d0*(s(1,1)*2.d0-s(2,1)-s(3,1))**2/
     1               q**3.d0
          dfds2(2,2)=1.d0/q-0.25d0*(s(2,1)*2.d0-s(3,1)-s(1,1))**2/
     1               q**3.d0
          dfds2(3,3)=1.d0/q-0.25d0*(s(3,1)*2.d0-s(1,1)-s(2,1))**2/
     1               q**3.d0
          dfds2(1,2)=-0.25d0*(s(1,1)*2.d0-s(2,1)-s(3,1))*
     1      (s(2,1)*2.d0-s(3,1)-s(1,1))/q**3.d0-0.5d0/q
          dfds2(2,1)=dfds2(1,2)
          dfds2(1,3)=-0.25d0*(s(1,1)*2.d0-s(2,1)-s(3,1))*
     1      (s(3,1)*2.d0-s(1,1)-s(2,1))/q**3.d0-0.5d0/q
          dfds2(3,1)=dfds2(1,3)
          dfds2(2,3)=-0.25d0*(s(2,1)*2.d0-s(3,1)-s(1,1))*
     1      (s(3,1)*2.d0-s(1,1)-s(2,1))/q**3.d0-0.5d0/q
          dfds2(3,2)=dfds2(2,3)
          
          dfds2(1,4)=-1.5d0*s(4,1)*(s(1,1)*2.d0-s(2,1)-s(3,1))/q**3.d0
          dfds2(4,1)=dfds2(1,4)
          dfds2(1,5)=-1.5d0*s(5,1)*(s(1,1)*2.d0-s(2,1)-s(3,1))/q**3.d0
          dfds2(5,1)=dfds2(1,5)
          dfds2(1,6)=-1.5d0*s(6,1)*(s(1,1)*2.d0-s(2,1)-s(3,1))/q**3.d0
          dfds2(6,1)=dfds2(1,6)
          dfds2(2,4)=-1.5d0*s(4,1)*(s(2,1)*2.d0-s(3,1)-s(1,1))/q**3.d0
          dfds2(4,2)=dfds2(2,4)
          dfds2(2,5)=-1.5d0*s(5,1)*(s(2,1)*2.d0-s(3,1)-s(1,1))/q**3.d0
          dfds2(5,2)=dfds2(2,5)
          dfds2(2,6)=-1.5d0*s(6,1)*(s(2,1)*2.d0-s(3,1)-s(1,1))/q**3.d0
          dfds2(6,2)=dfds2(2,6)
          dfds2(3,4)=-1.5d0*s(4,1)*(s(3,1)*2.d0-s(1,1)-s(2,1))/q**3.d0
          dfds2(4,3)=dfds2(3,4)
          dfds2(3,5)=-1.5d0*s(5,1)*(s(3,1)*2.d0-s(1,1)-s(2,1))/q**3.d0
          dfds2(5,3)=dfds2(3,5)
          dfds2(3,6)=-1.5d0*s(6,1)*(s(3,1)*2.d0-s(1,1)-s(2,1))/q**3.d0
          dfds2(6,3)=dfds2(3,6)
          
          dfds2(4,4)=3.d0/q-9.d0*s(4,1)**2/q**3.d0
          dfds2(5,5)=3.d0/q-9.d0*s(5,1)**2/q**3.d0
          dfds2(6,6)=3.d0/q-9.d0*s(6,1)**2/q**3.d0
          dfds2(4,5)=-9.d0*s(4,1)*s(5,1)/q**3.d0
          dfds2(5,4)=dfds2(4,5)
          dfds2(4,6)=-9.d0*s(4,1)*s(6,1)/q**3.d0
          dfds2(6,4)=dfds2(4,6)
          dfds2(5,6)=-9.d0*s(5,1)*s(6,1)/q**3.d0
          dfds2(6,5)=dfds2(5,6)
        else
          dfds=0.d0
          dfds2=0.d0
          do i=1,3
            do j=1,3
              if (i.eq.j) then
                dfds2(i,j)=1.d0
              else
                dfds2(i,j)=-0.5d0
              endif
            enddo
          enddo
          do i=4,6
            dfds2(i,i)=3.d0
          enddo
        endif

        return
      end
      
C!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
C       Elastic Matrix
C!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      subroutine dmatrix(dels,elconloc)
        integer i,j
        real*8 dels(6,6),elconloc(21),e,v
        real*8,parameter :: zero=0.0d0,one=1.d0,two=2.d0,four=4.d0,
     1    half=0.5d0   
        
        e=elconloc(1)
        v=elconloc(2)

        do i = 1,6
          do j = 1,6
            dels(i,j) = zero
          end do 
        end do
        do i = 1, 3
          do j = 1, 3
            if (i .eq. j) then
              dels(i,j) = e*(one-v)/(one+v)/(one-two*v)
            else
              dels(i,j) = e*v/(one+v)/(one-two*v)
            end if
          end do 
        end do
        do i = 4, 6
          dels(i,i) = e/(one+v)/2.d0
        end do 
        
        return
      end subroutine

C!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
C       Comliance matrix
C!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      subroutine cmatrix(cels,elconloc)

        integer i,j
        real*8 cels(6,6),elconloc(21),e,v
        
        e=elconloc(1)
        v=elconloc(2)

        do i = 1, 6
          do j = 1, 6
            cels(i,j) = 0.d0
          end do 
        end do
        do i = 1, 3
          do j = 1, 3
            if (i .eq. j) then
              cels(i,j) = 1.d0/e
            else
              cels(i,j) = -v/e
            end if
          end do 
        end do
        do i = 4, 6
          cels(i,i) = 2.d0*(1.d0+v)/e
        end do

        return
      end subroutine     

