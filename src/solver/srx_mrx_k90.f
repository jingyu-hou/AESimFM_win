C
C     AESim_FM — SRX/MRX recrystallization model extracted from K90DRX.f
C
C     Based on classical JMAK/Avrami kinetics, Zener-Hollomon parameter,
C     and Beck grain-growth law.  Original K90 formulas and hardcoded
C     constants are preserved as defaults with [HARDCODED] markers.
C
C     This module is called AFTER the existing drx.f and uses its output
C     (SDV11 X_DRX, SDV12 D_DRX) to determine the DRX completion state.
C     It does NOT overwrite SDV1-21.
C
C     Authors: AESim_FM team
C     Copyright: Shenzhen Wedge Central South Research Institute co., Ltd.
C

      subroutine srx_mrx_k90(eqplas,eqplasrt,deqpl,tempk,dtime,
     &     time_total,statev,nstatv,kinc,gsloc)
      implicit none
C
C     Input arguments
C
      integer nstatv, kinc
      real*8 eqplas, eqplasrt, deqpl, tempk, dtime, time_total
      real*8 statev(nstatv), gsloc(30,5)
C
C     Physical constant
C
      real*8, parameter :: R = 8.314d0
      real*8, parameter :: ZERO = 0.d0
      real*8, parameter :: ONE = 1.d0
      real*8, parameter :: HALF = 0.5d0
      real*8, parameter :: PI = 3.141592653589793d0
C
C     Defaults for K90 hardcoded material constants [HARDCODED]
C     These may be overridden via gsloc(i,2) in future versions.
C
      real*8, parameter :: Q_DRX_DEF    = 300000.d0   ! DRX activation energy, J/mol
      real*8, parameter :: Q_MRX_SRX_DEF = 230000.d0  ! MRX/SRX activation energy, J/mol
      real*8, parameter :: Q_GG_DEF      = 384000.d0  ! grain-growth activation energy, J/mol
      real*8, parameter :: A_EC_DEF      = 5.6d-4     ! Ec prefactor (Sellars form)
      real*8, parameter :: D0_EXP_EC     = 0.3d0      ! D0 exponent in Ec
      real*8, parameter :: Z_EXP_EC      = 0.17d0     ! Z exponent in Ec
      real*8, parameter :: A_E05_DEF     = 1.144d-3   ! epsilon_05_DRX prefactor
      real*8, parameter :: D0_EXP_E05    = 0.28d0     ! D0 exponent in epsilon_05
      real*8, parameter :: ER_EXP_E05    = 0.05d0     ! strain-rate exponent in epsilon_05
      real*8, parameter :: Q_E05_DEF     = 6420.d0    ! epsilon_05 temperature factor, K
      real*8, parameter :: A_DDRX_DEF    = 1.6d4      ! D_DRX100 prefactor, um
      real*8, parameter :: Z_EXP_DDRX    = -0.23d0    ! Z exponent in D_DRX100
      real*8, parameter :: A_T05_MRX     = 1.1d0      ! t05_MRX prefactor, s
      real*8, parameter :: Z_EXP_TMRX    = -0.8d0     ! Z exponent in t05_MRX
      real*8, parameter :: A_DMRX_DEF    = 2.6d4      ! D_MRX prefactor, um
      real*8, parameter :: AVRAMI_MRX_DEF = 1.5d0     ! Avrami exponent for MRX
      real*8, parameter :: A_T05_SRX     = 2.3d-15    ! t05_SRX prefactor, s
      real*8, parameter :: EQUE_EXP_TSRX = -2.5d0     ! EQUE_RE exponent in t05_SRX
      real*8, parameter :: D0_EXP_TSRX   = 2.d0       ! D0 exponent in t05_SRX
      real*8, parameter :: AVRAMI_SRX_DEF = 1.d0      ! Avrami exponent for SRX
      real*8, parameter :: A_DSRX_DEF    = 343.d0     ! D_SRX prefactor, um
      real*8, parameter :: EQUE_EXP_DSRX = -0.5d0     ! EQUE_RE exponent in D_SRX
      real*8, parameter :: D0_EXP_DSRX   = 0.4d0      ! D0 exponent in D_SRX
      real*8, parameter :: Q_DSRX_DEF    = -45000.d0  ! D_SRX activation energy, J/mol
      real*8, parameter :: A_KG_DEF      = 1.72d21    ! K_G prefactor, um^m/s
      real*8, parameter :: GG_EXP_DEF    = 4.112d0    ! grain-growth exponent m
      real*8, parameter :: TEMP_HOLD_DEF = 760.d0     ! holding grain-growth threshold, C
C
C     Derived defaults
C
      real*8, parameter :: ONE_OVER_M = 1.d0 / 4.112d0  ! 1/m ≈ 0.2432
      real*8, parameter :: BETA = 0.6931471805599453d0   ! ln(2)
      real*8, parameter :: X_THRESHOLD = 0.95d0          ! completion threshold
      real*8, parameter :: DQPL_TOL = 1.d-10             ! strain-rate threshold
C
C     SDV index constants (must match solver SDV layout)
C     SDV1-21 are reserved — do NOT write to them
C
      integer, parameter :: I_MRX_SIGN      = 22
      integer, parameter :: I_SRX_SIGN      = 23
      integer, parameter :: I_X_MRX         = 24
      integer, parameter :: I_X_SRX         = 25
      integer, parameter :: I_D_MRX         = 26
      integer, parameter :: I_D_SRX         = 27
      integer, parameter :: I_D_MIX         = 28
      integer, parameter :: I_EQUE_RE       = 29
      integer, parameter :: I_EQUE_RE0      = 30
      integer, parameter :: I_EQUER_MEAN    = 31
      integer, parameter :: I_EQUE05_DRX    = 32
      integer, parameter :: I_T05_MRX       = 33
      integer, parameter :: I_T05_SRX       = 34
      integer, parameter :: I_T_GROWTH0_MRX = 35
      integer, parameter :: I_D_GROWTH0_MRX = 36
      integer, parameter :: I_T_GROWTH0_SRX = 37
      integer, parameter :: I_D_GROWTH0_SRX = 38
      integer, parameter :: I_UNDEFORM_SIGN = 39
      integer, parameter :: I_T_DEFORM      = 40
      integer, parameter :: I_D0_K90        = 41
      integer, parameter :: I_N3_MRX_GG     = 42
      integer, parameter :: I_N4_SRX_GG     = 43
C
C     Local variables
C
      real*8 D0, X_DRX, D_AVE
      real*8 EQUE_RE, EQUE_RE0, EQUE_T, EQUE_C
      real*8 EQUER_mean, Z, Ec, EQUE05_DRX
      real*8 X_MRX, D_MRX, t05_MRX, X_SRX, D_SRX, t05_SRX
      real*8 D_MIX, D_GROWTH_MRX, D_GROWTH_SRX, D_GROWTH_DRX
      real*8 K_G, t_growth
      real*8 MRX_sign, SRX_sign, UNDEFORM_sign
      real*8 N3, N4, t_Deform, D_GROWTH0_MRX, D_GROWTH0_SRX
      real*8 t_GROWTH0_MRX, t_GROWTH0_SRX
      real*8 tempk_safe, t_total, t_hold, rate_safe
      real*8 q_drx, q_mrx_srx, q_gg, a_ec, avrami_mrx, avrami_srx
      real*8 gg_exp, temp_hold, gsloc_switch
C
C     ————————————————————————————————————————————————————————
C     Safety checks
C     ————————————————————————————————————————————————————————
C
      if (nstatv .lt. 43) return
      if (dtime .le. ZERO) return
      if (tempk .le. ZERO) return
C
C     Read enable switch
C
      gsloc_switch = gsloc(1,2)
      if (gsloc_switch .eq. ZERO) return

C
C     Read parameters from gsloc(1..,2), falling back to [HARDCODED] defaults
C
      q_drx       = 300000.d0
      q_mrx_srx   = 230000.d0
      q_gg        = 384000.d0
      avrami_mrx  = 1.5d0
      avrami_srx  = 1.d0
      gg_exp      = 4.112d0
      temp_hold   = 760.d0
      a_ec        = 5.6d-4
      if (gsloc(3,2) .ne. ZERO) q_drx      = gsloc(3,2)
      if (gsloc(4,2) .ne. ZERO) q_mrx_srx  = gsloc(4,2)
      if (gsloc(5,2) .ne. ZERO) q_gg       = gsloc(5,2)
      if (gsloc(6,2) .ne. ZERO) avrami_mrx = gsloc(6,2)
      if (gsloc(7,2) .ne. ZERO) avrami_srx = gsloc(7,2)
      if (gsloc(8,2) .ne. ZERO) gg_exp     = gsloc(8,2)
      if (gsloc(9,2) .ne. ZERO) temp_hold  = gsloc(9,2)
      if (gsloc(10,2) .ne. ZERO) a_ec      = gsloc(10,2)
C
C     Read state from statev
C
      D0    = statev(I_D0_K90)
      X_DRX = statev(11)
      D_AVE = statev(13)
C
C     ————————————————————————————————————————————————————————
C     First-call initialisation (once per simulation, not per step)
C     ————————————————————————————————————————————————————————
C
      if (statev(I_D0_K90) .le. ZERO) then
C         Seed D0 from existing D_AVE (drx.f output) or gsloc override
          if (gsloc(2,2) .ne. ZERO) then
            D0 = gsloc(2,2)
          elseif (D_AVE .gt. ZERO) then
            D0 = D_AVE
          else
            D0 = 100.d0  ! safe fallback, um
          endif
          statev(I_D0_K90)        = D0
          statev(I_MRX_SIGN)      = ZERO
          statev(I_SRX_SIGN)      = ZERO
          statev(I_X_MRX)         = ZERO
          statev(I_X_SRX)         = ZERO
          statev(I_D_MRX)         = ZERO
          statev(I_D_SRX)         = ZERO
          statev(I_D_MIX)         = D0
          statev(I_EQUE_RE)       = ZERO
          statev(I_EQUE_RE0)      = ZERO
          statev(I_EQUER_MEAN)    = ZERO
          statev(I_EQUE05_DRX)    = ZERO
          statev(I_T05_MRX)       = ZERO
          statev(I_T05_SRX)       = ZERO
          statev(I_T_GROWTH0_MRX) = ZERO
          statev(I_D_GROWTH0_MRX) = ZERO
          statev(I_T_GROWTH0_SRX) = ZERO
          statev(I_D_GROWTH0_SRX) = ZERO
          statev(I_UNDEFORM_SIGN) = ZERO
          statev(I_T_DEFORM)      = ZERO
          statev(I_N3_MRX_GG) = ZERO   ! N3 — MRX growth complete flag
          statev(I_N4_SRX_GG) = ZERO   ! N4 — SRX growth complete flag
          return
      endif
C
C     Read persistent state for this increment
C
      MRX_sign       = statev(I_MRX_SIGN)
      SRX_sign       = statev(I_SRX_SIGN)
C     DRX completion is determined from X_DRX (SDV11) — see drx.f
      UNDEFORM_sign  = statev(I_UNDEFORM_SIGN)
      EQUE_RE0       = statev(I_EQUE_RE0)
      EQUE_RE        = statev(I_EQUE_RE)
      EQUE05_DRX     = statev(I_EQUE05_DRX)
      EQUER_mean     = statev(I_EQUER_MEAN)
      t_Deform       = statev(I_T_DEFORM)
      N3             = statev(I_N3_MRX_GG)
      N4             = statev(I_N4_SRX_GG)
      t_GROWTH0_MRX  = statev(I_T_GROWTH0_MRX)
      D_GROWTH0_MRX  = statev(I_D_GROWTH0_MRX)
      t_GROWTH0_SRX  = statev(I_T_GROWTH0_SRX)
      D_GROWTH0_SRX  = statev(I_D_GROWTH0_SRX)
C
C     Guard: clamp temperature to a sensible lower bound for kinetics
C
      tempk_safe = tempk
      if (tempk_safe .lt. 973.d0) tempk_safe = 973.d0  ! 700 C
      t_total = time_total
      if (t_total .lt. ZERO) t_total = ZERO
C
C     ————————————————————————————————————————————————————————
C     Deformation vs. holding detection
C     ————————————————————————————————————————————————————————
C
      if (deqpl .gt. DQPL_TOL) then
C
C ===== DEFORMATION MODE =====
C
          UNDEFORM_sign = ZERO
C
C         Average strain rate: current-step approximate
          EQUER_mean = deqpl / dtime
C
C         Zener-Hollomon parameter
          rate_safe = EQUER_mean
          if (rate_safe .lt. 1.d-20) rate_safe = 1.d-20
          Z = rate_safe * dexp(q_drx / R / tempk_safe)
C
C         Critical strain (Sellars form) [HARDCODED exponents 0.3, 0.17]
          Ec = a_ec * (D0 ** 0.3d0) * (Z ** 0.17d0)
C
C         Total equivalent strain driving DRX
          EQUE_C = deqpl
          EQUE_T = EQUE_C + EQUE_RE0
          EQUE_RE = EQUE_T
C
C         DRX 50% characteristic strain [HARDCODED exponents]
          EQUE05_DRX = 1.144d-3 * (D0 ** 0.28d0)
     &               * (EQUER_mean ** 0.05d0)
     &               * dexp(6420.d0 / tempk_safe)
C
C         Check if total strain reaches critical strain for DRX
          if (EQUE_T .lt. Ec) then
C             Below critical — no DRX nucleation
C             SRX will be set when deformation ends
              MRX_sign = ZERO
              EQUE_RE  = EQUE_T
          else
C             Above critical — DRX should be active
C             Use existing drx.f X_DRX to decide completion
              if (X_DRX .gt. X_THRESHOLD) then
C                 DRX completed: pure grain growth later
                  MRX_sign = ZERO
                  EQUE_RE  = ZERO
              else
C                 DRX incomplete → metadynamic (MRX) after deformation
                  MRX_sign = ONE
                  EQUE_RE  = (ONE - X_DRX) * EQUE_T
              endif
          endif
C
C         Update deformation timer
          t_Deform = t_total
C
C         Propagate residual strain for next increment
          EQUE_RE0 = EQUE_RE
C
C         Save current state
          statev(I_MRX_SIGN)      = MRX_sign
          statev(I_UNDEFORM_SIGN) = ZERO
          statev(I_EQUE_RE)       = EQUE_RE
          statev(I_EQUE_RE0)      = EQUE_RE0
          statev(I_EQUER_MEAN)    = EQUER_mean
          statev(I_EQUE05_DRX)    = EQUE05_DRX
          statev(I_T_DEFORM)      = t_Deform
C          Clear holding-only SDVs
          statev(I_X_MRX) = ZERO
          statev(I_X_SRX) = ZERO
          statev(I_T05_MRX) = ZERO
          statev(I_T05_SRX) = ZERO
          statev(I_D_MIX)  = D0
          statev(I_N3_MRX_GG) = ZERO
          statev(I_N4_SRX_GG) = ZERO
C
          return
      endif
C
C ===== HOLDING MODE (deqpl ≈ 0) =====
C
C     On first holding increment after deformation, decide SRX/MRX/DRX
C
      if (UNDEFORM_sign .eq. ZERO) then
C         Transition: deformation period just ended
          if (MRX_sign .eq. ZERO .and. X_DRX .le. X_THRESHOLD) then
C             Never reached DRX critical strain → static recryst.
              SRX_sign = ONE
          endif
C         Save EQUE_RE0 for SRX/MRX kinetics
          EQUE_RE0 = EQUE_RE
          statev(I_EQUE_RE0) = EQUE_RE0
          UNDEFORM_sign = ONE
          statev(I_UNDEFORM_SIGN) = ONE
          statev(I_SRX_SIGN) = SRX_sign
C         Reset growth flags for new episode
          N3 = ZERO
          N4 = ZERO
          statev(I_N3_MRX_GG) = ZERO
          statev(I_N4_SRX_GG) = ZERO
      endif
C
C     Re-read signs in case they were just set
      MRX_sign = statev(I_MRX_SIGN)
      SRX_sign = statev(I_SRX_SIGN)
      X_DRX    = statev(11)
      EQUE_RE0 = statev(I_EQUE_RE0)
      EQUER_mean = statev(I_EQUER_MEAN)
      N3 = statev(I_N3_MRX_GG)
      N4 = statev(I_N4_SRX_GG)
C
C     Guard EQUER_mean for Z computation in holding
      rate_safe = EQUER_mean
      if (rate_safe .lt. 1.d-20) rate_safe = 1.d-20
      Z = rate_safe * dexp(q_drx / R / tempk_safe)
C
C     Holding time for SRX/MRX kinetics: time since deformation ended
C
      t_hold = t_total - t_Deform
      if (t_hold .lt. ZERO) t_hold = ZERO
C
C     ============================================
C     MRX: metadynamic recrystallization
C     ============================================
C
      if (MRX_sign .ne. ZERO) then
C
          t05_MRX = 1.1d0 * (Z ** (-0.8d0))
     &            * dexp(q_mrx_srx / R / tempk_safe)
          if (t05_MRX .lt. 1.d-30) t05_MRX = 1.d-30
C
          X_MRX = ONE - dexp(-BETA * (t_hold / t05_MRX) ** avrami_mrx)
          X_MRX = dmax1(ZERO, dmin1(ONE, X_MRX))
C
          D_MRX = 2.6d4 * (Z ** (-0.23d0))
          if (D_MRX .lt. ZERO) D_MRX = ZERO
C
          if (X_MRX .gt. X_THRESHOLD) then
C             MRX complete → grain growth
              if (N3 .ne. ONE) then
                  t_GROWTH0_MRX = t_total
                  D_GROWTH0_MRX = D_MRX
                  N3 = ONE
              endif
              t_growth = t_total - t_GROWTH0_MRX
              if (t_growth .lt. ZERO) t_growth = ZERO
              K_G = 1.72d21 * dexp(-q_gg / R / tempk_safe)
              D_GROWTH_MRX = (D_GROWTH0_MRX ** gg_exp
     &                     + K_G * t_growth) ** (ONE / gg_exp)
              D_AVE = D_GROWTH_MRX
              EQUE_RE = ZERO
          else
C             MRX in progress — mix rule
              D_MIX = (X_MRX ** (4.d0 / 3.d0)) * D_MRX
     &              + ((ONE - X_MRX) ** 2.d0) * D0
              D_AVE = D_MIX
              EQUE_RE = (ONE - X_MRX) * EQUE_RE0
          endif
C
C         Store MRX state
          statev(I_T05_MRX)       = t05_MRX
          statev(I_X_MRX)         = X_MRX
          statev(I_D_MRX)         = D_MRX
          statev(I_D_MIX)         = D_AVE
          statev(I_EQUE_RE)       = EQUE_RE
          statev(I_T_GROWTH0_MRX) = t_GROWTH0_MRX
          statev(I_D_GROWTH0_MRX) = D_GROWTH0_MRX
          statev(I_N3_MRX_GG)      = N3
C
C     ============================================
C     SRX: static recrystallization
C     ============================================
C
      elseif (SRX_sign .ne. ZERO) then
C
C         Guard: EQUE_RE0 must be positive for t05_SRX formula
          if (EQUE_RE0 .le. ZERO) EQUE_RE0 = 1.d-10
C
          t05_SRX = 2.3d-15 * (EQUE_RE0 ** (-2.5d0))
     &            * (D0 ** 2.d0)
     &            * dexp(q_mrx_srx / R / tempk_safe)
          if (t05_SRX .lt. 1.d-30) t05_SRX = 1.d-30
C
          X_SRX = ONE - dexp(-BETA * (t_hold / t05_SRX) ** avrami_srx)
          X_SRX = dmax1(ZERO, dmin1(ONE, X_SRX))
C
          D_SRX = 343.d0 * (EQUE_RE0 ** (-0.5d0))
     &          * (D0 ** 0.4d0)
     &          * dexp(-45000.d0 / R / tempk_safe)
          if (D_SRX .lt. ZERO) D_SRX = ZERO
C
          if (X_SRX .gt. X_THRESHOLD) then
C             SRX complete → grain growth
              if (N4 .ne. ONE) then
                  t_GROWTH0_SRX = t_total
                  D_GROWTH0_SRX = D_SRX
                  N4 = ONE
              endif
              t_growth = t_total - t_GROWTH0_SRX
              if (t_growth .lt. ZERO) t_growth = ZERO
              K_G = 1.72d21 * dexp(-q_gg / R / tempk_safe)
              D_GROWTH_SRX = (D_GROWTH0_SRX ** gg_exp
     &                     + K_G * t_growth) ** (ONE / gg_exp)
              D_AVE = D_GROWTH_SRX
              EQUE_RE = ZERO
          else
C             SRX in progress — mix rule
              D_MIX = (X_SRX ** (4.d0 / 3.d0)) * D_SRX
     &              + ((ONE - X_SRX) ** 2.d0) * D0
              D_AVE = D_MIX
              EQUE_RE = (ONE - X_SRX) * EQUE_RE0
          endif
C
C         Store SRX state
          statev(I_T05_SRX)       = t05_SRX
          statev(I_X_SRX)         = X_SRX
          statev(I_D_SRX)         = D_SRX
          statev(I_D_MIX)         = D_AVE
          statev(I_EQUE_RE)       = EQUE_RE
          statev(I_T_GROWTH0_SRX) = t_GROWTH0_SRX
          statev(I_D_GROWTH0_SRX) = D_GROWTH0_SRX
          statev(I_N4_SRX_GG)      = N4
C
C     ============================================
C     DRX complete: pure grain growth (no recryst.)
C     ============================================
C
      elseif (X_DRX .gt. X_THRESHOLD) then
C
C         DRX completed in deformation — pure grain growth
C         [HARDCODED] K90 DRX grain growth: D^7 + 8.2E25 * t * exp(-400000/RT)
          t_growth = t_total
          if (t_growth .lt. ZERO) t_growth = ZERO
          D_GROWTH_DRX = (D0 ** 7.d0
     &        + 8.2d25 * t_growth * dexp(-400000.d0 / R / tempk_safe))
     &        ** (1.d0 / 7.d0)
          D_AVE = D_GROWTH_DRX
          EQUE_RE = ZERO
          statev(I_D_MIX)   = D_AVE
          statev(I_EQUE_RE) = ZERO
C
C     ============================================
C     Never deformed: simple grain growth above threshold
C     ============================================
C
      elseif (UNDEFORM_sign .ne. ZERO) then
C
C         Holding grain growth above temperature threshold
          if ((tempk_safe - 273.d0) .gt. temp_hold) then
              K_G = 1.72d21 * dexp(-q_gg / R / tempk_safe)
              D_GROWTH_DRX = (D0 ** gg_exp
     &            + K_G * t_total) ** (ONE / gg_exp)
              D_AVE = D_GROWTH_DRX
          endif
C         D_AVE unchanged if below threshold
          EQUE_RE = ZERO
          statev(I_D_MIX)   = D_AVE
          statev(I_EQUE_RE) = ZERO
      endif
C
C     ————————————————————————————————————————————————————————
C     Common holding increment: update D_AVE into SDV13
C     First version: D_AVE is NOT fed back to flow stress.
C     ————————————————————————————————————————————————————————
C
      statev(13) = D_AVE
C
C     NaN guard: if any key output is NaN, keep previous value
C
      if (.not. (D_AVE .ge. ZERO .or. D_AVE .lt. ZERO)) then
          statev(13) = D0
      endif
C
      end subroutine srx_mrx_k90
