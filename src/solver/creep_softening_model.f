!
!     AESim_FM solver
!     creep_softening_model.f: creep / aging-softening core model
!
!     Copyright (C) 2026 AESim_FM
!
!     MODEL_TYPE=1: Norton power-law creep
!     MODEL_TYPE=2: Historical user CREEP formula (fixed GA/GAMMA)
!
!     SDV allocation:
!       powder-coupled porous model: grouped porous module layout
!       independent forge/softening model: SDV44-SDV53 (forge layout)
!       +0 = CREEP_EQ          cumulative equivalent creep strain
!       +1 = CREEP_RATE        current equivalent creep strain rate (1/s)
!       +2 = CREEP_DINC        current increment equivalent creep strain
!       +3 = CREEP_QTILD       pre-relaxation equivalent stress (Pa)
!       +4 = CREEP_PRESSURE    pressure used by creep model (Pa)
!       +5 = SOFTENING_FACTOR  aging softening / relaxation factor
!       +6 = RELAXED_STRESS_EQ relaxed equivalent stress (Pa)
!       +7 = CREEP_ACTIVE_FLAG creep/softening active flag
!       +8 = CREEP_TEMP_K      temperature used in model (K)
!       +9 = CREEP_TIME_HOLD   accumulated hold / relaxation time (s)
!
      subroutine creep_softening_model(stress,statev,ddsdde,
     &     sse,spd,scd,rpl,ddsddt,drplde,drpldt,
     &     stran,dstran,time,dtime,temp,dtemp,temp0,
     &     predef,dpred,cmname,ndi,nshr,ntens,nstatv,
     &     elconloc,plconloc,mpconloc,coords,drot,pnewdt,
     &     celent,dfgrd0,dfgrd1,noel,npt,layer,kspt,jstep,kinc)
!
      implicit none
!
!     --- UMAT arguments ---
      integer ntens,nshr,ndi,nstatv,noel,npt,layer,kspt,jstep(4),kinc
      real*8 sse,spd,scd,rpl,drpldt,dtime,temp,dtemp,temp0,pnewdt,celent
      real*8 stress(6),statev(nstatv),ddsdde(6,6)
      real*8 ddsddt(6),drplde(6)
      real*8 stran(6),dstran(6),time(2),predef(1),dpred(1)
      real*8 coords(3),drot(3,3),dfgrd0(3,3),dfgrd1(3,3)
      real*8 elconloc(*),plconloc(*),mpconloc(*)
      character*80 cmname
!
!     --- common block for creep parameters ---
      real*8 creepcon
      integer creep_nmat_active,creep_powder_coupled(100)
      common /creepdata/ creepcon(16,100),
     &  creep_nmat_active,creep_powder_coupled
!
!     --- local variables ---
      integer enable,model_type,i,j,nmat_loc,density_coupling
      real*8 A_param,B_param,N_param,GA_param,ALPHA_param
      real*8 BETA_param,RV_param,time_unit,Q_act,ref_temp
      real*8 min_stress,max_dinc,output_mode
      real*8 qtild,pressure,qtild_trial,pressure_trial
      real*8 tempk,time_step,time_hour
      real*8 dcreep_eq,A1,B1,N1,qtild_kpa,qtild_mpa
      real*8 creep_rate,softening_factor,relaxed_stress
      real*8 rho_rel,rho_coupling_factor,rho_eps
      integer powder_coupled,offset_sdv
      integer do_elastic_predict
      real*8 R_gas,EMOD,ENU,EG,ELAMB,EBULK3
      parameter (R_gas=8.314d0)
      real*8 dev(6),dcreep_dev(6)
      real*8 zero,one,two,three,half,twothirds
      parameter (zero=0.d0, one=1.d0, two=2.d0, three=3.d0)
      parameter (half=0.5d0, twothirds=2.d0/3.d0)
!
!     --- locate material number from common block ---
      nmat_loc=creep_nmat_active
      if(nmat_loc.lt.1.or.nmat_loc.gt.100) nmat_loc=1
!
!     --- read parameters ---
      enable     = int(creepcon(1,nmat_loc))
      model_type = int(creepcon(2,nmat_loc))
      A_param    = creepcon(3,nmat_loc)
      B_param    = creepcon(4,nmat_loc)
      N_param    = creepcon(5,nmat_loc)
      GA_param   = creepcon(6,nmat_loc)
      ALPHA_param= creepcon(7,nmat_loc)
      BETA_param = creepcon(8,nmat_loc)
      RV_param   = creepcon(9,nmat_loc)
      time_unit  = creepcon(10,nmat_loc)
      Q_act      = creepcon(11,nmat_loc)
      ref_temp   = creepcon(12,nmat_loc)
      density_coupling = int(creepcon(13,nmat_loc))
      min_stress = creepcon(14,nmat_loc)
      max_dinc   = creepcon(15,nmat_loc)
      output_mode= int(creepcon(16,nmat_loc))
!
!     --- elastic constants (temperature-interpolated by caller) ---
      EMOD=elconloc(1)
      ENU=elconloc(2)
      if(ENU.ge.0.5d0) ENU=0.499d0
      EG=EMOD/(two*(one+ENU))
      ELAMB=EMOD*ENU/((one+ENU)*(one-two*ENU))
      EBULK3=EMOD/(one-two*ENU)
!
!     --- default values for zero parameters ---
      if(time_unit.le.zero) time_unit=3600.d0
      if(min_stress.le.zero) min_stress=1.d3
      if(max_dinc.le.zero) max_dinc=1.d-2
!
!     --- powder coupling mode ---
      powder_coupled=creep_powder_coupled(nmat_loc)
      rho_eps=1.d-6
      if(powder_coupled.eq.1) then
         rho_rel=statev(1)
         if(rho_rel.lt.0.1d0) rho_rel=0.1d0
         if(rho_rel.gt.1.0d0) rho_rel=1.0d0
!        creep accelerates at lower relative density: factor = 1/(1-rho)
         rho_coupling_factor=1.d0/(1.d0-rho_rel+rho_eps)
         if(rho_coupling_factor.gt.100.d0) rho_coupling_factor=100.d0
         offset_sdv=3
      else
         rho_rel=1.0d0
         rho_coupling_factor=1.0d0
         offset_sdv=44
      endif
      do_elastic_predict=1
      if(powder_coupled.eq.1) do_elastic_predict=0
!
!
!     --- build elastic stiffness DDSDDE ---
!     Independent creep materials own the elastic predictor/tangent.
!     Powder-coupled materials must keep the metal_powder tangent.
      if(do_elastic_predict.eq.1) then
        do i=1,6
          do j=1,6
            ddsdde(i,j)=zero
          enddo
        enddo
        do i=1,3
          do j=1,3
            ddsdde(i,j)=ELAMB
          enddo
          ddsdde(i,i)=ELAMB+two*EG
        enddo
        do i=4,6
          ddsdde(i,i)=EG
        enddo
      endif
!
!     --- elastic stress update ---
!     Independent creep materials need an elastic predictor. In
!     powder-coupled mode metal_powder has already updated stress/tangent.
      if(do_elastic_predict.eq.1) then
        do i=1,6
          do j=1,6
            stress(i)=stress(i)+ddsdde(i,j)*dstran(j)
          enddo
        enddo
      endif
!
!     --- guard: disabled ---
      if(enable.eq.0) then
        if(powder_coupled.eq.1) then
          statev(22)=zero
        else
          statev(offset_sdv+7)=zero
        endif
        return
      endif
!
!     --- compute Mises stress and pressure ---
      pressure=(stress(1)+stress(2)+stress(3))/three
      dev(1)=stress(1)-pressure
      dev(2)=stress(2)-pressure
      dev(3)=stress(3)-pressure
      dev(4)=stress(4)
      dev(5)=stress(5)
      dev(6)=stress(6)
      qtild=dev(1)**2+dev(2)**2+dev(3)**2
     &     +two*(dev(4)**2+dev(5)**2+dev(6)**2)
      qtild=sqrt(1.5d0*qtild)
      if(qtild.lt.min_stress) qtild=min_stress
      qtild_trial=qtild
      pressure_trial=pressure
!
!     --- temperature: Celsius to Kelvin ---
      tempk=temp+273.15d0
      if(tempk.le.zero) tempk=273.15d0
!
!     --- time ---
      if(dtime.le.zero) then
        if(powder_coupled.eq.1) then
          statev(22)=zero
        else
          statev(offset_sdv+7)=zero
        endif
        return
      endif
      time_step=time(1)
      time_hour=dtime/time_unit
!
!     --- compute creep increment ---
      dcreep_eq=zero
!
      if(model_type.eq.1) then
!       Norton power-law: dcreep = A * (sigma/1MPa)^N * dt_hour
        qtild_mpa=qtild/1.d6
        dcreep_eq=A_param * (qtild_mpa**N_param) * time_hour
!
      elseif(model_type.eq.2) then
!       Historical user CREEP formula (fixed: GA used, not GAMMA)
        qtild_kpa=qtild/1.d3
!
        if((N_param-one-ALPHA_param).eq.zero) then
          dcreep_eq=max_dinc
        else
          A1=A_param * (qtild_kpa**(N_param-GA_param))
     &       / (B_param * (N_param-one-ALPHA_param))
          B1=B_param * (one+ALPHA_param) * (qtild_kpa**GA_param)
          N1=(one+ALPHA_param-N_param)/(one+ALPHA_param)
!
          if((one-B1*time_step).le.zero) then
            dcreep_eq=max_dinc
          else
            dcreep_eq=-A1*B1*N1
     &           *((one-B1*time_step)**(N1-one))
     &           *time_hour
            if(dcreep_eq.lt.zero) dcreep_eq=abs(dcreep_eq)
          endif
        endif
      endif
!
!     --- Arrhenius temperature correction ---
      if(Q_act.gt.zero) then
        dcreep_eq=dcreep_eq
     &       *exp(-Q_act/(R_gas*tempk))
      endif
!
!     --- numerical protection ---
      if(dcreep_eq.gt.max_dinc) dcreep_eq=max_dinc
      if(dcreep_eq.lt.zero) dcreep_eq=zero
!
!     --- powder density coupling ---
      if(powder_coupled.eq.1) then
         dcreep_eq=dcreep_eq*rho_coupling_factor
         if(dcreep_eq.gt.max_dinc) dcreep_eq=max_dinc
      endif
!
!     --- compute creep rate ---
      creep_rate=zero
      if(dtime.gt.zero) creep_rate=dcreep_eq/dtime
!
!     --- creep strain correction (deviatoric flow rule) ---
      do i=1,6
        dcreep_dev(i)=zero
      enddo
      if(dcreep_eq.gt.zero) then
        do i=1,6
          dcreep_dev(i)=1.5d0*dcreep_eq*dev(i)/qtild
        enddo
!       subtract creep strain from stress
        do i=1,6
          do j=1,6
            stress(i)=stress(i)-ddsdde(i,j)*dcreep_dev(j)
          enddo
        enddo
      endif
!
!     --- recompute Mises after relaxation ---
      pressure=(stress(1)+stress(2)+stress(3))/three
      qtild=(stress(1)-pressure)**2+(stress(2)-pressure)**2
     &     +(stress(3)-pressure)**2
     &     +two*(stress(4)**2+stress(5)**2+stress(6)**2)
      qtild=sqrt(1.5d0*qtild)
      if(qtild.lt.min_stress) qtild=min_stress
!
!     --- update state variables ---
!       independent mode: SDV44-SDV53.
!       powder-coupled porous mode keeps user-facing groups compact:
!       SDV3-5 creep strain, SDV9-11 creep stress, SDV21-24 aux.
      if(powder_coupled.eq.1) then
        statev(3)=statev(3)+dcreep_eq
        statev(4)=creep_rate
        statev(5)=dcreep_eq
        statev(9)=qtild_trial
        statev(10)=pressure_trial
      else
        statev(offset_sdv)=statev(offset_sdv)+dcreep_eq
        statev(offset_sdv+1)=creep_rate
        statev(offset_sdv+2)=dcreep_eq
        statev(offset_sdv+3)=qtild_trial
        statev(offset_sdv+4)=pressure_trial
      endif
!
!     --- softening factor ---
      softening_factor=one
      if(powder_coupled.eq.1) then
        if(statev(3).gt.zero .and. model_type.eq.2) then
          softening_factor=exp(-statev(3))
          if(softening_factor.lt.0.01d0) softening_factor=0.01d0
        endif
        statev(21)=softening_factor
      else
        if(statev(offset_sdv).gt.zero .and. model_type.eq.2) then
          softening_factor=exp(-statev(offset_sdv))
          if(softening_factor.lt.0.01d0) softening_factor=0.01d0
        endif
        statev(offset_sdv+5)=softening_factor
      endif
!
!     --- relaxed equivalent stress ---
      relaxed_stress=qtild*softening_factor
      if(powder_coupled.eq.1) then
        statev(11)=relaxed_stress
        statev(22)=one
        statev(23)=tempk
        statev(24)=statev(24)+dtime
      else
        statev(offset_sdv+6)=relaxed_stress
        statev(offset_sdv+7)=one
        statev(offset_sdv+8)=tempk
        statev(offset_sdv+9)=statev(offset_sdv+9)+dtime
      endif
!
!     --- creep dissipation ---
      scd=scd+dcreep_eq*qtild
!
      return
      end
