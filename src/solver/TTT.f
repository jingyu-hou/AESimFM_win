      SUBROUTINE USDFLD(FIELD,STATEV,PNEWDT,DIRECT,T,CELENT,
     1 TIME,DTIME,CMNAME,ORNAME,NFIELD,NSTATV,NOEL,NPT,LAYER,
     2 KSPT,KSTEP,KINC,NDI,NSHR,COORD,JMAC,JMATYP,MATLAYO,
     3 LACCFLA)
C
C
      CHARACTER*80 CMNAME,ORNAME
      CHARACTER*3  FLGRAY(15)
      DIMENSION FIELD(NFIELD),STATEV(NSTATV),DIRECT(3,3),
     1 T(3,3),TIME(2)
      DIMENSION ARRAY(15),JARRAY(15),JMAC(*),JMATYP(*),
     1 COORD(*)
      parameter(zero=0.d0,one=1.d0,two=2.d0,three=3.d0)
C
      REAL TEMP_M_S,TEMP_M_F,FRAC_A,FRAC_F,FRAC_B,FRAC_M,TIME_UP_0,
     1      TIME_DOWN_0,SUM_TIME_F,SUM_TIME_B,I,TEMP0,TEMP_UP,TEMP_DOWN,
     2      TIME_UP_S,TIME_DOWN_S,TIME_UP_F,TIME_DOWN_F,TIME_S,TIME_F,
     3      SSN_T,SSA_T,P_S,P_F,TIME_0,SUM_TIME_P,FRAC_P,
     4      TIME_UP_00,TIME_DOWN_00,TIME_00,
     5      HARDNESS
C
      REAL::TPF(8)=(/750.0,725.0,700.0,675.0,650.0,625.0,600.0,575.0/),
     1     TPP(8)=(/700.0,675.0,650.0,625.0,600.0,575.0,550.0,525.0/),
     2     TPB(8)=(/600.0,575.0,550.0,525.0,500.0,475.0,450.0,425.0/),
C
     3     TIME_F_0(8)=(/200.0,100.0,22.4,14.9,12.4,6.2,4.9,9.2/),
     4     TIME_F_1(8)=(/210.0,110.0,26.2,16.4,13.9,7.6,6.8,11.0/),
     5     TIME_F_50(8)=(/800.0,500.0,250.0,123.8,55.5,33.0,35.0,41.3/),
C
     6     TIME_P_0(8)=(/22.4,14.9,12.4,6.2,4.9,9.2,7.4,4.9/),
     7     TIME_P_1(8)=(/26.2,16.4,13.9,7.6,6.8,11.0,8.8,6.4/),
     8     TIME_P_50(8)=(/250.0,123.8,55.5,33.0,35.0,41.3,39.4,29.7/),
C
     9     TIME_P_00(8)=(/100.0,45.7,18.4,9.9,6.0,28.9,83.7,352.4/)
          
      REAL::TIME_B_0(8)=(/12.0,9.2,7.4,4.9,9.3,9.6,9.2,9.9/),
     1     TIME_B_1(8)=(/13.8,11.0,8.8,6.4,10.9,11.1,10.5,11.1/),
     2     TIME_B_50(8)=(/42.0,41.3,39.4,29.7,28.2,29.1,29.5,29.6/)
C
C      STATEV(1)=temperature
C      STATEV(2)=the incubation time of ferrite (F)
C      STATEV(3)=the volume fraction of ferrite (F)
C      STATEV(4)=the incubation time of pearlite (P)
C      STATEV(5)=the volume fraction of ferrite and pearlite (P+F)
C      STATEV(6)=the incubation time of bainite (B)
C      STATEV(7)=the volume fraction of bainite (B)
C      STATEV(8)=the volume fraction of martensite (M)
C      STATEV(9)=the volume fraction of austenite (A)
C      STATEV(10)=the volume fraction phase transition (F+P+B+M)
C      STATEV(11)=the volume fraction of pearlite (P)
C      STATEV(12)=HARDNESS
C      SUM_TIME_F=0   
C      SUM_TIME_B=0   
C
      P_S=0.01
      P_F=0.5
      TEMP_M_S=425
      TEMP_M_F=200
C 
      CALL GETVRM('TEMP',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,JMATYP,
     1      MATLAYO,LACCFLA)
      TEMP0 = ARRAY(1)
      STATEV(1)=TEMP0
C 
      IF(TEMP0.GE.TPF(1))THEN
      SUM_TIME_F=ZERO
      SUM_TIME_P=ZERO
      SUM_TIME_B=ZERO
      ENDIF
C
C     Ferrite transformation
      DO I=1,7
      IF((TEMP0.LE.TPF(I)).AND.(TEMP0.GE.TPF(I+1)))THEN
      TEMPO=STATEV(1)
      TEMP_UP=TPF(I)
      TEMP_DOWN=TPF(I+1)
C     
      TIME_UP_0=TIME_F_0(I)
      TIME_DOWN_0=TIME_F_0(I+1)
C     
      TIME_UP_S=TIME_F_1(I)
      TIME_DOWN_S=TIME_F_1(I+1)
      TIME_UP_F=TIME_F_50(I)
      TIME_DOWN_F=TIME_F_50(I+1)
C
      SUM_TIME_P=STATEV(4)
      SUM_TIME_F=STATEV(2)
      R=(TEMP0-TEMP_UP)/(TEMP_DOWN-TEMP_UP)
C      
      TIME_0=R*(TIME_DOWN_0-TIME_UP_0)+TIME_UP_0
C     
      TIME_S=R*(TIME_DOWN_S-TIME_UP_S)+TIME_UP_S
      TIME_S=TIME_S-TIME_0
C     
      TIME_F=R*(TIME_DOWN_F-TIME_UP_F)+TIME_UP_F
      TIME_F=TIME_F-TIME_0
      SUM_TIME_F=SUM_TIME_F+DTIME/TIME_0
      STATEV(2)=SUM_TIME_F
      SSN_T=LOG(LOG(1-P_S)/LOG(1-P_F))
      SSN_T=SSN_T/(LOG(TIME_S)-LOG(TIME_F))
      SSA_T=-LOG(1-P_S)*TIME_S**(-SSN_T)
C
        IF((SUM_TIME_F.GE.ONE).AND.(SUM_TIME_P.LT.ONE))THEN
        FRAC_F=STATEV(3)
        FRAC_B=STATEV(7)
C  
        IF((FRAC_B.LT.ONE).AND.(FRAC_F.LT.ONE))THEN
        FRAC_F=FRAC_F/(1-FRAC_B)
        T_FRAC_SUM=(-LOG(1-FRAC_F)/SSA_T)**(ONE/SSN_T)
        T_SUM=DTIME+T_FRAC_SUM
        FRAC_F=ONE-EXP(-SSA_T*(T_SUM**SSN_T))
        FRAC_F=FRAC_F*(1-FRAC_B)
        STATEV(3)=FRAC_F
        ENDIF
        ENDIF
C
      ENDIF
      ENDDO
C
C
C     pearlite transformation
      DO I=1,5
      IF((TEMP0.LE.TPP(I)).AND.(TEMP0.GE.TPP(I+1)))THEN
      TEMPO=STATEV(1)
      TEMP_UP=TPP(I)
      TEMP_DOWN=TPP(I+1)
C      
      TIME_UP_0=TIME_P_0(I)
      TIME_DOWN_0=TIME_P_0(I+1)
      TIME_UP_00=TIME_P_00(I)
      TIME_DOWN_00=TIME_P_00(I+1)
C     
      TIME_UP_S=TIME_P_1(I)
      TIME_DOWN_S=TIME_P_1(I+1)
      TIME_UP_F=TIME_P_50(I)
      TIME_DOWN_F=TIME_P_50(I+1)
C
      SUM_TIME_P=STATEV(4)
      R=(TEMP0-TEMP_UP)/(TEMP_DOWN-TEMP_UP)
C      
      TIME_0=R*(TIME_DOWN_0-TIME_UP_0)+TIME_UP_0
C     
      TIME_00=R*(TIME_DOWN_00-TIME_UP_00)+TIME_UP_00
C     
      TIME_S=R*(TIME_DOWN_S-TIME_UP_S)+TIME_UP_S
      TIME_S=TIME_S-TIME_0
C     
      TIME_F=R*(TIME_DOWN_F-TIME_UP_F)+TIME_UP_F
      TIME_F=TIME_F-TIME_0
      SUM_TIME_P=SUM_TIME_P+DTIME/TIME_00
      STATEV(4)=SUM_TIME_P
      SSN_T=LOG(LOG(1-P_S)/LOG(1-P_F))
      SSN_T=SSN_T/(LOG(TIME_S)-LOG(TIME_F))
      SSA_T=-LOG(1-P_S)*TIME_S**(-SSN_T)
        IF(SUM_TIME_P.LT.ONE)THEN
        FRAC_F=STATEV(3)
        FRAC_P=FRAC_F
        STATEV(5)=FRAC_P
        ENDIF
        IF(SUM_TIME_P.GE.ONE)THEN
        FRAC_F=STATEV(3)
        FRAC_P=STATEV(5)
        IF(FRAC_P.LE.FRAC_F)THEN
        FRAC_P=FRAC_F
        STATEV(5)=FRAC_P
        ENDIF
        FRAC_B=STATEV(7)
C  
        IF((FRAC_B.LT.ONE).AND.(FRAC_P.LT.ONE))THEN
        FRAC_P=FRAC_P/(1-FRAC_B)
        T_FRAC_SUM=(-LOG(1-FRAC_P)/SSA_T)**(ONE/SSN_T)
        T_SUM=DTIME+T_FRAC_SUM
        FRAC_P=ONE-EXP(-SSA_T*(T_SUM**SSN_T))
        FRAC_P=FRAC_P*(1-FRAC_B)
        STATEV(5)=FRAC_P
        ENDIF
        ENDIF
      ENDIF
      ENDDO
C
C     bainite transformation
      DO I=1,7
      IF((TEMP0.LE.TPB(I)).AND.(TEMP0.GE.TPB(I+1)))THEN
      TEMPO=STATEV(1)
      TEMP_UP=TPB(I)
      TEMP_DOWN=TPB(I+1)
C      
      TIME_UP_0=TIME_B_0(I)
      TIME_DOWN_0=TIME_B_0(I+1)
C     
      TIME_UP_S=TIME_B_1(I)
      TIME_DOWN_S=TIME_B_1(I+1)
      TIME_UP_F=TIME_B_50(I)
      TIME_DOWN_F=TIME_B_50(I+1)
C
      SUM_TIME_B=STATEV(6)
      R=(TEMP0-TEMP_UP)/(TEMP_DOWN-TEMP_UP)
C      
      TIME_0=R*(TIME_DOWN_0-TIME_UP_0)+TIME_UP_0
C     
      TIME_S=R*(TIME_DOWN_S-TIME_UP_S)+TIME_UP_S
      TIME_S=TIME_S-TIME_0
C     
      TIME_F=R*(TIME_DOWN_F-TIME_UP_F)+TIME_UP_F
      TIME_F=TIME_F-TIME_0
      SUM_TIME_B=SUM_TIME_B+DTIME/TIME_0
      STATEV(6)=SUM_TIME_B
      SSN_T=LOG(LOG(1-P_S)/LOG(1-P_F))
      SSN_T=SSN_T/(LOG(TIME_S)-LOG(TIME_F))
      SSA_T=-LOG(1-P_S)*TIME_S**(-SSN_T)
        IF((SUM_TIME_B.GE.ONE).AND.(FRAC_F.LT.ONE))THEN
        FRAC_B=STATEV(7)
        FRAC_P=STATEV(5)
        FRAC_F=STATEV(3)
C        
C       avoid£¨1-FRAC_B£©=0
        IF((FRAC_B.LT.0.99).AND.(FRAC_P.LT.0.99))THEN
        FRAC_B=FRAC_B/(1-FRAC_P)
        T_FRAC_SUM=(-LOG(1-FRAC_B)/SSA_T)**(ONE/SSN_T)
        T_SUM=DTIME+T_FRAC_SUM
        FRAC_B=ONE-EXP(-SSA_T*(T_SUM**SSN_T))
        FRAC_B=FRAC_B*(1-FRAC_P)
        STATEV(7)=FRAC_B
        ENDIF
        ENDIF
      ENDIF
      ENDDO
C     martensite transformation
      IF((TEMP0.LT.TEMP_M_S).AND.((1-STATEV(5)-STATEV(7)).GE.0.01))THEN
      FRAC_M=STATEV(8)
      FRAC_F=STATEV(3)
      FRAC_P=STATEV(5)
      FRAC_B=STATEV(7)
      FRAC_M=ONE-EXP(-0.011*(TEMP_M_S-TEMP0))
      FRAC_M=(1-FRAC_P-FRAC_B)*FRAC_M
      IF(FRAC_M.GT.STATEV(8))THEN
      STATEV(8)=FRAC_M
      ENDIF
      ENDIF
C
C     retained austenite
      IF(STATEV(9).EQ.ZERO)THEN
      STATEV(9)=ONE
      ELSE
      FRAC_F=STATEV(3)
      STATEV(11)=STATEV(5)-STATEV(3)
      FRAC_B=STATEV(7)
      FRAC_M=STATEV(8)
      FRAC_A=(1-FRAC_F-FRAC_B-FRAC_M-STATEV(11))
C      STATEV(10)=STATEV(9)-FRAC_A
      STATEV(9)=FRAC_A
      END IF     
C
C     hardness
C
      HARDNESS=49.8*STATEV(8)+31.5*STATEV(7)+11.0*STATEV(5)
      STATEV(12)=HARDNESS
C
      RETURN
      END
C
C
C
C
C
C
C
      SUBROUTINE HETVAL(CMNAME,TEMP,TIME,DTIME,STATEV,FLUX,
     1             PREDEF,DPRED)      
C
      INCLUDE 'ABA_PARAM.INC' 
C
      CHARACTER*80 CMNAME
C
      DIMENSION TEMP(2),STATEV(*),PREDEF(*),TIME(2),FLUX(2),
     1 DPRED(*)
C
      REAL  FRAC,H1,H2,TEMP00
C      
C      CALL GETVRM('TEMP',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,JMATYP,
C     1      MATLAYO,LACCFLA)
      TEMP00=STATEV(1)
      H1=1560000000
      H2=1500000
      FLUX(1)=1.2*(H1-H2*TEMP00)*STATEV(10)/DTIME
C
      RETURN
      END       
