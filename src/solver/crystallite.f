!--------------------------------------------------------------------------------------------------
!> @author Haiming Zhang, Shanghai Jiao Tong University
!> @brief crystallite state integration functions and reporting of results
!--------------------------------------------------------------------------------------------------
module crystallite
  use prec
  use constants
  use rotations, only: &
    tRotation
  use material
  use math
  use numerics
  use constitutive
  use cpfemlib

  implicit none
  private
  integer, public, protected :: &
    crystallite_maxResultSize                                                                    !< description not available
  integer, dimension(:),   allocatable, public, protected :: &
    crystallite_sizeResults                                                                      !< description not available
  integer, dimension(:,:), allocatable :: &
    crystallite_sizeResult                                                                       !< description not available

  type :: tCrystallite
    real(pReal), dimension(3,3) :: &
      Fe  = 0.0_pReal, &
      Fi  = 0.0_pReal, &
      Fp  = 0.0_pReal, &
      Fi0 = 0.0_pReal, &
      Fp0 = 0.0_pReal, &
      F0  = 0.0_pReal, &
      F   = 0.0_pReal, &
      Li  = 0.0_pReal, &
      Lp  = 0.0_pReal, &
      Li0 = 0.0_pReal, &
      Lp0 = 0.0_pReal, &
      S   = 0.0_pReal, &
      P   = 0.0_pReal, &
      pk2 = 0.0_pReal
    type(tRotation) :: O
    real(pReal) :: &
      work(2) = 0.0_pReal, &
      dfc(2)  = 0.0_pReal
  end type tCrystallite

  type(tCrystallite), dimension(:), allocatable, public :: ISVs
                                                                                              !< flag to indicate need for further computation
  logical,                    dimension(2),                        public, protected :: &
    crystallite_hasIntegratedISVs = .false.
  logical :: &
    crystallite_specialOutput     = .false.

  integer(kind(undefined_ID)),dimension(:,:),   allocatable :: &
    crystallite_outputID                                                                      !< ID of each post result output
  procedure(integrateStateEuler), pointer :: integrateState
  procedure(integrateStress_stagger), pointer :: integrateStress
                                                                                              !< containers of constitutive parameters (len Ninstance)
  integer, private :: nMatGrs
  public :: &
    crystallite_init, &
    phase_mechanical_constitutive, &
    phase_physical_constitutive, &
    crystallite_dSdF, &
    crystallite_orientations, &
    crystallite_push33ToRef, &
    crystallite_results, &
    crystallite_updateIntegratedISV, &
    crystallite_recallIntegratedISV, &
    materialpoint_forward

contains


!--------------------------------------------------------------------------------------------------
!> @brief allocates and initialize per grain variables
!--------------------------------------------------------------------------------------------------
subroutine crystallite_init
  use IO
  use config, only: &
    config_deallocate, &
    config_crystallite, &
    config_name_crystallite

  implicit none

  integer, parameter :: FILEUNIT = 434
  integer :: &
    gr, o, c, &                                                                            !< counter in crystallite loop
    size_, Ncrystallite
  character(len=pStringLen), dimension(:), allocatable :: outputs
  logical :: converged_
  character(len=pStringLen), dimension(:,:), allocatable :: crystallite_output             !< name of each post result output


  write(6,'(/,a)')   ' <<<+-  crystallite init  -+>>>'
  write(6,*) 'Compiled on ', __DATE__,' at ',__TIME__; write(6,*); flush(6)

  size_ = maxval(crystallite_Noutput)
  Ncrystallite = size(config_crystallite)
  nMatGrs = size(matGr)

  allocate( ISVs(nMatGrs) )

  allocate(crystallite_output(size_,  Ncrystallite));  crystallite_output=''
  allocate(crystallite_outputID(size_,Ncrystallite),   source=undefined_ID)
  allocate(crystallite_sizeResults(Ncrystallite),      source=0)
  allocate(crystallite_sizeResult(size_,Ncrystallite), source=0)


  select case(numerics_integrator)
    case(1)
      integrateState => integrateStateFPI
    case(2)
      integrateState => integrateStateEuler
    case(3,4)
      integrateState => integrateStateRK4
  end select

  if(stress_integrationMode == 1) then
    integrateStress => integrateStress_onlyLp
  else
    integrateStress => integrateStress_stagger
  endif

  do c = 1, Ncrystallite
    outputs = config_crystallite(c)%getStrings('(output)',defaultVal=[character(len=pStringLen)::])

    size_  = size(outputs)

    do o = 1, size_                                                 ! size_ can be zeor
      crystallite_output(o,c) = outputs(o)

      select case(outputs(o))
        case ('phase')
          crystallite_outputID(o,c) = phase_ID
        case ('texture')
          crystallite_outputID(o,c) = texture_ID
        case ('orientation')
          crystallite_outputID(o,c) = orientation_ID
        case ('grainrotation')
          crystallite_outputID(o,c) = grainrotation_ID
        case ('eulerangles')
          crystallite_outputID(o,c) = eulerangles_ID
        case ('peq','peeq')
          crystallite_outputID(o,c) = peq_ID
          crystallite_specialOutput = .true.
        case ('lep')
          crystallite_outputID(o,c) = lep_ID
          crystallite_specialOutput = .true.
        case ('energy', 'work')
          crystallite_outputID(o,c) = energy_ID
          crystallite_hasIntegratedISVs(1) = .true.
        case ('dfc', 'damage')
          if (.not. material_DFC_specified) then
            call IO_warning(102, ext_msg=outputs(o)//' (Crystallite)')
          else
            crystallite_outputID(o,c) = dfc_ID
            crystallite_hasIntegratedISVs(2) = .true.
          endif
        case default
        call IO_error(105,ext_msg=outputs(o)//' (Crystallite)')
      end select
    enddo
  enddo

  close(FILEUNIT)

  do c = 1, Ncrystallite
    do o = 1, crystallite_Noutput(c)
      select case(crystallite_outputID(o,c))
        case(phase_ID,texture_ID,peq_ID,energy_ID,dfc_ID,grainrotation_ID)
          size_ = 1
        case(orientation_ID)
          size_ = 4
        case(eulerangles_ID)
          size_ = 3
        case(lep_ID)
          size_ = 6
        case default
          size_ = 0
      end select
      crystallite_sizeResult(o,c) = size_
      crystallite_sizeResults(c)  = crystallite_sizeResults(c) + size_
    enddo
  enddo

  crystallite_maxResultSize = &
    maxval(crystallite_sizeResults(microstructure_crystallite), microstructure_active)

  ! write description file for crystallite output
  if (worldrank == 0) then
    call IO_write_jobFile(FILEUNIT,'outputCrystallite')

    do c = 1, Ncrystallite
      if (any(microstructure_crystallite(material_grainID) == c)) then
        write(FILEUNIT,'(/,a,/)') '['//trim(config_name_crystallite(c))//']'
        do o = 1,crystallite_Noutput(c)
          write(FILEUNIT,'(a,i4)') trim(crystallite_output(o,c))//char(9),crystallite_sizeResult(o,c)
        enddo
      endif
    enddo

    close(FILEUNIT)
  endif

  call config_deallocate('material.config/crystallite')

  ! initialize
  !$OMP PARALLEL DO
  do gr = 1, nMatGrs
    ISVs(gr)%Fp = matGr(gr)%O_0%asMatrix()              ! plastic def gradient reflects init orientation
    ISVs(gr)%Fp = ISVs(gr)%Fp / math_det33(ISVs(gr)%Fp)**one_third
    ISVs(gr)%Fi = constitutive_initialFi(gr)
    ISVs(gr)%F0  = math_I3
    ISVs(gr)%Fe  = math_inv33(matmul(ISVs(gr)%Fi, ISVs(gr)%Fp))   ! assuming that euler angles are given in internal strain free configuration
    ISVs(gr)%Fp0 = ISVs(gr)%Fp
    ISVs(gr)%Fi0 = ISVs(gr)%Fi
    ISVs(gr)%F   = ISVs(gr)%F0
  enddo
  !$OMP END PARALLEL DO

  !$OMP PARALLEL DO
  do gr = 1, nMatGrs
    call crystallite_orientations(gr)
    call constitutive_depState(gr)                                          ! update dependent state variables to be consistent with basic states

    matGr(gr)%crystal_resultSize = &
      1 + crystallite_sizeResults(microstructure_crystallite(matGr(gr)%gr_id)) + &
      1 + matGr(gr)%constit_resultsize
    converged_ = phase_mechanical_constitutive(gr, 0.0_pReal) .and. &             ! request elastic answers, donot delete
                 phase_physical_constitutive(gr, 0.0_pReal)                       ! damage and thermal
  enddo
  !$OMP END PARALLEL DO

  call cpfemlib_init()

end subroutine crystallite_init


!--------------------------------------------------------------------------------------------------
!> @brief calculate stress (P)
!--------------------------------------------------------------------------------------------------
function phase_mechanical_constitutive(gr, Delta_t) result(converged_)

  integer, intent(in) :: gr
  real(pReal), intent(in) :: Delta_t
  integer :: ph, en, dotsize
  real(pReal) :: subFrac,subStep
  real(pReal), dimension(3,3) :: &
    subFp0, subFi0, subLp0, subLi0, subF0, subF, aux33, S0
  real(pReal), dimension(:), allocatable :: subState0
  logical :: todo, converged_


  ! initialize to starting condition
  ph = matGr(gr)%ph; en = matGr(gr)%phAt

  subState0 = plasticState(ph)%state0(:,en)
  dotSize = size(subState0)

  subFp0 = ISVs(gr)%Fp0                  ! ...plastic def grad
  subLp0 = ISVs(gr)%Lp0                  ! ...plastic velocity grad
  subFi0 = ISVs(gr)%Fi0                  ! ...intermediate def grad
  subLi0 = ISVs(gr)%Li0                  ! ...intermediate velocity grad
  subF0  = ISVs(gr)%F0                   ! ...def grad
  S0     = ISVs(gr)%S                 ! ...2nd PK stress

  subFrac  = 0.0_pReal
  subStep  = 1.0_pReal/subStepSizeCryst
  todo     = .true.
  converged_= .false.                                              ! pretend failed step of twice the required size

  cutbackLooping: do while ( todo )
                                                                                                      ! some grains do not finish the entire timestep
    ! --- wind forward ---
    convergeCheck: if (converged_ ) then                                    ! convergent at the last sub-dt
      subFrac = subFrac + subStep
      subStep = min(1.0_pReal - subFrac, stepIncreaseCryst * subStep)  ! compute the current sub-dt

      todo = subStep > 0.0_pReal                        ! still time left to integrate on?
      if (todo) then                                         ! the current sub-dt is non-zero, i.e., the entire timestep hasn't been finished
        subF0  = subF                             ! ...def grad
        subLp0 = ISVs(gr)%Lp                     ! ...plastic velocity gradient
        subLi0 = ISVs(gr)%Li                     ! ...intermediate velocity gradient
        subFp0 = ISVs(gr)%Fp                     ! ...plastic def grad
        subFi0 = ISVs(gr)%Fi                     ! ...intermediate def grad

        !if abbrevation, make c and p private in omp
        subState0 = plasticState(ph)%state(:, en)
      endif

    ! --- cutback ---(reduced time and restore)
    else convergeCheck                                                                        ! the last sub-dt is still not convergent
      subStep     = subStepSizeCryst * subStep        ! cut step in half and restore...
      ISVs(gr)%Fp = subFp0                    ! ...plastic def grad
      ISVs(gr)%Fi = subFi0                    ! ...intermediate def grad
      ISVs(gr)%S  = S0                 ! ...2nd PK stress

      ISVs(gr)%Lp = subLp0                    ! ...plastic velocity grad
      ISVs(gr)%Li = subLi0                    ! ...intermediate velocity grad

      plasticState(ph)%state(:,en) = subState0
                                                  ! cant restore dotState here, since not yet calculated in first cutback after initialization
      todo = subStep > subStepMinCryst            ! still on track or already done (beyond repair)
    endif convergeCheck

    ! --- prepare for integration ---
    if (todo ) then
      subF = subF0 + subStep * (ISVs(gr)%F - ISVs(gr)%F0)
      aux33= math_inv33(matmul(ISVs(gr)%Fi, ISVs(gr)%Fp))
      ISVs(gr)%Fe = matmul(subF, aux33)
      converged_ = .not. integrateState(subF0, subF, subFp0, subFi0, &
                                        subState0(1:dotSize), subStep*Delta_t, gr, ph, en)
    endif

  enddo cutbackLooping

end function phase_mechanical_constitutive


!--------------------------------------------------------------------------------------------------
!> @brief integrate damage/thermal fields
!--------------------------------------------------------------------------------------------------
function phase_physical_constitutive(gr, Delta_t) result(converged_)

  integer, intent(in) :: gr
  real(pReal), intent(in) :: Delta_t
  integer :: ph, en
  logical :: converged_

  ph = matGr(gr)%ph; en = matGr(gr)%phAt
  converged_ = .not. integrateDamageState(Delta_t, gr, ph, en) .and. &
               .not. integrateThermalState(Delta_t, gr, ph, en)

end function phase_physical_constitutive


!--------------------------------------------------------------------------------------------------
!> @brief calculate tangent (dPdF)
!--------------------------------------------------------------------------------------------------
function crystallite_dSdF(gr, Delta_t) result(dSdF)
  use IO, only: &
    IO_warning, &
    IO_error

  integer, intent(in) :: gr
  real(pReal), intent(in) :: Delta_t
  real(pReal), dimension(3,3) :: temp_33, Fi0inv, invFp0, F_Fpinv, F_Fp0inv, invFp, invFi

  real(pReal), dimension(3,3,3,3) :: dSedFe, &
                                     dSedFi, &
                                     dLidSe, &
                                     dLidFi, &
                                     dLpdSe, &
                                     dLpdFi, &
                                     temp_3333, &
                                     dFedFidSe, &
                                     dSdF
  real(pReal), dimension(9,9):: dSedF, &
                                dSedFidSe, &
                                temp_99,lhs_99
  integer :: o,p
  logical :: error, Li_dLidM_areZero                                                                ! if Li_dLidM_areZero is ture, the Li is zero, Fi is eye, all the derivative of Li and Fi are zero


  call phase_SandItsTangents(temp_33, dSedFe, dSedFi, ISVs(gr)%Fe, ISVs(gr)%Fi, gr)          ! call constitutive law to calculate elastic stress tangent
  call eigen_LiAndItsTangents(temp_33, dLidSe, dLidFi, &
                                    ISVs(gr)%S, ISVs(gr)%Fi, ISVs(gr)%Fe, gr, Li_dLidM_areZero)     ! call constitutive law to calculate Li tangent in lattice configuration
  call plastic_LpAndItsTangents(temp_33, dLpdSe, dLpdFi, &
                                    ISVs(gr)%S, ISVs(gr)%Fi, gr, Li_dLidM_areZero)       ! call constitutive law to calculate Lp tangent in lattice configuration


  invFp0   = math_inv33(ISVs(gr)%Fp0)
  invFp    = math_inv33(ISVs(gr)%Fp)

  F_Fpinv  = matmul(ISVs(gr)%F, invFp)
  F_Fp0inv = matmul(ISVs(gr)%F, invFp0)

  !--------Calculate dSedF------------------------------------------------
  if (.not. Li_dLidM_areZero) then

    dLidSevalid: if (maxval(abs(dLidSe)) < machine_eps) then
      dSedFidSe = 0.0_pReal
      dFedFidSe = 0.0_pReal

    else dLidSevalid

      Fi0inv   = math_inv33(ISVs(gr)%Fi0)

      !------------Calculate dLidSe-------------------------------------------
      temp_33 = Delta_t*matmul(Fi0inv, ISVs(gr)%Fi) !Fi0inv_Fi
      forall(o=1:3, p=1:3) ! -pLi_pFi_pLi is the minus needed? YES
        temp_3333(o,p,1:3,1:3) = -matmul(transpose(ISVs(gr)%Fi), &
                                  matmul(dLidFi(o,p,1:3,1:3), transpose(temp_33) ) )
      end forall

      lhs_99 = reshape(temp_3333, [9,9])
      forall (o=1:9)
        lhs_99(o,o) = lhs_99(o,o)+1.0_pReal
      end forall

      call math_invert(9,lhs_99,temp_99,error)
      if (error) then
        call IO_warning(warning_ID=600,el=gr,ext_msg='inversion error in analytic tangent calculation')
      else
        dLidSe = reshape( matmul(temp_99, reshape(dLidSe,[9,9]) ), [3,3,3,3] )
      endif
      !------------Finish calculating dLidSe----------------------------------

      forall( o=1:3, p=1:3 )
        temp_3333(:,:,o,p) = matmul(ISVs(gr)%Fi, matmul(dLidSe(:,:,o,p),temp_33) )       !< temp_33 is Fi0inv_Fi
        dFedFidSe(:,:,o,p) = matmul(F_Fpinv, matmul(dLidSe(:,:,o,p), Fi0inv) )
      end forall

      lhs_99 = reshape(temp_3333, [9,9])                                                ! lhs_99 - dFidSe
      dLpdSe = dLpdSe + reshape( matmul(reshape(dLpdFi, [9,9]), lhs_99), [3,3,3,3] )    !dLpdSe at the rhs is pLppSe
      dSedFidSe = matmul(reshape(dSedFi, [9,9]), lhs_99)                                !RIGHT, dSedFi is calculated from the Hooken's law
    endif dLidSevalid

    invFi = math_inv33(ISVs(gr)%Fi)
    call dSedF_2sides(Delta_t, invFp, F_Fp0inv, dSedFe, dLpdSe, lhs_99, dSedF, &
                      invFi, dFedFidSe, dSedFidSe)

  else
    call dSedF_2sides(Delta_t, invFp, F_Fp0inv, dSedFe, dLpdSe, lhs_99, dSedF)
  endif


  call math_invert(9, lhs_99, temp_99, error)
  if (error) then
    call IO_warning(warning_ID=600, el=gr, ext_msg='inversion error in analytic tangent calculation')
  else
    dSedF = matmul(temp_99, dSedF)
  endif
  !--------Finish calculating dSedF------------------------------------------------

  dSdF = dPK2_dF(Delta_t, ISVs(gr)%S, invFp, invFp0, dLpdSe, dSedF )

end function crystallite_dSdF


!--------------------------------------------------------------------------------------------------
!> @brief calculates orientations
!--------------------------------------------------------------------------------------------------
subroutine crystallite_orientations(gr)

  integer, intent(in) :: gr
  type(tRotation) :: orient


  call orient%fromMatrix( transpose(math_rotationalPart(ISVs(gr)%Fe)) ) ! rotational part from polar decomposition as quaternion
  ! twinning reorientation
  ISVs(gr)%O = constitutive_twinReorientation(orient,gr)

end subroutine crystallite_orientations


!--------------------------------------------------------------------------------------------------
!> @brief Map 2nd order tensor to reference config
!--------------------------------------------------------------------------------------------------
pure function crystallite_push33ToRef(gr,tensor33)

  real(pReal), dimension(3,3) :: crystallite_push33ToRef
  real(pReal), dimension(3,3), intent(in) :: tensor33
  real(pReal), dimension(3,3)             :: T
  integer, intent(in):: gr


  T = matmul(matGr(gr)%O_0%asMatrix(), transpose(math_inv33(ISVs(gr)%F)) )
  crystallite_push33ToRef = matmul(transpose(T), matmul(tensor33, T) )

end function crystallite_push33ToRef


!--------------------------------------------------------------------------------------------------
!> @brief return results of particular grain
!--------------------------------------------------------------------------------------------------
function crystallite_results(gr) result(postResults)
  use rotations, only: &
    tRotation

  integer, intent(in):: gr
  real(pReal), dimension( matGr(gr)%crystal_resultSize ) :: postResults
  real(pReal), dimension(6) :: lnVp
  real(pReal), dimension(4) :: axis_angle
  integer :: o,c,crystID,size_
  type(tRotation) :: rot


  if ( crystallite_specialOutput ) &
    lnVp = math_lnV(ISVs(gr)%F) - math_lnV(ISVs(gr)%Fe)


  crystID = microstructure_crystallite( matGr(gr)%gr_id )
  postResults = 0.0_pReal
  postResults(1) = real(crystallite_sizeResults(crystID),pReal)                                         ! size of results from cryst
  c = 1

  do o = 1, crystallite_Noutput(crystID)

    select case(crystallite_outputID(o, crystID))

      case (phase_ID)
        size_ = 1
        postResults(c+1) = real(matGr(gr)%ph, pReal)                                                   ! phaseID of grain

      case (texture_ID)
        size_ = 1
        postResults(c+1) = real(matGr(gr)%tex_id, pReal)                                          ! textureID of grain

      case (orientation_ID)
        size_ = 4
        postResults(c+1:c+size_) = ISVs(gr)%O%asQuaternion()                          ! grain orientation as quaternion

      case (eulerangles_ID)
        size_ = 3
        postResults(c+1:c+size_) = inDeg*ISVs(gr)%O%asEulers()                        ! grain orientation as Euler angles in degree

      case (grainrotation_ID)
        rot = matGr(gr)%O_0%misorientation(ISVs(gr)%O)
        size_ = 1
        axis_angle = rot%asAxisAngle()                                                   ! grain rotation away from initial orientation as axis-angle in sample reference coordinates
        if (axis_angle(4) > PI) axis_angle(4) = twoPI - axis_angle(4)
        postResults(c+1) = inDeg * axis_angle(4)                                                         ! angle in degree

      case (lep_ID)
        size_ = 6
        postResults(c+1:c+size_) = lnVp

      case (peq_ID)
        size_ = 1
        postResults(c+1:c+size_) = math_normal6(lnVp)/sqrt_onehalf

      case (energy_ID)
        size_ = 1
        postResults(c+1:c+size_) = ISVs(gr)%work(1)*stressunit

      case (dfc_ID)
        size_ = 1
        postResults(c+1:c+size_) = ISVs(gr)%dfc(1)

      case default
        size_ = 0
    end select
    c = c + size_
  enddo

  postResults(c+1) = real(plasticState(matGr(gr)%ph)%sizeResults, pReal)             ! size of constitutive results

  size_ = matGr(gr)%crystal_resultSize ! size(postResults)
  c = c + 1
  if (size_ > c) postResults(c+1:size_) = &
    constitutive_results(ISVs(gr)%S, ISVs(gr)%Fi, ISVs(gr)%Lp, gr)

end function crystallite_results


!--------------------------------------------------------------------------------------------------
!> @brief calculation of Lp & Li with time integration based on a residuum in Lp and
!> intermediate acceleration of the Newton-Raphson correction
!--------------------------------------------------------------------------------------------------
function integrateStress_stagger(F, subFp0, subFi0, Delta_t, gr) result(broken)

  real(pReal), dimension(3,3), intent(in) :: F,subFp0,subFi0
  real(pReal),                 intent(in) :: Delta_t
  integer,                     intent(in) :: gr
  logical :: broken

  !** local variables ***!
  real(pReal), dimension(3,3)::       Fp_new, &                                                       ! plastic deformation gradient at end of timestep
                                      Fe, &                                                       ! elastic deformation gradient at end of timestep
                                      invFp_new, &                                                    ! inverse of Fp_new
                                      Fi_new, &                                                       ! gradient of intermediate deformation stages
                                      invFi_new, &
                                      invFp_current, &                                                ! inverse of Fp_current
                                      invFi_current, &                                                ! inverse of Fp_current
                                      Lpguess, &                                                      ! current guess for plastic velocity gradient
                                      Lpguess_old, &                                                  ! known last good guess for plastic velocity gradient
                                      Lp_constitutive, &                                              ! plastic velocity gradient resulting from constitutive law
                                      residuumLp, &                                                   ! current residuum of plastic velocity gradient
                                      deltaLp, &                                                      ! direction of next guess
                                      Liguess, &                                                      ! current guess for intermediate velocity gradient
                                      Liguess_old, &                                                  ! known last good guess for intermediate velocity gradient
                                      Li_constitutive, &                                              ! intermediate velocity gradient resulting from constitutive law
                                      residuumLi, &                                                   ! current residuum of intermediate velocity gradient
                                      deltaLi, &                                                      ! direction of next guess
                                      Tstar33, &                                                      ! 2nd Piola-Kirchhoff Stress in plastic (lattice) configuration
                                      F_Fp0inv, &
                                      I_minus_dtLP, &
                                      F_Fpnewinv
  real(pReal), dimension(9)::         work                                                            ! needed for matrix inversion by LAPACK
  integer, dimension(9) ::            ipiv                                                            ! needed for matrix inversion by LAPACK
  real(pReal), dimension(9,9) ::      Jacobian
  real(pReal), dimension(3,3,3,3)::   dSedFe, &                                                       ! partial derivative of 2nd Piola-Kirchhoff stress
                                      dSedFi, &
                                      dLpdFi, &
                                      dLidFi, &
                                      dLidSe, &
                                      dLpdSe
  real(pReal)                     ::  steplengthLp, &
                                      steplengthLi, &
                                      aTolLp, &
                                      aTolLi, &
                                      norm2_Lp_t1, norm2_Li_t1, norm2_Lp_t0, norm2_Li_t0
  integer                             Niter_Lp, &                                           ! number of stress integrations
                                      Niter_Li, &                                           ! number of inner stress integrations
                                      ierr                                                         ! error indicator for LAPACK

  external :: dgesv
  logical  :: Li_dLidM_areZero, inv_error                                                                        ! if Li_dLidM_areZero is ture, the Li is zero, Fi is eye, all the derivative of Li and Fi are zero


  ! be pessimistic
  broken = .true.

  call constitutive_depState(gr)

  ! feed local variables
  Lpguess     = ISVs(gr)%Lp                                                  ! ... and take it as first guess
  Liguess     = ISVs(gr)%Li                                                  ! ... and take it as first guess
  Liguess_old = Liguess

  ! inversion of Fp_current...
  call math_invert33(subFp0, invFp_current, inv_error)
  if ( inv_error ) return

  ! inversion of Fi_current...
  call math_invert33(subFi0, invFi_current, inv_error)
  if ( inv_error ) return

  F_Fp0inv = matmul(F, invFp_current)                                                       ! intermediate tensor needed later to calculate dFe_dLp

  ! start LpLoop with normal step length
  Niter_Li     = 0
  steplengthLi = 1.0_pReal
  deltaLi      = 0.0_pReal
  norm2_Li_t0  = 1.0e16_pReal

  LiLoop: do
    Niter_Li = Niter_Li + 1
    if (Niter_Li > nStress) return

    invFi_new = matmul(invFi_current, math_I3 - Delta_t*Liguess)
    Fi_new    = math_inv33(invFi_new)

    ! start Lp loop with normal step length
    Niter_Lp     = 0
    steplengthLp = 1.0_pReal
    Lpguess_old  = Lpguess
    deltaLp      = 0.0_pReal
    norm2_Lp_t0  = 1.0e16_pReal

    LpLoop: do                                                                                      ! inner stress integration loop for consistency with Fi
      Niter_Lp = Niter_Lp + 1
      if (Niter_Lp > nStress) return

      ! calculate (elastic) 2nd Piola--Kirchhoff stress tensor and its tangent from constitutive law
      I_minus_dtLP = math_I3 - Delta_t*Lpguess
      F_Fpnewinv   = matmul(F_Fp0inv,I_minus_dtLP)
      Fe           = matmul(F_Fpnewinv, invFi_new)                                                  ! current elastic deformation tensor
      call phase_SandItsTangents(Tstar33, dSedFe, dSedFi, Fe, Fi_new, gr)                           ! call constitutive law to calculate 2nd Piola-Kirchhoff stress Se and its derivative in unloaded configuration

      ! calculate plastic velocity gradient and its tangent from constitutive law
      call plastic_LpAndItsTangents(Lp_constitutive, dLpdSe, dLpdFi, Tstar33, &
                                    Fi_new, gr, Li_dLidM_areZero)

      ! update current residuum and check for convergence of loop
      aTolLp = max(rtol_velocityGrad * max(norm2(Lpguess), norm2(Lp_constitutive)), &               ! absolute tolerance from largest acceptable relative error
                   atol_velocityGrad)                                                               ! minimum lower cutoff
      residuumLp  = Lpguess - Lp_constitutive
      norm2_Lp_t1 = norm2(residuumLp)

      if (any(IEEE_is_NaN(residuumLp))) then                                                        ! NaN in residuum...
        return                                                                                      ! ...me = .false. to inform integrator about problem
      elseif (norm2_Lp_t1 < aTolLp) then                                                            ! converged if below absolute tolerance
        exit LpLoop                                                                                 ! ...leave iteration loop
      elseif (norm2_Lp_t1 < norm2_Lp_t0) then                                                       ! not converged, but improved norm of residuum (always proceed in first iteration)...
        norm2_Lp_t0  = norm2_Lp_t1                                                                  ! ...remember old values and...
        Lpguess_old  = Lpguess
        steplengthLp = 1.0_pReal                                                                    ! ...proceed with normal step length (calculate new search direction)
      else                                                                                          ! not converged and residuum not improved...
        steplengthLp = subStepSizeLx * steplengthLp                                                 ! ...try with smaller step length in same direction
        if (steplengthLp < stepLengthLowBound) return
        Lpguess      = Lpguess_old + steplengthLp * deltaLp
        cycle LpLoop
      endif

      ! Jacobain, the partial derivative of Residuum (Lp) with respect to Lp
      Jacobian = dRLp_dLp(Delta_t, transpose(F_Fp0inv), transpose(invFi_new), dSedFe, dLpdSe)
      work = reshape(residuumLp, [9])

      call dgesv(9, 1, Jacobian, 9, ipiv, work, 9, ierr)                                                   ! solve dRLp/dLp * delta Lp = -res for delta Lp

      if (ierr /= 0) return
      deltaLp = -reshape(work, [3,3]) !math_9to33(work)

      Lpguess = Lpguess + steplengthLp * deltaLp
    enddo LpLoop

    ! calculate intermediate velocity gradient and its tangent from constitutive law
    call eigen_LiAndItsTangents(Li_constitutive, dLidSe, dLidFi, Tstar33, &
                                Fi_new, Fe, gr, Li_dLidM_areZero)

    ! update current residuum and check for convergence of loop
    aTolLi = max(rtol_velocityGrad * max(norm2(Liguess),norm2(Li_constitutive)), &                  ! absolute tolerance from largest acceptable relative error
                 atol_velocityGrad)                                                                 ! minimum lower cutoff
    residuumLi  = Liguess - Li_constitutive
    norm2_Li_t1 = norm2(residuumLi)
    if (any(IEEE_is_NaN(residuumLi))) then                                                          ! NaN in residuum...
      return                                                                                        ! ...me = .false. to inform integrator about problem
    elseif (norm2_Li_t1 < aTolLi) then                                                              ! converged if below absolute tolerance
      exit LiLoop                                                                                   ! ...leave iteration loop
    elseif (norm2_Li_t1 < norm2_Li_t0) then                                                         ! not converged, but improved norm of residuum (always proceed in first iteration)...
      norm2_Li_t0  = norm2_Li_t1                                                                    ! ...remember old values and...
      Liguess_old  = Liguess
      steplengthLi = 1.0_pReal                                                                      ! ...proceed with normal step length (calculate new search direction)
    else                                                                                            ! not converged and residuum not improved...
      steplengthLi = subStepSizeLx * steplengthLi                                                   ! ...try with smaller step length in same direction
      Liguess      = Liguess_old + steplengthLi * deltaLi
      cycle LiLoop
    endif

    ! Jacobain, the partial derivative of Residuum (Li) with respect to Li
    Jacobian = dRLi_dLi(Delta_t, Fi_new, invFi_current, F_Fpnewinv, dLidSe, dSedFe, dSedFi, dLidFi)
    work  = reshape(residuumLi, [9])

    call dgesv(9, 1, Jacobian, 9, ipiv, work, 9, ierr)                                               ! solve dRLi/dLp * delta Li = -res for delta Li

    if (ierr /= 0) return

    deltaLi = - reshape(work, [3,3]) !math_9to33(work)

    Liguess = Liguess + steplengthLi * deltaLi
  enddo LiLoop

  ! calculate new plastic and elastic deformation gradient
  invFp_new = matmul(invFp_current,I_minus_dtLP)
  invFp_new = invFp_new / math_det33(invFp_new)**one_third                               ! regularize by det
  call math_invert33(invFp_new, Fp_new, inv_error)
  if ( inv_error ) return

  ! calculate 2nd Piola-Kirchhoff stress
  ISVs(gr)%pk2 = matmul(invFp_new, matmul(Tstar33, transpose(invFp_new)) )

  ! store local values in global variables
  ISVs(gr)%Lp = Lpguess
  ISVs(gr)%Li = Liguess
  ISVs(gr)%S  = Tstar33
  ISVs(gr)%Fp = Fp_new
  ISVs(gr)%Fi = Fi_new
  ISVs(gr)%Fe = matmul(F, matmul(invFp_new, invFi_new) )

  ! set return flag to true
  broken = .false.

end function integrateStress_stagger


!--------------------------------------------------------------------------------------------------
!> @brief calculation of Lp with time integration based on a residuum in Lp and
!> intermediate acceleration of the Newton-Raphson correction
!--------------------------------------------------------------------------------------------------
function integrateStress_onlyLp(F, subFp0, subFi0, Delta_t, gr) result(broken)

  real(pReal), dimension(3,3), intent(in) :: F,subFp0,subFi0
  real(pReal),                 intent(in) :: Delta_t
  integer, intent(in) ::         gr
  logical :: broken

  !** local variables ***!
  real(pReal), dimension(3,3)::       Fp_new, &                                                       ! plastic deformation gradient at end of timestep
                                      Fe, &                                                           ! elastic deformation gradient at end of timestep
                                      invFp_new, &                                                    ! inverse of Fp_new
                                      invFp_current, &                                                ! inverse of Fp_current
                                      Lpguess, &                                                      ! current guess for plastic velocity gradient
                                      Lpguess_old, &                                                  ! known last good guess for plastic velocity gradient
                                      Lp_constitutive, &                                              ! plastic velocity gradient resulting from constitutive law
                                      residuumLp, &                                                   ! current residuum of plastic velocity gradient
                                      deltaLp, &                                                      ! direction of next guess
                                      Tstar33, &                                                      ! 2nd Piola-Kirchhoff Stress in plastic (lattice) configuration
                                      F_Fp0inv, &
                                      I_minus_dtLP
  real(pReal), dimension(9)::         work                                                            ! needed for matrix inversion by LAPACK
  integer, dimension(9) ::            ipiv                                                                  ! needed for matrix inversion by LAPACK
  real(pReal), dimension(9,9) ::      Jacobian                                                        ! partial derivative of residuum (Jacobian for NEwton-Raphson scheme)
  real(pReal), dimension(3,3,3,3)::   dSedFe, &                                                       ! partial derivative of 2nd Piola-Kirchhoff stress
                                      dLpdSe, &
                                      pLp_pLp
  real(pReal)                     ::  steplengthLp, &
                                      aTolLp, &
                                      norm2_Lp_t1, norm2_Lp_t0
  integer                             Niter_Lp, &                                                     ! number of inner stress integrations
                                      ierr                                                             ! error indicator for LAPACK
  external :: dgesv
  logical  :: Li_dLidM_areZero, inv_error                                                             ! if Li_dLidM_areZero is ture, the Li is zero, Fi is eye, all the derivative of Li and Fi are zero


  ! be pessimistic
  broken = .true.

  call constitutive_depState(gr)

  ! feed local variables
  Lpguess     = ISVs(gr)%Lp                                                                         ! ... and take it as first guess
  Lpguess_old = Lpguess

  ! inversion of Fp_current...
  call math_invert33(subFp0, invFp_current, inv_error)
  if ( inv_error ) return

  F_Fp0inv = matmul(F,invFp_current)                                                            ! intermediate tensor needed later to calculate dFe_dLp

  ! start LpLoop with normal step length
  Niter_Lp     = 0
  steplengthLp = 1.0_pReal
  deltaLp      = 0.0_pReal
  norm2_Lp_t0  = 1.0e16_pReal

  LpLoop: do
    Niter_Lp = Niter_Lp + 1
    if (Niter_Lp > nStress) return

    I_minus_dtLP = math_I3 - Delta_t*Lpguess
    Fe = matmul(F_Fp0inv, I_minus_dtLP)                                                             ! current elastic deformation tensor
    call phase_SandItsTangents(Tstar33, dSedFe, pLp_pLp, Fe, math_I3, gr)                           ! call constitutive law to calculate 2nd Piola-Kirchhoff stress Se and its derivative in unloaded configuration

    ! calculate plastic velocity gradient and its tangent from constitutive law
    call plastic_LpAndItsTangents(Lp_constitutive, dLpdSe, pLp_pLp, Tstar33, &
                                  math_I3, gr, Li_dLidM_areZero )

    ! update current residuum and check for convergence of loop
    aTolLp = max(rtol_velocityGrad * max(norm2(Lpguess),norm2(Lp_constitutive)), &                  ! absolute tolerance from largest acceptable relative error
                 atol_velocityGrad)                                                                 ! minimum lower cutoff
    residuumLp  = Lpguess - Lp_constitutive
    norm2_Lp_t1 = norm2(residuumLp)

    if (any(IEEE_is_NaN(residuumLp)) ) then                                                         ! NaN in residuum...
      return                                                                                        ! ...me = .false. to inform integrator about problem
    elseif ( norm2_Lp_t1 < aTolLp) then                                                             ! converged if below absolute tolerance
      exit LpLoop                                                                                   ! ...leave iteration loop
    elseif ( norm2_Lp_t1 < norm2_Lp_t0 ) then                                                       ! not converged, but improved norm of residuum (always proceed in first iteration)...
      norm2_Lp_t0  = norm2_Lp_t1                                                                    ! ...remember old values and...
      Lpguess_old  = Lpguess
      steplengthLp = 1.0_pReal                                                                      ! ...proceed with normal step length (calculate new search direction)
    else                                                                                            ! not converged and residuum not improved...
      steplengthLp = subStepSizeLx * steplengthLp                                                   ! ...try with smaller step length in same direction
      if (steplengthLp < stepLengthLowBound) return
      Lpguess = Lpguess_old + steplengthLp * deltaLp
      cycle LpLoop
    endif

    ! calculate Jacobian for correction term
    Jacobian = dRLp_dLp(Delta_t, transpose(F_Fp0inv), dSedFe, dLpdSe)
    work = reshape(residuumLp, [9])

    call dgesv(9,1,Jacobian,9,ipiv,work,9,ierr)                                              ! solve dRLp/dLp * delta Lp = -res for delta Lp
    if (ierr /= 0) return
    deltaLp = -reshape(work, [3,3])

    Lpguess = Lpguess + steplengthLp * deltaLp
  enddo LpLoop

  ! calculate new plastic and elastic deformation gradient
  invFp_new = matmul(invFp_current, I_minus_dtLP)
  invFp_new = invFp_new/math_det33(invFp_new)**one_third                                            ! regularize by det

  call math_invert33(invFp_new, Fp_new, inv_error)
  if ( inv_error ) return

  ! calculate 2nd Piola-Kirchhoff stress
  ISVs(gr)%pk2 = matmul(invFp_new, matmul(Tstar33, transpose(invFp_new)) )

  ! store local values in global variables
  ISVs(gr)%Lp = Lpguess
  ISVs(gr)%S  = Tstar33
  ISVs(gr)%Fp = Fp_new
  ISVs(gr)%Fe = matmul(F,invFp_new)

  ! set return flag to true
  broken = .false.

end function integrateStress_onlyLp


!--------------------------------------------------------------------------------------------------
!> @brief integrate stress, state with adaptive 1st order explicit Euler method
!> using Fixed Point Iteration to adapt the stepsize
!--------------------------------------------------------------------------------------------------
function integrateStateFPI(F_0,F,subFp0,subFi0,subState0,Delta_t,gr,ph,en) result(broken)

  integer, intent(in) :: gr, ph, en
  real(pReal), intent(in),dimension(3,3) :: F_0, F, subFp0, subFi0
  real(pReal), intent(in),dimension(:)   :: subState0
  real(pReal), intent(in) :: Delta_t

  real(pReal) :: zeta                                                                               ! damper for integration of state
  real(pReal), dimension(size(subState0)) :: &
    residuum, corrected, &
    dotState1, dotState2
  logical :: broken, converged_
  integer :: size_pl, niter


  broken = phase_plastic_dotState(ISVs(gr)%S, ISVs(gr)%Fi, gr)
  if (broken) return

  size_pl = plasticState(ph)%sizeDotState
  plasticState(ph)%state(1:size_pl, en) = subState0 + plasticState(ph)%dotState(:, en)*Delta_t

  dotState2 = 0.0_pReal

  iteration: do niter = 1, nState
    dotState1 = plasticState(ph)%dotState(:,en)

    broken = integrateStress(F, subFp0, subFi0, Delta_t, gr)
    if(broken) exit iteration

    broken = phase_plastic_dotState(ISVs(gr)%S, ISVs(gr)%Fi, gr)
    if(broken) exit iteration

    zeta = FPI_damper(plasticState(ph)%dotState(:,en), dotState1, dotState2)

    if (dNeq(zeta, 1.0_pReal) )&
      plasticState(ph)%dotState(:,en) = zeta*plasticState(ph)%dotState(:,en) + (1.0_pReal-zeta)*dotState1

    corrected = subState0 + plasticState(ph)%dotState(:,en) * Delta_t
    residuum   = plasticState(ph)%state(1:size_pl,en) - corrected
    converged_ = fpi_converged(residuum, corrected, plasticState(ph)%atol(1:size_pl) )

    plasticState(ph)%state(1:size_pl,en) = corrected

    if(converged_) then
      broken = phase_plastic_deltaState(ph,en)
      exit iteration
    endif
    dotState2 = dotState1
  enddo iteration

end function integrateStateFPI


!--------------------------------------------------------------------------------------------------
!> @brief determines whether a point is converged
!--------------------------------------------------------------------------------------------------
logical pure function fpi_converged(res,state,aTol)

  real(pReal), intent(in), dimension(:) ::res, state, aTol

  fpi_converged = all(abs(res) <= max(aTol, crystalliteState_rtol*abs(state)))

end function fpi_converged


!---------------------------------------------------------------------------------------------------
!> @brief Integrate state (including stress integration) with the classic Runge Kutta method
!---------------------------------------------------------------------------------------------------
function integrateStateRK4(F_0,F,subFp0,subFi0,subState0,Delta_t,gr,ph,en) result(broken)

  real(pReal), intent(in),dimension(3,3) :: F_0,F,subFp0,subFi0
  real(pReal), intent(in),dimension(:)   :: subState0
  real(pReal), intent(in) :: Delta_t
  integer, intent(in) :: gr, ph, en
  logical :: broken

  real(pReal), dimension(4), parameter :: &
    A = [1.0_pReal, 0.5_pReal, 0.5_pReal, 1.0_pReal]
  real(pReal), dimension(4), parameter :: &
    B = [1.0_pReal, 2.0_pReal, 2.0_pReal, 1.0_pReal]/6.0_pReal
  integer :: stage, size_pl
  real(pReal), dimension(size(subState0), 4) :: plastic_RKdotState
  real(pReal), dimension(3,3) :: deltaF


  broken = phase_plastic_dotState(ISVs(gr)%S, ISVs(gr)%Fi, gr)
  if (broken) return

  deltaF = (F-F_0)*Delta_t

  size_pl = plasticState(ph)%sizeDotState
  plastic_RKdotState(:,1) = plasticState(ph)%dotState(:, en)

  do stage = 2, 4
    plasticState(ph)%state(1:size_pl,en) = subState0 + &
        A(stage) * plastic_RKdotState(:, stage-1) * Delta_t

    broken = integrateStress(F_0 + deltaF*A(stage),subFp0,subFi0,Delta_t*A(stage), gr)
    if(broken) exit

    broken = phase_plastic_dotState(ISVs(gr)%S, ISVs(gr)%Fi, gr)
    if (broken) exit
    plastic_RKdotState(:,stage) = plasticState(ph)%dotState(:, en)
  enddo

  plasticState(ph)%dotState(:, en) = matmul(plastic_RKdotState, B)
  plasticState(ph)%state(1:size_pl,en) = subState0 + &
    plasticState(ph)%dotState(:, en)*Delta_t

  broken = integrateStress(F,subFp0,subFi0,Delta_t, gr)
  ! broken = phase_plastic_deltaState(ph, en)
  if(broken) return

end function integrateStateRK4


!--------------------------------------------------------------------------------------------------
!> @brief integrate state with 1st order explicit Euler method
!--------------------------------------------------------------------------------------------------
function integrateStateEuler(F_0,F,subFp0,subFi0,subState0,Delta_t,gr,ph,en) result(broken)

  real(pReal), intent(in),dimension(3,3) :: F_0,F,subFp0,subFi0
  real(pReal), intent(in),dimension(:)   :: subState0
  real(pReal), intent(in) :: Delta_t
  integer, intent(in) :: gr, ph, en
  logical :: broken
  integer :: sizeDotState


  broken = phase_plastic_dotState(ISVs(gr)%S, ISVs(gr)%Fi, gr)
  if (broken) return

  sizeDotState = plasticState(ph)%sizeDotState
  plasticState(ph)%state(1:sizeDotState,en) = subState0 + &
    plasticState(ph)%dotState(:, en)*Delta_t

  broken = phase_plastic_deltaState(ph,en)
  if(broken) return

  broken = integrateStress(F,subFp0,subFi0,Delta_t, gr)

end function integrateStateEuler


!--------------------------------------------------------------------------------------------------
!> @brief integrate stress, state with adaptive 1st order explicit Euler method
!> using Fixed Point Iteration to adapt the stepsize
!--------------------------------------------------------------------------------------------------
function integrateDamageState(Delta_t, gr, ph, en) result(broken)

  real(pReal), intent(in) :: Delta_t
  integer, intent(in) :: gr, ph, en
  logical :: broken

  integer :: &
    niter, &                                                                              !< number of iterations in state loop
    size_so
  real(pReal) :: &
    zeta
  real(pReal), dimension(damageState(ph)%sizeDotState) :: &
    residuum, corrected, &
    dotState1, dotState2
  logical :: converged_


  if (damageState(ph)%sizeState == 0) then
    broken = .false.
    return
  endif

  broken = phase_damage_dotState(ISVs(gr)%S, ISVs(gr)%Fi, ISVs(gr)%Fe, gr, ph,en)
  if (broken) return

  size_so = damageState(ph)%sizeDotState
  damageState(ph)%state(1:size_so,en) = damageState(ph)%state0  (1:size_so,en) &
                                      + damageState(ph)%dotState(:,en) * Delta_t
  dotState2 = 0.0_pReal

  iteration: do niter = 1, nState
    dotState1 = damageState(ph)%dotState(:,en)

    broken = phase_damage_dotState(ISVs(gr)%S, ISVs(gr)%Fi, ISVs(gr)%Fe, gr, ph,en)
    if (broken) exit iteration

    zeta = FPI_damper(damageState(ph)%dotState(:,en), dotState1, dotState2)
    damageState(ph)%dotState(:,en) = damageState(ph)%dotState(:,en) * zeta + &
                                     dotState1* (1.0_pReal - zeta)

    corrected  = damageState(ph)%state0  (1:size_so,en) + &
                 damageState(ph)%dotState(:,en) * Delta_t
    residuum   = damageState(ph)%state(1:size_so,en)  - corrected
    converged_ = fpi_converged(residuum, corrected, damageState(ph)%atol(1:size_so))

    damageState(ph)%state(1:size_so,en) = corrected

    if (converged_) then
      broken = phase_damage_deltaState(ISVs(gr)%Fe, gr, ph, en)
      exit iteration
    endif

  enddo iteration

  broken = broken .or. .not. converged_

end function integrateDamageState


!--------------------------------------------------------------------------------------------------
!> @brief integrate stress, state with adaptive 1st order explicit Euler method
!> using Fixed Point Iteration to adapt the stepsize
!--------------------------------------------------------------------------------------------------
function integrateThermalState(Delta_t, gr, ph, en) result(broken)

  real(pReal), intent(in) :: Delta_t
  integer, intent(in) :: gr, ph, en
  logical :: broken
  integer :: so, size_so


  broken = phase_thermal_dotState(ph, en)
  if (broken) return

  do so = 1, phase_Nthermal(ph)
    size_so = thermalState(ph)%p(so)%sizeDotState
    if (size_so > 0) then  ! euler forward
      thermalState(ph)%p(so)%state(1:size_so,en) = thermalState(ph)%p(so)%state(1:size_so,en) + &
        thermalState(ph)%p(so)%dotState(:, en) * Delta_t
    endif
  enddo

end function integrateThermalState


!--------------------------------------------------------------------------------------------------
!> @brief Forward data after successful increment.
! ToDo: Any guessing for the current states possible?
!--------------------------------------------------------------------------------------------------
subroutine materialpoint_forward

  integer :: gr, ph, so, ho


  ! homogenization_forward, damage and thermal forward, no mechancial
  do ho = 1, material_Nhomog
    thermalState_h(ho)%state0 = thermalState_h(ho)%state
    damageState_h (ho)%state0 = damageState_h (ho)%state
  enddo

  ! phase level
  ! mechancial forward
  forall (gr = 1: NmatGrs)
    ISVs(gr)%F0  = ISVs(gr)%F
    ISVs(gr)%Fp0 = ISVs(gr)%Fp
    ISVs(gr)%Lp0 = ISVs(gr)%Lp
    ISVs(gr)%Fi0 = ISVs(gr)%Fi
    ISVs(gr)%Li0 = ISVs(gr)%Li
  end forall

  do ph = 1, material_Nphase
    plasticState(ph)%state0 = plasticState(ph)%state

    ! damage forward
    if (damageState(ph)%sizeState > 0) &
      damageState(ph)%state0 = damageState(ph)%state

    ! thermal forward, could be multiple thermal sources
    do so = 1, phase_Nthermal(ph)
      if (thermalState(ph)%p(so)%sizeState > 0) &
        thermalState(ph)%p(so)%state0 = thermalState(ph)%p(so)%state
    enddo
  enddo

end subroutine materialpoint_forward


!--------------------------------------------------------------------------------------------------
!> @brief Restore data after homog cutback. No cutback, not required
!--------------------------------------------------------------------------------------------------
subroutine phase_restore(gr)

  integer, intent(in) :: gr
  integer :: ph, en, so


  ! ISVs(gr)%Lp = ISVs(gr)%Lp0
  ! ISVs(gr)%Li = ISVs(gr)%Li0

  ISVs(gr)%Fp = ISVs(gr)%Fp0
  ISVs(gr)%Fi = ISVs(gr)%Fi0

  ph = matGr(gr)%ph; en = matGr(gr)%phAt

  plasticState(ph)%state(:, en) = plasticState(ph)%state0(:, en)

  if (damageState(ph)%sizeState > 0) &
      damageState(ph)%state(:, en) = damageState(ph)%state0(:, en)

  do so = 1, phase_Nthermal(ph)
    if (thermalState(ph)%p(so)%sizeState > 0) &
      thermalState(ph)%p(so)%state(:, en) = thermalState(ph)%p(so)%state0(:, en)
  enddo
end subroutine phase_restore

!--------------------------------------------------------------------------------------------------
!> @brief return results of particular grain
!--------------------------------------------------------------------------------------------------
subroutine crystallite_updateIntegratedISV(gr, mat_dt)
  use constitutive_dfc, only: &
    constitutive_updateDFCinc

  integer, intent(in)         :: gr
  real(pReal), intent(in)     :: mat_dt
  real(pReal), dimension(3,3) :: BungeRot, Cauchy_mat, Cauchy_lattice, int_avgLp


  if (any(crystallite_hasIntegratedISVs)) then
    BungeRot   = ISVs(gr)%O%asMatrix()

    Cauchy_mat = matmul(ISVs(gr)%F, matmul(ISVs(gr)%pk2, transpose(ISVs(gr)%F)) )
    Cauchy_mat = Cauchy_mat / math_det33( ISVs(gr)%F )

    Cauchy_lattice = matmul(BungeRot, matmul(cauchy_mat, transpose(BungeRot)) )                  ! Q\sigma Q^T

    int_avgLp = (0.5_pReal * mat_dt) * (ISVs(gr)%Lp0 + ISVs(gr)%Lp)
  else
    return
  endif

  ! request the output of energy/plastic work
  if (crystallite_hasIntegratedISVs(1)) then
    ISVs(gr)%work(2) = abs( sum(Cauchy_lattice*int_avgLp) )
    ISVs(gr)%work(1) = ISVs(gr)%work(1) + ISVs(gr)%work(2)
  endif

  ! request the output of dfc
  if (crystallite_hasIntegratedISVs(2)) then
    ISVs(gr)%dfc(2) = constitutive_updateDFCinc(Cauchy_lattice, int_avgLp, gr)
    ISVs(gr)%dfc(1) = ISVs(gr)%dfc(1) + ISVs(gr)%dfc(2)
  endif

end subroutine crystallite_updateIntegratedISV


!--------------------------------------------------------------------------------------------------
!> @brief return results of particular grain
!--------------------------------------------------------------------------------------------------
subroutine crystallite_recallIntegratedISV(gr)

  integer, intent(in) :: gr

  ! request the output of energy/plastic work
  if (crystallite_hasIntegratedISVs(1)) &
    ISVs(gr)%work(1) = ISVs(gr)%work(1) - ISVs(gr)%work(2)

  ! request the output of dfc
  if (crystallite_hasIntegratedISVs(2)) &
    ISVs(gr)%dfc(1) = ISVs(gr)%dfc(1) - ISVs(gr)%dfc(2)

end subroutine crystallite_recallIntegratedISV

end module crystallite
