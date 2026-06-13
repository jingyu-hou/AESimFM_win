      SUBROUTINE USDFLD(FIELD,STATEV,PNEWDT,DIRECT,T,CELENT,
     1 TIME,DTIME,CMNAME,ORNAME,NFIELD,NSTATV,NOEL,NPT,LAYER,
     2 KSPT,KSTEP,KINC,NDI,NSHR,COORD,JMAC,JMATYP,MATLAYO,
     3 LACCFLA)
C
      CHARACTER*80 CMNAME,ORNAME
      CHARACTER*3  FLGRAY(15)
      DIMENSION FIELD(NFIELD),STATEV(NSTATV),DIRECT(3,3),
     1 T(3,3),TIME(2)
      DIMENSION ARRAY(15),JARRAY(15),JMAC(*),JMATYP(*),COORD(*)

C-------------------------------------------------------------------------------------------------------------------------------------------------------
c     定义锻造过程（变形和中间操作）中的变量及存储位置
	Real EQUER_mean, N1, N2, N3, N4, EQUE_RE, PEEQ0, TEMPER0, D_C, D0, 
     1     PEEQ_C, EQUE_C, EQUE_T, Z, Ec, t_i, SRX_sign, EQUE05_DRX,
     1	 X_DRX, D_DRX100, D_DRX, DRX_sign, MRX_sign, D_GROWTH0_MRX,
	1     D_GROWTH0_SRX,t_GROWTH0_MRX, t_GROWTH0_SRX, t_GROWTH_MRX, 
	1     t_GROWTH_SRX, t_GROWTH_DRX, EQUE_RE0, K_G, EQUER_total,
     1     D_GROWTH_MRX, D_GROWTH_SRX, D_GROWTH_DRX, t05_MRX, X_MRX,
	1     D_MRX, D_MIX, t05_SRX, X_SRX, D_SRX, t_Step, t_Step1, t_Step2,
	1     t_Step3, t_Step4, t_Step5, t_Step6, t_Deform, t0, 
     1     TEMPER_C, UNDEFORM_sign
     	
      PARAMETER(R=8.314,ZERO=0)
c     TEMPERATURE-该增量步的温度；EQUE－累计应变；EQUER－平均应变速率；Z－Zener参数；EC－临界应变；D0－初始晶粒度；D_C－该增量步的晶粒度；
c     XDRX－动态再结晶份数；DDRX－动态再结晶晶粒度；XSRX－静态再结晶份数；DSRX－静态再结晶晶粒度；XMRX－伪动态再结晶份数；DMRX－伪动态再结晶晶粒度；
c     DGROWTH-长大后的晶粒度；t05SRX-静态再结晶参数；t05MRX－伪动态再结晶参数；EQUE05DRX－动态再结晶参数；t－时间；
C
C     STATEV(1)------N1
C     STATEV(2)------EQUE_RE0
C     STATEV(3)------N3
C     STATEV(4)------N4
C     STATEV(5)------TEMPER0
C     STATEV(6)------PEEQ0
C     STATEV(7)----- PEEQ_C 
C     STATEV(8)------EQUE_C
C     STATEV(9)------EQUE_T
C     STATEV(10)-----EQUE_RE
C     STATEV(11)-----D0
C     STATEV(12)-----D_C
C     STATEV(13)-----D_GROWTH0_MRX
C     STATEV(14)-----DRX_sign
C     STATEV(15)-----MRX_sign
C     STATEV(16)-----SRX_sign
C     STATEV(17)-----EQUER_mean 
C     STATEV(18)-----X_DRX
C     STATEV(19)-----X_MRX
C     STATEV(20)-----X_SRX
C     STATEV(21)-----EQUE05_DRX
C     STATEV(22)-----t_GROWTH0_MRX
C     STATEV(23)-----t_05_MRX
C     STATEV(24)-----t_05_SRX
C     STATEV(25)-----t_GROWTH0_SRX
C     STATEV(26)-----D_GROWTH0_SRX
C     STATEV(27)-----UNDEFORM_sign
C     STATEV(28)-----t_Deform
C     STATEV(29)-----
C     STATEV(30)-----
C-------------------------------------------------------------------------------------------------------------------------------------------------------

C    定义正火冷却过程变量
      REAL vcooling, vcooling_total, vcooling_mean, TEMPER2, TEMPER1,
     1v_1, INC_F, INC_P, TEMPER2_total, Frac_A, Ae1, ASTM1, HB,
     1INC_i, TEMPER2_P_MEAN, Frac_F, Frac_F_ii, Frac_F_i, Frac_F_inc,
     1Frac_P, Frac_P_ii, Frac_P_i, Frac_P_inc, D_A, D_F, D_P, S_P, YS,
     1 TS, HV, ASTM
C
C各变量物理含义：
c     vcooling：该时间步内的冷却速率；                                                            STATEV(33)
c     vcooling_total： 为计算vcooling_mean服务												    STATEV(37)
c     vcooling_mean：节点冷却通过F相区的平均冷却速度,为计算最终铁素体晶粒尺寸服务；               STATEV(38)
c     TEMPER2： 该时间步内节点的温度；															STATEV(32)
c     TEMPER1： 上一个时间步内节点的温度；														STATEV(31)
c     v_1： A-F+P转变的临界冷却速度,小于等于该速度均会发生A-F+P转变；   
c     INC_F： 计数器,为计算vcooling_mean服务；												    STATEV(50)
c     INC_P： 计数器,为计算TEMPER2_P_MEAN服务；													STATEV(47)
c     INC_i： 临时计数器																			STATEV(48)
C     TEMPER2_total: 为计算TEMPER2_mean服务													    STATEV(49)
c     TEMPER2_P_MEAN:  节点冷却通过P相区的平均温度,为计算珠光体片层间距服务						STATEV(46)
c     Frac_F_ii：假如是理想连续冷却（从一开始就是v恒定）,则该时间步时节点上铁素体的总量。
C     Frac_F_i：假设条件下,则上一个时间步时节点上铁素体的总量。									STATEV(39)
c     Frac_F_inc: 该时间步长内铁素体的新增加量
c     Frac_F： 铁素体总量																			STATEV(35)
c     Frac_P_ii：假如是理想连续冷却（从一开始就是v恒定）,则该时间步时节点上珠光体的总量。
C     Frac_P_i：假设条件下,则上一个时间步时节点上珠光体的总量。									STATEV(40)
c     Frac_P_inc: 该时间步长内珠光体的新增加量
c     Frac_P: 珠光体总量																			STATEV(36)
c     Frac_A: 残余奥氏体量																		STATEV(34)
c     D_A：相变前初始奥氏体晶粒尺寸,um                                                                  STATEV(57)
c     D_F：相变得到的铁素体晶粒尺寸,um															STATEV(41)
c     S_P：相变得到的珠光体片层间距, um															STATEV(42)
c     YS: 屈服强度 MPa																		    STATEV(43)
c     TS：抗拉强度																				STATEV(44)
c     HV：硬度																					STATEV(45)
c     Ae1: 平衡转变共析温度，为计算珠光体片层间距服务
c     ASTM: ASTM晶粒度																			STATEV(51)
c     HB：布氏硬度												     							STATEV(52)
C     ASTM1: ASTM晶粒度																			STATEV(53)
c     Sign_TLowThanP:温度低于珠光体转变标志，可考察此时残余奥氏体量，以确定是否时间步长过大		STATEV(55)
c     D_P：相变得到的铁素体晶粒尺寸,um															STATEV(56)

C-------------------------------------------------------------------------------------------------------------------------------------------------------

C    定义正火加热过程变量
      REAL AC1, Austen_s_sign, Austen_f_sign, t0_Austen_s, t0_Austen_f

C     STATEV(61)------Austen_s_sign
C     STATEV(62)------t0_Austen_s
C     STATEV(63)------Austen_f_sign
C     STATEV(64)------t0_Austen_f
C-------------------------------------------------------------------------------------------------------------------------------------------------------
                            
c     初始化变量

	t_Step1=900
	t_Step2=10
	t_Step3=30
	t_Step4=60
	t_Step5=900
	t_Step6=30
	t_Step7=10
	t_Step8=120
	t_Step9=60
	t_Step10=10
	t_Step11=120
	t_Step12=60
	t_Step13=10
	t_Step14=120
	t_Step15=60
	t_Step16=10
	t_Step17=120
	t_Step18=60
	t_Step19=10
	t_Step20=120
	t_Step21=60
	t_Step22=10
	t_Step23=120
	t_Step24=60
	t_Step25=10
	t_Step26=120
	t_Step27=3000
	t_Step28=86400
	t_Step29=97200
	t_Step30=86400

      IF (KSTEP.EQ.1) THEN
	   	t_Step=t_Step1
      ELSEIF (KSTEP.EQ.2) THEN
		t_Step=t_Step2
      ELSEIF (KSTEP.EQ.3) THEN
		t_Step=t_Step3
      ELSEIF (KSTEP.EQ.4) THEN
		t_Step=t_Step4
      ELSEIF (KSTEP.EQ.5) THEN
		t_Step=t_Step5
      ELSEIF (KSTEP.EQ.6) THEN
		t_Step=t_Step6
      ELSEIF (KSTEP.EQ.7) THEN
		t_Step=t_Step7
      ELSEIF (KSTEP.EQ.8) THEN
		t_Step=t_Step8
      ELSEIF (KSTEP.EQ.9) THEN
		t_Step=t_Step9
      ELSEIF (KSTEP.EQ.10) THEN
		t_Step=t_Step10
      ELSEIF (KSTEP.EQ.11) THEN
	   	t_Step=t_Step11
      ELSEIF (KSTEP.EQ.12) THEN
		t_Step=t_Step12
      ELSEIF (KSTEP.EQ.13) THEN
		t_Step=t_Step13
      ELSEIF (KSTEP.EQ.14) THEN
		t_Step=t_Step14
      ELSEIF (KSTEP.EQ.15) THEN
		t_Step=t_Step15
      ELSEIF (KSTEP.EQ.16) THEN
		t_Step=t_Step16
      ELSEIF (KSTEP.EQ.17) THEN
		t_Step=t_Step17
      ELSEIF (KSTEP.EQ.18) THEN
		t_Step=t_Step18
      ELSEIF (KSTEP.EQ.19) THEN
		t_Step=t_Step19
      ELSEIF (KSTEP.EQ.20) THEN
		t_Step=t_Step20
      ELSEIF (KSTEP.EQ.21) THEN
	   	t_Step=t_Step21
      ELSEIF (KSTEP.EQ.22) THEN
		t_Step=t_Step22
      ELSEIF (KSTEP.EQ.23) THEN
		t_Step=t_Step23
      ELSEIF (KSTEP.EQ.24) THEN
		t_Step=t_Step24
      ELSEIF (KSTEP.EQ.25) THEN
		t_Step=t_Step25
      ELSEIF (KSTEP.EQ.26) THEN
		t_Step=t_Step26
      ELSEIF (KSTEP.EQ.27) THEN
		t_Step=t_Step27
      ELSEIF (KSTEP.EQ.28) THEN
		t_Step=t_Step28
      ELSEIF (KSTEP.EQ.29) THEN
		t_Step=t_Step29

      ENDIF
C
C-------------------------------------------------------------------------------------------------------------------------------------------------------

C     如果是锻造前加热步骤
C      IF (KSTEP .EQ. 1) THEN
C	   D0=100
C         t_i=TIME(1)+DTIME
C	   CALL GETVRM('TEMP',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,
C	1   JMATYP,MATLAYO,LACCFLA)
C	   TEMPER_C = ARRAY(1)+273.15
C	   D_C=(D0**4.739+(76671*EXP(-91872/8.314/(TEMPER_C+273)))
C     1	    **4.739*t_i)**0.211
C	   STATEV(12)=D_C
C        初始化变量
C        TEMPER0=TEMPER_C
C	  STATEV(5)=TEMPER0
C	  EQUE_RE0=0
C        STATEV(2)=EQUE_RE0
C
C	  STATEV(11)=D0
C        STATEV(12)=D_C
C	  EQUE_RE=0
C        STATEV(10)=EQUE_RE
C
C	  STATEV(6)=0
C	  STATEV(7)=0
C	  STATEV(8)=0
C	  STATEV(9)=0
C        STATEV(21)=0
C        STATEV(18)=0
C	  STATEV(28)=0
C	  STATEV(1)=0
C
C	  STATEV(13)=0
C	  STATEV(22)=0
C	  STATEV(23)=0        
C	  STATEV(19)=0
C
C	  STATEV(26)=0
C	  STATEV(25)=0
C	  STATEV(24)=0
C       STATEV(20)=0
C      ENDIF

C     如果是锻造前冷却步骤
      IF ((KSTEP .EQ. 1) .OR. (KSTEP .EQ. 2)) THEN
C        变量初始化	   
	   D0=400

         STATEV(1)=0
         STATEV(2)=0
         STATEV(3)=0
         STATEV(4)=0
         STATEV(5)=0
         STATEV(6)=0
         STATEV(7)=0
         STATEV(8)=0
         STATEV(9)=0
         STATEV(10)=0    
         STATEV(11)=D0
         STATEV(12)=D0
         STATEV(13)=0
         STATEV(14)=0
         STATEV(15)=0
         STATEV(16)=0
         STATEV(17)=0
         STATEV(18)=0
         STATEV(19)=0
         STATEV(20)=0
         STATEV(21)=0
         STATEV(22)=0
         STATEV(23)=0
         STATEV(24)=0
         STATEV(25)=0
         STATEV(26)=0
         STATEV(27)=0
         STATEV(28)=0
         STATEV(29)=0
         STATEV(30)=0
         STATEV(31)=0
         STATEV(32)=0
         STATEV(33)=0
         STATEV(34)=0
         STATEV(35)=0
         STATEV(36)=0
         STATEV(37)=0
         STATEV(38)=0
         STATEV(39)=0
         STATEV(40)=0
         STATEV(41)=0
         STATEV(42)=0
         STATEV(43)=0
         STATEV(44)=0
         STATEV(45)=0
         STATEV(46)=0
         STATEV(47)=0
         STATEV(48)=0
         STATEV(49)=0
         STATEV(50)=0
         STATEV(51)=0
         STATEV(52)=0
         STATEV(53)=0
         STATEV(54)=0
         STATEV(55)=0
         STATEV(56)=0
         STATEV(57)=0
         STATEV(58)=0
         STATEV(59)=0
         STATEV(60)=0
         STATEV(61)=0
         STATEV(62)=0
         STATEV(63)=0
         STATEV(64)=0
         STATEV(65)=0
         STATEV(66)=0
         STATEV(67)=0
         STATEV(68)=0
         STATEV(69)=0
         STATEV(70)=0
      ENDIF

C-------------------------------------------------------------------------------------------------------------------------------------------------------

c     STEP类型1： 如果是锻造变形步（动态在结晶）
      IF ((KSTEP.EQ.3) .OR. (KSTEP.EQ.7) .OR. (KSTEP.EQ.10) .OR. 
	1   (KSTEP.EQ.13) .OR. (KSTEP.EQ.16) .OR. (KSTEP.EQ.19) .OR. 
     1   (KSTEP.EQ.22) .OR. (KSTEP.EQ.25))  THEN

	 IF (KINC .EQ. 1) THEN

C          获取该step入口处的温度T0，PEEQ0，
		 CALL GETVRM('TEMP',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,
	1     JMATYP,MATLAYO,LACCFLA)
	     TEMPER0 = ARRAY(1)+273.15
	     CALL GETVRM('PE',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,
	1     JMATYP,MATLAYO,LACCFLA)
           PEEQ0 = ARRAY(7)

C         获取该step入口处的残余应变、和晶粒度
	    CALL GETVRM('SDV',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,
	1    JMATYP,MATLAYO,LACCFLA)
	    EQUE_RE0=ARRAY(10)
          D_C=ARRAY(12)
	    D0=D_C

       ELSE
C      获取该增量步入口处的残余应变0、PEEQ0，温度和晶粒度
	   CALL GETVRM('SDV',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,
	1   JMATYP,MATLAYO,LACCFLA)
	   EQUE_RE0=ARRAY(2)

	   CALL GETVRM('SDV',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,
	1   JMATYP,MATLAYO,LACCFLA)
         PEEQ0 = ARRAY(6)

	   CALL GETVRM('SDV',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,
	1   JMATYP,MATLAYO,LACCFLA)
         TEMPER0 = ARRAY(5)

	   CALL GETVRM('SDV',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,
	1   JMATYP,MATLAYO,LACCFLA)
	   D0=ARRAY(11)
	 ENDIF



CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
       CALL GETVRM('TEMP',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,
	1 JMATYP,MATLAYO,LACCFLA)
	 TEMPER_C = ARRAY(1)+273.15
	 TEMPER0=TEMPER_C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC

      IF (TEMPER_C .LT. (700+273)) THEN
      TEMPER_C=(700+273)
      ENDIF

CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC

c      定义该step内到该增量步的时间
       t_i=TIME(1)+DTIME

	 D_C=D0
	 EQUE_RE=EQUE_RE0

C      计算该增量步的应变
	 CALL GETVRM('PE',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,
	1 JMATYP,MATLAYO,LACCFLA)
       PEEQ_C = ARRAY(7)
       EQUE_C=PEEQ_C-PEEQ0
       EQUE_T=EQUE_C+EQUE_RE0
C      计算该增量步的平均应变速率
	 IF (EQUE_C .GT. 0) THEN
         CALL GETVRM('SDV',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,
	1   JMATYP,MATLAYO,LACCFLA)
	   t_Deform=ARRAY(28)
	   N1=ARRAY(1)
	   EQUER_mean=EQUE_C/(t_i-t_Deform)
	 ELSE
	   N1=KINC
	   t_Deform=t_i
         EQUER_mean=0
	 ENDIF
    
     
	 IF (EQUE_C .EQ. 0) THEN
       UNDEFORM_sign=1
	 SRX_sign=0
	 DRX_sign=0
	 MRX_sign=0
C      如果变形已经开始
	 ELSE

c      计算临界应变
       UNDEFORM_sign=0
       Z=EQUER_mean*EXP(300000/8.315/TEMPER0)
       Ec= (5.6E-4)*(D0**0.3)*(Z**0.17)


c      判断是否达到临界应变

c      如果小于临界应变
       IF (EQUE_T .LT. Ec) THEN
C        如果变形结束          
         IF (t_i .EQ. t_Step) THEN
c          静态再结晶标识	    
		 SRX_sign=1
	     DRX_sign=0
	     MRX_sign=0
         ELSE
	     SRX_sign=0
	     DRX_sign=0
	     MRX_sign=0    
	   ENDIF

	   EQUE_RE=EQUE_T
         X_DRX=0
	   D_C=D0
c        退出
         GOTO 100

c      如果大于等于临界应变，发生动态再结晶
       ELSE
	   EQUE05_DRX=(1.144E-3)*D0**0.28*EQUER_mean**0.05*EXP(6420/TEMPER0)
	   X_DRX=1-EXP(-0.693*((EQUE_T-Ec)/EQUE05_DRX)**2)
	   D_DRX100=1.6E4*Z**(-0.23)
	   D_DRX=SQRT(D0**2*(1-X_DRX**2)+(X_DRX*D_DRX100)**2)
	   D_C=D_DRX

C        如果动态再结晶份数大于95％，则再结晶充分，后续无伪动态再结晶发生
         IF (X_DRX .GT. 0.95) THEN
	     DRX_sign=1
	     MRX_sign=0
	     SRX_sign=0

	     EQUE_RE=0
C        如果动态再结晶不充分，后续将有伪动态再结晶发生
	   ELSE
	     MRX_sign=1
	     DRX_sign=0
	     SRX_sign=0

	     EQUE_RE=(1-X_DRX)*EQUE_T
	   ENDIF

	 ENDIF
       ENDIF

c      存储和更新变量
100    STATEV(2)=EQUE_RE0
	 STATEV(6)=PEEQ0
	 STATEV(5)=TEMPER0
	 STATEV(11)=D0
	 STATEV(1)=N1
       STATEV(28)=t_Deform

	 STATEV(7)=PEEQ_C
	 STATEV(8)=EQUE_C
	 STATEV(9)=EQUE_T
       STATEV(10)=EQUE_RE
	 STATEV(17)=EQUER_mean

       STATEV(21)=EQUE05_DRX
       STATEV(18)=X_DRX
	 STATEV(12)=D_C

       STATEV(14)=DRX_sign
       STATEV(15)=MRX_sign
       STATEV(16)=SRX_sign
       STATEV(27)=UNDEFORM_sign

C       所有与伪动态再结晶和静态再结晶的变量均归零
	  STATEV(13)=0
	  STATEV(22)=0
	  STATEV(23)=0        
	  STATEV(19)=0

	  STATEV(26)=0
	  STATEV(25)=0
	  STATEV(24)=0
        STATEV(20)=0
	
	  STATEV(3)=0
	  STATEV(4)=0

200	ENDIF


C 
C-------------------------------------------------------------------------------------------------------------------------------------------------------

C     STEP类型2： 如果是锻造间隙步（静态在结晶和伪动态在结晶）
      IF ((KSTEP .EQ. 5) .OR. (KSTEP .EQ. 9) .OR. (KSTEP .EQ. 12) .OR.
	1   (KSTEP .EQ. 15) .OR. (KSTEP .EQ. 18) .OR. (KSTEP .EQ. 21) .OR.
     1   (KSTEP .EQ. 24) .OR. (KSTEP .EQ. 26)) THEN

C       读取入口温度，继承上个step末尾的残余应变,晶粒度
        IF (KINC .EQ. 1) THEN
C       获取该step入口处的温度0，残余应变0，晶粒度0, 等效应变速率
	    CALL GETVRM('TEMP',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,
	1    JMATYP,MATLAYO,LACCFLA)
          TEMPER0 = ARRAY(1)+273.15

	    CALL GETVRM('SDV',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,
	1    JMATYP,MATLAYO,LACCFLA)
	    EQUE_RE0=ARRAY(10)
          EQUE_RE=ARRAY(10)
	    EQUER_mean=ARRAY(17)
          D_C=ARRAY(12)
	    D0=D_C

        ELSE
C      获取该增量步入口处的温度TEMPER0，残余应变EQUE_RE0，晶粒度D0, 等效应变速率
	    CALL GETVRM('SDV',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,
	1    JMATYP,MATLAYO,LACCFLA)
          TEMPER0 = ARRAY(5)
		
		CALL GETVRM('SDV',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,
	1    JMATYP,MATLAYO,LACCFLA)
	    EQUE_RE0=ARRAY(2)
          EQUE_RE=ARRAY(10)
	    EQUER_mean=ARRAY(17)
	    D0=ARRAY(11)

        ENDIF


CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
       CALL GETVRM('TEMP',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,
	1 JMATYP,MATLAYO,LACCFLA)
	 TEMPER_C = ARRAY(1)+273.15
	 TEMPER0=TEMPER_C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC

      IF (TEMPER_C .LT. (700+273)) THEN
      TEMPER_C=(700+273)
      ENDIF

CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
      
        D_C=D0

C       读取标识符
	  CALL GETVRM('SDV',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,
	1  JMATYP,MATLAYO,LACCFLA)

        MRX_sign=ARRAY(15)
	  SRX_sign=ARRAY(16)
	  DRX_sign=ARRAY(14)
        UNDEFORM_sign=ARRAY(27)

        t_i=TIME(1)+DTIME
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C        t_i=TIME(1)
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC    
C       如果满足伪动态再结晶的条件
        IF (MRX_sign .EQ. 1) THEN

	    Z=EQUER_mean*EXP(300000/8.315/TEMPER0)
	    t05_MRX=1.1*(Z**(-0.8))*EXP(230000/8.314/TEMPER0)
	    X_MRX=1-EXP(-0.693*(t_i/t05_MRX)**1.5)
	    D_MRX=2.6E4*Z**(-0.23)

     
c         如果伪动态再结晶充分
          IF (X_MRX .GT. 0.95) THEN

C           记录伪动态再结晶结束时刻
	      CALL GETVRM('SDV',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,
	1      JMATYP,MATLAYO,LACCFLA) 
            N3=ARRAY(3)

		  IF (N3 .NE. 1) THEN
C             记录伪动态再结晶晶粒开始生长的时刻	        
              t_GROWTH0_MRX=t_i
c             记录伪动态再结晶晶粒开始生长的初始晶粒度
	        D_GROWTH0_MRX=D_MRX
	        STATEV(13)=D_GROWTH0_MRX
	        STATEV(22)=t_GROWTH0_MRX
	        D_C=D_GROWTH0_MRX
            ELSE
C             伪动态再结晶得到的晶粒长大
	        CALL GETVRM('SDV',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,
	1        JMATYP,MATLAYO,LACCFLA)

              t_GROWTH0_MRX=ARRAY(22)
              D_GROWTH0_MRX=ARRAY(13)
	        STATEV(13)=D_GROWTH0_MRX
	        STATEV(22)=t_GROWTH0_MRX
              t_GROWTH_MRX=t_i-t_GROWTH0_MRX

CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C	        D_GROWTH_MRX=(D_GROWTH0_MRX**4.5+4.1E23*(t_GROWTH_MRX)*
C     1			EXP(-435000/8.314/TEMPER0))**(1.0/4.5)
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
c              t0=(1.3E-5*D0*EXP(11050/TEMPER0))**4.74
c	        D_GROWTH_MRX=76671*EXP(-11050/TEMPER0)*
c     1			         (t_GROWTH_MRX+t0)**0.211
c	        IF ((t_GROWTH_MRX-2.65*t05_MRX) .GT. 0) THEN
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
	        K_G=1.72E21*EXP(-384000/8.314/TEMPER0)
	        D_GROWTH_MRX=(D_GROWTH0_MRX**(4.112)+K_G*t_GROWTH_MRX)**0.2432
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
c 	        D_GROWTH_MRX=(D_GROWTH0_MRX**7+8.2E25*(t_GROWTH_MRX)*
c     1			EXP(-400000/8.314/TEMPER0))**(1.000/7.000)
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
c	        D_GROWTH_MRX=(D_GROWTH0_MRX**2+1.2E7*(t_GROWTH_MRX-2.65*
c     1			    t05_MRX)*EXP(-113000/8.314/TEMPER0))**(1.000/2.000)
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
	        
	        D_C=D_GROWTH_MRX
c	        ELSE
c		    D_C=D_GROWTH0_MRX
c	        ENDIF

		  ENDIF

		  N3=1
	      STATEV(3)=N3
	      EQUE_RE=0
		  
c         伪动态再结晶不充分		  	     
          ELSE
	   
	      D_MIX=X_MRX**(4.000/3.000)*D_MRX+(1-X_MRX)**2*D0

	      D_C=D_MIX
	      EQUE_RE=(1-X_MRX)*EQUE_RE0
          ENDIF

C       更新自定义变量：伪动态再结晶份数；晶粒度，残余应变

	  STATEV(5)=TEMPER0
	  STATEV(11)=D0
        STATEV(2)=EQUE_RE0

	  STATEV(23)=t05_MRX        
	  STATEV(19)=X_MRX
        STATEV(12)=D_C
        STATEV(10)=EQUE_RE

C       所有与动态再结晶和静态再结晶的变量均归零
	  STATEV(6)=0
	  STATEV(7)=0
	  STATEV(8)=0
	  STATEV(9)=0
        STATEV(21)=0
        STATEV(18)=0
	  STATEV(28)=0
        STATEV(1)=0

	  STATEV(26)=0
	  STATEV(25)=0
	  STATEV(24)=0
        STATEV(20)=0

        STATEV(27)=0

	  ENDIF



C       如果满足静态再结晶的条件
        IF (SRX_sign .EQ. 1) THEN

	     t05_SRX=(2.3E-15)*EQUE_RE0**(-2.5)*D0**
     1    	  2*EXP(230000/8.315/TEMPER0)
	     X_SRX=1-EXP(-0.693*(t_i/t05_SRX))
	     D_SRX=343*EQUE_RE0**(-0.5)*D0**0.4*EXP(-45000/8.315/TEMPER0)

c         如果静态再结晶充分
          IF (X_SRX .GT. 0.95) THEN

C           记录静态再结晶结束时刻
	      CALL GETVRM('SDV',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,
	1      JMATYP,MATLAYO,LACCFLA) 
            N4=ARRAY(4)

		  IF (N4 .NE. 1) THEN
C             记录静态再结晶晶粒开始生长的时刻	        
              t_GROWTH0_SRX=t_i
c             记录静态再结晶晶粒开始生长的初始晶粒度
	        D_GROWTH0_SRX=D_SRX
	        STATEV(26)=D_GROWTH0_SRX
	        STATEV(25)=t_GROWTH0_SRX
	        D_C=D_GROWTH0_SRX
            ELSE
C             静态再结晶得到的晶粒长大
	        CALL GETVRM('SDV',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,
	1        JMATYP,MATLAYO,LACCFLA)

              t_GROWTH0_SRX=ARRAY(25)
              D_GROWTH0_SRX=ARRAY(26)
	        STATEV(26)=D_GROWTH0_SRX
	        STATEV(25)=t_GROWTH0_SRX
              t_GROWTH_SRX=t_i-t_GROWTH0_SRX


CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C	        D_GROWTH_SRX=(D_GROWTH0_SRX**4.5+4.1E23*(t_GROWTH_SRX)*
C     1			EXP(-435000/8.314/TEMPER0))**(1.0/4.5)
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
c              t0=(1.3E-5*D0*EXP(11050/TEMPER0))**4.74
c	        D_GROWTH_SRX=76671*EXP(-11050/TEMPER0)*
c     1			         (t_GROWTH_SRX+t0)**0.211

c	        IF ((t_GROWTH_SRX-4.32*t05_SRX) .GT. 0) THEN
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
	        K_G=1.72E21*EXP(-384000/8.314/TEMPER0)
	        D_GROWTH_SRX=(D_GROWTH0_SRX**(4.112)+K_G*t_GROWTH_SRX)**0.2432
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
c 	        D_GROWTH_SRX=(D_GROWTH0_SRX**7+1.5E27*(t_GROWTH_SRX)*
c     1			EXP(-400000/8.314/TEMPER0))**(1.000/7.000)
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
c	        D_GROWTH_SRX=(D_GROWTH0_SRX**2+4.0E7*(t_GROWTH_SRX-4.32*
c     1  			    t05_SRX)*EXP(-113000/8.314/TEMPER0))**(1.000/2.000)
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC

	        D_C=D_GROWTH_SRX
c			ELSE
c			D_C=D_GROWTH0_SRX	        
c	        ENDIF

		  ENDIF

		  N4=1
		  STATEV(4)=N4
	      EQUE_RE=0
  
c         静态再结晶不充分
          ELSE

	      D_MIX=X_SRX**(4.000/3.000)*D_SRX+(1-X_SRX)**2*D0
	      D_C=D_MIX
	      EQUE_RE=(1-X_SRX)*EQUE_RE0

          ENDIF

C       更新自定义变量：静态再结晶份数；晶粒度，残余应变

	  STATEV(5)=TEMPER0
	  STATEV(11)=D0
        STATEV(2)=EQUE_RE0


	  STATEV(24)=t05_SRX
        STATEV(20)=X_SRX
        STATEV(12)=D_C
        STATEV(10)=EQUE_RE

C       所有与动态再结晶和伪动态再结晶的变量均归零
	  STATEV(6)=0
	  STATEV(7)=0
	  STATEV(8)=0
	  STATEV(9)=0
        STATEV(21)=0
        STATEV(18)=0
	  STATEV(28)=0
	  STATEV(1)=0

	  STATEV(13)=0
	  STATEV(22)=0
	  STATEV(23)=0        
	  STATEV(19)=0

        STATEV(27)=0

	  ENDIF      



C       动态再结晶晶粒长大
        IF (DRX_sign .EQ. 1) THEN

	    Z=EQUER_mean*EXP(300000/8.315/TEMPER0)
	    t05_MRX=1.1*(Z**(-0.8))*EXP(230000/8.314/TEMPER0)
          t_GROWTH_DRX=t_i

CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C	        D_GROWTH_DRX=(D0**4.5+4.1E23*(t_GROWTH_DRX)*
C     1			EXP(-435000/8.314/TEMPER0))**(1.0/4.5)
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C          t0=(1.3E-5*D0*EXP(11050/TEMPER0))**4.74
C	    D_GROWTH_DRX=76671*EXP(-11050/TEMPER0)*
C     1			         (t_GROWTH_DRX+t0)**0.211
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
c	    K_G=1.72E21*EXP(-384000/8.314/TEMPER0)
c	    D_GROWTH_DRX=(D0**(4.112)+K_G*t_GROWTH_DRX)**0.2432
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
  	    D_GROWTH_DRX=(D0**7+8.2E25*(t_GROWTH_DRX)*
     1	         EXP(-400000/8.314/TEMPER0))**(1.000/7.000)
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC

	    D_C=D_GROWTH_DRX
          EQUE_RE=0

C       更新自定义变量：晶粒度，残余应变

	  STATEV(5)=TEMPER0
	  STATEV(11)=D0
        STATEV(2)=EQUE_RE0

        STATEV(12)=D_C
        STATEV(10)=EQUE_RE

C       所有与动态再结晶，静态再结晶和伪动态再结晶的变量均归零
	  STATEV(6)=0
	  STATEV(7)=0
	  STATEV(8)=0
	  STATEV(9)=0
        STATEV(21)=0
        STATEV(18)=0
	  STATEV(28)=0
	  STATEV(1)=0

	  STATEV(13)=0
	  STATEV(22)=0
	  STATEV(23)=0        
	  STATEV(19)=0

	  STATEV(26)=0
	  STATEV(25)=0
	  STATEV(24)=0
        STATEV(20)=0

        STATEV(27)=0

        ENDIF




C       如果未变形，晶粒长大
        IF (UNDEFORM_sign .EQ. 1) THEN

	    D_C=(D0**4.111+1.72E21*EXP(-384000/8.314/TEMPER0)*t_i)**0.2432
          EQUE_RE=0

C       更新自定义变量：静态再结晶份数；晶粒度，残余应变

	  STATEV(5)=TEMPER0
	  STATEV(11)=D0
        STATEV(2)=EQUE_RE0

        STATEV(12)=D_C
        STATEV(10)=EQUE_RE

C       所有与动态再结晶，静态再结晶和伪动态再结晶的变量均归零
	  STATEV(6)=0
	  STATEV(7)=0
	  STATEV(8)=0
	  STATEV(9)=0
        STATEV(21)=0
        STATEV(18)=0
	  STATEV(28)=0
	  STATEV(1)=0

	  STATEV(13)=0
	  STATEV(22)=0
	  STATEV(23)=0        
	  STATEV(19)=0

	  STATEV(26)=0
	  STATEV(25)=0
	  STATEV(24)=0
        STATEV(20)=0

        ENDIF

300   ENDIF

C-------------------------------------------------------------------------------------------------------------------------------------------------------
C     STEP类型：锻后冷却步（奥氏体晶粒长大）
      IF (KSTEP .EQ. 27)  THEN

C       读取入口温度，继承上个step末尾的残余应变,晶粒度
        IF (KINC .EQ. 1) THEN
C       获取该step入口处的温度0，残余应变0，晶粒度0, 等效应变速率
	    CALL GETVRM('TEMP',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,
	1    JMATYP,MATLAYO,LACCFLA)
          TEMPER0 = ARRAY(1)+273.15

	    CALL GETVRM('SDV',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,
	1    JMATYP,MATLAYO,LACCFLA)
          D_C=ARRAY(12)
	    D0=D_C

        ELSE
C       获取该增量步入口处的温度TEMPER0，残余应变EQUE_RE0，晶粒度D0, 等效应变速率
	    CALL GETVRM('SDV',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,
	1    JMATYP,MATLAYO,LACCFLA)
          TEMPER0 = ARRAY(5)
		
		CALL GETVRM('SDV',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,
	1    JMATYP,MATLAYO,LACCFLA)
	    D0=ARRAY(11)

        ENDIF

CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
        CALL GETVRM('TEMP',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,
	1  JMATYP,MATLAYO,LACCFLA)
	  TEMPER_C = ARRAY(1)+273.15
	  TEMPER0=TEMPER_C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC

        t_i=TIME(1)+DTIME

        IF (TEMPER_C .GT. (760+273)) THEN
	    D_C=(D0**4.111+1.72E21*EXP(-384000/8.314/TEMPER0)*t_i)**0.2432
        ENDIF

C       更新晶粒度     
        STATEV(5)=TEMPER0
	  STATEV(11)=D0
        STATEV(12)=D_C

      ENDIF

C-------------------------------------------------------------------------------------------------------------------------------------------------------
C     STEP类型3：如果是热处理加热步（F＋P－>A 转变，奥氏体晶粒长大）
      IF (KSTEP .EQ. 29)  THEN
	  AC1=735+273.15
	  CALL GETVRM('TEMP',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,
	1  MATYP,MATLAYO,LACCFLA)
	  TEMPER_C = ARRAY(1)+273.15
        t_i=TIME(1)+DTIME

C	    调整时间步长
	  CALL GETVRM('SDV',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,
	1    JMATYP,MATLAYO,LACCFLA)
        Austen_s_sign=ARRAY(61)
        Austen_f_sign=ARRAY(63)
        IF ((TEMPER_C .GE. (AC1-20)) .AND. (Austen_f_sign .NE. 1)) THEN
           PNEWDT=60/DTIME
        ENDIF

C       计算奥氏体化的分数
        IF (TEMPER_C .GE. AC1) THEN

	     CALL GETVRM('SDV',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,
	1     JMATYP,MATLAYO,LACCFLA)
           Austen_s_sign=ARRAY(61)

C          记录奥氏体化开始的时刻
	     IF (Austen_s_sign .EQ. 0) THEN
	        Austen_s_sign=1
	        STATEV(61)=Austen_s_sign
	        t0_Austen_s=t_i
	        STATEV(62)=t0_Austen_s
              Frac_A=0
              STATEV(34)=Frac_A
C          计算奥氏体化的份数
           ELSEIF (Austen_s_sign .EQ. 1) THEN
	        CALL GETVRM('SDV',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,
	1        MATYP,MATLAYO,LACCFLA)
              t0_Austen_s=ARRAY(62)
              Frac_A=1-EXP(-(7E-5)*(t_i-t0_Austen_s)**1.5)
              STATEV(34)=Frac_A
	        STATEV(61)=1

           ENDIF
        ELSE
           Frac_A=0
           STATEV(34)=0
		 STATEV(61)=0
	     STATEV(62)=0
        ENDIF

        IF (Frac_A .GE. 0.99) THEN
	     CALL GETVRM('SDV',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,
	1     MATYP,MATLAYO,LACCFLA)
           Austen_f_sign=ARRAY(63)
C          记录奥氏体化刚刚结束的时刻
	     IF (Austen_f_sign .EQ. 0) THEN
	        D0=10
	        STATEV(57)=D0
              Austen_f_sign=1
	        STATEV(63)=Austen_f_sign
	        t0_Austen_f=t_i
	        STATEV(64)=t0_Austen_f

C          奥氏体晶粒开始生长
           ELSE
	        CALL GETVRM('SDV',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,
	1        MATYP,MATLAYO,LACCFLA)
              D0=10
	        t0_Austen_f=ARRAY(64)
              D_A=(D0**4.112+1.72E21*EXP(-384000/8.314/
     1			TEMPER_C)*(t_i-t0_Austen_f))**0.2432
	        STATEV(57)=D_A
	        STATEV(63)=1

           ENDIF
        ENDIF	     

c     与热处理冷却奥氏体分解相关的变量均归零
      STATEV(31)=0
      STATEV(32)=0
      STATEV(33)=0
C      STATEV(34)=0
      STATEV(35)=0
      STATEV(36)=0
      STATEV(37)=0
      STATEV(38)=0
      STATEV(39)=0
      STATEV(40)=0
      STATEV(41)=0
      STATEV(42)=0
      STATEV(43)=0
      STATEV(44)=0
      STATEV(45)=0
      STATEV(46)=0
      STATEV(47)=0
      STATEV(48)=0
      STATEV(49)=0
      STATEV(50)=0
      STATEV(51)=0
      STATEV(52)=0
      STATEV(53)=0
      STATEV(54)=0
      STATEV(55)=0
      STATEV(56)=0
C      STATEV(57)=0
      STATEV(58)=0
      STATEV(59)=0

	ENDIF

C-------------------------------------------------------------------------------------------------------------------------------------------------------

C     STEP类型4：如果是热处理冷却步（A－>F＋P，预测晶粒度和机械性能）
      IF ((KSTEP .EQ. 28) .OR. (KSTEP .EQ. 30))  THEN

C	   调整时间步长
         CALL GETVRM('TEMP',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,
	1   JMATYP,MATLAYO,LACCFLA)
	   TEMPER2=ARRAY(1)
	   IF ((TEMPER2 .LE. 770) .AND. (TEMPER2 .GE. 550))  THEN
            PNEWDT=60/DTIME
         ENDIF



        IF (TEMPER2 .GT. 760) THEN

C     继承上个step末尾的晶粒度
        IF (KINC .EQ. 1) THEN

	    CALL GETVRM('SDV',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,
	1    JMATYP,MATLAYO,LACCFLA)
          D_C=ARRAY(12)
	    D0=D_C

        ELSE
C       获取该增量步入口处的晶粒度D0
		
		CALL GETVRM('SDV',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,
	1    JMATYP,MATLAYO,LACCFLA)
	    D0=ARRAY(11)

        ENDIF

CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
        CALL GETVRM('TEMP',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,
	1  JMATYP,MATLAYO,LACCFLA)
	  TEMPER_C = ARRAY(1)+273.15
	  TEMPER0=TEMPER_C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC

        t_i=TIME(1)+DTIME

        IF (TEMPER_C .GT. (760+273)) THEN
	    D_C=(D0**4.111+1.72E21*EXP(-384000/8.314/TEMPER0)*t_i)**0.2432
        ENDIF

C       更新晶粒度     
        STATEV(5)=TEMPER0
	  STATEV(11)=D0
        STATEV(12)=D_C
	  GOTO 500

      ENDIF


































c    初始化
      IF (KINC.EQ.1) THEN

        CALL GETVRM('TEMP',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,
	1  JMATYP,MATLAYO,LACCFLA)
	  TEMPER2=ARRAY(1)

CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C       进入锻后冷却步骤，如果该点温度已经降低到相变点以下，则人为指定
         IF (TEMPER2 .LT. 760) THEN
	     IF (TEMPER2 .LT. 350) THEN
	        vcooling_mean=0.1
		    Frac_P=0.65
	        Frac_F=0.35
	     ELSEIF (TEMPER2 .GE. 350 .AND. TEMPER2 .LT. 400) THEN
	        vcooling_mean=0.09
		    Frac_P=0.64
	        Frac_F=0.36
	     ELSEIF (TEMPER2 .GE. 400 .AND. TEMPER2 .LT. 450) THEN
	        vcooling_mean=0.08
		    Frac_P=0.63
	        Frac_F=0.37
	     ELSEIF (TEMPER2 .GE. 450 .AND. TEMPER2 .LT. 500) THEN
	        vcooling_mean=0.07
		    Frac_P=0.62
	        Frac_F=0.38
	     ELSEIF (TEMPER2 .GE. 500 .AND. TEMPER2 .LT. 600) THEN
	        vcooling_mean=0.06
		    Frac_P=0.61
	        Frac_F=0.39
	     ELSEIF (TEMPER2 .GE. 600) THEN
	        vcooling_mean=0.05
		    Frac_P=0.60
	        Frac_F=0.40
           ENDIF

	      Frac_A=0.0

	      D_F=(22.6-57.0*0.48+(1.0+0)*vcooling_mean**(-0.5)+
	1         22.0*(1-exp(-0.015*400)))*1.5
            D_F=D_F*(1-0.45*0.05**(0.5))
	      D_P=D_F*(Frac_P/Frac_F)**0.5

            ASTM1=(2.0/log10(2.0))*log10(254.0/
     1		 (D_F*Frac_F**0.5+D_P*Frac_P**0.5))+1.0
	      ASTM=INT(ASTM1)
	      STATEV(54)=ASTM
            IF ((ASTM1 .GE. ASTM) .AND. (ASTM1 .LT. (ASTM+0.25)))
     1	     THEN 
	        ASTM=ASTM
	      ELSEIF ((ASTM1 .GE. (ASTM+0.25)) .AND. 
     1			 (ASTM1 .LT. (ASTM+0.75))) THEN 
	        ASTM=ASTM+0.5
	      ELSEIF ((ASTM1 .GE. (ASTM+0.75)) .AND. 
     1	   (ASTM1 .LT. (ASTM+1.00))) THEN 
	        ASTM=ASTM+1.0
	      END IF
	      YS=62.6+26.1*1.4+60.2*0.25+759*0.01+212.9*0.015+
     1		 3286.0*0.0065+10.0*(D_F/1000.0)**(-0.5)+20.0*
     1          log10(vcooling_mean)+700.0*0.1+7800.0*0.0065+90.0
            TS=164.9+634.7*0.35+53.6*1.4+99.7*0.25+651.9*0.01+
     1	    472.6*0.15+3339.4*0.0065+11.0*(D_F/1000.0)**(-0.5)+
     1        30.0*log10(vcooling_mean)+700.0*0.1+7800.0*0.0065-50.0
c
	      HV=(TS-80.00)/2.57
	      HB=(TS+20.00)/3.50

            STATEV(34)=Frac_A
            STATEV(35)=Frac_F
            STATEV(36)=Frac_P
            STATEV(41)=D_F
	      STATEV(51)=ASTM
	      STATEV(53)=ASTM1
   	      STATEV(43)=YS
	      STATEV(44)=TS
	      STATEV(45)=HV
	      STATEV(52)=HB
	      STATEV(57)=D_F*Frac_F**0.5+D_P*Frac_P**0.5

            ALREADY_SIGN=1
  		  STATEV(59)=ALREADY_SIGN
            GOTO 500
         ENDIF
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC

	  TEMPER1=TEMPER2
	  STATEV(32)=TEMPER2
	  STATEV(31)=TEMPER1
	  STATEV(34)=1
	  STATEV(35)=0
	  STATEV(36)=0
	ELSE

        CALL GETVRM('TEMP',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,
	1  JMATYP,MATLAYO,LACCFLA)
	  TEMPER2=ARRAY(1)

CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
        CALL GETVRM('SDV',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,
	1  JMATYP,MATLAYO,LACCFLA)
C       如果满足条件，则人为指定，继承变量后跳出
        IF (ARRAY(59) .EQ. 1) THEN
           GOTO 500
        ENDIF
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC

	  STATEV(32)=TEMPER2
        FIELD(1)=TEMPER2
C
        CALL GETVRM('SDV',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,
	1  JMATYP,MATLAYO,LACCFLA)
	  TEMPER1=ARRAY(31)
C       获得节点温度和冷却速度值
	  vcooling=-(TEMPER2-TEMPER1)/DTIME     
C
        TEMPER1=TEMPER2
	  STATEV(31)=TEMPER1
	  STATEV(33)=vcooling
c       定义临界冷却速度和初始晶粒度
        v_1=0.1
	  Ae1=723.0-16.9*0.083+29.1*0.23+6.38*0-10.7*1.27+16.9*0.25+290.0*0

C       获取上一个step的奥氏体晶粒度
        IF (KSTEP .EQ. 28) THEN
           CALL GETVRM('SDV',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,
	1     JMATYP,MATLAYO,LACCFLA)
	     A_GROWTH_SIGN=ARRAY(65)
           IF (TEMPER2 .GT. Tf_s(vcooling)) THEN
              IF (A_GROWTH_SIGN .EQ. 0) THEN
                 CALL GETVRM('SDV',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,
	1           JMATYP,MATLAYO,LACCFLA)
	           D0=ARRAY(12)
                 D_A=D0
	           STATEV(57)=D_A
                 A_GROWTH_SIGN=1
                 STATEV(65)=A_GROWTH_SIGN
              ELSE
                 CALL GETVRM('SDV',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,
	1           JMATYP,MATLAYO,LACCFLA)
	           D0=ARRAY(12)
                 D_A=(D0**4.112+1.72E21*EXP(-384000/8.314/
     1		        TEMPER2)*DTIME)**0.2432
	           STATEV(57)=D_A
	        ENDIF
           ENDIF
C       如果是正火加热后冷却
        ELSEIF (KSTEP .EQ. 30) THEN
           CALL GETVRM('SDV',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,
	1     JMATYP,MATLAYO,LACCFLA)
	     D_A=ARRAY(57)
        ENDIF

C----------------------------------------------
c
        IF (vcooling .LE. 0) THEN
	    vcooling=0.00000001
	  END IF
C

        IF (vcooling .GT. v_1) THEN
	    vcooling=0.1
	  END IF
C
c       确定当前节点处于哪个温度区间
c
c       1. 奥氏体区
        IF (TEMPER2 .GT. Tf_s(vcooling)) THEN
    	    STATEV(35)=0
	    STATEV(36)=0
          STATEV(34)=1
	    INC_i=0
	    STATEV(48)=INC_i

c       2. 铁素体转变区
        ELSE IF (TEMPER2 .LE. Tf_s(vcooling) .AND. 
     1    (TEMPER2 .GE. Tf_f(vcooling))) THEN
C
	    CALL GETVRM('SDV',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,
	1    JMATYP,MATLAYO,LACCFLA)
C         导入上一时间步计算得到的铁素体总量
          Frac_F=ARRAY(35)
C         计算铁素体的增量
          Frac_F_ii=Vmax_f(vcooling)*(Tf_s(vcooling)-TEMPER2)/
     1    (Tf_s(vcooling)-Tf_f(vcooling))
	    Frac_F_i=ARRAY(39)
	    STATEV(39)=Frac_F_ii
C         铁素体增量
	    Frac_F_inc=Frac_F_ii-Frac_F_i
c         铁素体总量
          Frac_F=Frac_F+Frac_F_inc
	    STATEV(35)=Frac_F
c         残余奥氏体量
          Frac_A=1-Frac_F
		STATEV(34)=Frac_A 
c         求通过铁素体转变区时的平均冷却速率,为计算铁素体晶粒尺寸服务
          vcooling_total=ARRAY(37)
	    vcooling_total=vcooling_total+vcooling
	    INC_F=ARRAY(50)
          INC_F=INC_F+1
          vcooling_mean=vcooling_total/INC_F
	    STATEV(38)=vcooling_mean
c	    更新
	    STATEV(37)=vcooling_total
	    STATEV(50)=INC_F
	    INC_i=0
	    STATEV(48)=INC_i
c
c       3. 珠光体转变区
        ELSE IF (TEMPER2 .LT. Tp_s(vcooling) .AND. 
     1    (TEMPER2 .GE. Tp_f(vcooling))) THEN
c
	    CALL GETVRM('SDV',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,
	1    JMATYP,MATLAYO,LACCFLA)
C         导入上一时间步计算得到的珠光体总量
          Frac_P=ARRAY(36)
c         该时间步内铁素体总量STATEV(35)和平均冷却速度STATEV(38)没有值（默认为零）,必须从上一个时间步读取
          Frac_F=ARRAY(35)
	    STATEV(35)=Frac_F
	    vcooling_mean=ARRAY(38)
          STATEV(38)=vcooling_mean
c      
C         计算珠光体的增量
          Frac_P_ii=Vmax_p(vcooling)*(Tp_s(vcooling)-TEMPER2)/
     1    (Tp_s(vcooling)-Tp_f(vcooling))
	    Frac_P_i=ARRAY(40)
	    STATEV(40)=Frac_P_ii
C     	珠光体增量
	    Frac_P_inc=Frac_P_ii-Frac_P_i
c         珠光体总量
          Frac_P=Frac_P+Frac_P_inc
	    STATEV(36)=Frac_P
c         残余奥氏体量
          Frac_A=1-Frac_F-Frac_P
c         避免残余奥氏体量出现负数
	    IF (Frac_A .LT. 0) THEN
	        Frac_A=0
	    ENDIF
		STATEV(34)=Frac_A
c
c         计算通过珠光体转变区时的平均温度,为求珠光体片层距服务
          TEMPER2_total=ARRAY(49)
          TEMPER2_total=TEMPER2_total+TEMPER2
          INC_P=ARRAY(47)
	    INC_P=INC_P+1
          TEMPER2_P_MEAN=TEMPER2_total/INC_P
C         更新
          STATEV(49)=TEMPER2_total
	    STATEV(46)=TEMPER2_P_MEAN
          STATEV(47)=INC_P
	    INC_i=0
	    STATEV(48)=INC_i
C
c       4. 转变结束区
	  ELSE IF (TEMPER2 .LT. Tp_f(vcooling)) THEN
          Sign_TLowThanP=1
		STATEV(55)=Sign_TLowThanP

          CALL GETVRM('SDV',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,
	1    JMATYP,MATLAYO,LACCFLA)
C         得到前面计算的铁素体、珠光体、残余奥氏体份数
	    STATEV(34)=ARRAY(34)
      	Frac_A=STATEV(34)
	    STATEV(35)=ARRAY(35)
          Frac_F=STATEV(35)
	    STATEV(36)=ARRAY(36)
	    Frac_P=STATEV(36)
	    vcooling_mean=ARRAY(38)
	    TEMPER2_P_MEAN=ARRAY(46)
c         若还有残余奥氏体,则逐渐分配到珠光体中
	    IF (Frac_A .GT. 0) THEN
	       Frac_P=Frac_P+Frac_A*vcooling*0.8
	       Frac_A=Frac_A-Frac_A*vcooling*0.8
	       IF (Frac_A .LT. 0.001) THEN
                Frac_A=0
	       END IF
c            更新
             STATEV(34)=Frac_A
             STATEV(36)=Frac_P
	    END IF
c
C         如果残余奥氏体为零,则彻底转变结束
          IF (Frac_A .EQ. 0) THEN
	      INC_i=ARRAY(48)
c
c	      判断是不是彻底转变结束后的第一个时间步
	      IF (INC_i .EQ. 0) THEN
c	         铁素体晶粒尺寸
c              D_F=5.7*D_A**(0.46)*vcooling_mean**(-0.26)
c              D_F=(13-0.73*0.487**0.45)*D_A**0.3*vcooling_mean**(-0.15)
	         D_F=(22.6-57.0*0.48+(1.0+0)*vcooling_mean**(-0.5)+
	1         22.0*(1-exp(-0.015*D_A)))*1.5
c              残余应变对晶粒度的影响
	         D_F=D_F*(1-0.45*0.05**(0.5))
	         D_P=D_F*(Frac_P/Frac_F)**0.5
               ASTM1=(2.0/log10(2.0))*log10(254.0/
     1			 (D_F*Frac_F**0.5+D_P*Frac_P**0.5))+1.0
	         ASTM=INT(ASTM1)
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
	         STATEV(54)=ASTM
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
               IF ((ASTM1 .GE. ASTM) .AND. (ASTM1 .LT. (ASTM+0.25)))
     1			  THEN 
	         ASTM=ASTM
	         ELSEIF ((ASTM1 .GE. (ASTM+0.25)) .AND. 
     1			 (ASTM1 .LT. (ASTM+0.75))) THEN 
	         ASTM=ASTM+0.5
	         ELSEIF ((ASTM1 .GE. (ASTM+0.75)) .AND. 
     1			 (ASTM1 .LT. (ASTM+1.00))) THEN 
	         ASTM=ASTM+1.0
	         END IF
c
C              珠光体片层距
c	         S_P=0.018/(996-TEMPER2_P_MEAN)
               S_P=exp(-2.212+0.0514*1.27-0.0396*0.25+0.0967*0.083-
	1         0.002*0.23-0.4812*0.11-log10((Ae1-TEMPER2_P_MEAN)/Ae1))
c    
c              屈服强度
c	         YS=STATEV(5)**(1/3)*(35.4+58.5*1.4+17.4*D_F**(-0.5))+
c              1(1-STATEV(5)**(1/3))*(178.6+3.85*S_P**(-0.5))+
c              163.1*0.25+42*(0.0065)**0.5
c              YS=246+4.15*Frac_P*100+44.6*1.27+138*0.23+923*0.01+
c	         1 169*0+3754*0.006+14.9/(D_F**0.5)

	         YS=62.6+26.1*1.4+60.2*0.25+759*0.01+212.9*0.015+
     1			 3286.0*0.0065+10.0*(D_F/1000.0)**(-0.5)+20.0*
     1             log10(vcooling_mean)+700.0*0.1+7800.0*0.0065+90.0
c
c              拉伸强度
c	         TS=STATEV(5)**(1/3)*(246.4+1142.7*(0.0065)**0.5+
c	         118.17*D_F**(-0.5))+
c    1         (1-STATEV(5)**(1/3))*(719.2+3.54*S_P**(-0.5))
c              TS=492-3.38*Frac_P*100+246*1.27+277*0.23-2616*0.002+
c	1         723*0.01+246*0.25+6616*0.006+44.6/(D_F**0.5)
c	         TS=237+29*1.27+79*0.23+700*0.01+5369*0.006
c	1         +7.24*Frac_F*D_F**(-0.5)+500*(1-Frac_F)

               TS=164.9+634.7*0.35+53.6*1.4+99.7*0.25+651.9*0.01+
     1		    472.6*0.15+3339.4*0.0065+11.0*(D_F/1000.0)**(-0.5)+
     1            30.0*log10(vcooling_mean)+700.0*0.1+7800.0*0.0065-50.0
c
c              硬度
	         HV=(TS-80.00)/2.57
	         HB=(TS+20.00)/3.50
C
c              保存
               STATEV(41)=D_F
	         STATEV(51)=ASTM
	         STATEV(53)=ASTM1
               STATEV(42)=S_P
	         STATEV(43)=YS
	         STATEV(44)=TS
	         STATEV(45)=HV
	         STATEV(52)=HB
C    
	         INC_i=1
	         STATEV(48)=INC_i

	       ELSE
C            如果不是刚转变结束后的第一个时间步,晶粒度和机械性能继承上一步的值即可
               CALL GETVRM('SDV',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,
	1         JMATYP,MATLAYO,LACCFLA)

	         STATEV(41)=ARRAY(41)
	         STATEV(42)=ARRAY(42)
	         STATEV(43)=ARRAY(43)
	         STATEV(44)=ARRAY(44)
	         STATEV(45)=ARRAY(45)

	         STATEV(51)=ARRAY(51)
	         STATEV(52)=ARRAY(52)
	         STATEV(53)=ARRAY(53)
 
             END IF
C         如果没有彻底转变结束,残留奥氏体还没分配完
	    ELSE
c	       更新
             STATEV(34)=Frac_A
             STATEV(35)=Frac_F    
             STATEV(36)=Frac_P     
             STATEV(38)=vcooling_mean
	       STATEV(46)=TEMPER2_P_MEAN
	       INC_i=0
	       STATEV(48)=INC_i	
C
	    END IF
C
C       
	  END IF
C
	END IF 

c     与热处理加热相关的变量均归零
500   STATEV(61)=0
      STATEV(62)=0
      STATEV(63)=0
      STATEV(64)=0
	ENDIF

C-------------------------------------------------------------------------------------------------------------------------------------------------------

C     If error, write comment to .DAT file:
      IF(JRCD.NE.0)THEN
           WRITE(6,*) 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
           WRITE(6,*) 'REQUEST ERROR IN USDFLD FOR ELEMENT NUMBER ',
     1     NOEL,'INTEGRATION POINT NUMBER ',NPT
      ENDIF
C-------------------------------------------------------------------------------------------------------------------------------------------------------

      RETURN
      END




C
C
C
C
C
C    子函数1 插值定义铁素体、珠光体的开始、结束转变温度
C     T = (T1*V + (950-t1*V)*K) / (K+V)    K=(T2-T1)/(t2-t1)
C
      REAL FUNCTION Tf_s(vcooling)
	REAL vcooling, K, T2, T1, v_2, v_1
	IF (vcooling .LT. 0.01) THEN
      Tf_s=755
	ELSE IF (vcooling .LT. 0.05) THEN
      T2=755.0
	T1=750.0
	v_2=0.01
	v_1=0.05
	K=(T2-T1)/(v_2-v_1)
      Tf_s=T1+k*(vcooling-v_1)
	ELSE IF (vcooling .LE. 0.1) THEN
      T2=750.0
	T1=740.0
	v_2=0.05
	v_1=0.1
	K=(T2-T1)/(v_2-v_1)
      Tf_s=T1+k*(vcooling-v_1)
	END IF
	END
C
      REAL FUNCTION Tf_f(vcooling)
	REAL vcooling, K, T2, T1, v_2, v_1
	IF (vcooling .LT. 0.01) THEN
      Tf_f=695.0
	ELSE IF (vcooling .LT. 0.05) THEN
      T2=695.0
	T1=690.0
	v_2=0.01
	v_1=0.05
	K=(T2-T1)/(v_2-v_1)
      Tf_f=T1+k*(vcooling-v_1)
	ELSE IF (vcooling .LE. 0.1) THEN
      T2=690.0
	T1=680.0
	v_2=0.05
	v_1=0.1
	K=(T2-T1)/(v_2-v_1)
      Tf_f=T1+k*(vcooling-v_1)
	END IF
      END
C
      REAL FUNCTION Tp_s(vcooling)
	REAL vcooling, K, T2, T1, v_2, v_1
	IF (vcooling .LT. 0.01) THEN
      Tp_s=695
	ELSE IF (vcooling .LT. 0.05) THEN
      T2=695.0
	T1=690.0
	v_2=0.01
	v_1=0.05
	K=(T2-T1)/(v_2-v_1)
      Tp_s=T1+k*(vcooling-v_1)
	ELSE IF (vcooling .LE. 0.1) THEN
      T2=690.0
	T1=680.0
	v_2=0.05
	v_1=0.1
	K=(T2-T1)/(v_2-v_1)
      Tp_s=T1+k*(vcooling-v_1)
	END IF
	END
C
      REAL FUNCTION Tp_f(vcooling)
	REAL vcooling, K, T2, T1, v_2, v_1
	IF (vcooling .LT. 0.01) THEN
      Tp_f=575.0
	ELSE IF (vcooling .LT. 0.05) THEN
      T2=575.0
	T1=570.0
	v_2=0.01
	v_1=0.05
	K=(T2-T1)/(v_2-v_1)
      Tp_f=T1+k*(vcooling-v_1)
	ELSE IF (vcooling .LE. 0.1) THEN
      T2=570.0
	T1=560.0
	v_2=0.05
	v_1=0.1
	K=(T2-T1)/(v_2-v_1)
      Tp_f=T1+k*(vcooling-v_1)
	END IF
	END
C------------------------------------------------
C
c    子函数2  定义铁素体、珠光体在不同冷速下的最大转变量
C        MAXIMUM VOLUME OF FERRITE
      REAL FUNCTION Vmax_f(vcooling)
	REAL vcooling, K, VOL2, VOL1, v_2, v_1
      IF (vcooling .LT. 0.01) THEN
      Vmax_f=0.44
	ELSE IF (vcooling .LT. 0.05) THEN
	VOL2=0.44
	VOL1=0.41
	v_2=0.01
	v_1=0.05
	K=(VOL2-VOL1)/(v_2-v_1)
      Vmax_f=VOL1+k*(vcooling-v_1)
      ELSE IF (vcooling .LE. 0.1) THEN
	VOL2=0.41
	VOL1=0.34
	v_2=0.05
	v_1=0.1
	K=(VOL2-VOL1)/(v_2-v_1)
      Vmax_f=VOL1+k*(vcooling-v_1)
      END IF
	END
C
C        MAXIMUM VOLUME OF PERLITE
      REAL FUNCTION Vmax_p(vcooling)
	REAL vcooling, K, VOL2, VOL1, v_2, v_1
      IF (vcooling .LT. 0.01) THEN
      Vmax_p=0.56
	ELSE IF (vcooling .LT. 0.05) THEN
	VOL2=0.56
	VOL1=0.59
	v_2=0.01
	v_1=0.05
	K=(VOL2-VOL1)/(v_2-v_1)
      Vmax_p=VOL1+k*(vcooling-v_1)
	ELSE IF (vcooling .LE. 0.1) THEN
	VOL2=0.59
	VOL1=0.66
	v_2=0.05
	v_1=0.1
	K=(VOL2-VOL1)/(v_2-v_1)
      Vmax_p=VOL1+k*(vcooling-v_1)
      END IF
	END
C---------------------------------------------------
