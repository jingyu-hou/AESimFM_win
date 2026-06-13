C*****************************************************************
C                          计算孕育期
C*****************************************************************
      SUBROUTINE Incubation_time(tt,FF,NCurve_Number,ts) 
        IMPLICIT NONE
        INTEGER NCurve_Number
        REAL*8  tt(NCurve_Number),FF(NCurve_Number)
        REAL*8  ts,ak,t_t
      
        ak=dlog(dlog(1.d0-FF(1))/dlog(1.d0-FF(2)))/
     &  dlog(dlog(1.d0-FF(1))/dlog(1.d0-FF(3)))
        t_t=tt(1)-dexp(1.d0/(1.d0-ak)*(dlog(tt(2))-ak*dlog(tt(3))))
        ts=tt(1)-dexp(1.d0/(1.d0-ak)*(dlog(tt(2)-t_t)-ak*
     &   dlog(tt(3)-t_t)))

      RETURN
      END
      
C*****************************************************************
C               计算CCT曲线转为TTT曲线的等温相变时间
C*****************************************************************
      SUBROUTINE Incubation_time2(CCTCurve_Equivalenttime,holding_temp,
     &Curave_Data,N1,ts)
        IMPLICIT NONE
        REAL*8 Curave_Data(N1),CCTCurve_Equivalenttime(N1)
        REAL*8 ts,TempMax,TempMin,holding_temp
        INTEGER N1,II,JJ

        DO II=1,N1-1,1
          JJ=II+1
          TempMax=max(Curave_Data(II),Curave_Data(JJ))
          TempMin=min(Curave_Data(II),Curave_Data(JJ))
          IF(holding_temp.Le.TempMax.and.holding_temp.ge.TempMin)THEN
          CALL Proportional(Curave_Data(II),CCTCurve_Equivalenttime(II),
     &Curave_Data(JJ),CCTCurve_Equivalenttime(JJ),holding_temp,ts)
          ENDIF
       ENDDO

      RETURN
      END
      
C*****************************************************************
C                     考虑孕育期相变计算 
C*****************************************************************
      SUBROUTINE ip(NTTTCCT_Type,Whether_CCTIsothermal,tt,FF,
     &NCurve_Number,F,ts,Curave_Data,t,holding_time,holding_temp,
     &NTTCT_Point,V_Rate,N1,N2,N3,ef,peq)
        IMPLICIT NONE
        INTEGER NTTTCCT_Type,NCurve_Number,Nmax,Nmin,N1,II,
     &          Whether_CCTIsothermal,N2,N3,peq
        INTEGER NTTCT_Point(NCurve_Number)
        REAL*8 tt(NCurve_Number),FF(NCurve_Number),
     &         V_Rate(NCurve_Number),V_Temp(2),Curave_Data(N1,2),
     &         Curave_Data2(N1,2),f(N3)
        REAL*8 An,An1,An2,Vni,Vnj,b,ta,fa,tb,fb,t,holding_time,ts,
     &         holding_temp,ef,ef1

        Nmin=1
        Curave_Data2(1:N1,2)=Curave_Data(1:N1,1)
        Curave_Data2(1:N1,1)=Curave_Data(1:N1,2)
        IF(NCurve_Number.GE.3)THEN
           Nmax=3
        ELSE
          Nmax=2
        ENDIF

        ta=tt(Nmin)
        fa=FF(Nmin)
        tb=tt(Nmax)
        fb=FF(Nmax)

        IF(NTTTCCT_Type.eq.1.or.Whether_CCTIsothermal.eq.1)THEN
          An=dlog(dlog(1.d0-fa)/dlog(1.d0-fb))/dlog((ta-ts)/(tb-ts))
           b=-dlog(1.d0-fa)/(ta-ts)**An
        ELSE
          An1=dlog(dlog(1.d0-fa)/dlog(1.d0-fb))
          An2=(fa-1.d0)*dlog(1.d0-fa)/((fb-1.d0)*dlog(1.d0-fb))
          DO II=1,2
             CALL CurveData_Intersection
     &        (2,V_Rate(II),V_Temp,Curave_Data2,NTTCT_Point,N1)
          IF(II.eq.1)Vni=(fb-fa)/(V_Temp(2)-holding_temp)*V_Rate(II)
          IF(II.eq.2)Vnj=(fa-fb)/(V_Temp(1)-holding_temp)*V_Rate(II)
          ENDDO
      
          An=An1/dlog(An2*Vnj/Vni)
          b=-dlog(1.d0-fa)/((fa-1.d0)*dlog(1.d0-fa)/Vni*An)**An
         ENDIF
      
         holding_time=t+ts+(-dlog(1.d0-f(N2)/ef)/b)**(1.d0/An)
        ef1=1.d0-sum(f(2:N3))+f(N2)
C         f=1.d0-dexp(-b*(holding_time-ts)**An)
C        f(N2)=(1.d0-sum(f(2:N3)))*(an*b*(holding_time-ts)**(An-1.d0))*t
      if(peq.eq.1)then
        f(N2)=(ef-f(N2))*(an*b*(holding_time-ts)**(An-1.d0))*t*ef1
      else
        f(N2)=(ef1-f(N2))*(an*b*(holding_time-ts)**(An-1.d0))*t
      endif

      RETURN
      END 
      
C*****************************************************************
C                     不考虑孕育期相变计算 
C*****************************************************************
       SUBROUTINE rofip(NTTTCCT_Type,Whether_CCTIsothermal,tt,FF,
     &NCurve_Number,F,Curave_Data,t,holding_time,holding_temp,
     &NTTCT_Point, V_Rate,N1,N2,N3,ef,peq)
        IMPLICIT NONE

        INTEGER NTTTCCT_Type,NCurve_Number,Nmax,Nmin,N1,II,III1,
     &          Whether_CCTIsothermal,N2,N3,peq
        INTEGER NTTCT_Point(NCurve_Number)

        REAL*8 tt(NCurve_Number),FF(NCurve_Number),V_Rate(NCurve_Number)
     &      ,Curave_Data(N1,2),Curave_Data2(N1,2),V_Temp(2)
        REAL*8 An,b,ta,fa,tb,fb,f(N3),t,holding_time,holding_temp,AN1,
     &         An2,VNI,VNJ,ef,ef1
      
        Curave_Data2(1:N1,1)=Curave_Data(1:N1,2)
        Nmin=1
        ef1=0.d0
        Curave_Data2(1:N1,2)=Curave_Data(1:N1,1)
        Curave_Data2(1:N1,1)=Curave_Data(1:N1,2)
        IF(NCurve_Number.GE.3)THEN
           Nmax=3
        ELSE
           Nmax=2
        ENDIF
        ta=tt(Nmin)
        fa=FF(Nmin)
        tb=tt(Nmax)
        fb=FF(Nmax)

        IF(NTTTCCT_Type.eq.1.or.Whether_CCTIsothermal.eq.1)THEN
          An=dlog(dlog(1.d0-fa)/dlog(1.d0-fb))/dlog(ta/tb)
          b=-dlog(1.d0-fa)/ta**An
        ELSE
          An1=dlog(dlog(1.d0-fa)/dlog(1.d0-fb))
          An2=(fa-1.d0)*dlog(1.d0-fa)/((fb-1.d0)*dlog(1.d0-fb))
          DO II=1,2
            CALL CurveData_Intersection
     &      (2,V_Rate(II),V_Temp,Curave_Data2,NTTCT_Point,N1)
            IF(II.eq.1)Vni=(fb-fa)/(V_Temp(2)-holding_temp)*V_Rate(II)
            IF(II.eq.2)Vnj=(fa-fb)/(V_Temp(1)-holding_temp)*V_Rate(II)
          ENDDO
         An=An1/dlog(An2*Vnj/Vni)
         b=-dlog(1.d0-fa)/((fa-1.d0)*dlog(1.d0-fa)/Vni*An)**An
        ENDIF
C      holding_time=t+(-dlog(1.d0-f(N2)/ef(N2))/b)**(1.d0/An)
C      f(N2)=(ef(N2)-sum(f(2:N3)))*(an*b*holding_time
C     &          **(An-1.d0))*t

      holding_time=t+(-dlog(1.d0-f(N2)/ef)/b)**(1.d0/An)

      ef1=1.d0-sum(f(2:N3))+f(N2)

      if(peq.eq.1)then
        f(N2)=(ef-f(N2))*(an*b*holding_time
     &          **(An-1.d0))*t*ef1
      else
        f(N2)=(ef1-f(N2))*(an*b*holding_time
     &          **(An-1.d0))*t
      endif
      RETURN
      END
      
C*****************************************************************
C                  考虑母子相晶粒尺寸的相变计算 
C*****************************************************************
      SUBROUTINE Grainsize(NTTTCCT_Type,Whether_CCTIsothermal,tt,FF,
     &NCurve_Number,f,ts,Curave_Data,t,Dm,Dz,Cm,holding_time,
     &holding_temp,NTTCT_Point,V_Rate,N1,N2,N3,ef,peq) 
        IMPLICIT NONE

        INTEGER NTTTCCT_Type,NCurve_Number,Nmax,Nmin,N1,II,
     &          Whether_CCTIsothermal,N2,N3,peq
        INTEGER NTTCT_Point(NCurve_Number)

        REAL*8 tt(NCurve_Number),FF(NCurve_Number),V_Rate(NCurve_Number)
     &,Curave_Data(N1,2),holding_temp,Curave_Data2(N1,2),V_TEMP(2),f(N3)
        REAL*8 An,b,holding_time,Dm,Dz,Cm,ts,t,fa,fb,ta,tb,AN1,AN2,
     &   VNI,VNJ,ef,ef1
      
       Nmin=1
       Curave_Data2(1:N1,2)=Curave_Data(1:N1,1)
       Curave_Data2(1:N1,1)=Curave_Data(1:N1,2)

       IF(NCurve_Number.GE.3)THEN
          Nmax=3
       ELSE
          Nmax=2
       ENDIF
       ta=tt(Nmin)
       fa=FF(Nmin)
       tb=tt(Nmax)
       fb=FF(Nmax)

       IF(NTTTCCT_Type.eq.1.or.Whether_CCTIsothermal.eq.1)THEN
         An=dlog(dlog(1.d0-fa)/dlog(1.d0-fb))/dlog((ta-ts)/(tb-ts))
         b=-dlog(1.d0-fa)/(ta-ts)**An
       ELSE
         An1=dlog(dlog(1.d0-fa)/dlog(1.d0-fb))
         An2=(fa-1.d0)*dlog(1.d0-fa)/((fb-1.d0)*dlog(1.d0-fb))
         DO II=1,2
           CALL CurveData_Intersection
     &     (2,V_Rate(II),V_Temp,Curave_Data2,NTTCT_Point,N1)
         IF(II.eq.1)Vni=(fb-fa)/(V_Temp(2)-holding_temp)*V_Rate(II)
         IF(II.eq.2)Vnj=(fa-fb)/(V_Temp(1)-holding_temp)*V_Rate(II)
         ENDDO
         An=An1/dlog(An2*Vnj/Vni)
         b=-dlog(1.d0-fa)/((fa-1.d0)*dlog(1.d0-fa)/Vni*An)**An
       ENDIF
      
       holding_time=t+ts+(-dlog(1.d0-f(N2)/ef)/(b*(Dm/Dz)**Cm))
     &  **(1.d0/An)
C       f=1.d0-dexp(-b*(Dm/Dz)**Cm*(holding_time-ts)**An)
       ef1=1.d0-sum(f(2:N3))+f(N2)

      if(peq.eq.1)then
       f(N2)=(ef-f(N2))*((Dm/Dz)**Cm*an*b*(holding_time-ts)
     &   **(An-1.d0))*t*ef1
      else
       f(N2)=(ef1-f(N2))*((Dm/Dz)**Cm*an*b*(holding_time-ts)
     &   **(An-1.d0))*t
      endif

      RETURN
      END
