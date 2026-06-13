
      SUBROUTINE PhaseTransition(STATEV1,temp1,temp2,
     &time1,time2,NTTCT_Point,phaseequilibrium_point,
     &AIncubationtime_point,tempzbf_point,cphase,
     &phase_inf,nphase,pphase,phaseother,d,
     &phase_equilibrium)
        IMPLICIT NONE

        INTEGER phase_inf(4),nphase(11)

        INTEGER phaseequilibrium_point(phase_inf(1)),
     &          NTTCT_Point(phase_inf(2),phase_inf(1)),
     &          AIncubationtime_Point(phase_inf(1))

        INTEGER Whether_Cal_AIncubationtime,Whether_CCTIsothermal, 
     &          NTran_Type,NTTTCCT_Type,NSTATV1,NCurve_Number,
     &          III1,NN,N1,KK,KK2,IJK,IJK2,IJK3,imat

        REAl*8 STATEV1(phase_inf(1)),STATEV3(phase_inf(1)),
     &         TIME_T(phase_inf(2)),Residual,Phase,maxtemp,mintemp,
     &         phase_equilibrium(2*phase_inf(3),phase_inf(1)),
     &         AIncubation_time(phase_inf(3),2,phase_inf(1)),
     &         V_Rate(phase_inf(2)),
     &         CCTCurve_Equivalenttime(phase_inf(2)*phase_inf(3)),
     &         Curave_Data2(phase_inf(2)*phase_inf(3),2),
     &         Curave_Data(phase_inf(2)*phase_inf(3),2),
     &         tempzbf_point(phase_inf(4),phase_inf(1)),
     &         cphase(12+phase_inf(4),phase_inf(1)),
     &         pphase(2,phase_inf(3),7+phase_inf(4),phase_inf(1)),
     &         FF(phase_inf(2),phase_inf(1)),
     &         phaseother(15+phase_inf(1)*phase_inf(4))

        REAL*8 TIME1,TIME2,TEMP1,TEMP2,Dm,Dz,Cm,DTEMPMX,DTIMEMX,
     &         holding_temp,ts,TIMEINC,TEMPINC,DTEMP,DTIME,HOLDING_TIME,
     &         F_equilibrium,d,dA0,A1,N,Q,R

        LOGICAL Logi1,Logi2,Logi3

C        open(unit=10000,file='10000.dat')
        Residual=1.d-5
        DTEMPMX=0.1d0;DTIMEMX=5.d0
        NTran_Type=nphase(4)
        NCurve_Number=phase_inf(2)
        NSTATV1=phase_inf(1)
        Whether_Cal_AIncubationtime=nphase(7)
        NTTTCCT_Type=nphase(3)
        Whether_CCTIsothermal=nphase(8)
        FF(1:NCurve_Number,1:NSTATV1)=
     &               cphase(3:NCurve_Number+2,1:NSTATV1)


        Logi3=NTran_Type.ne.1.and.NCurve_Number.GE.3.and.
     &  Whether_Cal_AIncubationtime.eq.1.and.NTTTCCT_Type.eq.1.or.
     &  NTran_Type.ne.1.and.NCurve_Number.GE.3.and.
     &  Whether_Cal_AIncubationtime.eq.1.and.Whether_CCTIsothermal.eq.1
 
        if(nphase(9).eq.1)then
          dA0=phaseother(4)
           A1=phaseother(5)
            Q=phaseother(6)
            R=phaseother(7)
            N=phaseother(8)
        endif
              
        IF(Ntran_type.eq.3)THEN
           Dm=phaseother(1)
           Dz=phaseother(3)
           Cm=phaseother(2)
        ENDIF 

        IF(STATEV1(1).le.Residual)THEN
          RETURN
        ELSE

C***************************************************************************
C                       开始相变计算 
C***************************************************************************
          DO III1=2,NSTATV1
             IF(STATEV1(1).le.Residual)RETURN
               Logi1=FF(1,III1).lt.0.05d0.and.NTTTCCT_Type.eq.1.and.
     &         NTran_Type.ne.1
               Logi2=FF(1,III1).lt.0.05d0.and.NTTTCCT_Type.eq.2.and.
     &         NTran_Type.ne.1
               N1=sum(NTTCT_Point(1:NCurve_Number,III1))
             Do IJK=1,NCurve_Number
                KK2=NTTCT_Point(IJK,III1)
                Call FIRSTLAST_POINT(NTTCT_Point
     &           (1:NCurve_Number,III1),NCurve_Number,IJK2,IJK3,IJK)
                Curave_Data(IJK2:IJK3,1)=
     &             pphase(1,1:NTTCT_Point(IJK,III1),IJK,III1)
                Curave_Data(IJK2:IJK3,2)=
     &             pphase(2,1:NTTCT_Point(IJK,III1),IJK,III1)
C               write(10000,*)'第',iii1,'个相','第',ijk,'条曲线'
C               do iiii=ijk2,ijk3
C               write(10000,*)curave_data(iiii,1),curave_data(iiii,2)
C               enddo
             ENDDO
             maxtemp=maxval(Curave_Data(1:N1,2))!相变上限温度
             mintemp=minval(Curave_Data(1:N1,2))!相变下限温度
      
c               write(10000,*)'第',iii1,'个相'
c               write(10000,*)maxtemp,mintemp
C***************************************************************************
C                    以下几行用于CCT曲线转TTT曲线相变计算 
C***************************************************************************
             IF(NTTTCCT_Type.eq.2.and.Whether_CCTIsothermal.eq.1)THEN
               CALL Calculation_CCT_coolingrate(CCTCurve_Equivalenttime
     &        (1:N1),Curave_Data(1:N1,1:2),NTTCT_Point(:,III1),N1,
     &         NCurve_Number)

               Curave_Data2(1:N1,1)=CCTCurve_Equivalenttime(1:N1)
               Curave_Data2(1:N1,2)=Curave_Data(1:N1,2)
             ENDIF
C***************************************************************************
C                     以上几行用于CCT曲线转TTT曲线相变计算   
C***************************************************************************
             IF (maxtemp.Gt.MIN(TEMP1,TEMP2)
     &       .AND. mintemp .Lt.MAX(TEMP1,TEMP2))THEN
               IF (TEMP2 .LT. TEMP1) THEN
                 CALL KSTARTSTOPC (TEMP1,TEMP2,TIME1,TIME2,
     &           maxtemp,mintemp,holding_temp,DTEMP,DTIME)
               ELSE
                 CALL KSTARTSTOPH (TEMP1,TEMP2,TIME1,TIME2,
     &              mintemp,maxtemp,holding_temp,DTEMP,DTIME)
               ENDIF
      
               NN=1+MAX(INT(ABS(DTEMP)/DTEMPMX),INT(DTIME/DTIMEMX))
C               IF(NN.lt.5)NN=5
               TIMEINC=DTIME/NN   
               TEMPINC=DTEMP/NN   
      
C***************************************************************************
C                        开始连续降温多等分相变计算 
C***************************************************************************
                DO KK=1,NN,1
                 IF(STATEV1(1).Le.Residual)RETURN
                 holding_temp=holding_temp+TEMPINC
                 ts=0.d0
C***************************************************************************
C                以下几行用于计算当前温度下与TTT曲线的交点 
C***************************************************************************
                IF(NTTTCCT_Type.eq.1)THEN
                 CALL CurveData_Intersection
     &            (NCurve_Number,holding_temp,TIME_T,
     &            Curave_Data(1:N1,1:2),
     &            NTTCT_Point(1:NCurve_Number,III1),N1)
                ELSEIF(Whether_CCTIsothermal.eq.1)then
                    CALL CurveData_Intersection 
     &              (NCurve_Number,holding_temp,TIME_T,
     &               Curave_Data2(1:N1,1:2),
     &               NTTCT_Point(1:NCurve_Number,III1),N1)
                 ELSE
                   CALL CurveData_Intersection
     &              (NCurve_Number,holding_temp,V_Rate,
     &                Curave_Data(1:N1,1:2),
     &                NTTCT_Point(1:NCurve_Number,III1),N1)
                 ENDIF
C***************************************************************************
C                以上几行用于计算当前温度下与TTT曲线的交点 
C***************************************************************************
      
C***************************************************************************
C                          开始孕育期计算 
C***************************************************************************
                IF(Logi3)THEN
                  CALL Incubation_time(TIME_T,FF(1:NCurve_Number,III1)
     &            , NCurve_Number,ts) 
      
                ELSEIF(NTran_Type.ne.1.and.Whether_Cal_AIncubationtime
     &           .ne.1)then
                  CALL IsothermalCurve_Intersection(minval(
     &            AIncubation_time(1:AIncubationtime_Point(III1),
     &            1,III1)),
     &            maxval(AIncubation_time(1:AIncubationtime_Point
     &            (III1),1,III1
     &            )),AIncubation_time(1:AIncubationtime_Point
     &            (III1),1,III1),
     &            AIncubation_time(1:AIncubationtime_Point(III1),2,
     &            III1),
     &            AIncubationtime_Point(III1),holding_temp,ts,1)
                ENDIF
C!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
C                 采用体积分数小于5%的曲线所对应的相变时间为孕育期
C!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                IF(Logi1.and.ts.le.0.d0.or.Logi1.and.ts.gt.
     &           TIME_T(1))THEN
                    ts=TIME_T(1)  
                ELSEIF (Logi2.and.(ts.le.0.d0.or.
     &           (Whether_CCTIsothermal.eq.1.and.ts.gt.TIME_T(1))))THEN
                   IF(Whether_CCTIsothermal.eq.1)THEN
                     CALL Incubation_time2(CCTCurve_Equivalenttime
     &               (1:NTTCT_Point(1,III1)),holding_temp,
     &               Curave_Data2(1:NTTCT_Point(1,III1),2),
     &               NTTCT_Point(1,III1),ts)
                   ELSE
                     ts=TIMEINC
                   ENDIF
                 ENDIF
                 IF(NTran_Type.ne.1.and.ts.le.Residual)ts=TIMEINC

C***************************************************************************
C                          孕育期计算结束 
C***************************************************************************
      
                IF(NTran_Type.ne.1)
     &             STATEV3(III1)=STATEV3(III1)+TIMEINC/ts
      
                   Phase=STATEV1(III1)
C***************************************************************************
C                          开始相平衡计算 
C***************************************************************************
                if(nphase(10).eq.1)then
                  CALL IsothermalCurve_Intersection(
     &             minval(phase_equilibrium
     &             (1:phaseequilibrium_point(III1),III1))
     &            ,maxval(phase_equilibrium
     &             (1:phaseequilibrium_point(III1),III1)
     &             ),phase_equilibrium
     &             (1:phaseequilibrium_point(III1),III1),
     &             phase_equilibrium(phaseequilibrium_point(III1)+1:2*
     &             phaseequilibrium_point(III1),III1),
     &             phaseequilibrium_point(III1),holding_temp,
     &             F_equilibrium,2)
                else
                    F_equilibrium=1.d0
                endif
C***************************************************************************
C                           相平衡计算结束 
C***************************************************************************
                IF(STATEV1(III1).lt.F_equilibrium)then
                   SELECT CASE(NTran_Type)
                   CASE(1)
                       CALL rofip(NTTTCCT_Type,Whether_CCTIsothermal,
     &                  TIME_T,FF(1:NCurve_Number,III1),
     &                  NCurve_Number,STATEV1(1:NSTATV1),
     &                  Curave_Data(1:N1,1:2),TIMEINC,holding_time,
     &                  holding_temp,NTTCT_Point(1:NCurve_Number,III1),
     &                 V_Rate,N1,III1,NSTATV1,F_equilibrium,nphase(10))
                       if(nphase(9).eq.1)
     &                   d=(dA0**N+A1*holding_time*
     &                     dexp(-Q/R/holding_temp))**(1.d0/N)
                   CASE(2)
                       IF(STATEV3(III1).ge.1.d0)THEN
                         CALL ip(NTTTCCT_Type,Whether_CCTIsothermal,
     &                    TIME_T,FF(1:NCurve_Number,III1),
     &                    NCurve_Number,STATEV1(1:NSTATV1),ts,
     &                    Curave_Data(1:N1,1:2),TIMEINC,holding_time,
     &                    holding_temp,NTTCT_Point(1:NCurve_Number,III1)
     &                 ,V_Rate,N1,III1,NSTATV1,F_equilibrium,nphase(10))
                         if(nphase(9).eq.1)
     &                     d=(dA0**N+A1*holding_time*
     &                       dexp(-Q/R/holding_temp))**(1.d0/N)
                       ENDIF 
                   CASE(3)
                        IF(STATEV3(III1).ge.1.d0)THEN
                      CALL Grainsize(NTTTCCT_Type,Whether_CCTIsothermal,
     &                    TIME_T,FF(1:NCurve_Number,III1),NCurve_Number,
     &                    STATEV1(1:NSTATV1),ts,Curave_Data(1:N1,1:2),
     &                    TIMEINC,Dm,Dz,Cm,holding_time,holding_temp,
     &                    NTTCT_Point(1:NCurve_Number,III1),V_Rate,N1,
     &                     III1,NSTATV1,F_equilibrium,nphase(10))
                         if(nphase(9).eq.1)
     &                     d=(dA0**N+A1*holding_time*
     &                       dexp(-Q/R/holding_temp))**(1.d0/N)
                      ENDIF
                   END SELECT
                    STATEV1(1)=STATEV1(1)-STATEV1(III1)
                    STATEV1(III1)=STATEV1(III1)+Phase
                IF(STATEV1(1).lt.Residual)THEN
                  STATEV1(1)=Residual
                  STATEV1(III1)=Phase
                  STATEV1(III1)=1.d0-sum(STATEV1(1:NSTATV1))+Phase 
                RETURN
                ENDIF
               ENDIF
              ENDDO
C***************************************************************************
C                        连续降温多等分相变计算结束 
C***************************************************************************
           ENDIF
          ENDDO
C***************************************************************************
C                        相变计算结束 
C***************************************************************************
        ENDIF
      
      RETURN
      END
      
