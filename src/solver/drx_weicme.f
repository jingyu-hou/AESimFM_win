      
C     WeICME (Wedge Integrated Computational Materials Engineering)
C                 - A 3-dimensional finite element program.
C     
C     Developed and maintained by Shenzhen Wedge Central 
C     South Research Institute co., Ltd., Shenzhen, China
C     
C     Copy Right 2019-2023.
C

      subroutine drx_weicme(epsilon_eff,epsilon_rate,t,dtime,statev,
     1  nstatv,kinc)
c a integrateion method
      implicit none
      integer nstatv,kinc
      real*8 epsilon_eff,epsilon_rate,t,dtime,x_drx,d_drx,d_ave,
     1  dd_drx,dx_drx,statev(nstatv),x_drx_old
      real*8 epsilon05,d_epsilon05,epsilon_c,epsilon_p,epsilon_old,
     1  epsilon_0,t_ave,rate_ave
      real*8 a1,n1,m1,q1,c1,a2,n2,a5,h5,n5,m5,q5,c5,beta_d,k_d,a10,
     1  a8,h8,n8,m8,q8,c8,d0
      real*8, parameter :: r=8.314d0

      a1=0.004659d0
      n1=0.d0
      m1=0.1238d0
      q1=49520.d0
      c1=0.d0
      a2=0.83d0
      n2=0.d0
      d0=50.d0
      a5=5.043d-9
      h5=0.d0
      n5=-1.42d0
      m5=-0.408d0
      q5=196000.d0
      c5=0.d0
      a10=0.8d0
      beta_d=0.693d0
      k_d=1.d0
      a8=485.d8
      h8=0.d0
      n8=-0.41d0
      m8=-0.028d0
      q8=-24.d4
      c8=0.d0
      
      if (kinc.eq.1) then
        x_drx=0.d0
        d_drx=0.d0
        t_ave=t
        rate_ave=epsilon_rate
      else
        x_drx=statev(11)
        d_drx=statev(12)
        t_ave=statev(16)+273.d0
        rate_ave=statev(17)
      endif
      


      epsilon_old=epsilon_eff-epsilon_rate*dtime

c drx fraction
      epsilon_p=a1*d0**n1*epsilon_rate**m1*dexp(q1/r/t)+c1
      epsilon_c=a2*epsilon_p
      epsilon05=a5*d0**h5*epsilon_rate**m5*
     1  dexp(q5/r/t)+c5
      epsilon_0=(-dlog(1.d0-0.d0)/beta_d)**(1.d0/k_d)*epsilon05+
     1  a10*epsilon_p

      if (epsilon_eff.le.epsilon_0) then
        dx_drx=0.d0
      else
        dx_drx=(1.d0-x_drx)*((epsilon_old-a10*epsilon_p)/epsilon05)
     1    **(k_d-1.0d0)*beta_d*k_d/epsilon05*epsilon_rate*dtime
      endif

      x_drx_old=x_drx
      x_drx=x_drx+dx_drx

c drx grain size
      
      if (x_drx.eq.0.d0)then
        d_drx=0.d0
        dd_drx=0.d0
      else
        epsilon_0=((d0-c8)/(a8*d0**h8*epsilon_rate**m8*
     1    dexp(q8/r/t)))**(1.d0/n8)
        d_drx=a8*d0**h8*epsilon_eff**n8*rate_ave**m8*
     1    dexp(q8/8.314/t_ave)+c8

        if (d_drx.gt.d0)then
          d_drx=d0
          dd_drx=0.d0
        else
          if (epsilon_eff.lt.epsilon_0) then
            dd_drx=0.d0
          else
            dd_drx=a8*d0**h8*epsilon_rate**m8*dexp(q8/r/t)*n8*
     1        epsilon_old**(n8-1.0)*epsilon_rate*dtime
          endif 
        endif

      endif

      d_drx=d_drx+dd_drx

c average grain size        :
      d_ave=d0*(1.d0-x_drx)+d_drx*x_drx
      
      statev(11)=x_drx
      statev(12)=d_drx
      statev(13)=d_ave
      statev(16)=t_ave-273.d0
      statev(17)=rate_ave

      return
      end

