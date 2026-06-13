
C************************************************************************
C                        获取热物参数
C************************************************************************

      SUBROUTINE phaseprop(pphase,pointnumber,TEMP,DUDT,COND,DKDT,
     &STATEV1,phase_inf)
      IMPLICIT NONE
      INTEGER Phase_inf(4)
      INTEGER NSTATV1,K1,KK2,KK3,KK4,KK5,II1,JJ,
     &pointnumber(2,phase_inf(1))

      REAL*8 PPhase(2,phase_inf(3),2,phase_inf(1)),DCond,
     &STATEV1(phase_inf(1))
      REAL*8 TEMP,DUDT,COND,DKDT,value1
      
      Cond=0.d0
      DKDT=0.d0
      DUDT=0.d0

      Do JJ=1,2
        DO II1=1,phase_inf(1)
           value1=0.d0
           DCond=0.d0
           K1=pointnumber(JJ,II1)
           KK2=1  
           KK3=KK2+1 
           KK4=KK3+1 
           KK5=KK4+1
           CALL getcondspeci(STATEV1(II1),KK2,KK3,KK4,KK5,K1,JJ,
     &     PPhase(1:2,1:K1,JJ,II1),TEMP,value1,DCond)
           IF(JJ.eq.1)then
              DUDT=DUDT+value1*statev1(II1)
           else
              Cond=Cond+value1*statev1(II1)
              DKDT=DKDT+DCond*statev1(II1)
           ENDIF
        ENDDO
      ENDDO
      
      RETURN
      END 
C************************************************************************
C                   计算降温过程中温度增量和时间增量 
C************************************************************************
      SUBROUTINE KSTARTSTOPC (TEMP1,TEMP2,TIME1,TIME2,
     &TMAX,TMIN,holding_temp,DTEMP,DTIME)
        IMPLICIT NONE
        REAL*8 TEMP1,TEMP2,TMAX,TEMP0,TIME0,DTEMP,
     &   DTIME,TIME2,FAC,holding_temp,TIME1,TMIN
      
        IF (TEMP1 .LT. TMAX) THEN
          TEMP0 = TEMP1
          TIME0 = TIME1
        ELSE
          TEMP0 = TMAX
          CALL Proportional(TEMP1,TIME1,TEMP2,TIME2,TMAX,TIME0,4)
        ENDIF
      
        IF (TEMP2 .GT. TMIN) THEN
          DTEMP = TEMP2-TEMP0
          DTIME = TIME2-TIME0
        ELSE
          DTEMP = TMIN - TEMP0
          FAC = (TMIN-TEMP1)/(TEMP2-TEMP1)
          DTIME = TIME1 - TIME0 + (TIME2-TIME1)*FAC
        ENDIF
      
        IF(TEMP1 .Ge. TMAX.and. TEMP2.lT.TMAX)THEN
          holding_temp=TMAX
        ELSE
          holding_temp=TEMP1
        ENDIF
      
        RETURN
      END SUBROUTINE KSTARTSTOPC
      
C************************************************************************
C                   计算升温过程中温度增量和时间增量 
C************************************************************************
      SUBROUTINE KSTARTSTOPH(TEMP1,TEMP2,TIME1,TIME2,
     &TMIN,TMAX,holding_temp,DTEMP,DTIME)
        IMPLICIT NONE
      
        REAL*8 TEMP1,TEMP2,TMAX,TEMP0,TIME0,DTEMP,
     &    DTIME,TIME2,FAC,holding_temp,TIME1,TMIN
      
       IF (TEMP1 .GE. TMIN) THEN
         TEMP0 = TEMP1
         TIME0 = TIME1
       ELSE
         TEMP0 = TMIN
         CALL Proportional(TEMP1,TIME1,TEMP2,TIME2,TEMP0,TIME0,4)
       ENDIF
      
       IF (TEMP2 .LE. TMAX) THEN
          DTEMP = TEMP2 - TEMP0
          DTIME = TIME2 - TIME0
       ELSE
          DTEMP = TMAX-TEMP0
          FAC = (TMAX-TEMP1)/(TEMP2-TEMP1) 
          DTIME = TIME1 - TIME0 + (TIME2-TIME1)*FAC
       ENDIF

       IF(TEMP1 .lt. Tmin.and. TEMP2.ge.Tmin)THEN
         holding_temp=TMin
       ELSE
         holding_temp=TEMP1
       ENDIF
      
      RETURN
      END SUBROUTINE KSTARTSTOPH
      
C************************************************************************
C                      两点插值公式 
C************************************************************************
      SUBROUTINE Proportional(a1,b1,a2,b2,a3,b3,IB)
        IMPLICIT NONE
        REAL*8 a1,b1,a2,b2,a3,b3,r,CC
        integer IB
      
        CC=a2-a1
        IF(abs(CC).gt.1.d-10)THEN
          r=(b2-b1)/CC
          b3=(a3-a1)*r+b1
       ELSE
         SELECT CASE(IB)
         case(1)
            write(*,*)
     &'计算孕育期时存在两个相临特别近的点计算斜率'
         case(2)
            write(*,*)
     &'计算相平衡时存在两个相临特别近的点计算斜率'
         case(3)
            write(*,*)
     &'遍历TTT/CCT曲线存在两个相临特别近的点计算斜率'
         case(4)
            write(*,*)
     &'计算相变温度/时间增量时存在两个相临特别近'
            write(*,*)   '的点计算斜率'
         case(5)
            write(*,*)
     &'计算热物时存在两个相临特别近的点计算斜率'
         END SELECT
         write(*,*)'a1=',a1,'b1=',b1
         write(*,*)'a2=',a2,'b2=',b2
         stop
       ENDIF
      
      RETURN
      END
      
C************************************************************************
C                计算CCT曲线上点的等温相变时间 
C************************************************************************
      SUBROUTINE Calculation_CCT_coolingrate(CCTCurve_Equivalenttime,
     &Curave_Data,NTTCT_Point,N1,NCurve_Number)
        IMPLICIT NONE
        INTEGER::N1,II,III,JJ,KK,LL,MN,NCurve_Number
        INTEGER ::NTTCT_Point(NCurve_Number)
        REAL*8 ::Curave_Data(N1,2),CCTCurve_Equivalenttime(N1)

        MN=1
        DO LL=1,NCurve_Number,1
           DO III=1,NTTCT_Point(LL),1
              II=NTTCT_Point(LL)*(LL-1)+III
              JJ=II-1
              KK=II+1
              IF(III.ne.1.and.III.ne.NTTCT_Point(LL))THEN
                CCTCurve_Equivalenttime(MN)=(Curave_Data(KK,2)-
     &          Curave_Data(JJ,2))/(Curave_Data(KK,1)-
     &          Curave_Data(JJ,1))
              ELSEIF(III.eq.1)THEN
                CCTCurve_Equivalenttime(MN)=(Curave_Data(II,2)-
     &          Curave_Data(KK,2))/(Curave_Data(II,1)-
     &          Curave_Data(KK,1))
              ELSE
                 CCTCurve_Equivalenttime(MN)=(Curave_Data(II,2)-
     &           Curave_Data(JJ,2))/(Curave_Data(II,1)-
     &           Curave_Data(JJ,1))
              ENDIF
              MN=MN+1
            ENDDO
        ENDDO
        CCTCurve_Equivalenttime=abs(CCTCurve_Equivalenttime)
      RETURN
      END
      
      
C************************************************************************
C                用于获取热物属性子程序 
C************************************************************************
      SUBROUTINE getcondspeci(f,KK2,KK3,KK4,KK5,K1,JJ,PROPS,
     &TEMP,value1,DCond)
        IMPLICIT NONE
        INTEGER ::K1,KK2,KK3,KK4,KK5,NPROPS,JJ,II
        REAL*8 ::f,TEMP,value1,DCond
        REAL*8 ::PROPS(2*k1)
      
       IF(f.gT.0)THEN
         IF(TEMP.LE.PROPS(KK2))THEN   
           CALL Proportional(PROPS(KK2),PROPS(KK3),PROPS(KK4),PROPS(KK5)
     &       ,TEMP,value1,5)
          IF(JJ.eq.2) DCond=(PROPS(KK5)-PROPS(KK3))/(PROPS(KK4)-
     &     PROPS(KK2))
        ELSEIF(TEMP.gE.PROPS((K1-1)*2+1))THEN
           KK2=(K1-2)*2+1
           KK3=KK2+1
           KK4=KK3+1
           KK5=KK4+1
           CALL Proportional(PROPS(KK2),PROPS(KK3),PROPS(KK4),PROPS(KK5)
     &    ,TEMP,value1,5)
           IF(JJ.eq.2)DCond=(PROPS(KK5)-PROPS(KK3))/(PROPS(KK4)-
     &     PROPS(KK2))
        ELSE
           DO II=1,K1-1,1
              KK2=(II-1)*2+1
              KK3=KK2+1
              KK4=KK3+1
              KK5=KK4+1
              IF(TEMP.GT.PROPS(KK2).and.TEMP.LE.PROPS(KK4))THEN
               CALL Proportional(PROPS(KK2),PROPS(KK3),
     &            PROPS(KK4),PROPS(KK5),TEMP,value1,5)
              IF(JJ.eq.2) DCond=(PROPS(KK5)-PROPS(KK3))/(PROPS(KK4)
     &                -PROPS(KK2))
              ENDIF
           ENDDO
         ENDIF
      ENDIF
      RETURN
      END
      
C************************************************************************
C           遍历某个数组，找到给定温度/时间/其他变量下对应的变量 
C************************************************************************
      SUBROUTINE CurveData_Intersection(NCurve_Number,holding_temp,
     &TIME_T,Curave_Data,NTTCT_Point,N1)
        IMPLICIT NONE
        INTEGER ::III2,NCurve_Number,KKK1,KKK2,N1
        INTEGER ::NTTCT_Point(NCurve_Number)
        REAL*8 ::TIME_T(NCurve_Number),Curave_Data(N1,2)
        REAL*8 ::holding_temp
      
        DO III2=1,NCurve_Number,1
          CALL FIRSTLAST_POINT(NTTCT_Point,NCurve_Number,KKK1,KKK2,III2)
          CALL IsothermalCurve_Intersection(Curave_Data(KKK1,2),
     &    Curave_Data(KKK2,2),Curave_Data(KKK1:KKK2,2),
     &    Curave_Data(KKK1:KKK2,1),KKK2-KKK1+1,holding_temp,
     &    TIME_T(III2),3)
        ENDDO
      RETURN
      END
      
      SUBROUTINE IsothermalCurve_Intersection(Tmin,Tmax,TTT_Temp1,
     & TTT_Time1,NT1,holding_temp,t,IB)
        IMPLICIT NONE
      
        INTEGER ::NT1,II,IB
        REAL*8 ::Tmax,Tmin,holding_temp,t
        REAL*8 ::TTT_Temp1(NT1),TTT_Time1(NT1) 
      
        DO II=1,NT1
          IF(((TTT_Temp1(II).LE.holding_temp.AND.
     &      TTT_Temp1(II+1).GE.holding_temp).OR.
     &      (TTT_Temp1(II).GE.holding_temp.AND.
     &      TTT_Temp1(II+1).LE.holding_temp)).and.(II+1).LE.NT1)THEN 
            CALL Proportional(TTT_Temp1(II),TTT_Time1(II),
     &      TTT_Temp1(II+1),TTT_Time1(II+1),holding_temp,t,IB)
            return
          ELSEIF(holding_temp.Lt.Tmin)THEN
          CALL Proportional(TTT_Temp1(1),TTT_Time1(1),
     &    TTT_Temp1(2),TTT_Time1(2),holding_temp,t,IB)
          RETURN
          ELSEIF(holding_temp.GT.Tmax)THEN
             CALL Proportional(TTT_Temp1(NT1),TTT_Time1(NT1),
     &       TTT_Temp1(NT1-1),TTT_Time1(NT1-1),holding_temp,t,IB)
            RETURN
          ENDIF         
        ENDDO
      RETURN
      END
      
C*********************************************************************************************************
C 获取某个已存储（这个数组可能开的特别大，但不一定都存储数据）数据数组第一个点和最后一个点的数组下标
C*********************************************************************************************************
      SUBROUTINE FIRSTLAST_POINT(NTTCT_Point,NCurve_Number,KKK1,KKK2,
     & III2)
        IMPLICIT NONE
        INTEGER::NCurve_Number,III2,KKK1,KKK2
        INTEGER::NTTCT_Point(NCurve_Number)
        IF(III2.eq.1)THEN
          KKK1=1 
          KKK2=NTTCT_Point(III2)
        ELSE
          KKK1=sum(NTTCT_Point(1:III2-1))+1
          KKK2=sum(NTTCT_Point(1:III2))
        ENDIF
      RETURN
      END

      subroutine phaseini(xstate,nstate,mi,ne,lakon,cphase,
     &phase_inf,nphase)
        implicit none
        character*8 lakon(*)
        integer phase_inf(4),i,j,k,mint3d,ne,nstate,
     &   mi(*),nphase(11,*)
         real*8 cphase(13+phase_inf(4),phase_inf(1),*),
     & xstate(nstate,mi(1),*)

       if(nphase(3,1).ne.1.and.nphase(3,1).ne.2)return

       do i=1,ne
          if(lakon(i)(4:5).eq.'8R') then
             mint3d=1
          elseif((lakon(i)(4:4).eq.'8').or.
     &      (lakon(i)(4:6).eq.'20R')) then
             mint3d=8
          elseif(lakon(i)(4:4).eq.'2') then
             mint3d=27
          elseif(lakon(i)(4:5).eq.'10') then
             mint3d=4
          elseif(lakon(i)(4:4).eq.'4') then
             mint3d=1
          elseif(lakon(i)(4:5).eq.'15') then
             mint3d=9
          elseif(lakon(i)(4:4).eq.'6') then
             mint3d=2
          endif
          do j=1,mint3d
              do k=1,phase_inf(1)
                if(nstate.ge.13)then
                  xstate(14+k,j,i)=cphase(1,k,1)
                else
                  xstate(k,j,i)=cphase(1,k,1)
                endif
              enddo
          enddo
       enddo
      return
      end

