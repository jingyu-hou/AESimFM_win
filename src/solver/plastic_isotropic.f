!--------------------------------------------------------------------------------------------------
!> @author Haiming Zhang, Shanghai Jiao Tong University
!> @details Isotropic (ISOTROPIC) Plasticity which resembles the phenopowerlaw plasticity without
!> resolving the stress on the slip systems. Will give the response of phenopowerlaw for an
!> untextured polycrystal
!--------------------------------------------------------------------------------------------------
module plastic_isotropic
  use prec
  use constants
  use material

  implicit none
  private

  type :: tParameters                                                                               !< container type for internal constitutive parameters
    integer :: &
      Noutput = 0, &
      sizeResults= 0
    real(pReal) :: &
      fTaylor, &
      gdot0, &
      n, &
      h0, &
      h0_slopeLnRate, &
      tausat, &
      a, &
      tausat_SinhFitA, &
      tausat_SinhFitB, &
      tausat_SinhFitC, &
      tausat_SinhFitD, &
      k_hp, &                                                                                       !< Hall-Petch modulus
      n_hp, &                                                                                       !< Hall-Petch exponent
      xi_0_hp, &
      m_hp, c_hp
    logical :: &
      dilatation = .false.
    integer(kind(undefined_ID)), dimension(:), allocatable :: &
      outputID                                                                                      !< ID of each post result output
  end type tParameters

  type :: tIsotropicState                                                                           !< internal state aliases
    real(pReal), pointer, dimension(:)   :: &                                                       !< scalars along NcoMyInstance
      xi, &
      gamma
  end type tIsotropicState

  type(tParameters), dimension(:), allocatable :: param                                             !< containers of constitutive parameters (len Ninstance)
  type(tIsotropicState), allocatable, dimension(:) :: &                                             !< state aliases per instance
    dotState, &
    state
  type(tPlastic_auxState), allocatable, dimension(:) :: auxState

  public :: &
    plastic_isotropic_init, &
    plastic_isotropic_LpAndItsTangent, &
    plastic_isotropic_LiAndItsTangent, &
    plastic_isotropic_dotState, &
    plastic_isotropic_results

contains


!--------------------------------------------------------------------------------------------------
!> @brief module initialization
!> @details reads in material parameters, allocates arrays, and does sanity checks
!--------------------------------------------------------------------------------------------------
subroutine plastic_isotropic_init()
  use IO, only: &
    IO_error
  use config, only: &
    config_phase

  integer(kind(undefined_ID)) :: outputID                                                           !< ID of each post result output
  integer :: i, ph, Nmembers, outputSize
  character(len=pStringLen) :: extmsg = ''
  character(len=pStringLen), dimension(:), allocatable :: outputs
  real(pReal) ::  &
    atol_xi, &
    atol_gamma, &
    tau0


  write(6,'(/,a)')   ' <<<+-  constitutive_plastic_isotropic init  -+>>>'
  write(6,*) 'Compiled on ', __DATE__,' at ',__TIME__; write(6,*); flush(6)

  allocate(param(material_Nphase), auxState(material_Nphase), &
           state(material_Nphase), dotState(material_Nphase))


  phaseScan: do ph = 1, material_Nphase                                                             ! loop over every plasticity
    if (phase_plastic(ph) /= PLASTICITY_ISOTROPIC_ID) cycle phaseScan                               ! isolate instances of own constitutive description

    Nmembers = count(matGr%ph == ph)                                                                ! number of own material points (including point components co)
    associate(prm => param(ph), pl => config_phase(ph), stt => state(ph), dot => dotState(ph))
    if (pl%keyExists('/dfc/')) material_DFC_specified = .true.

    ! read material parameter
    prm%dilatation      = pl%keyExists('/dilatation/')
    tau0                = pl%getFloat('xi_0')
    prm%gdot0           = pl%getFloat('dot_gamma_0')
    prm%n               = pl%getFloat('n')
    prm%h0              = pl%getFloat('h_0')
    prm%h0_slopeLnRate  = pl%getFloat('h_0_slope', defaultVal=0.0_pReal)
    prm%tausat          = pl%getFloat('xi_inf')
    prm%tausat_SinhFitA = pl%getFloat('xi_inf_sinhfita', defaultVal=0.0_pReal)
    prm%tausat_SinhFitB = pl%getFloat('xi_inf_sinhfitb', defaultVal=0.0_pReal)
    prm%tausat_SinhFitC = pl%getFloat('xi_inf_sinhfitc', defaultVal=0.0_pReal)
    prm%tausat_SinhFitD = pl%getFloat('xi_inf_sinhfitd', defaultVal=0.0_pReal)
    prm%a               = pl%getFloat('a')
    prm%fTaylor         = pl%getFloat('m')        ! Taylor factor
    atol_xi             = pl%getFloat('atol_xi', defaultVal=1.0_pReal)
    atol_gamma          = pl%getFloat('atol_gamma',      defaultVal=1.0e-6_pReal)

    ! sanity checks
    if (tau0       <  0.0_pReal) extmsg = trim(extmsg)//'@xi_0 (>=0.0) '
    if (atol_xi    <= 0.0_pReal) extmsg = trim(extmsg)//'@atol_xi (>0.0) '
    if (atol_gamma <= 0.0_pReal) extmsg = trim(extmsg)//'@atol_gamma (>0.0) '
    if (prm%gdot0  <= 0.0_pReal) extmsg = trim(extmsg)//'@dot_gamma_0 (>0.0) '
    if (prm%n      <= 0.0_pReal) extmsg = trim(extmsg)//'@n (>0.0) '
    if (prm%tausat <= 0.0_pReal) extmsg = trim(extmsg)//'@xi_inf (>0.0) '
    if (prm%a      <= 0.0_pReal) extmsg = trim(extmsg)//'@a (>0.0) '
    if (prm%fTaylor<= 0.0_pReal) extmsg = trim(extmsg)//'@M (>0.0) '

    ! read material parameters of Hall-Petch effect
    call material_get_hp_paras(ph, prm%n_hp, prm%k_hp, prm%m_hp, prm%c_hp, prm%xi_0_hp)

    if (extmsg /= '') &
      call IO_error(211, el=ph, ext_msg=trim(extmsg)//'(isotropic)')


    ! output pararameters
    outputs = pl%getStrings('(output)', defaultVal=emptyStringArray)
    allocate(prm%outputID(0))

    do i = 1, size(outputs)
      outputSize = 0
      select case(outputs(i))
        case ('xi')           ! flow stress (resistance)
          outputID   = flowstress_ID
          outputSize = 1
        case ('dot_gamma')   ! strain rate
          outputID   = strainrate_ID
          outputSize = 1
        case default
      end select

      if (outputSize > 0) then
        phase_outputs(ph)%pl_ou_labels(i) = outputs(i)
        phase_outputs(ph)%pl_ou_size(i)   = outputSize
        prm%outputID = [prm%outputID, outputID]
        prm%Noutput  = prm%Noutput + 1
      endif
    enddo
    phase_outputs(ph)%pl_name = 'isotropic'

    prm%sizeResults = sum(phase_outputs(ph)%pl_ou_size)

    ! allocate state arrays
    call phase_allocateState_pl(plasticState(ph), Nmembers, 2, prm%sizeResults, 0, 0, 0)

    ! locally defined state aliases and initialization of state0 and atol
    stt%xi => plasticState(ph)%state (1,1:Nmembers)
    dot%xi => plasticState(ph)%dotState (1,1:Nmembers)
    stt%xi =  tau0

    stt%gamma => plasticState(ph)%state    (2,1:Nmembers)
    dot%gamma => plasticState(ph)%dotState (2,1:Nmembers)
    stt%gamma =  0.0_pReal
    plasticState(ph)%atol(1) = atol_xi
    plasticState(ph)%atol(2) = atol_gamma

    ! global alias
    plasticState(ph)%shearRate => plasticState(ph)%dotState(2:2,1:Nmembers)

    call material_allocate_auxState(0, Nmembers, auxState(ph), phase_outputs(ph)%pl_ou_labels)

#ifdef Abaqus_std
    plasticState(ph)%state0 = plasticState(ph)%state
#endif

    end associate
  enddo phaseScan

end subroutine plastic_isotropic_init


!--------------------------------------------------------------------------------------------------
!> @brief calculates plastic velocity gradient and its tangent
!--------------------------------------------------------------------------------------------------
subroutine plastic_isotropic_LpAndItsTangent(Lp,dLp_dMp,Mp,T, ph,en,grainID)
  use math, only: &
    math_deviatoric33

  real(pReal), dimension(3,3), intent(out) :: &
    Lp                                                                                              !< plastic velocity gradient
  real(pReal), dimension(3,3), intent(in) :: &
    Mp                                                                                              !< 2nd Piola Kirchhoff stress tensor in Mandel notation
  integer,     intent(in) :: ph,en,grainID
  real(pReal), intent(in) :: T                                                                      !< temperature, not used
  real(pReal), dimension(3,3) :: &
    Mp_dev                                                                                          !< deviatoric part of the 2nd Piola Kirchhoff stress tensor as 2nd order tensor
  real(pReal), dimension(3,3,3,3), intent(out) :: &
    dLp_dMp                                                                                      !< derivative of Lp with respect to Tstar as 4th order tensor
  real(pReal) :: &
    gamma_dot, &                                                                                    !< strainrate
    normTstar_dev, &                                                                                !< euclidean norm of Tstar_dev
    normTstar_dev_sqr, &                                                                            !< square of the euclidean norm of Tstar_dev
    aux,xi
  integer :: k, l


  Mp_dev = math_deviatoric33(Mp)                                                                    !< deviatoric part of 2nd Piola-Kirchhoff stress
  normTstar_dev     = norm2(Mp_dev)
  normTstar_dev_sqr = normTstar_dev*normTstar_dev

  if (normTstar_dev <= 0.0_pReal) then                                                              !< Tstar == 0 --> both Lp and dLp_dMp are zero
    Lp         = 0.0_pReal
    dLp_dMp = 0.0_pReal

  else
    associate(prm => param(ph), stt => state(ph))

    xi= stt%xi(en) + auxState(ph)%xi_0_hp(en)
    gamma_dot = prm%gdot0*(1.224744871391589_pReal*normTstar_dev/(prm%fTaylor*xi) )**prm%n
    Lp = gamma_dot/(prm%fTaylor*normTstar_dev) * Mp_dev

    ! Calculation of the tangent of Lp
    aux = (prm%n-1.0_pReal) / normTstar_dev_sqr
    forall (k=1:3, l=1:3)
      dLp_dMp(k,l,:,:) = aux * Mp_dev(k,l)*Mp_dev
    end forall

    forall (k=1:3, l=1:3)
      dLp_dMp(k,l,k,l) = dLp_dMp(k,l,k,l) + 1.0_pReal
      dLp_dMp(k,k,l,l) = dLp_dMp(k,k,l,l) - 0.3333333333333333_pReal
    end forall
    dLp_dMp = ( gamma_dot/(prm%fTaylor*normTstar_dev) ) * dLp_dMp

    end associate
  endif

end subroutine plastic_isotropic_LpAndItsTangent


!--------------------------------------------------------------------------------------------------
!> @brief calculates plastic velocity gradient and its tangent
!--------------------------------------------------------------------------------------------------
subroutine plastic_isotropic_LiAndItsTangent(Li,dLi_dMp,Mp,ph,en, Li_dLidT_areZero)
  use math, only: &
    math_spherical33

  real(pReal), dimension(3,3), intent(out) :: &
    Li                                                                                              !< plastic velocity gradient
  real(pReal), dimension(3,3,3,3), intent(out)  :: &
    dLi_dMp                                                                                         !< derivative of Li with respect to Tstar as 4th order tensor
  real(pReal), dimension(3,3),   intent(in) :: &
    Mp                                                                                              !< 2nd Piola Kirchhoff stress tensor in Mandel notation
  integer,     intent(in) :: ph, en
  real(pReal), dimension(3,3) :: &
    Mp_sph                                                                                          !< sphiatoric part of the 2nd Piola Kirchhoff stress tensor as 2nd order tensor
  real(pReal) :: &
    gamma_dot, &                                                                                    !< strainrate
    normTstar_sph, &                                                                                !< euclidean norm of Tstar_sph
    normTstar_sph_sqr, &                                                                            !< square of the euclidean norm of Tstar_sph
    aux, xi
  logical, intent(out) :: Li_dLidT_areZero
  integer :: k, l


  associate(prm => param(ph), stt => state(ph))

  Mp_sph = math_spherical33(Mp)                                                                     !< spherical part of 2nd Piola-Kirchhoff stress
  normTstar_sph = norm2(Mp_sph)
  normTstar_sph_sqr = normTstar_sph*normTstar_sph

  activated: if (prm%dilatation .and. normTstar_sph > 0.0_pReal) then                               !< Tstar == 0 or J2 plascitiy --> both Li and dLi_dMp are zero
    xi = stt%xi(en) + auxState(ph)%xi_0_hp(en)
    gamma_dot = prm%gdot0*(1.224744871391589_pReal*normTstar_sph/( prm%fTaylor*xi ) )**prm%n

    Li = gamma_dot/(prm%fTaylor*normTstar_sph) * Mp_sph

    ! Calculation of the tangent of Li
    aux = (prm%n-1.0_pReal)/normTstar_sph_sqr
    forall (k=1:3, l=1:3)
      dLi_dMp(k,l,:,:) = aux * Mp_sph(k,l)*Mp_sph
    end forall
    forall (k=1:3, l=1:3)
      dLi_dMp(k,l,k,l) = dLi_dMp(k,l,k,l) + 1.0_pReal
    end forall

    dLi_dMp = gamma_dot/(normTstar_sph*prm%fTaylor) * dLi_dMp
    Li_dLidT_areZero = .false.
  else activated
    Li = 0.0_pReal
    dLi_dMp = 0.0_pReal
    Li_dLidT_areZero = .true.
  endif activated

  end associate

end subroutine plastic_isotropic_LiAndItsTangent


!--------------------------------------------------------------------------------------------------
!> @brief calculates the rate of change of microstructure
!--------------------------------------------------------------------------------------------------
subroutine plastic_isotropic_dotState(Mp, T, ph,en,grainID)
  use math, only: &
    math_deviatoric33

  real(pReal), dimension(3,3), intent(in):: &
    Mp                                                                                              !< 2nd Piola Kirchhoff stress tensor in Mandel notation
  integer, intent(in) :: ph, en, grainID
  real(pReal), intent(in) :: T                                                                      !< temperature, not used
  real(pReal) :: &
    gamma_dot, &                                                                                    !< strainrate
    hardening, &                                                                                    !< hardening coefficient
    saturation, &                                                                                   !< saturation xi
    normTstar, &                                                                                    !< euclidean norm of Tstar_dev
    aux1, aux2, &
    xi


  associate(prm => param(ph), stt => state(ph), dot => dotState(ph), aux => auxState(ph))

  ! norm of (deviatoric) 2nd Piola-Kirchhoff stress
  if(prm%dilatation) then; normTstar = norm2(Mp); else; normTstar = norm2(math_deviatoric33(Mp)); endif

  if ( aux%xi_0_hp(en) < 0.0_pReal ) & ! uninitialized
    aux%xi_0_hp(en) = material_HP_Strengthen(prm%k_hp, prm%n_hp,  prm%xi_0_hp, grainID)

  ! strain rate
  xi= stt%xi(en) + aux%xi_0_hp(en)
  gamma_dot = prm%gdot0 * ( 1.224744871391589_pReal*normTstar/(prm%fTaylor*xi) )**prm%n

  ! hardening coefficient
  if ( gamma_dot > machine_eps ) then ! gamma_dot is always non-negative
    if (dEq0(prm%tausat_SinhFitA)) then
      saturation = prm%tausat
    else
      saturation = prm%tausat + &
                   asinh( (gamma_dot/prm%tausat_SinhFitA)**(1.0_pReal/prm%tausat_SinhFitD)) ** &
                     (1.0_pReal / prm%tausat_SinhFitC) / &
                 ( prm%tausat_SinhFitB * (gamma_dot/prm%gdot0)**(1.0_pReal/prm%n) )
    endif
    aux1 = 1.0_pReal - stt%xi(en)/saturation
    aux2 = abs(aux1)**prm%a * sign(1.0_pReal, aux1)
    hardening = ( prm%h0 + prm%h0_slopeLnRate*log(gamma_dot) )
    dot%xi(en) = hardening * aux2 * gamma_dot
    dot%gamma(en) = gamma_dot
  else
    dot%xi(en) = 0.0_pReal
    dot%gamma(en) = 0.0_pReal
  endif

  end associate

end subroutine plastic_isotropic_dotState


!--------------------------------------------------------------------------------------------------
!> @brief return array of constitutive results
!--------------------------------------------------------------------------------------------------
subroutine plastic_isotropic_results(Mp,Lp,T,ph,en,grainID,postResults)
  use math, only: &
    math_deviatoric33

  real(pReal), dimension(3,3), intent(in) :: &
    Mp, Lp                                                                                              !< 2nd Piola Kirchhoff stress tensor in Mandel notation
  integer,               intent(in) :: &
    ph,en,grainID
  real(pReal), intent(in) :: T                                                                      !< temperature, not used
  real(pReal), dimension(param(ph)%sizeResults), intent(out) :: &
    postResults
  real(pReal)   :: &
    normTstar, &                                                                                    !< Euclidean norm of Tstar_dev
    xi
  integer :: c,o


  associate( prm => param(ph), stt => state(ph))

  ! norm of (deviatoric) 2nd Piola-Kirchhoff stress
  if(prm%dilatation) then; normTstar = norm2(Mp); else; normTstar = norm2(math_deviatoric33(Mp)); endif

  c = 0
  postResults = 0.0_pReal
  xi= stt%xi(en) + auxState(ph)%xi_0_hp(en)

  do o = 1, prm%Noutput
    select case(prm%outputID(o))
      case (flowstress_ID)   ! flow stress (resistance)
        postResults(c+1) = xi*stressunit
        c = c + 1
      case (strainrate_ID)   ! equivalent strain rate
        postResults(c+1) = prm%gdot0*(1.224744871391589_pReal*normTstar/(prm%fTaylor*xi) )**prm%n
        c = c + 1
    end select
  enddo
  end associate

end subroutine plastic_isotropic_results

end module plastic_isotropic