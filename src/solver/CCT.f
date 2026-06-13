      SUBROUTINE USDFLD(FIELD,STATEV,PNEWDT,DIRECT,T,CELENT,
     1 TIME,DTIME,CMNAME,ORNAME,NFIELD,NSTATV,NOEL,NPT,LAYER,
     2 KSPT,KSTEP,KINC,NDI,NSHR,COORD,JMAC,JMATYP,MATLAYO,
     3 LACCFLA)
C
      INCLUDE 'ABA_PARAM.INC'
C
c     PARAMETER(D0=30,Q=312000,R=8.315,ZERO=0)
      
      CHARACTER*80 CMNAME,ORNAME
      CHARACTER*3  FLGRAY(15)
      DIMENSION FIELD(NFIELD),STATEV(NSTATV),DIRECT(3,3),
     1 T(3,3),TIME(2)
      DIMENSION ARRAY(15),JARRAY(15),JMAC(*),JMATYP(*),COORD(*)
c
c
c
C    SYMBOL MEANING:  TEMPER2---Ti , TEMPER1---Ti-1, v_cooling---COOLING RATE
C                     
C                     V_MAX_f---MAXIMUM FRACTION OF FERRITE TRANSFORMATION
C                     V_MAX_p---MAXIMUM FRACTION OF PERLITE TRANSFORMATION
C                     V_MAX_b---MAXIMUM FRACTION OF BAINITE TRANSFORMATION
C                     V_MAX_m---MAXIMUM FRACTION OF MARTENSITE TRANSFORMATION
C
C                     v_critical_p---CRITICAL COOLING RATE FOR PERLITE TRANSFORMATION
C                     v_critical_b---CRITICAL COOLING RATE FOR BAINITE TRANSFORMATION  
C                     v_critical_m---CRITICAL COOLING RATE FOR MARTENSITE TRANSFORMATION 
C           
C                     Tf_s---STARTING TEMPERATURE OF FERRITE TRANSFORMATION
C                     Tf_f---FINISHING  TEMPERATURE OF FERRITE TRANSFORMATION
C                     Tp_f---STARTING  TEMPERATURE OF PERLITE TRANSFORMATION                         
C                     Tp_f---FINISHING  TEMPERATURE OF PERLITE TRANSFORMATION
C                     Tb_S---STARTING  TEMPERATURE OF BAINITE TRANSFORMATION
C                     Tb_f---FINISHING  TEMPERATURE OF BAINITE TRANSFORMATION
C                     Tm_s---STARTING  TEMPERATURE OF MARTENSITE TRANSFORMATION
C                     Tm_f---FINISHING  TEMPERATURE OF MARTENSITE TRANSFORMATION
C    
C                     PAHSE_STATE
C            0         1        2         3         4         5         6        7
C             r        F       F+P      F+P+B     P+B      P+B+M      B+M        M        
C 
C
C PART 1/  START DEFINE FUNCTIONS OF STARTING OR FINISHING TEMPERATURE OF F,P,B,M PHASES ACCRODING TO CCT CURVES
      FUNCTION Tf_s(v_cooling)
	IF (v_cooling LT 0.01) THEN
      Tf_s=695
	ELSE IF (v_cooling LT 0.05) THEN
      Tf_s=695+v_cooling*((715-695)/(0.05-0.01))
	ELSE IF (v_cooling LT 0.1) THEN
      Tf_s=715+v_cooling*((710-715)/(0.1-0.05))
	ELSE IF (v_cooling LT 0.5) THEN
      Tf_s=710+v_cooling*((670-710)/(0.5-0.1))
	ELSE IF (v_cooling LT 1) THEN
      Tf_s=670+v_cooling*((630-670)/(1-0.5))
	ELSE IF (v_cooling LT 3) THEN
      Tf_s=630+v_cooling*((580-630)/(3-1))
	ELSE IF (v_cooling LT 4) THEN
      Tf_s=580+v_cooling*((586-580)/(4-3))
	ELSE
      Tf_s=586
	END
C
      FUNCTION Tf_f---FINISHING(v_cooling)
	IF (v_cooling LT 0.01) THEN
      Tf_f=630
	ELSE IF (v_cooling LT 0.05) THEN
      Tf_f=630+v_cooling*((640-630)/(0.05-0.01))
	ELSE IF (v_cooling LT 0.1) THEN
      Tf_f=640+v_cooling*((645-640)/(0.1-0.05))
	ELSE IF (v_cooling LT 0.5) THEN
      Tf_f=645+v_cooling*((620-645)/(0.5-0.1))
	ELSE IF (v_cooling LT 1) THEN
      Tf_f=620+v_cooling*((605-620)/(1-0.5))
	ELSE IF (v_cooling LT 3) THEN
      Tf_f=605+v_cooling*((580-605)/(3-1))
	ELSE IF (v_cooling LT 4) THEN
      Tf_f=580+v_cooling*((580-580)/(4-3))
	ELSE
      Tf_f=580
	END
C
      FUNCTION Tp_s(v_cooling)
	IF (v_cooling LT 0.01) THEN
      Tp_s=630
	ELSE IF (v_cooling LT 0.05) THEN
      Tp_s=630+v_cooling*((640-630)/(0.05-0.01))
	ELSE IF (v_cooling LT 0.1) THEN
      Tp_s=630+v_cooling*((645-630)/(0.1-0.05))
	ELSE IF (v_cooling LT 0.5) THEN
      Tp_s=645+v_cooling*((620-645)/(0.5-0.1))
	ELSE IF (v_cooling LT 1) THEN
      Tp_s=620+v_cooling*((605-620)/(1-0.5))
	ELSE IF (v_cooling LT 3) THEN
      Tp_s=605+v_cooling*((580-605)/(3-1))
	ELSE IF (v_cooling LT 4) THEN
      Tp_s=580+v_cooling*((579-580)/(4-3))
	ELSE IF (v_cooling LT 5) THEN
      Tp_s=579+v_cooling*((575-579)/(5-4))
	ELSE IF (v_cooling LT 7) THEN
      Tp_s=575+v_cooling*((570-575)/(7-5))
	ELSE
      Tp_s=570
	END
C
      FUNCTION Tp_f(v_cooling)
	IF (v_cooling LT 0.01) THEN
      Tp_f=610
	ELSE IF (v_cooling LT 0.05) THEN
      Tp_f=610+v_cooling*((610-610)/(0.05-0.01))
	ELSE IF (v_cooling LT 0.1) THEN
      Tp_f=610+v_cooling*((555-610)/(0.1-0.05))
	ELSE IF (v_cooling LT 0.5) THEN
      Tp_f=555+v_cooling*((580-555)/(0.5-0.1))
	ELSE IF (v_cooling LT 1) THEN
      Tp_f=580+v_cooling*((570-580)/(1-0.5))
	ELSE IF (v_cooling LT 3) THEN
      Tp_f=570+v_cooling*((555-570)/(3-1))
	ELSE IF (v_cooling LT 4) THEN
      Tp_f=555+v_cooling*((560-555)/(4-3))
	ELSE IF (v_cooling LT 5) THEN
      Tp_f=560+v_cooling*((518-560)/(5-4))
	ELSE IF (v_cooling LT 7) THEN
      Tp_f=518+v_cooling*((540-518)/(7-5))
	ELSE
      Tp_f=540
	END
C
      FUNCTION Tb_s(v_cooling)
	IF (v_cooling LT 0.5) THEN
      Tb_s=580
	ELSE IF (v_cooling LT 1) THEN
      Tb_s=580+v_cooling*((570-580)/(1-0.5))
	ELSE IF (v_cooling LT 3) THEN
      Tb_s=580+v_cooling*((555-580)/(3-1))
	ELSE IF (v_cooling LT 4) THEN
      Tb_s=555+v_cooling*((560-555)/(4-3))
	ELSE IF (v_cooling LT 5) THEN
      Tb_s=560+v_cooling*((518-560)/(5-4))
	ELSE IF (v_cooling LT 7) THEN
      Tb_s=518+v_cooling*((540-518)/(7-5))
	ELSE IF (v_cooling LT 10) THEN
      Tb_s=540+v_cooling*((528-540)/(10-7))
	ELSE
      Tb_s=540
	END
C
      FUNCTION Tb_f(v_cooling)
	IF (v_cooling LT 0.5) THEN
      Tb_f=435
	ELSE IF (v_cooling LT 1) THEN
      Tb_f=435+v_cooling*((390-435)/(1-0.5))
	ELSE IF (v_cooling LT 3) THEN
      Tb_f=390+v_cooling*((375-390)/(3-1))
	ELSE IF (v_cooling LT 4) THEN
      Tb_f=375+v_cooling*((370-375)/(4-3))
	ELSE IF (v_cooling LT 5) THEN
      Tb_f=370+v_cooling*((344-370)/(5-4))
	ELSE IF (v_cooling LT 7) THEN
      Tb_f=344+v_cooling*((365-344)/(7-5))
	ELSE IF (v_cooling LT 10) THEN
      Tb_f=344+v_cooling*((330-344)/(10-7))
	ELSE
      Tb_f=330
	END
C
      FUNCTION Tm_s(v_cooling)
	IF (v_cooling LT 5) THEN
      Tm_s=344
	ELSE IF (v_cooling LT 7) THEN
      Tm_s=344+v_cooling*((365-344)/(7-5))
	ELSE IF (v_cooling LT 10) THEN
      Tm_s=365+v_cooling*((330-365)/(10-7))
	ELSE IF (v_cooling LT 20) THEN
      Tm_s=330+v_cooling*((320-330)/(20-10))
	ELSE
      Tm_s=320
	END
C
      FUNCTION Tm_f(v_cooling)
	IF (v_cooling LT 5) THEN
      Tm_f=225
	ELSE IF (v_cooling LT 7) THEN
      Tm_f=225+v_cooling*((235-225)/(7-5))
	ELSE IF (v_cooling LT 10) THEN
      Tm_f=235+v_cooling*((245-235)/(10-7))
	ELSE IF (v_cooling LT 20) THEN
      Tm_f=245+v_cooling*((225-245)/(20-10))
	ELSE
      Tm_f=225
	END
C PART 1/  FINISH DEFINE FUNCTIONS OF STARTING OR FINISHING TEMPERATURE OF F,P,B,M PHASES ACCRODING TO CCT CURVES
c
c
c PART 2/ DEFINE MAXIMUM VOLUME OF F,P,B,M
C        MAXIMUM VOLUME OF FERRITE
      FUNCTION Vmax_f(v_cooling)
      IF (v_cooling LT 0.01) THEN
      Vmax_f=44
	ELSE IF (v_cooling LT 0.05) THEN
      Vmax_f=44+v_cooling*((41-44)/(0.05-0.01))
	ELSE IF (v_cooling LT 0.1) THEN
      Vmax_f=41+v_cooling*((34-41)/(0.1-0.05))
	ELSE IF (v_cooling LT 0.5) THEN
      Vmax_f=34+v_cooling*((15-34)/(0.5-0.1))
	ELSE IF (v_cooling LT 1) THEN
      Vmax_f=15+v_cooling*((12-15)/(1-0.5))
	ELSE IF (v_cooling LT 3) THEN
      Vmax_f=12+v_cooling*((6-12)/(3-1))
	ELSE IF (v_cooling LT 4) THEN
      Vmax_f=6+v_cooling*((2-6)/(4-3))
	ELSE IF (v_cooling LT 5) THEN
      Vmax_f=2+v_cooling*((0-2)/(5-4))
	ELSE
      Vmax_f=0
      END
C
C        MAXIMUM VOLUME OF PERLITE
      FUNCTION Vmax_p(v_cooling)
      IF (v_cooling LT 0.01) THEN
      Vmax_p=56
	ELSE IF (v_cooling LT 0.05) THEN
      Vmax_p=56+v_cooling*((59-56)/(0.05-0.01))
	ELSE IF (v_cooling LT 0.1) THEN
      Vmax_p=59+v_cooling*((66-59)/(0.1-0.05))
	ELSE IF (v_cooling LT 0.5) THEN
      Vmax_p=66+v_cooling*((32-66)/(0.5-0.1))
	ELSE IF (v_cooling LT 1) THEN
      Vmax_p=32+v_cooling*((33-32)/(1-0.5))
	ELSE IF (v_cooling LT 3) THEN
      Vmax_p=33+v_cooling*((37-33)/(3-1))
	ELSE IF (v_cooling LT 4) THEN
      Vmax_p=37+v_cooling*((44-37)/(4-3))
	ELSE IF (v_cooling LT 5) THEN
      Vmax_p=44+v_cooling*((20-44)/(5-4))
	ELSE IF (v_cooling LT 7) THEN
      Vmax_p=20+v_cooling*((5-20)/(7-5))
	ELSE
      Vmax_p=0
      END
C
c        MAXIMUM VOLUME OF BAINITE
      FUNCTION Vmax_b(v_cooling)
      IF (v_cooling LT 0.5) THEN
      Vmax_b=0
	ELSE IF (v_cooling LT 1) THEN
      Vmax_b=53+v_cooling*((55-53)/(1-0.5))
	ELSE IF (v_cooling LT 3) THEN
      Vmax_b=55+v_cooling*((57-55)/(3-1))
	ELSE IF (v_cooling LT 4) THEN
      Vmax_b=57+v_cooling*((55-57)/(4-3))
	ELSE IF (v_cooling LT 5) THEN
      Vmax_b=55+v_cooling*((70-55)/(5-4))
	ELSE IF (v_cooling LT 7) THEN
      Vmax_b=70+v_cooling*((45-70)/(7-5))
	ELSE IF (v_cooling LT 10) THEN
      Vmax_b=45+v_cooling*((20-45)/(10-7))
	ELSE
      Vmax_b=0
      END
c
c        MAXIMUM VOLUME OF MARTENSITE
      FUNCTION Vmax_m(v_cooling)
   	IF (v_cooling LT 5) THEN
      Vmax_m=0
	ELSE IF (v_cooling LT 7) THEN
      Vmax_m=10+v_cooling*((50-10)/(7-5))
	ELSE IF (v_cooling LT 10) THEN
      Vmax_m=50+v_cooling*((80-50)/(10-7))
	ELSE IF (v_cooling LT 20) THEN
      Vmax_m=80+v_cooling*((100-80)/(20-10))
	ELSE
      Vmax_m=0
      END
c PART 2/ DEFINE MAXIMUM VOLUME OF F,P,B,M
C
C
C
C PART 3/     START CALCULATE COOLING RATE
      IF (KINC.EQ.1) THEN
      TEMPER2=850
	TEMPER1=850
	STATEV(2)=TEMPER2
	STATEV(1)=TEMPER1
	ELSE

      CALL GETVRM('TEMP',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,
	1JMATYP,MATLAYO,LACCFLA)
	TEMPER2=ARRAY(1)
      FIELD(1)=TEMPER2
C
      CALL GETVRM('SDV',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,
	1JMATYP,MATLAYO,LACCFLA)
	TEMPER1=ARRAY(1)
C
	vcooling=(TEMPER2-TEMPER1)/DTIME     
C
	STATEV(1)=TEMPER2
	STATEV(2)=TEMPER1
	STATEV(3)=vcooling
C PART 3/    FINISH CACULATE COOLING RATE
C
C PART 4/   START DEFINE v_critical ACCRODING TO CCT CURVES
      v_critical_P=3
	v_critical_B=0.3
      v_critical_M=5
C PART 4/   FINISH DEFINE v_critical ACCRODING TO CCT CURVES
C
C PART 5   AREA IDENTIFICATION AND INCREAMENT OF NEW PHASE
      IF (vcooling LT v_critical_B) THEN
C     IN 1ST AREA     F+P
          IF (TEMPER2 LT Tf_s(v_cooling) AND 
     1(TEMPER2 GE Tf_f(v_cooling))) THEN
C         AUSTENITE TO FERRITE
          V_F_ii=Vmax_f*(Tf_s(vcooling)-TEMPER2)/
     1(Tf_s(vcooling)-Tf_f(vcooling))
	    V_F_i=Vmax_f*(Tf_s(vcooling)-TEMPER1)/
     1(Tf_s(vcooling)-Tf_f(vcooling))
C         INCREAMENT VOLUME OF F
	    V_F_inc=V_F_ii-V_F_i
	    STATEV(5)=STATEV(5)+V_F_inc
C         
          ELSE IF (TEMPER2 LT Tp_s(v_cooling) AND 
     1(TEMPER2 GE Tp_f(v_cooling))) THEN
C         AUSTENITE TO PERLITE
          V_P_ii=Vmax_f*(Tp_s(vcooling)-TEMPER2)/
     1(Tp_s(vcooling)-Tp_f(vcooling))
          V_P_i=Vmax_f*(Tp_s(vcooling)-TEMPER1)/
     1(Tp_s(vcooling)-Tp_f(vcooling))
C     	INCREAMENT VOLUME OF P
	    V_P_inc=V_P_ii-V_P_i
	    STATEV(6)=STATEV(6)+V_P_inc
          ELSE
          V_F_inc=0
	    V_P_inc=0
	    END IF
C
	ELSE IF(vcooling LT v_critical_P) THEN 
C     IN 2ND AREA    F+P+B
          IF (TEMPER2 LT Tf_s(v_cooling) AND 
     1(TEMPER2 GE Tf_f(v_cooling))) THEN
C         AUSTENITE TO FERRITE
          V_F_ii=Vmax_f*(Tf_s(vcooling)-TEMPER2)/
     1(Tf_s(vcooling)-Tf_f(vcooling))
	    V_F_i=Vmax_f*(Tf_s(vcooling)-TEMPER1)/
     1(Tf_s(vcooling)-Tf_f(vcooling))
C         INCREAMENT VOLUME OF F
	    V_F_inc=V_F_ii-V_F_i
	    STATEV(5)=STATEV(5)+V_F_inc
C         
          ELSE IF (TEMPER2 LT Tp_s(v_cooling) AND 
     1(TEMPER2 GE Tp_f(v_cooling))) THEN
C         AUSTENITE TO PERLITE
          V_P_ii=Vmax_f*(Tp_s(vcooling)-TEMPER2)/
     1(Tp_s(vcooling)-Tp_f(vcooling))
          V_P_i=Vmax_f*(Tp_s(vcooling)-TEMPER1)/
     1(Tp_s(vcooling)-Tp_f(vcooling))
C     	INCREAMENT VOLUME OF P
	    V_P_inc=V_P_ii-V_P_i
	    STATEV(6)=STATEV(6)+V_P_inc
          ELSE IF (TEMPER2 LT Tb_s(v_cooling) AND 
     1(TEMPER2 GE Tb_f(v_cooling))) THEN
C         AUSTENITE TO BAINITE
          V_B_ii=Vmax_f*(Tb_s(vcooling)-TEMPER2)/
     1(Tb_s(vcooling)-Tb_f(vcooling))
          V_B_i=Vmax_f*(Tb_s(vcooling)-TEMPER1)/
     1(Tb_s(vcooling)-Tb_f(vcooling))
C     	INCREAMENT VOLUME OF B
	    V_B_inc=V_B_ii-V_B_i
	    STATEV(7)=STATEV(7)+V_B_inc
	    ELSE
          V_F_inc=0
	    V_P_inc=0
          V_B_inc=0
	    END IF
C
	ELSE IF(vcooling LT v_critical_M) THEN 
C     IN 3ND AREA    P+B
          IF (TEMPER2 LT Tp_s(v_cooling) AND 
     1(TEMPER2 GE Tp_f(v_cooling))) THEN
C         AUSTENITE TO PERLITE
          V_P_ii=Vmax_f*(Tp_s(vcooling)-TEMPER2)/
     1(Tp_s(vcooling)-Tp_f(vcooling))
          V_P_i=Vmax_f*(Tp_s(vcooling)-TEMPER1)/
     1(Tp_s(vcooling)-Tp_f(vcooling))
C     	INCREAMENT VOLUME OF P
	    V_P_inc=V_P_ii-V_P_i
	    STATEV(6)=STATEV(6)+V_P_inc
          ELSE IF (TEMPER2 LT Tb_s(v_cooling) AND 
     1(TEMPER2 GE Tb_f(v_cooling))) THEN
C         AUSTENITE TO BAINITE
          V_B_ii=Vmax_f*(Tb_s(vcooling)-TEMPER2)/
     1(Tb_s(vcooling)-Tb_f(vcooling))
          V_B_i=Vmax_f*(Tb_s(vcooling)-TEMPER1)/
     1(Tb_s(vcooling)-Tb_f(vcooling))
C     	INCREAMENT VOLUME OF B
	    V_B_inc=V_B_ii-V_B_i
	    STATEV(7)=STATEV(7)+V_B_inc
	    ELSE
	    V_P_inc=0
          V_B_inc=0
		END IF
	ELSE 
C     IN 4TH AREA    B+M
          IF (TEMPER2 LT Tm_s(v_cooling) AND 
     1(TEMPER2 GE Tm_f(v_cooling))) THEN
C         AUSTENITE TO MARTENSITE
          V_M_ii=Vmax_m*(Tm_s(vcooling)-TEMPER2)/
     1(Tm_s(vcooling)-Tm_f(vcooling))
          V_M_i=Vmax_m*(Tm_s(vcooling)-TEMPER1)/
     1(Tm_s(vcooling)-Tm_f(vcooling))
C     	INCREAMENT VOLUME OF M
	    V_B_inc=V_B_ii-V_B_i
	    STATEV(7)=STATEV(8)+V_B_inc










    
		
	ELSE
C	IN M AREA
      PHASE_STATE=2
	ENDIF
C PART 5   AREA IDENTIFICATION
c
c
c PART 6  PHASE PERCENTATION  CACULATION
      IF
c
c
c
c     
	ENDIF 
      RETURN
      END