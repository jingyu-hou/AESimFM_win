
C     WeICME (Wedge Integrated Computational Materials Engineering)
C                 - A 3-dimensional finite element program.
C     
C     Developed and maintained by Shenzhen Wedge Central 
C     South Research Institute co., Ltd., Shenzhen, China
C     
C     Copy Right 2019-2023.
C
      subroutine drx_hip_weicme(epsilon_eff,epsilon_rate,t,dtime,statev,
     1   nstatv,kinc)
      implicit none
      integer nstatv,kinc
      real*8 epsilon_eff,epsilon_rate,t,dtime,x_drex,d_drex,d_ave,
     1  dd_drex,dx_drex,statev(nstatv),x_drex_old
      real*8 epsilon_05,epsilon_c,epsilon_p,epsilon_vir,
     1  epsilon_0,z,d0
      real*8 a1,n1,a2,n2,a3,n3,q,ad,md,qd,nd
      real*8, parameter :: r=8.314d0
      real*8, external :: drx_hip_size
c dynamic recrystallizaion 

      a1=1.89d-4
      n1=0.0892d0
      a2=2.78d-4
      n2=0.10232d0
      a3=-0.693d0
      n3=2.6305d0
      q=867203d0
      ad=1.3961d4
      md=-0.489d0
      qd=106226d0
      nd=1.408d0
      d0=36.d0
      
      if (kinc.eq.1) then
        x_drex=0.d0
        d_drex=0.d0
      else
        x_drex=statev(12)
        d_drex=statev(13)
      endif
      
      z=max(epsilon_rate*dexp(q/r/t),1.d-10)
      epsilon_c=a1*z**n1
      epsilon_05=a2*z**n2

c recrystallization ratio
      epsilon_vir=(epsilon_05-epsilon_c)*(dlog(1.d0-x_drex)/a3)
     1  **(1.d0/n3)+epsilon_c
      if (epsilon_eff.le.epsilon_c) then
        dx_drex=0.d0
      else
        dx_drex=-(1.d0-x_drex)*a3*n3*((epsilon_eff-epsilon_c)/
     1    (epsilon_05-epsilon_c))**(n3-1.d0)/(epsilon_05-epsilon_c)*
     2    epsilon_rate*dtime
      endif
      x_drex_old=x_drex
      x_drex=x_drex+dx_drex

c recrtallization grain size
      epsilon_vir=(d_drex/(ad*epsilon_rate**md*dexp(-qd/r/t)))
     1  **(1.d0/nd)
      epsilon_0=(d0/(ad*epsilon_rate**md*dexp(-qd/r/t)))
     1  **(1.d0/nd)
      if (x_drex.eq.0.d0)then
        d_drex=0.d0
      elseif (x_drex_old.eq.0.d0)then
        d_drex=drx_hip_size(ad,md,qd,nd,epsilon_eff,epsilon_rate,t)
        if (d_drex.gt.d0)then
          d_drex=d0
        endif
      endif
      if ((x_drex.eq.0.d0).or.(epsilon_rate.eq.0.d0)) then
        dd_drex=0.d0
      else
        dd_drex=ad*epsilon_rate**md*dexp(-qd/r/t)*epsilon_eff**(nd-1.d0)
     1    *nd*epsilon_rate*dtime
      endif
      d_drex=d_drex+dd_drex

c averer grain size        
      d_ave=d0*(1.d0-x_drex)+d_drex*x_drex
      
      statev(12)=x_drex
      statev(13)=d_drex
      statev(14)=d_ave

      return
      end


      function drx_hip_size(a,m,q,n,ep,epr,t)
        implicit none
        real*8 drx_hip_size,a,m,q,n,ep,epr,t

        drx_hip_size=a*epr**m*exp(-q/8.314d0/t)*ep**n
      end

