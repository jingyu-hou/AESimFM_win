      
C     WeICME (Wedge Integrated Computational Materials Engineering)
C                 - A 3-dimensional finite element program.
C     
C     Developed and maintained by Shenzhen Wedge Central 
C     South Research Institute co., Ltd., Shenzhen, China
C     
C     Copy Right 2019-2023.
C

      subroutine drx(epsilon_eff,epsilon_rate,deqpl,t,dtime,statev,
     1   nstatv,kinc,gsloc)
      implicit none
C the same average methode used in DeFORM      
      integer nstatv,kinc
      real*8 epsilon_eff,epsilon_rate,t,dtime,x_drx,d_drx,d_ave,
     1  dd_drx,dx_drx,statev(nstatv),x_drx_old,gsloc(30,5),deqpl
      real*8 epsilon05,d_epsilon05,epsilon_c,epsilon_p,epsilon_old,
     1  epsilon_0,t_ave,rate_ave
      real*8 a1,n1,m1,q1,c1,a2,n2,a5,h5,n5,m5,q5,c5,beta_d,k_d,a10,
     1  a8,h8,n8,m8,q8,c8,d0
      real*8, parameter :: r=8.314d0

      
      real*8 :: rate_ave0


      a1    =gsloc( 1,1)
      n1    =gsloc( 2,1)
      m1    =gsloc( 3,1)
      q1    =gsloc( 4,1)
      c1    =gsloc( 5,1)
      a2    =gsloc( 6,1)
      n2    =gsloc( 7,1)
      d0    =gsloc( 8,1)
      a5    =gsloc( 9,1)
      h5    =gsloc(10,1)
      n5    =gsloc(11,1)
      m5    =gsloc(12,1)
      q5    =gsloc(13,1)
      c5    =gsloc(14,1)
      a10   =gsloc(15,1)
      beta_d=gsloc(16,1)
      k_d   =gsloc(17,1)
      a8    =gsloc(18,1)
      h8    =gsloc(19,1)
      n8    =gsloc(20,1)
      m8    =gsloc(21,1)
      q8    =gsloc(22,1)
      c8    =gsloc(23,1)
      
      x_drx=statev(11)
      d_drx=statev(12)
      t_ave=statev(14)+273.d0
      rate_ave=statev(15)
      
      t_ave=(t_ave*(epsilon_eff-deqpl)+t*deqpl)/epsilon_eff

      rate_ave0 = rate_ave

      rate_ave=(rate_ave*(epsilon_eff-deqpl)+epsilon_rate*deqpl)
     &    /epsilon_eff
cc      t_ave=(t_ave*(epsilon_eff-epsilon_rate*dtime)+
cc     1  t*epsilon_rate*dtime)/epsilon_eff
cc      
cc      rate_ave=(rate_ave*(epsilon_eff-epsilon_rate*dtime)+
cc     1  epsilon_rate**2.d0*dtime)/epsilon_eff
     

      if ( rate_ave .lt. 0.D0 ) rate_ave = 0.D0
 
      epsilon_p=a1*d0**n1*rate_ave**m1*dexp(q1/r/t_ave)+c1
      epsilon_c=a2*epsilon_p
      epsilon05=a5*d0**h5*epsilon_eff**n5*rate_ave**m5*
     1  dexp(q5/r/t_ave)+c5

c drx fraction

      x_drx=1.d0-dexp(-beta_d*((epsilon_eff-a10*epsilon_p)/epsilon05)
     1    **k_d)
      if (x_drx .lt. 0.d0) then
        x_drx=0.d0
      endif

      if ( isnan(x_drx) ) then
         write ( 0, * ) "NAN in drx.f"
         write ( 0, * ) t_ave, rate_ave, rate_ave0, epsilon_p, epsilon05
         write ( 0, * ) a1, d0, n1, m1, q1, r, t_ave, c1
         write ( 0, * )
      end if


c drx grain size
      d_drx=a8*d0**h8*epsilon_eff**n8*rate_ave**m8*
     1  dexp(q8/8.314/t_ave)+c8
      if (x_drx .eq. 0.d0) then
        d_drx=0.d0 
      elseif (d_drx .gt. d0) then
        d_drx=d0
      endif

c average grain size        :
      d_ave=d0*(1.d0-x_drx)+d_drx*x_drx
      
      statev(11)=x_drx
      statev(12)=d_drx
      statev(13)=d_ave
      statev(14)=t_ave-273.d0
      statev(15)=rate_ave

      return
      end

