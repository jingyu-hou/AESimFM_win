!--------------------------------------------------------------------------------------------------
!> @author Zhang Haiming, Shanghai Jiao Tong University, hm.zhang@sjtu.edu.cn
!> @brief elasticity, plasticity, internal microstructure state
!--------------------------------------------------------------------------------------------------
module constitutive
  use prec
  use constants
  use material
  use math
  use cpfemlib

  implicit none
  public

  type :: tPlastic_procedures
    procedure(), pointer, nopass :: LpAndItsTangent
    procedure(), pointer, nopass :: dotState
    procedure(), pointer, nopass :: postResults
  end type
  type(tPlastic_procedures), dimension(:), allocatable, private :: pl_procedures

  private :: &
    constitutive_homogenizedC

contains


!--------------------------------------------------------------------------------------------------
!> @brief allocates arrays pointing to array of the various constitutive modules
!--------------------------------------------------------------------------------------------------
subroutine constitutive_init
  use numerics, only: &
    worldrank
  use IO, only: &
    IO_error, &
    IO_write_jobFile
  use config, only: &
    config_name_phase, &
    config_deallocate
  use rotations, only: &
    tRotation

  use plastic_none
  use plastic_isotropic
  use plastic_superPlastic
  use plastic_phenopowerlaw
  use plastic_phenopowerlawClassic
  use plastic_dislotwin
  use plastic_disloKM
  use plastic_kmjmak
  use THERMAL_dissipation
  use THERMAL_externalheat
  use DAMAGE_isoBrittle
  use DAMAGE_isoDuctile
  use DAMAGE_anisoBrittle
  use DAMAGE_anisoDuctile
  use DAMAGE_voidMC
  use cleavage_opening
  use EIGEN_slipplane_opening
  use EIGEN_damage_voidMC
  use EIGEN_thermal_expansion
  use constitutive_dfc

  integer, parameter :: FILEUNIT = 204
  integer :: o, ph, so, gr


  write(6,'(/,a)')   ' <<<+-  constitutive init  -+>>>'
  write(6,*) 'Compiled on ', __DATE__,' at ',__TIME__; write(6,*); flush(6)

  ! parse plasticities from config file
  if (any(phase_plastic == PLASTICITY_NONE_ID))          call plastic_none_init
  if (any(phase_plastic == PLASTICITY_ISOTROPIC_ID))     call plastic_isotropic_init
  if (any(phase_plastic == PLASTICITY_SUPERPLASTIC_ID))  call plastic_superPlastic_init
  if (any(phase_plastic == PLASTICITY_PHENOPOWERLAW2_ID))call plastic_phenopowerlawClassic_init
  if (any(phase_plastic == PLASTICITY_DISLOKM_ID))       call plastic_disloKM_init
  if (any(phase_plastic == PLASTICITY_KMJMAK_ID))        call plastic_kmjmak_init
  if (mapISVtoFEmesh) call material_deallocateISV0()

  ! parse source mechanisms from config file
  if (any(phase_thermal == THERMAL_dissipation_ID))      call THERMAL_dissipation_init
  if (any(phase_thermal == THERMAL_externalheat_ID))     call THERMAL_externalheat_init
  if (any(phase_damage  == DAMAGE_isoBrittle_ID))        call DAMAGE_isoBrittle_init
  if (any(phase_damage  == DAMAGE_isoDuctile_ID))        call DAMAGE_isoDuctile_init
  if (any(phase_damage  == DAMAGE_anisoBrittle_ID))      call DAMAGE_anisoBrittle_init
  if (any(phase_damage  == DAMAGE_anisoDuctile_ID))      call DAMAGE_anisoDuctile_init
  if (any(phase_damage  == DAMAGE_voidMC_ID))            call DAMAGE_voidMC_init

  ! parse kinematic mechanisms from config file
  if (any(phase_eigen == EIGEN_cleavage_opening_ID))     call EIGEN_cleavage_opening_init
  if (any(phase_eigen == EIGEN_slipplane_opening_ID))    call EIGEN_slipplane_opening_init
  if (any(phase_eigen == EIGEN_damage_voidMC_ID))        call EIGEN_damage_voidMC_init
  if (any(phase_eigen == EIGEN_thermal_expansion_ID))    call EIGEN_thermal_expansion_init

  if (material_DFC_specified) call constitutive_dfc_init
  call config_deallocate('material.config/phase')

  mainProcess: if (worldrank == 0) then

    ! write description file for constitutive output
    call IO_write_jobFile(FILEUNIT, 'outputConstitutive')

    do ph = 1,material_Nphase
      if (any(matGr%ph == ph)) then
        associate(pot => phase_outputs(ph))

        ! plasticity
        write(FILEUNIT,'(/,a,/)') '['//trim(config_name_phase(ph))//']'
        if (len(trim(pot%pl_name)) > 0) then
          write(FILEUNIT,'(a)') '(plasticity)'//char(9)//trim(pot%pl_name)
          if (phase_plastic(ph) /= PLASTICITY_NONE_ID) then
            do o = 1, size(pot%pl_ou_labels)
              if(len(trim(pot%pl_ou_labels(o))) > 0) &
                write(FILEUNIT,'(a,i4)') trim(pot%pl_ou_labels(o))//char(9), pot%pl_ou_size(o)
            enddo
          endif
        endif

        ! damage
        if (len(trim(pot%da_name)) > 0) then
          write(FILEUNIT,'(a)') '(damage)'//char(9)//trim(pot%da_name)
          do o = 1, size(pot%da_ou_labels)
            if(len(trim(pot%da_ou_labels(o))) > 0) &
              write(FILEUNIT,'(a,i4)') trim(pot%da_ou_labels(o))//char(9), pot%da_ou_size(o)
          enddo
        endif

        ! thermal, could be multiple sources
        do so = 1, phase_Nthermal(ph)

          if (len(trim(pot%th_name(so))) > 0) then
            write(FILEUNIT,'(a)') '(thermal)'//char(9)//trim(pot%th_name(so))
            do o = 1, size(pot%th_ou_labels(:, so))
              if(len(trim(pot%th_ou_labels(o, so))) > 0) &
                write(FILEUNIT,'(a,i4)') trim(pot%th_ou_labels(o, so))//char(9), pot%th_ou_size(o, so)
            enddo
          endif
        enddo

        end associate
      endif
    enddo
    close(FILEUNIT)
  endif mainProcess

  !$OMP PARALLEL DO
  do gr = 1, size(matGr)
    matGr(gr)%constit_resultsize = plasticState(matGr(gr)%ph)%sizeResults + &
      damageState(matGr(gr)%ph)%sizeResults + &
      sum(thermalState(matGr(gr)%ph)%p(:)%sizeResults)
  enddo
  !$OMP END PARALLEL DO

  allocate(pl_procedures(material_Nphase))

  do ph = 1, material_Nphase

    select case (phase_plastic(ph))

      case (PLASTICITY_NONE_ID)
        pl_procedures(ph)%LpAndItsTangent => plastic_none_LpAndItsTangent
        pl_procedures(ph)%dotState        => plastic_none_dotState
        pl_procedures(ph)%postResults     => plastic_none_results
      case (PLASTICITY_ISOTROPIC_ID)
        pl_procedures(ph)%LpAndItsTangent => plastic_isotropic_LpAndItsTangent
        pl_procedures(ph)%dotState        => plastic_isotropic_dotState
        pl_procedures(ph)%postResults     => plastic_isotropic_results
      case (PLASTICITY_SUPERPLASTIC_ID)
        pl_procedures(ph)%LpAndItsTangent => plastic_superPlastic_LpAndItsTangent
        pl_procedures(ph)%dotState        => plastic_superPlastic_dotState
        pl_procedures(ph)%postResults     => plastic_superPlastic_results
      case (PLASTICITY_PHENOPOWERLAW2_ID)
        pl_procedures(ph)%LpAndItsTangent => plastic_phenopowerlawClassic_LpAndItsTangent
        pl_procedures(ph)%dotState        => plastic_phenopowerlawClassic_dotState
        pl_procedures(ph)%postResults     => plastic_phenopowerlawClassic_results
      case (PLASTICITY_DISLOKM_ID)
        pl_procedures(ph)%LpAndItsTangent => plastic_disloKM_LpAndItsTangent
        pl_procedures(ph)%dotState        => plastic_disloKM_dotState
        pl_procedures(ph)%postResults     => plastic_disloKM_results
      case (PLASTICITY_KMJMAK_ID)
        pl_procedures(ph)%LpAndItsTangent => plastic_kmjmak_LpAndItsTangent
        pl_procedures(ph)%dotState        => plastic_kmjmak_dotState
        pl_procedures(ph)%postResults     => plastic_kmjmak_results
    end select
  enddo

end subroutine constitutive_init


!--------------------------------------------------------------------------------------------------
!> @brief returns the homogenize elasticity matrix
!> ToDo: homogenizedC66 would be more consistent
!--------------------------------------------------------------------------------------------------
function constitutive_homogenizedC(gr)
  use plastic_dislotwin, only: &
    plastic_dislotwin_homogenizedC
  use lattice, only: &
    lattice_C66
  use DAMAGE_voidMC, only: &
    DAMAGE_voidMC_homogenizedC

  integer, intent(in) :: gr
  real(pReal), dimension(6,6) :: constitutive_homogenizedC
  integer :: ph


  ph  = matGr(gr)%ph

  select case (phase_plastic(ph))
    case (PLASTICITY_DISLOTWIN_ID)
      constitutive_homogenizedC = plastic_dislotwin_homogenizedC(ph, matGr(gr)%phAt)
    case default
      constitutive_homogenizedC = lattice_C66(1:6,1:6, ph)
  end select

  select case (phase_damage(ph))
    case (DAMAGE_voidMC_ID)
      constitutive_homogenizedC = &
        DAMAGE_voidMC_homogenizedC(ph,matGr(gr)%phAt,constitutive_homogenizedC)
  end select

end function constitutive_homogenizedC


!--------------------------------------------------------------------------------------------------
!> @brief calls microstructure function of the different constitutive models
!--------------------------------------------------------------------------------------------------
subroutine constitutive_depState(gr)
  use plastic_dislotwin, only: &
    plastic_dislotwin_depState
  use plastic_disloKM, only: &
    plastic_disloKM_depState
  use plastic_kmjmak, only: &
    plastic_kmjmak_depState
  use plastic_phenopowerlaw, only: &
    plastic_phenopowerlaw_depState

  integer, intent(in) :: gr
  integer :: en,ho


  associate( mgr => matGr(gr))

  select case (phase_plastic(mgr%ph))

    case (PLASTICITY_DISLOTWIN_ID)
      en = thermalAt(matPt(mgr%mt)%ho)%p(mgr%mt)
      call plastic_dislotwin_depState(temperature(matPt(mgr%mt)%ho)%val(en),mgr%ph,mgr%phAt,mgr%gr_id)

    case (PLASTICITY_DISLOKM_ID)
      call plastic_disloKM_depState(mgr%ph,mgr%phAt,mgr%gr_id)

    case (PLASTICITY_KMJMAK_ID)
      ho = matPt(mgr%mt)%ho
      call plastic_kmjmak_depState(mgr%ph,mgr%phAt,temperature(ho)%val(thermalAt(ho)%p(mgr%mt)),mgr%gr_id)

    case (PLASTICITY_PHENOPOWERLAW_ID)
      call plastic_phenopowerlaw_depState(mgr%ph,mgr%phAt)

  end select
  end associate

end subroutine constitutive_depState


!--------------------------------------------------------------------------------------------------
!> @brief  contains the constitutive equation for calculating the velocity gradient RIGHT20180702
!--------------------------------------------------------------------------------------------------
subroutine plastic_LpAndItsTangents(Lp, dLp_dS, dLp_dFi, Sstar33, Fi, gr, Li_dLidM_areZero)

  integer, intent(in) :: gr
  real(pReal),   intent(in),  dimension(3,3) :: &
    Sstar33, Fi                                                                                      !< intermediate deformation gradient
  real(pReal),   intent(out), dimension(3,3) :: &
    Lp                                                                                               !< plastic velocity gradient
  real(pReal),   intent(out), dimension(3,3,3,3) :: &
    dLp_dS, &                                                                                        !< derivative mgr%phAt Lp with respect to Tstar (4th-order tensor)
    dLp_dFi                                                                                          !< derivative mgr%phAt Lp with respect to Fi (4th-order tensor)
  real(pReal), dimension(3,3) :: &
    FiTFi, Mp
  real(pReal), dimension(3,3,3,3) :: dLp_dMp
  integer :: ph, ho
  logical, intent(in) :: Li_dLidM_areZero


  associate( mgr => matGr(gr))
  ph = mgr%ph
  FiTFi = matmul(transpose(Fi), Fi)

  Mp = matmul(FiTFi,Sstar33)                                                                   !< non-symmetric when Fi is not a eye tensor

  ho = matPt(mgr%mt)%ho
  call pl_procedures(ph)%LpAndItsTangent(Lp, dLp_dMp, Mp, &
       temperature(ho)%val(thermalAt(ho)%p(mgr%mt)), ph, mgr%phAt, mgr%gr_id)
  end associate

  if (.not. Li_dLidM_areZero) then
    call Lp_tangent(Fi, Sstar33, FiTFi, dLp_dMp, dLp_dFi, dLp_dS)
  else
    dLp_dFi = 0.0_pReal
    dLp_dS  = dLp_dMp
  endif

end subroutine plastic_LpAndItsTangents


!--------------------------------------------------------------------------------------------------
!> @brief  contains the constitutive equation for calculating the velocity gradient RIGHT20180702
!--------------------------------------------------------------------------------------------------
subroutine eigen_LiAndItsTangents(Li, dLi_dS, dLi_dFi, Sstar33, Fi, Fe, gr, Li_dLidM_areZero)
  use plastic_isotropic, only: &
    plastic_isotropic_LiAndItsTangent
  use cleavage_opening, only: &
    EIGEN_cleavage_opening_LiAndItsTangent
  use EIGEN_slipplane_opening, only: &
    EIGEN_slipplane_opening_LiAndItsTangent
  use EIGEN_damage_voidMC, only: &
    EIGEN_damage_voidMC_LiAndItsTangent
  use EIGEN_thermal_expansion, only: &
    EIGEN_thermal_expansion_LiAndItsTangent


  integer, intent(in) :: gr
  real(pReal),   intent(in),  dimension(3,3) :: &
    Sstar33,Fi,Fe                                                                                    !< intermediate deformation gradient
  real(pReal),   intent(out), dimension(3,3) :: &
    Li                                                                                               !< intermediate velocity gradient
  real(pReal),   intent(out), dimension(3,3,3,3) :: &
    dLi_dS, &                                                                                        !< derivative mgr%phAt Li with respect to Tstar (4th-order tensor)
    dLi_dFi
  real(pReal), dimension(3,3) :: &
    Li_, Mp                                                                                    !< intermediate velocity gradient
  real(pReal), dimension(3,3,3,3) :: &
    dLi_dSstar_, dLi_dMstar_, dLi_dFi_,dLi_dMstar
  integer :: ph, k

  logical :: noLiDueToSource
  logical, intent(out) :: Li_dLidM_areZero


  associate( mgr => matGr(gr))
  ph = mgr%ph

  Li = 0.0_pReal; dLi_dS = 0.0_pReal; dLi_dMstar = 0.0_pReal
  dLi_dFi = 0.0_pReal; Li_dLidM_areZero  = .true.

  Mp = matmul(Fi, matmul(Sstar33, transpose(Fi) ))

  if (phase_plastic(ph) == PLASTICITY_isotropic_ID) &
    call plastic_isotropic_LiAndItsTangent(Li_, dLi_dSstar_, Sstar33, ph, mgr%phAt, Li_dLidM_areZero)

  if (.not. Li_dLidM_areZero) then
    Li = Li + Li_
    dLi_dS = dLi_dS + dLi_dSstar_
  endif

  do k = 1, phase_Neigen(ph)
    noLiDueToSource = .False.

    select case (phase_eigen(k,ph))
      case (EIGEN_cleavage_opening_ID)
        call EIGEN_cleavage_opening_LiAndItsTangent(Li_, dLi_dSstar_, Sstar33, mgr%mt, ph)
        dLi_dS = dLi_dS + dLi_dSstar_

      case (EIGEN_slipplane_opening_ID)
        call EIGEN_slipplane_opening_LiAndItsTangent(Li_, dLi_dSstar_, Sstar33, mgr%mt, ph)
        dLi_dS = dLi_dS + dLi_dSstar_

      case (EIGEN_damage_voidMC_ID)
        call EIGEN_damage_voidMC_LiAndItsTangent(Li_, dLi_dMstar_, dLi_dFi_, Mp,Fi,Fe, ph, mgr%phAt)
        dLi_dMstar = dLi_dMstar + dLi_dMstar_
        dLi_dFi    = dLi_dFi + dLi_dFi_

      case (EIGEN_thermal_expansion_ID)
        call EIGEN_thermal_expansion_LiAndItsTangent(Li_, dLi_dSstar_, mgr%mt,ph)
        dLi_dS = dLi_dS + dLi_dSstar_

      case default
        noLiDueToSource = .True.
    end select

    if (.not. noLiDueToSource) then
      Li = Li + Li_
      Li_dLidM_areZero = .false.
    endif
  enddo
  end associate


  if(.not. Li_dLidM_areZero) call Li_tangent(Fi, Sstar33, dLi_dMstar, dLi_dS, dLi_dFi)

end subroutine eigen_LiAndItsTangents


!--------------------------------------------------------------------------------------------------
!> @brief  collects initial intermediate deformation gradient
!--------------------------------------------------------------------------------------------------
pure function constitutive_initialFi(gr)
  use EIGEN_thermal_expansion, only: &
    EIGEN_thermal_expansion_initialStrain

  integer, intent(in) :: gr
  real(pReal), dimension(3,3) :: &
    constitutive_initialFi                                                                           !< composite initial intermediate deformation gradient
  integer :: k                                                                             !< counter in kinematics loop


  constitutive_initialFi = math_I3

  associate( mgr => matGr(gr))
  do k = 1, phase_Neigen(mgr%ph)                                               !< Warning: small initial strain assumption
    select case (phase_eigen(k, mgr%ph))
      case (EIGEN_thermal_expansion_ID)
        constitutive_initialFi = &
          constitutive_initialFi + EIGEN_thermal_expansion_initialStrain(mgr%mt, mgr%ph)
    end select
  enddo
  end associate

end function constitutive_initialFi


!--------------------------------------------------------------------------------------------------
!> @brief returns the 2nd Piola-Kirchhoff stress tensor and its tangent with respect to
!> the elastic and intermeidate deformation gradients using Hookes law PASS
!--------------------------------------------------------------------------------------------------
subroutine phase_SandItsTangents(S, dS_dFe, dS_dFi, Fe, Fi, gr)

  integer, intent(in) :: gr
  real(pReal),   intent(in),  dimension(3,3) :: &
    Fe, &                                                                                            !< elastic deformation gradient
    Fi                                                                                               !< intermediate deformation gradient
  real(pReal),   intent(out), dimension(3,3) :: &
    S                                                                                                !< 2nd Piola-Kirchhoff stress tensor in lattice configuration
  real(pReal),   intent(out), dimension(3,3,3,3) :: &
    dS_dFe, &                                                                                        !< derivative mgr%phAt 2nd mgr%ph-K stress with respect to elastic deformation gradient
    dS_dFi                                                                                           !< derivative mgr%phAt 2nd mgr%ph-K stress with respect to intermediate deformation gradient
  real(pReal), dimension(3,3,3,3) :: C
  integer :: ho


  associate( mgr => matGr(gr))

  C  = math_Mandel66to3333(constitutive_homogenizedC(gr))
  if (phase_stiffDegrade(mgr%ph) == STIFFNESS_DEGRADATION_damage_ID) then
    ho = matPt(mgr%mt)%ho
    C = C * damage(ho)%p(damageAt(ho)%p(mgr%mt))**2
  endif
  end associate

  ! Calculate 2nd P-K stress (S) and its tangents (dS_dFe, dS_dFi)
  call PK2_tangent(Fe, Fi, C, S, dS_dFe, dS_dFi)

end subroutine phase_SandItsTangents

#ifdef Abaqus_exp
!--------------------------------------------------------------------------------------------------
!> @brief returns the 2nd Piola-Kirchhoff stress tensor and its tangent with respect to
!> the elastic and intermeidate deformation gradients using Hookes law PASS
!--------------------------------------------------------------------------------------------------
function phase_S(Fe, Fi, gr)

  integer, intent(in) :: gr
  real(pReal),   intent(in),  dimension(3,3) :: &
    Fe, &                                                                                            !< elastic deformation gradient
    Fi                                                                                               !< intermediate deformation gradient
  real(pReal), dimension(3,3) :: &
    phase_S                                                                                                !< 2nd Piola-Kirchhoff stress tensor in lattice configuration
  real(pReal), dimension(3,3,3,3) :: C
  integer :: ho


  associate( mgr => matGr(gr))

  C  = math_Mandel66to3333(constitutive_homogenizedC(gr))
  if (phase_stiffDegrade(mgr%ph) == STIFFNESS_DEGRADATION_damage_ID) then
    ho = matPt(mgr%mt)%ho
    C = C * damage(ho)%p(damageAt(ho)%p(mgr%mt))**2
  endif
  end associate

  ! Calculate 2nd P-K stress (S) and its tangents (dS_dFe, dS_dFi)
  phase_S = PK2_(Fe, Fi, C)

end function phase_S
#endif


!--------------------------------------------------------------------------------------------------
!> @brief contains the constitutive equation for calculating the rate of change of microstructure
!--------------------------------------------------------------------------------------------------
function phase_plastic_dotState(Sstar33, Fi, gr) result(broken)

  integer, intent(in) :: gr
  real(pReal), intent(in), dimension(3,3) :: Sstar33, Fi
  real(pReal),             dimension(3,3) :: Mp
  logical :: broken
  integer :: ph, en, tme


  associate( mgr => matGr(gr), mpt => matPt(mgr%mt))
  ph = matGr(gr)%ph; en = matGr(gr)%phAt

  tme = thermalAt(mpt%ho)%p(mgr%mt)
  Mp = matmul(transpose(Fi), matmul(Fi, Sstar33) ) ! non-symmetric when Fi is not a eye tensor

  call pl_procedures(ph)%dotState(Mp,temperature(mpt%ho)%val(tme),ph,en,mgr%gr_id)

  broken = any(IEEE_is_NaN(plasticState(ph)%dotState(:,en)))

  end associate

end function phase_plastic_dotState


!--------------------------------------------------------------------------------------------------
!> @brief contains the constitutive equation for calculating the rate of change of microstructure
!--------------------------------------------------------------------------------------------------
function phase_damage_dotState(Sstar33, Fi, Fe, gr, ph,en) result(broken)
  use damage_isoDuctile, only: &
    damage_isoDuctile_dotState
  use damage_anisoBrittle, only: &
    damage_anisoBrittle_dotState
  use damage_anisoDuctile, only: &
    damage_anisoDuctile_dotState
  use damage_voidMC, only: &
    damage_voidMC_dotState

  integer, intent(in) :: gr, ph,en
  real(pReal),   intent(in), dimension(3,3) :: Sstar33, Fi, Fe
  logical :: broken
  real(pReal) :: accumShearRate


  associate( mgr => matGr(gr), mpt => matPt(mgr%mt))

  select case (phase_damage(ph))
    case (damage_anisoBrittle_ID)
      call damage_anisoBrittle_dotState (Sstar33, mgr%mt, ph, en, mpt%ho)

    case (damage_isoDuctile_ID)
      accumShearRate = sum(plasticState(ph)%shearRate(:, en))
      call damage_isoDuctile_dotState(mgr%mt, ph, en, mpt%ho, accumShearRate)

    case (damage_anisoDuctile_ID)
      call damage_anisoDuctile_dotState(mgr%mt, ph, en, mpt%ho, &
        plasticState(ph)%shearRate(:,en))

    case (damage_voidMC_ID)
        call damage_voidMC_dotState(Sstar33,Fi,Fe,en,ph)

  end select

  broken = any(IEEE_is_NaN(damageState(ph)%dotState(:,en)))

  end associate

end function phase_damage_dotState


!--------------------------------------------------------------------------------------------------
!> @brief contains the constitutive equation for calculating the rate of change of microstructure
!--------------------------------------------------------------------------------------------------
function phase_thermal_dotState(ph,en) result(broken)
  use THERMAL_externalheat, only: &
    THERMAL_externalheat_dotState

  integer, intent(in) :: ph, en
  logical :: broken
  integer :: so


  broken = .false.
  do so = 1, phase_Nthermal(ph)
    select case (phase_thermal(so, ph))
      case (THERMAL_externalheat_ID)
        call THERMAL_externalheat_dotState (ph, en)
    end select
  enddo

end function phase_thermal_dotState


!--------------------------------------------------------------------------------------------------
!> @brief for constitutive models having an instantaneous change of state
!> will return false if delta state is not needed/supported by the constitutive model
!--------------------------------------------------------------------------------------------------
function phase_plastic_deltaState(ph, en) result(broken)
  integer, intent(in) :: ph, en
  logical :: broken


  broken = .false.
  ! select case (phase_plasticity(ph))
  !   case (PLASTIC_KINEHARDENING_ID)
  !     Mp = matmul(matmul(transpose(phase_mechanical_Fi(ph)%data(1:3,1:3,en)),&
  !                        phase_mechanical_Fi(ph)%data(1:3,1:3,en)),&
  !                 phase_mechanical_S(ph)%data(1:3,1:3,en))
  !     call plastic_kinehardening_deltaState(Mp,ph,en)
  !     broken = any(IEEE_is_NaN(plasticState(ph)%deltaState(:,en)))
  !     if (.not. broken) then
  !       mySize   = plasticState(ph)%sizeDeltaState
  !       plasticState(ph)%deltaState2(1:mySize,en) = plasticState(ph)%deltaState2(1:mySize,en) &
  !                                                 + plasticState(ph)%deltaState(1:mySize,en)
  !     end if
  ! end select
end function phase_plastic_deltaState


!--------------------------------------------------------------------------------------------------
!> @brief for constitutive models having an instantaneous change of state
!> will return false if delta state is not needed/supported by the constitutive model
!--------------------------------------------------------------------------------------------------
logical function phase_damage_deltaState(Fe, gr, ph, en)
  use DAMAGE_isoBrittle, only: &
    DAMAGE_isoBrittle_deltaState

  integer, intent(in) :: gr, ph, en
  real(pReal), intent(in), dimension(3,3) :: Fe
  integer :: sSize                                                                           !< counter in source loop


  phase_damage_deltaState = .true.

  select case (phase_damage(ph))
    case (DAMAGE_isoBrittle_ID)
      call DAMAGE_isoBrittle_deltaState(constitutive_homogenizedC(gr), Fe, ph, en)

      if( any(IEEE_is_NaN(damageState(ph)%deltaState(:,en)))) then                                    ! NaN occured in deltaState
        phase_damage_deltaState = .false.
        return
      endif
      sSize = damageState(ph)%sizeDeltaState
      damageState(ph)%state(1:sSize,en) = damageState(ph)%state(1:sSize, en) + &
                                          damageState(ph)%deltaState(1:sSize, en)
  end select

end function phase_damage_deltaState


!--------------------------------------------------------------------------------------------------
!> @brief returns array of constitutive results
!--------------------------------------------------------------------------------------------------
function constitutive_results(Sstar33, Fi, Lp, gr)
  use DAMAGE_isoBrittle, only: &
    DAMAGE_isoBrittle_results
  use DAMAGE_isoDuctile, only: &
    DAMAGE_isoDuctile_results
  use DAMAGE_anisoBrittle, only: &
    DAMAGE_anisoBrittle_results
  use DAMAGE_anisoDuctile, only: &
    DAMAGE_anisoDuctile_results
  use DAMAGE_voidMC, only: &
    DAMAGE_voidMC_results

  integer, intent(in) :: gr
  real(pReal), dimension( matGr(gr)%constit_resultsize ) :: constitutive_results
  real(pReal),  intent(in), dimension(3,3) :: Sstar33, Fi, Lp
  real(pReal), dimension(3,3) :: Mp
  integer :: startPos, endPos, ph, en


  constitutive_results = 0.0_pReal

  associate( mgr => matGr(gr), mpt => matPt(mgr%mt))
  ph = mgr%ph

  Mp  = matmul(transpose(Fi), matmul(Fi, Sstar33) ) ! non-symmetric when Fi is not a eye tensor
  startPos = 1; endPos = plasticState(ph)%sizeResults

  en = thermalAt(mpt%ho)%p(mgr%mt)
  call pl_procedures(ph)%postResults(Mp, Lp, temperature(mpt%ho)%val(en), ph, mgr%phAt, &
         mgr%gr_id, constitutive_results(startPos:endPos))


  if (damageState(ph)%sizeResults > 0) then
    startPos = endPos + 1; endPos = endPos + damageState(ph)%sizeResults
    select case (phase_damage(ph))
      case (DAMAGE_isoBrittle_ID)
        constitutive_results(startPos:endPos) = DAMAGE_isoBrittle_results  (ph, mgr%phAt)

      case (DAMAGE_isoDuctile_ID)
        constitutive_results(startPos:endPos) = DAMAGE_isoDuctile_results  (ph, mgr%phAt)

      case (DAMAGE_anisoBrittle_ID)
        constitutive_results(startPos:endPos) = DAMAGE_anisoBrittle_results(ph, mgr%phAt)

      case (DAMAGE_anisoDuctile_ID)
        constitutive_results(startPos:endPos) = DAMAGE_anisoDuctile_results(ph, mgr%phAt)

      case (DAMAGE_voidMC_ID)
        constitutive_results(startPos:endPos) = DAMAGE_voidMC_results      (ph, mgr%phAt)
    end select
  endif

  end associate

end function constitutive_results


!--------------------------------------------------------------------------------------------------
!> @brief contains the constitutive equation for calculating the rate of change of microstructure
!--------------------------------------------------------------------------------------------------
function constitutive_twinReorientation(orientation, gr) result(reorientation)
  use plastic_phenopowerlaw, only: &
    plastic_phenopowerlaw_twinRotation
  use rotations, only: &
    tRotation

  integer,        intent(in) :: gr
  type(tRotation), intent(in) :: orientation
  type(tRotation) :: reorientation, reorient
  logical :: twReorient


  associate( mgr => matGr(gr))
  twReorient = .false.

  select case (phase_plastic(mgr%ph))
    case (PLASTICITY_PHENOPOWERLAW_ID)
      call plastic_phenopowerlaw_twinRotation(mgr%ph, mgr%phAt, twReorient, reorient)
    case (PLASTICITY_DISLOTWIN_ID)
      !call plastic_dislotwin_dotState(instance,mgr%phAt, twReorient, reorient)
    case default
  end select

  if (twReorient) then
    reorientation = reorient * orientation !math_qMul(reorient, orientation)
  else
    reorientation = orientation
  endif
  end associate

end function constitutive_twinReorientation

end module constitutive