!--------------------------------------------------------------------------------------------------
!> @author Haiming Zhang, Shanghai Jiao Tong University
!> @brief material subroutine for phenomenological crystal plasticity formulation using a powerlaw
!> fitting (without consideration of twinning and non-Schmid effect)
!--------------------------------------------------------------------------------------------------
module plastic_phenopowerlawclassic
  use prec
  use constants
  use material

  implicit none
  private

  type, extends(tPlastic_Params) :: tParameters
    real(pReal) :: &
      dot_gamma_0_sl = 1.0_pReal, &                                                                 !< reference shear strain rate for slip
      n_sl           = 1.0_pReal                                                                    !< stress exponent for slip    real(pReal), allocatable, dimension(:) :: &
    real(pReal), allocatable, dimension(:) :: &
      xi_inf_sl, &                                                                                  !< maximum critical shear stress for slip
      a_sl
    real(pReal), allocatable, dimension(:,:,:) :: &
      P_nS_pos, &
      P_nS_neg
    real(pReal), allocatable, dimension(:,:,:,:,:) :: &
      PP_pos, &
      PP_neg
    logical :: &
      sliprate_required_in_postResult = .false., &
      nonSchmidActive = .false., &
      nonlocal = .false.
    real(pReal),   dimension(:,:),   allocatable :: &
      slip_dir, &
      slip_tangent
  end type tParameters

  type :: tPhenopowerlawclassicState
    real(pReal), pointer, dimension(:,:) :: &
      xi_sl, &
      gamma_sl
  end type tPhenopowerlawclassicState

!--------------------------------------------------------------------------------------------------
! containers for parameters and state
  type(tParameters), allocatable, dimension(:) :: param
  type(tPhenopowerlawclassicState), allocatable, dimension(:) :: &
    dotState, &
    state
  type(tPlastic_auxState), allocatable, dimension(:) :: auxState

  public :: &
    plastic_phenopowerlawclassic_init, &
    plastic_phenopowerlawclassic_LpAndItsTangent, &
    plastic_phenopowerlawclassic_dotState, &
    plastic_phenopowerlawclassic_results

contains


!--------------------------------------------------------------------------------------------------
!> @brief Perform module initialization.
!> @details reads in material parameters, allocates arrays, and does sanity checks
!--------------------------------------------------------------------------------------------------
subroutine plastic_phenopowerlawclassic_init()
  use IO, only: &
    IO_error
  use config, only: &
    config_phase
  use math, only: &
    math_expand
  use lattice

  integer(kind(undefined_ID)) :: outputID
  integer :: ph, i, size_, idx_s, idx_e, Nmembers, Nfamilies_sl
  character(len=pStringLen) :: extmsg = ''
  character(len=pStringLen), dimension(:), allocatable :: outputs
  type :: tParasLocal
    real(pReal) ::  &
      atol_xi    = 0.0_pReal, &
      atol_gamma = 1.0e-6_pReal, &
      alpha, &                                                                                      !< required for gnd enhanced
      miu                                                                                           !< required for gnd enhanced
    real(pReal), dimension(:), allocatable :: &
      h_0_sl_sl, &                                                                                  !< reference hardening slip - slip
      xi_0_sl, &                                                                                    !< initial critical shear stress for slip (input parameter, per family)
      b_sl, &                                                                                       !< required for gnd enhanced
      a
  end type
  type(tParasLocal), dimension(:), allocatable :: prm_loc


  write(6,'(/,a)')   ' <<<+-  constitutive_plastic_phenopowerlaw_classic init  -+>>>'
  write(6,*) 'Compiled on ', __DATE__,' at ',__TIME__; write(6,*); flush(6)

  allocate(param(material_Nphase), prm_loc(material_Nphase), auxState(material_Nphase), &
           state(material_Nphase), dotState(material_Nphase))

  phaseScan: do ph = 1, material_Nphase
    if (phase_plastic(ph) /= PLASTICITY_PHENOPOWERLAW2_ID) cycle phaseScan

    Nmembers = count(matGr%ph == ph)                                                                ! put it here, very important number of cos containing my ph
    associate(prm => param(ph), prmloc => prm_loc(ph), pl => config_phase(ph), &
              stt => state(ph), dot => dotState(ph))

    if (pl%keyExists('/dfc/')) material_DFC_specified = .true.

    prm%Nslip = lattice_consts(ph)%NslipSystem; Nfamilies_sl = size(prm%Nslip,1)                        ! maximum number of slip families according to lattice type of current ph
    prm%sum_N_sl = sum(prm%Nslip)                                                                   ! how many slip systems altogether

    ! plastic_phenopowerlawclassic doesnot support twinning. If twinning is considered, use plastic_phenopowerlaw
    if (sum(lattice_consts(ph)%NtwinSystem) > 0 ) call IO_error(203, ext_msg = 'phenopowerlaw_classic')
    ! slip related parameters

    ! Schmid tensor
    prm%P_sl  = lattice_SchmidMatrix_slip(prm%sum_N_sl, prm%Nslip, ph)

    ! non-Schmid effect
    if (lattice_consts(ph)%structure == 'cI') then
      prmloc%a = pl%getFloats('a_nonSchmid', defaultVal=emptyRealArray)
      if(size(prmloc%a) > 0) prm%nonSchmidActive = .true.
      prm%P_nS_pos = lattice_nonSchmidMatrix(prm%sum_N_sl, prm%Nslip,prmloc%a,+1, ph)
      prm%P_nS_neg = lattice_nonSchmidMatrix(prm%sum_N_sl, prm%Nslip,prmloc%a,-1, ph)
    else
      prm%P_nS_pos = prm%P_sl
      prm%P_nS_neg = prm%P_sl
    endif

    prm%PP_pos = math_concatenate3333(prm%P_sl, prm%P_nS_pos, prm%sum_N_sl)
    prm%PP_neg = math_concatenate3333(prm%P_sl, prm%P_nS_neg, prm%sum_N_sl)

    ! interaction matrix
    prm%h_sl_sl = lattice_interaction_slXsl(prm%sum_N_sl, prm%Nslip, pl%getFloats('h_sl-sl'), ph)

    ! parameters depending on number of slip families
    prmloc%xi_0_sl     = pl%getFloats('xi_0_sl',   requiredSize=Nfamilies_sl)
    prm%xi_inf_sl      = pl%getFloats('xi_inf_sl', requiredSize=Nfamilies_sl)
    prm%a_sl           = pl%getFloats('a_sl',      requiredSize=Nfamilies_sl)
    prmloc%h_0_sl_sl   = pl%getFloats('h_0_sl-sl', requiredSize=Nfamilies_sl)
    prm%dot_gamma_0_sl = pl%getFloat ('dot_gamma_0_sl')
    prm%n_sl           = pl%getFloat ('n_sl')

    ! expand: family => system
    prmloc%xi_0_sl     = math_expand(prmloc%xi_0_sl,   prm%Nslip)
    prm%xi_inf_sl      = math_expand(prm%xi_inf_sl,    prm%Nslip)
    prm%a_sl           = math_expand(prm%a_sl,         prm%Nslip)
    prmloc%h_0_sl_sl   = math_expand(prmloc%h_0_sl_sl, prm%Nslip)

    ! sanity checks
    if (    prm%dot_gamma_0_sl <= 0.0_pReal)       extmsg = trim(extmsg)//'@dot_gamma_0_sl (>0.0) '
    if (    prm%n_sl           <= 0.0_pReal)       extmsg = trim(extmsg)//'@n_sl (>0.0) '
    if (any(prm%a_sl           <= 0.0_pReal))      extmsg = trim(extmsg)//'@a_sl (>0.0) '
    if (any(prmloc%xi_0_sl     <= 0.0_pReal))      extmsg = trim(extmsg)//'@xi_0_sl (>0.0) '
    if (any(prm%xi_inf_sl      <  prmloc%xi_0_sl)) extmsg = trim(extmsg)//'@xi_inf_sl (>=xi_0_sl) '
    if (any(prmloc%h_0_sl_sl   < 0.0_pReal))       extmsg = trim(extmsg)//"@h_0_sl-sl (>=0.0) "
    forall (i = 1:prm%sum_N_sl)
      prm%h_sl_sl(:,i) = prmloc%h_0_sl_sl*prm%h_sl_sl(:,i)
    end forall


    ! read material parameters of Hall-Petch effect
    call material_get_hp_paras(ph, prm%n_hp, prm%k_hp, prm%m_hp, prm%c_hp, prm%xi_0_hp)

    ! output pararameters
    outputs = pl%getStrings('(output)', defaultVal=emptyStringArray)
    allocate(prm%outputID(0))

    do i = 1, size(outputs)
      size_ = 0
      select case(outputs(i))
        case ('crss_sl')                          ! resistance of dislocation movement (critical shear stress)
          outputID = crss_sl_ID
          size_    = prm%sum_N_sl
        case ('gamma_sl')                         ! accumulated shear strains due to dislocation slip
          outputID = gamma_sl_ID
          size_    = prm%sum_N_sl
        case ('dot_gamma_sl')                     ! shear strain rates due to dislocation slip
          outputID = dot_gamma_sl_ID
          size_    = prm%sum_N_sl
          prm%sliprate_required_in_postResult = .true.
        case ('rss_sl')                           ! resolved shear stress of slip system
          outputID = rss_sl_ID
          size_    = prm%sum_N_sl
        case ('totalshear')                       ! total shear strain due to slip
          outputID = totalshear_ID
          size_    = merge(1, 0, prm%sum_N_sl > 0)
        case ('taylorfactor')                     ! Taylor factor
          outputID = M_ID
          size_    = merge(1, 0, prm%sum_N_sl > 0)
          prm%sliprate_required_in_postResult = .true.
        case ('n_sl')                             ! the number of activated slip systems
          outputID = N_sl_ID
          size_    = merge(1, 0, prm%sum_N_sl > 0)
          prm%sliprate_required_in_postResult = .true.
        case default
      end select

      if (size_ > 0) then
        phase_outputs(ph)%pl_ou_labels(i) = outputs(i)
        phase_outputs(ph)%pl_ou_size(i)   = size_
        prm%outputID = [prm%outputID, outputID]
        prm%Noutput  = prm%Noutput + 1
      endif
    enddo
    phase_outputs(ph)%pl_name = 'phenopowerlaw_classic'

    prm%sizeResults = sum(phase_outputs(ph)%pl_ou_size)

    ! allocate state arrays
    size_ = 2 * prm%sum_N_sl

    call phase_allocateState_pl(plasticState(ph), Nmembers, size_, &
                                prm%sizeResults, prm%sum_N_sl, 0, 0)


    ! parameters independent of number of slip/twin systems
    prmloc%atol_xi   = pl%getFloat('atol_xi',    defaultVal = 1.0_pReal)
    prmloc%atol_gamma= pl%getFloat('atol_gamma', defaultVal = 1.0e-6_pReal)
    if(prmloc%atol_xi    < 0.0_pReal) extmsg = trim(extmsg)//'@atol_xi(> 0.0) '
    if(prmloc%atol_gamma < 0.0_pReal) extmsg = trim(extmsg)//'@atol_gamma(> 0.0) '

    ! locally defined state aliases and initialization of state0 and atol
    idx_s = 1;          idx_e = prm%sum_N_sl
    stt%gamma_sl => plasticState(ph)%state   (idx_s:idx_e,:)
    dot%gamma_sl => plasticState(ph)%dotState(idx_s:idx_e,:)
    plasticState(ph)%atol(idx_s:idx_e) = prmloc%atol_gamma

    ! global alias
    plasticState(ph)%shearRate => plasticState(ph)%dotState(idx_s:idx_e,:)

    idx_s = idx_e + 1; idx_e = idx_e + prm%sum_N_sl
    stt%xi_sl => plasticState(ph)%state   (idx_s:idx_e,:)
    dot%xi_sl => plasticState(ph)%dotState(idx_s:idx_e,:)
    plasticState(ph)%atol(idx_s:idx_e) = prmloc%atol_xi
    stt%xi_sl =  spread(prmloc%xi_0_sl, 2, Nmembers)

    call material_allocate_auxState(prm%sum_N_sl, Nmembers, auxState(ph), &
                                    phase_outputs(ph)%pl_ou_labels)

#ifdef Abaqus_std
    plasticState(ph)%state0 = plasticState(ph)%state
#endif

    end associate

    ! exit if any parameter is out of range
    if (extmsg /= '') call IO_error(211, el=ph, ext_msg=trim(extmsg)//'(phenopowerlaw_classic)')

  enddo phaseScan

end subroutine plastic_phenopowerlawclassic_init


!--------------------------------------------------------------------------------------------------
!> @brief Calculate plastic velocity gradient and its tangent.
!> @details asummes that deformation by dislocation glide
!--------------------------------------------------------------------------------------------------
subroutine plastic_phenopowerlawclassic_LpAndItsTangent(Lp,dLp_dMp,Mp,T,ph,en,grainID)

  real(pReal), dimension(3,3),     intent(out) :: &
    Lp                                                                                              !< plastic velocity gradient
  real(pReal), dimension(3,3,3,3), intent(out) :: &
    dLp_dMp                                                                                         !< derivative of Lp with respect to Mp as 4th order tensor
  real(pReal), dimension(3,3),      intent(in) :: &
    Mp                                                                                              !< Mandel stress
  real(pReal), intent(in) :: T                                                                      !< temperature, not used
  integer,     intent(in) :: ph, en, grainID
  integer :: i
  real(pReal), dimension(param(ph)%sum_N_sl) :: &
    dot_gamma_sl_pos,dot_gamma_sl_neg, xi_sl, gdot_sl, &
    ddot_gamma_dtau_sl_pos,ddot_gamma_dtau_sl_neg


  Lp = 0.0_pReal; dLp_dMp = 0.0_pReal
  associate(prm => param(ph), stt => state(ph))

  ! Hall-Petch enhanced
  xi_sl = stt%xi_sl(:,en) + auxState(ph)%xi_0_hp(en)
  call kinetics_sl(Mp,ph,en,xi_sl,dot_gamma_sl_pos,dot_gamma_sl_neg, &
                   ddot_gamma_dtau_sl_pos,ddot_gamma_dtau_sl_neg)

  gdot_sl = dot_gamma_sl_pos + dot_gamma_sl_neg
  do i = 1, prm%sum_N_sl
    if(abs(gdot_sl(i)) > tol_math_check2) then
      Lp = Lp + gdot_sl(i)*prm%P_sl(1:3,1:3,i)
      dLp_dMp = dLp_dMp + ddot_gamma_dtau_sl_pos(i) * prm%PP_pos(:,:,:,:,i) &
                        + ddot_gamma_dtau_sl_neg(i) * prm%PP_neg(:,:,:,:,i)
    endif
  enddo

  end associate

end subroutine plastic_phenopowerlawclassic_LpAndItsTangent


!--------------------------------------------------------------------------------------------------
!> @brief Calculate the rate of change of microstructure.
!--------------------------------------------------------------------------------------------------
subroutine plastic_phenopowerlawclassic_dotState(Mp,T,ph,en,grainID)

  real(pReal), dimension(3,3),  intent(in) :: &
    Mp                                                                                             !< 2nd Piola Kirchhoff stress tensor in Mandel notation
  integer, intent(in) :: ph, en, grainID
  real(pReal), intent(in) :: T                                                                     !< temperature, not used
  real(pReal) :: hp_ehanced_modulus

  real(pReal), dimension(param(ph)%sum_N_sl) :: &
    dot_gamma_sl_pos,dot_gamma_sl_neg, rss_gdot_sl, one_RSSratio, xi_sl


  associate(prm => param(ph), stt => state(ph), dot => dotState(ph), aux => auxState(ph))

  ! Hall-Petch effect
  if ( aux%xi_0_hp(en) < 0.0_pReal ) & ! uninitialized
    aux%xi_0_hp(en) = material_HP_Strengthen(prm%k_hp, prm%n_hp,  prm%xi_0_hp, grainID)

  xi_sl = stt%xi_sl(:,en) + aux%xi_0_hp(en)

  ! shear rates
  call kinetics_sl(Mp,ph,en,xi_sl,dot_gamma_sl_pos,dot_gamma_sl_neg)

  dot%gamma_sl(:,en) = abs(dot_gamma_sl_pos+dot_gamma_sl_neg)

  ! Calculate the slip resistance
  one_RSSratio   = 1.0_pReal - xi_sl / (prm%xi_inf_sl + aux%xi_0_hp(en))
  where (one_RSSratio > 0.0_pReal)
    rss_gdot_sl = one_RSSratio**prm%a_sl
  else where
    rss_gdot_sl = 0.0_pReal
  end where

  ! hardening
  hp_ehanced_modulus = material_HP_enhanceModulus(prm%m_hp, prm%c_hp, prm%d_avg, grainID)        !< calculate the overall hardening based on above
  dot%xi_sl(:,en) = matmul(hp_ehanced_modulus*prm%h_sl_sl, rss_gdot_sl*dot%gamma_sl(:,en))

  end associate

end subroutine plastic_phenopowerlawclassic_dotState


!--------------------------------------------------------------------------------------------------
!> @brief return array of constitutive results
!--------------------------------------------------------------------------------------------------
subroutine plastic_phenopowerlawclassic_results(Mp,Lp,T,ph,en,grainID,postResults)
  use math, only: &
    math_equivStrain33

  real(pReal), dimension(3,3), intent(in) :: Mp, Lp                                                 !< 2nd Piola Kirchhoff stress tensor in Mandel notation
  integer,     intent(in) :: ph,en,grainID
  real(pReal), intent(in) :: T                                                                      !< temperature, not used
  real(pReal), dimension(param(ph)%sizeResults), intent(out) :: postResults
  integer :: ns,c,i,ou
  real(pReal) :: aux1


  associate(prm => param(ph), stt => state(ph), dot => dotState(ph))
  ns = prm%sum_N_sl

  postResults = 0.0_pReal

  c = 0
  do ou = 1, prm%Noutput
    select case(prm%outputID(ou))
      case (crss_sl_ID)                 ! resistance of dislocation movement (critical shear stress)
        postResults(c+1:c+ns) = (stt%xi_sl(:,en) + auxState(ph)%xi_0_hp(en))*stressunit
        c = c + ns

      case (gamma_sl_ID)                ! accumulated shear strains due to dislocation slip
        postResults(c+1:c+ns) = stt%gamma_sl(:,en)
        c = c + ns

      case (dot_gamma_sl_ID)           ! shear strain rates due to dislocation slip
        postResults(c+1:c+ns) = dot%gamma_sl(:,en)
        c = c + ns

      case (rss_sl_ID)                 ! resolved shear stress of slip systems
        do i = 1, ns
          postResults(c+i) = sum(Mp * prm%P_sl(1:3,1:3,i))*stressunit
        enddo
        c = c + ns

      case (totalshear_ID)              ! total shear strain due to slip
        postResults(c+1) = sum(stt%gamma_sl(:,en))
        c = c + 1

      case (M_ID)                       ! Taylor factor
        aux1 = math_equivStrain33(Lp)
        if (aux1 > tol_math_check2) postResults(c+1) = sum(dot%gamma_sl(:,en))/aux1
        c = c + 1

      case (N_sl_ID)                    ! the number of activated slip systems
        i = count( dot%gamma_sl(:,en)/max(maxval(dot%gamma_sl(:,en)), tol_math_check2) > 0.05_pReal)
        postResults(c+1) = real(i, pReal)
        c = c + 1

    end select
  enddo

  end associate

end subroutine plastic_phenopowerlawclassic_results


!--------------------------------------------------------------------------------------------------
!> @brief Calculate shear rates on slip systems and their derivatives with respect to resolved
!         stress.
!> @details Derivatives are calculated only optionally.
! NOTE: Against the common convention, the result (i.e. intent(out)) variables are the last to
! have the optional arguments at the end.
!--------------------------------------------------------------------------------------------------
pure subroutine kinetics_sl(Mp,ph,en, xi_sl, dot_gamma_sl_pos,dot_gamma_sl_neg,&
                            ddot_gamma_dtau_sl_pos,ddot_gamma_dtau_sl_neg)

  real(pReal), dimension(3,3),  intent(in) :: &
    Mp                                                                                              !< Mandel stress
  integer,     intent(in) :: ph, en

  real(pReal), intent(in), dimension(param(ph)%sum_N_sl) :: &
    xi_sl
  real(pReal), intent(out), dimension(param(ph)%sum_N_sl) :: &
    dot_gamma_sl_pos, &
    dot_gamma_sl_neg
  real(pReal), intent(out), optional, dimension(param(ph)%sum_N_sl) :: &
    ddot_gamma_dtau_sl_pos, &
    ddot_gamma_dtau_sl_neg

  real(pReal), dimension(param(ph)%sum_N_sl) :: &
    tau_sl_pos, tau_sl_neg
  integer :: i


  associate(prm => param(ph))

  forall (i = 1 : prm%sum_N_sl)
    tau_sl_pos(i) = sum(Mp * prm%P_nS_pos(1:3,1:3,i))
  end forall

  if (prm%nonSchmidActive) then
    forall (i = 1 : prm%sum_N_sl)
      tau_sl_neg(i) = sum(Mp * prm%P_nS_neg(1:3,1:3,i))
    end forall
  else
    tau_sl_neg = 0.0_pReal
  endif


  where(dNeq0(tau_sl_pos))
    dot_gamma_sl_pos = prm%dot_gamma_0_sl * merge(0.5_pReal,1.0_pReal, prm%nonSchmidActive) &     ! 1/2 if non-Schmid active
                     * sign(abs(tau_sl_pos/xi_sl)**prm%n_sl, tau_sl_pos)
  else where
    dot_gamma_sl_pos = 0.0_pReal
  end where

  where(dNeq0(tau_sl_neg))
    dot_gamma_sl_neg = prm%dot_gamma_0_sl * 0.5_pReal &                                           ! only used if non-Schmid active, always 1/2
                     * sign(abs(tau_sl_neg/xi_sl)**prm%n_sl, tau_sl_neg)
  else where
    dot_gamma_sl_neg = 0.0_pReal
  end where

  if (present(ddot_gamma_dtau_sl_pos)) then
    where(dNeq0(dot_gamma_sl_pos))
      ddot_gamma_dtau_sl_pos = dot_gamma_sl_pos*prm%n_sl/tau_sl_pos
    else where
      ddot_gamma_dtau_sl_pos = 0.0_pReal
    end where

    where(dNeq0(dot_gamma_sl_neg))
      ddot_gamma_dtau_sl_neg = dot_gamma_sl_neg*prm%n_sl/tau_sl_neg
    else where
      ddot_gamma_dtau_sl_neg = 0.0_pReal
    end where
  endif

  end associate

end subroutine kinetics_sl


!--------------------------------------------------------------------------------------------------
!> @brief
!--------------------------------------------------------------------------------------------------
subroutine plastic_phenopowerlawclassic_auxState(Lp,Fi,S,ph,en)

  real(pReal), dimension(3,3),  intent(in) :: &
    Lp, Fi, S                                                                                              !< PK2 stress
  integer,                      intent(in) :: &
    ph, en
  real(pReal), dimension(3,3) :: &
    Mp                                                                  ! Mandel stress
  integer :: i


  if (size(auxState(ph)%rss_sl, 1) > 0) then
    Mp = matmul( matmul(transpose(Fi), Fi), S)
    forall (i = 1:param(ph)%sum_N_sl)
      auxState(ph)%rss_sl(i,en) = sum(Mp*param(ph)%P_sl(1:3,1:3,i))
    end forall
    auxState(ph)%rss_sl(:,en) = auxState(ph)%rss_sl(:,en)*1.0-6_pReal
  endif

  if (size(auxState(ph)%eqLp_sl) > 0) &
    auxState(ph)%eqLp_sl(en) = max(math_equivStrain33(Lp), tol_math_check)

end subroutine plastic_phenopowerlawclassic_auxState

end module plastic_phenopowerlawclassic