!--------------------------------------------------------------------------------------------------
!> @brief material subroutine incoprorating dislocation and twinning physics
!> @details to be done
!--------------------------------------------------------------------------------------------------
module plastic_kmjmak
  use prec
  use constants
  use material

  implicit none
  private

  real(pReal), parameter :: ratio_mobile_total = 0.1_pReal                                          !< the ratio of mobile dislocation density to total
  type, extends(tPlastic_Params) :: tParameters                                                     !< container type for internal constitutive parameters
    real(pReal) :: &
      E_cl         = 1.0_pReal, &                                                                   !< activation energy for dislocation climb
      omega        = 1.0_pReal, &                                                                   !< frequency factor for dislocation climb
      c_mfp_gb     = 1.0_pReal, &
      Gamma_sf_0K  = 1.0_pReal, &                                                                   !< stacking fault energy at zero K
      dGamma_sf_dT = 1.0_pReal, &                                                                   !< temperature dependence of stacking fault energy
      mu, nu, &
      ! drx
      gamma_drx_cr, &                                                                               !< critical strain for the nucleation of DRX
      gamma_drx_half, &                                                                             !< strain at the time of 50% DRX
      beta_drx, &
      k_drx, &
      rho_0_drx, &                                                                                  !< the initial dislocation density of DRX grains
      ! grain growth
      a_gg, &
      h_gg, &
      m_gg, &
      n_gg, &
      E_gg, &
      d_0_drx                                                                                       !< the initial grain size of DRX grains
    character(len=:),          allocatable               :: &
      isotropic_bound
    real(pReal), allocatable, dimension(:) :: &
      b_sl, &                                                                                       !< absolute length of Burgers vector [m] for each slip system
      E_sl,&                                                                                        !< activation energy for glide [J] for each slip system
      v_0, &                                                                                        !< dislocation velocity prefactor [m/s] for each slip system
      D_a, &                                                                                        !< adjustment parameter to calculate minimum dipole distance
      p, &                                                                                          !< p-exponent in glide velocity
      q, &                                                                                          !< q-exponent in glide velocity
      p1, &                                                                                         !< p - 1
      q1, &                                                                                         !< q - 1
      tau_0, &                                                                                      !< strength due to elements in solid solution
      B, &                                                                                          !< drag coefficient
      cl_Vol
    real(pReal),               allocatable, dimension(:,:) :: &
      n0_sl, &                                                                                      !< slip system normal
      forestProjection
    logical :: &
      extendedDislocations                                                                          !< consider split into partials for climb calculation
  end type tParameters                                                                              !< container type for internal constitutive parameters

  type :: tkmjmakState
    real(pReal),                  dimension(:,:),   pointer :: &
      rho_ssd, &
      gamma_sl
  end type tkmjmakState

  type :: tkmjmakdepState
    real(pReal), dimension(:,:), allocatable :: &
      Lambda_sl, &                                                                                  !< mean free path between 2 obstacles seen by a moving dislocation
      tau_pass                                                                                      !< threshold stress for slip
    real(pReal), dimension(:), allocatable :: &
      Xdrx, &
      dXdrx_dgamma, &
      gamma_offset, &
      d_matrix, &                                                                                   !< grain size of the matrix
      Ddrx                                                                                          !< grain size of the DRX grain
    integer, dimension(:), allocatable :: &
      Ndrx                                                                                          !< the number (time) of complete DRX
  end type tkmjmakdepState

!--------------------------------------------------------------------------------------------------
! containers for parameters and state
  type(tParameters),  allocatable, dimension(:) :: param
  type(tkmjmakState), allocatable, dimension(:) :: &
    dotState, &
    state
  type(tkmjmakdepState),   allocatable, dimension(:) :: depState
  type(tPlastic_auxState), allocatable, dimension(:) :: auxState


  public :: &
    plastic_kmjmak_init, &
    plastic_kmjmak_depState, &
    plastic_kmjmak_LpAndItsTangent, &
    plastic_kmjmak_dotState, &
    plastic_kmjmak_results

contains


!--------------------------------------------------------------------------------------------------
!> @brief Perform module initialization.
!> @details reads in material parameters, allocates arrays, and does sanity checks
!--------------------------------------------------------------------------------------------------
subroutine plastic_kmjmak_init()

  use math, only: &
    math_expand
  use IO, only: &
    IO_error, &
    IO_warning
  use config, only: &
    config_phase
  use lattice

  integer(kind(undefined_ID)) :: outputID                                                           !< ID of each post result output
  integer :: ph, i, Nmembers, size_, idx_s, idx_e, Nfamilies_sl,ns
  real(pReal), allocatable, dimension(:) :: &
    rho_ssd_0                                                                                       !< initial unipolar dislocation density per slip system
  character(len=pStringLen) :: extmsg = ''
  character(len=pStringLen), dimension(:), allocatable :: outputs

  type :: tParasLocal                                                                               !< container type for internal constitutive parameters
    real(pReal) :: &
      alpha = 1.0_pReal, &                                                                          !< for Taylor hardening model
      C_cl_Vol, &                                                                                   !< atom volume in Bugers vector unit
      dipoleForm_coeff, &                                                                           !< scaling factor for dipole formation: 0: off, 1: on. other values not useful
      atol_rho, &                                                                                   !< absolute tolerance for integration of dislocation density
      atol_gamma, &
      D_0_cl
    real(pReal), dimension(:), allocatable :: &
      K_sl                                                                                          !< Adj. parameter for distance between 2 forest dislocations for each slip system
  end type tParasLocal
  type(tParasLocal), dimension(:), allocatable :: prm_loc                                           !< containers of constitutive parameters (len material_Nphase)




  print'(/,1x,a)', '<<<+-  constitutive_plastic_kmjmak init  -+>>>'
  write(6,*) 'Compiled on ', __DATE__,' at ',__TIME__; write(6,*); flush(6)

  allocate(param(material_Nphase), state(material_Nphase), dotState(material_Nphase), &
           depState(material_Nphase), prm_loc(material_Nphase), auxState(material_Nphase))


  phaseScan: do ph = 1, material_Nphase
    if (phase_plastic(ph) /= PLASTICITY_KMJMAK_ID) cycle phaseScan
    Nmembers = count(matGr%ph == ph)                                                                !< put it here, very important number of cos containing my ph

    associate(prm => param(ph), dot => dotState(ph), stt => state(ph), dst => depState(ph), &
              prmloc => prm_loc(ph), pl => config_phase(ph))


    if (pl%keyExists('/dfc/')) material_DFC_specified = .true.

    prm%Nslip = lattice_consts(ph)%NslipSystem; Nfamilies_sl = size(prm%Nslip,1)                          !< slip, for a 1-d array x, size(x,1) = size(x)

    ns = sum(prm%Nslip); prm%sum_N_sl = ns                                                           !< how many slip systems altogether
    prm%mu = lattice_mu(ph)
    prm%nu = lattice_nu(ph)

    ! Schmid tensor
    prm%P_sl = lattice_SchmidMatrix_slip(ns, prm%Nslip, ph)
    prm%PP_sl= math_concatenate3333(prm%P_sl, prm%P_sl, ns)

    ! interaction matrix
    prm%h_sl_sl = lattice_interaction_slXsl(ns, prm%Nslip, pl%getFloats('h_sl-sl'), ph)
    prm%forestProjection = lattice_slipProjection(ns, prm%Nslip, ph)
    prm%forestProjection = transpose(prm%forestProjection)

    prm%n0_sl = lattice_slip_normal(ns, prm%Nslip, ph)

    rho_ssd_0   = pl%getFloats('rho_0', requiredSize=Nfamilies_sl)
    prm%v_0     = pl%getFloats('v_0',   requiredSize=Nfamilies_sl)
    prm%b_sl    = pl%getFloats('b_sl',  requiredSize=Nfamilies_sl)
    prm%E_sl    = pl%getFloats('e_sl',  requiredSize=Nfamilies_sl)
    prmloc%K_sl = pl%getFloats('k_sl',  requiredSize=Nfamilies_sl)
    prm%D_a     = pl%getFloats('d_a',   requiredSize=Nfamilies_sl)
    prm%p       = pl%getFloats('p_sl',  requiredSize=Nfamilies_sl)
    prm%q       = pl%getFloats('q_sl',  requiredSize=Nfamilies_sl)
    prm%tau_0   = pl%getFloats('tau_0', requiredSize=Nfamilies_sl)
    prm%B       = pl%getFloats('b',     requiredSize=Nfamilies_sl, &
                                        defaultVal=[(0.0_pReal, i=1,Nfamilies_sl)])
    ! parameters independent of number of slip systems
    prmloc%alpha    = pl%getFloat('alpha', defaultVal = 1.0_pReal)
    prm%E_cl        = pl%getFloat('e_cl')
    prmloc%C_cl_Vol = pl%getFloat('climb_volume_coeff',defaultVal = 1.0_pReal)
    prm%extendedDislocations= pl%keyExists('extend_dislocations')

    ! multiplication factor according to crystal structure (nearest neighbors bcc vs fcc/hex)
    ! details: Argon & Moffat, Acta Metallurgica, Vol. 29, pg 293 to 299, 1981
    prm%omega = pl%getFloat('omega',  defaultVal = 1000.0_pReal) * &
      merge(12.0_pReal,8.0_pReal, any(lattice_consts(ph)%structure == ['cF', 'hP']))

    ! expand: family => system
    rho_ssd_0 = math_expand(rho_ssd_0, prm%Nslip)
    prm%v_0   = math_expand(prm%v_0,   prm%Nslip)
    prm%b_sl  = math_expand(prm%b_sl,  prm%Nslip)
    prm%E_sl  = math_expand(prm%E_sl,  prm%Nslip)
    prm%p     = math_expand(prm%p,     prm%Nslip)
    prm%q     = math_expand(prm%q,     prm%Nslip)
    prm%tau_0 = math_expand(prm%tau_0, prm%Nslip)
    prm%B     = math_expand(prm%B,     prm%Nslip)
    prm%D_a   = math_expand(prm%D_a,   prm%Nslip)
    prmloc%K_sl = math_expand(prmloc%K_sl, prm%Nslip)
    prm%p1    = prm%p - 1.0_pReal
    prm%q1    = prm%q - 1.0_pReal


    ! sanity checks
    if (    prm%E_cl    <= 0.0_pReal)  extmsg = trim(extmsg)//'@E_cl (>0.0) '
    if (    prmloc%alpha<= 0.0_pReal)  extmsg = trim(extmsg)//'@alpha (>0.0) '
    if (any(rho_ssd_0   <= 0.0_pReal)) extmsg = trim(extmsg)//'@rho_0 (>0.0) '
    if (any(prm%v_0     <= 0.0_pReal)) extmsg = trim(extmsg)//'@v_0 (>0.0) '
    if (any(prm%b_sl    <= 0.0_pReal)) extmsg = trim(extmsg)//'@b_sl (>0.0) '
    if (any(prm%E_sl    <= 0.0_pReal)) extmsg = trim(extmsg)//'@E_sl (>0.0) '
    if (any(prmloc%K_sl <= 0.0_pReal)) extmsg = trim(extmsg)//'@K_sl (>0.0) '
    if (any(prm%B       <  0.0_pReal)) extmsg = trim(extmsg)//'@B (>=0.0) '
    if (any(prm%D_a     <  0.0_pReal)) extmsg = trim(extmsg)//'@D_a (>0.0) '
    if (any(prm%p<=0.0_pReal .or. prm%p>1.0_pReal)) extmsg = trim(extmsg)//'@p_sl (0~1) '
    if (any(prm%q< 1.0_pReal .or. prm%q>2.0_pReal)) extmsg = trim(extmsg)//'@q_sl (1~2) '

    prm%cl_Vol = prmloc%C_cl_Vol*prm%b_sl**3

    do concurrent (i = 1 : prm%sum_N_sl )
      prm%h_sl_sl(:,i) = (prmloc%alpha*prm%b_sl)**2 * prm%h_sl_sl(:,i)
      prm%forestProjection(i, :) = prm%forestProjection(i, :) / prmloc%K_sl(i)**2
    enddo


    ! parameters required for several mechanisms and their interactions
    ! grain size effect, contribute to mfp and hall-petch effect
    prm%d_avg    = pl%getFloat('grainsize')                                                      ! average grain size, assume the RVE has a identical grain size
    prm%c_mfp_gb = pl%getFloat('c_mfp_gb', defaultVal = 1.0_pReal)
    if (prm%d_avg    <= 0.0_pReal) extmsg = trim(extmsg)//'@grainsize (>0.0) '
    if (prm%c_mfp_gb <  0.0_pReal) extmsg = trim(extmsg)//'@c_mfp_gb (>=0.0) '

    ! read material parameters of Hall-Petch effect
    call material_get_hp_paras(ph, prm%n_hp, prm%k_hp, prm%m_hp, prm%c_hp, prm%xi_0_hp)

    ! parameters describing temperature-dependent SFE
    if (prm%extendedDislocations) then
      prm%Gamma_sf_0K  = pl%getFloat('gamma_sf_0k')
      prm%dGamma_sf_dT = pl%getFloat('dgamma_sf_dt')
    endif

    ! parameters describing DRX process
    prm%beta_drx = pl%getFloat('beta_drx', defaultVal=0.0_pReal)
    if (prm%beta_drx < 0.0_pReal) extmsg = trim(extmsg)//'@beta_drx (>=0.0) '

    if (prm%beta_drx > machine_eps) then                                   ! only when prm%beta_drx > 0, there could be grain growth
      prm%gamma_drx_cr   = pl%getFloat('gamma_drx_cr')                  ! \epsilon_cr
      prm%gamma_drx_half = pl%getFloat('gamma_drx_half')                ! \epsilon_{0.5}
      prm%k_drx          = pl%getFloat('k_drx')
      prm%rho_0_drx      = pl%getFloat('rho_0_drx', defaultVal=1.0e11_pReal)

      if (prm%gamma_drx_cr <= 0.0_pReal) extmsg = trim(extmsg)//'@gamma_drx_cr (>0.0) '
      if (prm%k_drx        <= 0.0_pReal) extmsg = trim(extmsg)//'@k_drx (>0.0) '
      if (prm%rho_0_drx    >  minval(rho_ssd_0)) extmsg = trim(extmsg)//'@rho_0_drx (<= rho_ssd_0) '
      if (prm%gamma_drx_half <  prm%gamma_drx_cr) &
          extmsg = trim(extmsg)//'@gamma_drx_half (>gamma_drx_cr) '
    endif

    ! parameters describing grain growth during DRX process
    prm%a_gg = pl%getFloat('a_gg', defaultVal=0.0_pReal)
    if (prm%a_gg < 0.0_pReal) extmsg = trim(extmsg)//'@a_gg (>=0.0) '

    if (prm%a_gg > machine_eps) then                                       ! only when prm%a_gg > 0, there could be grain growth
      prm%h_gg    = pl%getFloat('h_gg')
      prm%m_gg    = pl%getFloat('m_gg')
      prm%n_gg    = pl%getFloat('n_gg')
      prm%E_gg    = pl%getFloat('e_gg')
      prm%d_0_drx = pl%getFloat('d_0_drx')
      if (prm%E_gg    <= 0.0_pReal) extmsg = trim(extmsg)//'@E_gg (>0.0) '
      if (prm%d_0_drx <= 0.0_pReal) extmsg = trim(extmsg)//'@d_0_drx (>0.0) '
    endif

    ! output pararameters
    outputs = pl%getStrings('(output)', defaultVal=emptyStringArray)
    allocate(prm%outputID(0))

    do i = 1, size(outputs)
      size_ = 0
      select case(outputs(i))
        case ('rho_mob')                          ! density of mobile dislocations
          outputID = rho_mob_ID
          size_    = ns
        case ('rho_dip')                          ! density of dislocation dipoles
          outputID = rho_dip_ID
          size_    = ns
        case ('dot_gamma_sl')                     ! shear strain rates due to dislocation slip
          outputID = dot_gamma_sl_ID
          size_    = ns
        case ('gamma_sl')                         ! accumulated shear strains due to dislocation slip
          outputID = gamma_sl_ID
          size_    = ns
        case ('mfp_sl')                           ! mean free path of dislocation slip
          outputID = mfp_sl_ID
          size_    = ns
        case ('rss_sl')                           ! resolved shear stress of slip system
          outputID = rss_sl_ID
          size_    = ns
        case ('crss_sl')                          ! long-range resistance of dislocation movement (critical shear stress)
          outputID = tau_pass_ID
          size_    = ns
        case ('totalshear')                       ! total shear strain due to slip
          outputID = totalshear_ID
          size_    = merge(1, 0, ns > 0)
        case ('taylorfactor')                     ! Taylor factor
          outputID = M_ID
          size_    = merge(1, 0, ns > 0)
        case ('n_sl')                             ! the number of activated slip systems
          outputID = N_sl_ID
          size_    = merge(1, 0, ns > 0)
        case ('rho_total')                        ! total dislocation density
          outputID = rho_total_ID
          size_    = merge(1, 0, ns > 0)
        case default
      end select

      if (size_ > 0) then
        phase_outputs(ph)%pl_ou_labels(i) = outputs(i)
        phase_outputs(ph)%pl_ou_size(i)   = size_
        prm%outputID = [prm%outputID, outputID]
        prm%Noutput  = prm%Noutput + 1
      endif
    enddo
    phase_outputs(ph)%pl_name = 'dislokm'

    prm%sizeResults = sum(phase_outputs(ph)%pl_ou_size)
    ! allocate state arrays
    size_    = size(['rho_ssd ','gamma_sl']) * prm%sum_N_sl

    call phase_allocateState_pl(plasticState(ph), Nmembers, size_, prm%sizeResults, ns, 0, 0)

    prmloc%atol_rho   = pl%getFloat('atol_rho',   defaultVal = 1.0_pReal)
    prmloc%atol_gamma = pl%getFloat('atol_gamma', defaultVal = 1.0e-6_pReal)

    if (prmloc%atol_rho   <= 0.0_pReal) extmsg = trim(extmsg)//'@atol_rho '
    if (prmloc%atol_gamma <= 0.0_pReal) extmsg = trim(extmsg)//'@atol_gamma '

    ! locally defined state aliases and initialization of state0 and atol
    idx_s = 1;         idx_e = prm%sum_N_sl
    stt%rho_ssd => plasticState(ph)%state   (idx_s:idx_e,:)
    stt%rho_ssd =  spread(rho_ssd_0,2,Nmembers)
    dot%rho_ssd => plasticState(ph)%dotState(idx_s:idx_e,:)
    plasticState(ph)%atol(idx_s:idx_e) = prmloc%atol_rho
    if (any(plasticState(ph)%atol(idx_s:idx_e) < 0.0_pReal)) extmsg = trim(extmsg)//'@atol_rho '


    idx_s = idx_e + 1; idx_e = idx_e + prm%sum_N_sl
    stt%gamma_sl => plasticState(ph)%state   (idx_s:idx_e,:)
    dot%gamma_sl => plasticState(ph)%dotState(idx_s:idx_e,:)
    plasticState(ph)%atol(idx_s:idx_e) = prmloc%atol_gamma
    if (any(plasticState(ph)%atol(idx_s:idx_e) < 0.0_pReal)) extmsg = trim(extmsg)//'@atol_gamma '
    ! global alias
    plasticState(ph)%shearRate => plasticState(ph)%dotState(idx_s:idx_e,:)

    ! non-independent state variables
    allocate(dst%tau_pass (prm%sum_N_sl, Nmembers), source=0.0_pReal)
    allocate(dst%Lambda_sl(prm%sum_N_sl, Nmembers), source=0.0_pReal)

    ! DRX and grain growth
    allocate(dst%Ndrx        (Nmembers), source= 0)
    allocate(dst%Xdrx        (Nmembers), source= 0.0_pReal)
    allocate(dst%dXdrx_dgamma(Nmembers), source= 0.0_pReal)
    allocate(dst%Ddrx        (Nmembers), source= prm%d_0_drx)
    allocate(dst%d_matrix    (Nmembers), source=-1.0_pReal)    ! use a negative to label it uninitialized
    allocate(dst%gamma_offset(Nmembers), source= 0.0_pReal)

    call material_allocate_auxState(ns, Nmembers, auxState(ph), &
                                    phase_outputs(ph)%pl_ou_labels, mfp_gb = .true.)

    plasticState(ph)%state0 = plasticState(ph)%state

    end associate

    ! exit if any parameter is out of range
    if (extmsg /= '') call IO_error(211,ext_msg=trim(extmsg)//'(kmjmak)')

  enddo phaseScan

end subroutine plastic_kmjmak_init


!--------------------------------------------------------------------------------------------------
!> @brief Calculate plastic velocity gradient and its tangent.
!--------------------------------------------------------------------------------------------------
subroutine plastic_kmjmak_LpAndItsTangent(Lp,dLp_dMp,Mp,T,ph, en,grainID)

  real(pReal), dimension(3,3),     intent(out) :: Lp
  real(pReal), dimension(3,3,3,3), intent(out) :: dLp_dMp
  real(pReal), dimension(3,3),     intent(in)  :: Mp
  integer,                         intent(in)  :: ph,en,grainID
  real(pReal),                     intent(in)  :: T                                                 !< temperature

  integer :: i
  real(pReal), dimension(param(ph)%sum_N_sl) :: &
    dot_gamma_sl, ddot_gamma_dtau_sl


  !T = thermal_T(ph,en)
  Lp = 0.0_pReal; dLp_dMp = 0.0_pReal

  associate(prm => param(ph), stt => state(ph))

  call kinetics_sl(Mp, T, auxState(ph)%xi_0_hp(en), ph, en, dot_gamma_sl, ddot_gamma_dtau_sl)

  do i = 1, prm%sum_N_sl
    if ( abs(dot_gamma_sl(i) ) > tol_math_check2) then
      Lp = Lp + dot_gamma_sl(i)*prm%P_sl(1:3,1:3,i)
      dLp_dMp = dLp_dMp + ddot_gamma_dtau_sl(i) * prm%PP_sl(1:3,1:3,1:3,1:3,i)
    endif
  enddo

  end associate

end subroutine plastic_kmjmak_LpAndItsTangent


!--------------------------------------------------------------------------------------------------
!> @brief Calculate the rate of change of microstructure.
!--------------------------------------------------------------------------------------------------
subroutine plastic_kmjmak_dotState(Mp,T,ph,en,grainID)

  real(pReal), dimension(3,3),  intent(in) :: &
    Mp                                                                                              !< Mandel stress
  real(pReal),                  intent(in) :: &
    T                                                                                               !< not used, cheat the compiler
  integer,                      intent(in) :: &
    ph, en, grainID

  integer :: i
  real(pReal) :: &
    climb_distance, &
    v_cl, &                                                                                         !< climb velocity
    abs_tau, &
    sigma_cl, &                                                                                     !< climb stress
    b_d, &                                                                                          !< ratio of Burgers vector to stacking fault width
    cl_distance_coeff, &
    mu, nu, rho_extended_coeff, kB_T
  real(pReal), dimension(param(ph)%sum_N_sl) :: &
    dot_rho_climb, &
    rhoDip_distance_min, &
    dot_gamma_sl


  !T = thermal_T(ph,en)
  associate(prm => param(ph), stt => state(ph), dot => dotState(ph), &
            dst => depState(ph), aux => auxState(ph))

  if ( aux%xi_0_hp(en) < 0.0_pReal ) & ! uninitialized
    aux%xi_0_hp(en) = material_HP_Strengthen(prm%k_hp, prm%n_hp,  prm%xi_0_hp, grainID)

  mu = prm%mu
  nu = prm%nu
  kB_T = k_B * T

  cl_distance_coeff   = 0.375_pReal*mu/twoPI                                                       ! climb/dipole distance coefficient
  rho_extended_coeff  = 24.0_pReal*PI*(1.0_pReal - nu)/(2.0_pReal + nu)/mu
  rhoDip_distance_min = prm%D_a*prm%b_sl

  !print'(a, e16.6)', 'T', T
  call kinetics_sl(Mp, T, aux%xi_0_hp(en), ph, en, dot_gamma_sl)
  dot%gamma_sl(:,en) = abs(dot_gamma_sl)

  !print'(a, 3e16.6)', 'dot_gamma_sl', dot_gamma_sl(1),dot_gamma_sl(2),dot_gamma_sl(3)
  dot_rho_climb = 0.0_pReal
  do i = 1, prm%sum_N_sl

    abs_tau = abs(sum(Mp * prm%P_sl(1:3,1:3,i)))

    if (abs_tau > tol_math_check2) then

      climb_distance = min(cl_distance_coeff*prm%b_sl(i)/abs_tau, dst%Lambda_sl(i,en)) - &
                           rhoDip_distance_min(i)

      ! dislocation climb
      if (climb_distance > 0.0_pReal) then

        ! Argon & Moffat, Acta Metallurgica, Vol. 29, pg 293 to 299, 1981
        sigma_cl = dot_product(prm%n0_sl(1:3,i), matmul(Mp, prm%n0_sl(1:3,i)))
        if (prm%extendedDislocations) then
          b_d = rho_extended_coeff * (prm%Gamma_sf_0K + prm%dGamma_sf_dT * T)/prm%b_sl(i)
        else
          b_d = 1.0_pReal
        endif

        v_cl = 2.0_pReal*prm%omega*b_d**2*exp(-prm%E_cl/kB_T) &
             * (exp(abs(sigma_cl)*prm%cl_Vol(i)/kB_T) - 1.0_pReal)

        dot_rho_climb(i) = 4.0_pReal*v_cl*stt%rho_ssd(i,en) / climb_distance
      endif
    endif
  enddo

  dot%rho_ssd(:,en) = (1.0_pReal/(prm%b_sl*dst%Lambda_sl(:,en))  - &
                       2.0_pReal*prm%D_a * stt%rho_ssd(:,en) )*dot%gamma_sl(:,en) - dot_rho_climb

  ! decrease of dislocation density due to DRX
  if (dst%Xdrx(en) > tol_math_check2) then
    dot%rho_ssd(:,en) = dot%rho_ssd(:,en) - &
        (stt%rho_ssd(:,en) - prm%rho_0_drx) * dst%dXdrx_dgamma(en)*dot%gamma_sl(:,en)
  endif

  end associate

end subroutine plastic_kmjmak_dotState


!--------------------------------------------------------------------------------------------------
!> @brief Calculate derived quantities from state.
!--------------------------------------------------------------------------------------------------
subroutine plastic_kmjmak_depState(ph, en,T,grainID)

  integer,       intent(in) :: ph, en,grainID
  real(pReal), intent(in) :: T
  real(pReal) :: mu, accum_strain, aux, d_weighted
  real(pReal), dimension(param(ph)%sum_N_sl) :: rho, inv_lambda_sl


  associate(prm => param(ph), stt => state(ph), dot => dotState(ph), dst => depState(ph))

  mu = prm%mu
  rho = stt%rho_ssd(:,en)


  inv_lambda_sl = sqrt(matmul(prm%forestProjection, rho))

  ! initialize grain size of the matrix
  if (dst%d_matrix(en) < 0.0_pReal ) then ! uninitialized
    dst%d_matrix(en) = prm%d_avg

  endif

  ! complete one DRX process
  if ( dEq(dst%Xdrx(en), 1.0_pReal) ) then
    dst%d_matrix(en) = dst%Ddrx(en)                                                                 ! change the grain size
    dst%Ndrx(en)     = dst%Ndrx(en) + 1                                                             ! number of DRX times
    dst%Xdrx(en)     = 0.0_pReal                                                                    ! Xdrx reseted to 0.0
    dst%Ddrx(en)     = prm%d_0_drx                                                                  ! initial grain size of next DRX grain
    dst%gamma_offset(en) = sum( stt%gamma_sl(:, en) )                                               ! new offset strain
  endif

  accum_strain = sum(stt%gamma_sl(:, en)) - dst%gamma_offset(en)

  ! JMAK DRX model
  if (prm%beta_drx > 0.0_pReal .and. accum_strain > prm%gamma_drx_cr) then
    aux = (accum_strain - prm%gamma_drx_cr)/prm%gamma_drx_half
    dst%Xdrx(en) = 1.0_pReal - exp( -prm%beta_drx * aux**prm%k_drx)

    dst%dXdrx_dgamma(en) = (1.0_pReal - dst%Xdrx(en))*prm%beta_drx*prm%k_drx/prm%gamma_drx_half * & ! \totalder{Xdrx}{gamma}
                            aux**( prm%k_drx - 1.0_pReal )
  else
    dst%Xdrx(en) = 0.0_pReal
    dst%dXdrx_dgamma(en) = 0.0_pReal
  endif

  ! grain size of drx grain
  if (dst%Xdrx(en) > tol_math_check2) then
    dst%Ddrx(en) = prm%a_gg * dst%d_matrix(en)**prm%h_gg * &
                    accum_strain**prm%n_gg * &
                  ( sum(dot%gamma_sl(:, en)) )**prm%m_gg * exp(prm%E_gg/(k_B*T)) + prm%d_0_drx

    d_weighted = dst%Ddrx(en) * dst%Xdrx(en) + dst%d_matrix(en) * (1.0_pReal - dst%Xdrx(en))        ! the weighted grain size
  else
    d_weighted = dst%d_matrix(en)
  endif

  dst%Lambda_sl(:,en) = 1.0_pReal / (prm%c_mfp_gb/d_weighted + inv_lambda_sl)
  dst%tau_pass(:,en)  = mu*sqrt(matmul(prm%h_sl_sl, (1.0_pReal-dst%Xdrx(en))*rho + dst%Xdrx(en)*prm%rho_0_drx))     !< threshold stress for dislocation motion

  end associate

end subroutine plastic_kmjmak_depState


!--------------------------------------------------------------------------------------------------
!> @brief Write results to HDF5 output file.
!--------------------------------------------------------------------------------------------------
subroutine plastic_kmjmak_results(Mp,Lp,T,ph,en,grainID,postResults)

  real(pReal), dimension(3,3),intent(in) :: &
    Mp, &                                                                                           !< 2nd Piola Kirchhoff stress tensor in Mandel notation
    Lp
  real(pReal),                intent(in) :: &
    T                                                                                               !< temperature at integration point
  integer,              intent(in) :: &
    ph, en, grainID

  real(pReal), dimension(param(ph)%sizeResults), intent(out) :: postResults

  postResults = 0.0_pReal

end subroutine plastic_kmjmak_results


!--------------------------------------------------------------------------------------------------
!> @brief Calculate shear rates on slip systems, their derivatives with respect to resolved
!         stress, and the resolved stress.
!> @details Derivatives and resolved stress are calculated only optionally.
! NOTE: Against the common convention, the result (i.e. intent(out)) variables are the last to
! have the optional arguments at the end
!--------------------------------------------------------------------------------------------------
pure subroutine kinetics_sl(Mp, T, xi_0_hp, ph, en, dot_gamma_sl,ddot_gamma_dtau_sl)

  real(pReal), dimension(3,3),  intent(in) :: &
    Mp                                                                                              !< Mandel stress
  real(pReal),                  intent(in) :: &
    T, &                                                                                            !< temperature
    xi_0_hp                                                                                         !< initial resistance due to Hall-Petch effect
  integer,                      intent(in) :: &
    ph, en

  real(pReal), dimension(param(ph)%sum_N_sl), intent(out) :: &
    dot_gamma_sl
  real(pReal), dimension(param(ph)%sum_N_sl), optional, intent(out) :: &
    ddot_gamma_dtau_sl

  real(pReal), dimension(param(ph)%sum_N_sl) :: &
    tau, &
    stressRatio, &
    StressRatio_p, &
    Q_kB_T, &
    v_wait_inverse, &                                                                               !< inverse of the effective velocity of a dislocation waiting at obstacles (unsigned)
    v_run_inverse, &                                                                                !< inverse of the velocity of a free moving dislocation (unsigned)
    dV_wait_inverse_dTau, &
    dV_run_inverse_dTau, &
    dV_dTau, &
    tau_eff, &
    rho_mob                                                                                         !< effective resolved stress
  integer :: i


  associate(prm => param(ph), stt => state(ph), dst => depState(ph))

  tau = [(sum(Mp * prm%P_sl(1:3,1:3,i)), i = 1, prm%sum_N_sl)]

  tau_eff = abs(tau) - dst%tau_pass(:,en) - xi_0_hp
  stressRatio = tau_eff/prm%tau_0      ! can not larger 1

  rho_mob = stt%rho_ssd(:,en) * ratio_mobile_total
  if(present(ddot_gamma_dtau_sl)) then
    where(stressRatio > tol_math_check2)
      StressRatio_p  = stressRatio**prm%p
      Q_kB_T         = prm%E_sl/(K_B*T)
      v_wait_inverse = exp( Q_kB_T*(1.0_pReal - StressRatio_p)**prm%q ) / prm%v_0
      v_run_inverse  = prm%B/(tau_eff*prm%b_sl)

      dot_gamma_sl   = sign(rho_mob*prm%b_sl/(v_wait_inverse + v_run_inverse), tau)

      dV_wait_inverse_dTau= - v_wait_inverse * prm%p * prm%q * Q_kB_T * &
                              (stressRatio**prm%p1) * (1.0_pReal-StressRatio_p)**prm%q1 / prm%tau_0
      dV_run_inverse_dTau = - v_run_inverse/tau_eff
      dV_dTau             = - (dV_wait_inverse_dTau + dV_run_inverse_dTau) / (v_wait_inverse + v_run_inverse)**2
      ddot_gamma_dtau_sl  = dV_dTau*rho_mob*prm%b_sl

    else where
      dot_gamma_sl       = 0.0_pReal
      ddot_gamma_dtau_sl = 0.0_pReal
    end where

  else
    where(stressRatio > tol_math_check2)
      StressRatio_p  = stressRatio** prm%p
      Q_kB_T         = prm%E_sl/(K_B*T)
      v_wait_inverse = exp(Q_kB_T*(1.0_pReal-StressRatio_p)** prm%q) / prm%v_0
      v_run_inverse  = prm%B/(tau_eff*prm%b_sl)

      !
      dot_gamma_sl   = sign(rho_mob*prm%b_sl/(v_wait_inverse + v_run_inverse), tau)
    else where
      dot_gamma_sl   = 0.0_pReal
    end where
  endif

  end associate

end subroutine kinetics_sl


!--------------------------------------------------------------------------------------------------
!> @brief
!--------------------------------------------------------------------------------------------------
subroutine plastic_kmjmak_auxState(Lp,Fi,S,ph,en)

  real(pReal), dimension(3,3),  intent(in) :: &
    Lp, Fi, S                                                           !< PK2 stress
  integer,                      intent(in) :: &
    ph, en
  real(pReal), dimension(3,3) :: &
    Mp                                                                  ! Mandel stress
  integer :: i


  if (size(auxState(ph)%rss_sl, 1) > 0) then
    Mp = matmul( matmul(transpose(Fi), Fi), S)
    do concurrent (i = 1:param(ph)%sum_N_sl)
      auxState(ph)%rss_sl(i,en) = sum(Mp*param(ph)%P_sl(1:3,1:3,i))
    enddo
    auxState(ph)%rss_sl(:,en) = auxState(ph)%rss_sl(:,en)*1.0-6_pReal
  endif

  if (size(auxState(ph)%eqLp_sl) > 0) &
    auxState(ph)%eqLp_sl(en) = max(math_equivStrain33(Lp), tol_math_check)

end subroutine plastic_kmjmak_auxState

end module plastic_kmjmak