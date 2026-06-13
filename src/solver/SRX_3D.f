! This program for static recrystallization
! coded by Namin Xiao: nmxiao@outlook.com

MODULE Constant
    IMPLICIT none

    INTEGER, PARAMETER :: SGL = SELECTED_REAL_KIND (p=6, r=37)             !Single data kind
    INTEGER, PARAMETER :: DBL = SELECTED_REAL_KIND (p=13)                  !Double data kind
    !-  ---------------------------------------------------------------------+
    REAL (KIND = DBL), PARAMETER :: PI = 3.1415926D0
    REAL (KIND = DBL), PARAMETER :: R = 8.314D0
    REAL (KIND = DBL), PARAMETER :: KB = 1.380658D-23
    REAL (KIND = DBL), PARAMETER :: LOGE = 2.71828183D0

    REAL (KIND = DBL), PARAMETER :: DX = 4.0D-7
    REAL (KIND = DBL), PARAMETER :: DY = DX
    REAL (KIND = DBL), PARAMETER :: DT = 5.0D-3
    REAL (KIND = DBL), PARAMETER :: KELVIN_T = 900.0D0+273.15D0
    INTEGER, PARAMETER :: TSTEP = 5000
    INTEGER, PARAMETER :: TINTERVAL = 100
    INTEGER, PARAMETER :: BC = 1

    INTEGER, PARAMETER :: ANISOTROPY_ORI = 0 ! if the misorientation anisotropy is considered, replace 0 by 1

    REAL (KIND = DBL), PARAMETER :: DELTADB = 1.1D-13
    REAL (KIND = DBL), PARAMETER :: QB = 174000.0D0
    REAL (KIND = DBL), PARAMETER :: QDEF = 400000.0D0

    !     dislocation model paramters
     REAL (KIND = DBL), PARAMETER :: BV = 2.56D-10
     REAL (KIND = DBL), PARAMETER :: M_TAYLOR = 3.0D0
     REAL (KIND = DBL), PARAMETER :: ALPHA = 0.15D0
     REAL (KIND = DBL), PARAMETER :: GSHEAR = (76.6D0-0.031D0*(KELVIN_T-273.15D0))*1.0D9
     REAL (KIND = DBL), PARAMETER :: TAO = 0.5D0*GSHEAR*BV*BV

    !REAL(KIND = DBL), PARAMETER :: ESTOR0 = TAO * (SIGMA_0/ALPHA/GSHEAR/BV)**2
    REAL (KIND = DBL), PARAMETER :: ESTOR0 = TAO * 1.0D12
    REAL(KIND = DBL), PARAMETER :: ESTOR0_1 = 1.09375e+006

    REAL (KIND = DBL), PARAMETER :: SGB_0 = 0.835D0
    REAL (KIND = DBL), PARAMETER :: UGB_0 = 8.9D-5*BV*BV/KB/KELVIN_T*exp(-208000.0D0/R/KELVIN_T)*3.d0

    REAL (KIND = DBL), PARAMETER :: GAMMA_0 = 1.5D0
    REAL (KIND = DBL), PARAMETER :: LGB = 4.0D0*DX
    REAL (KIND = DBL), PARAMETER :: THETA_0 = 20.0D0*PI/180.0D0
    REAL (KIND = DBL), PARAMETER :: TOLERANCE = 1.0D-3
END MODULE Constant

MODULE SparseDataStructure
    USE Constant
    IMPLICIT none
    SAVE

    TYPE node
        REAL (KIND = DBL) :: eta
        REAL (KIND = DBL) :: es
        INTEGER :: eta_id
        TYPE (node), POINTER :: next
    END TYPE node

    TYPE sparse_struct
        TYPE (node), POINTER :: head_ptr !points to the head of the list
        TYPE (node), POINTER :: copy_ptr !used to read through the list
        INTEGER :: list_size !number of order parameters at list spatial position
    END TYPE sparse_struct

    REAL (kind=DBL), DIMENSION (:,:,:), ALLOCATABLE :: neighbor_array
    REAL (kind=DBL), DIMENSION (:,:,:), ALLOCATABLE :: sum_eta
    REAL (kind=DBL), DIMENSION (:,:,:), ALLOCATABLE :: bulk_energy

    REAL (kind=DBL), DIMENSION (:,:,:), ALLOCATABLE :: kp, lp, yp, mp
    INTEGER, ALLOCATABLE, DIMENSION (:,:,:) :: sharp_ori

    REAL (kind=DBL), DIMENSION (:), ALLOCATABLE :: individual_radius

    TYPE (node), POINTER :: current_ptr !used to allocate new order parameters to the list
    TYPE (node), POINTER :: previous_ptr !used to allocate new order parameters to the list
    TYPE (node), POINTER :: secondary_ptr !used when current_ptr is in use holding values for a main loop
    TYPE (sparse_struct), ALLOCATABLE, TARGET :: grid(:,:,:) !contains all the order parameters in x,y,z space

    LOGICAL :: ierr
    INTEGER :: ioerr
    INTEGER :: x, y, t, matrix_q_number, total_q_number
    CHARACTER (LEN = 32) :: output_path, directory_name
END MODULE SparseDataStructure

MODULE ExternalSub
CONTAINS
    SUBROUTINE IncreaseArrayRank_1D(a, dynamic_array)
        IMPLICIT none
        INTEGER, INTENT (in) :: a
        INTEGER :: i
        INTEGER, ALLOCATABLE, DIMENSION (:), INTENT (inout) :: dynamic_array
        INTEGER, ALLOCATABLE, DIMENSION (:) :: temp

        ALLOCATE (temp(a-1))

        temp = dynamic_array

        DEALLOCATE (dynamic_array)

        ALLOCATE (dynamic_array(a))

        FORALL (i=1:a-1)
            dynamic_array(i) = temp(i)
        END FORALL

        DEALLOCATE (temp)

    END SUBROUTINE

    SUBROUTINE IncreaseArrayRank_1D_REAL(a, dynamic_array)
        USE Constant
        USE IFPORT
        IMPLICIT none
        INTEGER, INTENT (in) :: a
        INTEGER :: i
        REAL(KIND=DBL), ALLOCATABLE, DIMENSION (:), INTENT (inout) :: dynamic_array
        REAL(KIND=DBL), ALLOCATABLE, DIMENSION (:) :: temp

        ALLOCATE (temp(a-1))

        temp = dynamic_array

        DEALLOCATE (dynamic_array)
        ALLOCATE (dynamic_array(a))

        FORALL (i=1:a-1)
            dynamic_array(i) = temp(i)
        END FORALL

        DEALLOCATE (temp)
    END SUBROUTINE IncreaseArrayRank_1D_REAL

    SUBROUTINE IncreaseArrayRank_3D(a, b, c, dynamic_array)
        IMPLICIT none
        INTEGER, INTENT (in) :: a, b, c
        INTEGER :: k,i,j
        REAL, ALLOCATABLE, DIMENSION (:,:,:), INTENT (inout) :: dynamic_array
        REAL, ALLOCATABLE, DIMENSION (:,:,:) :: temp

        ALLOCATE (temp(c-1,a,b))

        temp = dynamic_array

        DEALLOCATE (dynamic_array)

        ALLOCATE (dynamic_array(c,a,b))

        DO j=1,b
            DO i=1,a
                DO k=1,c-1
                    dynamic_array(k,i,j) = temp(k,i,j)
                END DO
            END DO
        END DO

        DEALLOCATE (temp)

    END SUBROUTINE
END MODULE ExternalSub

PROGRAM main
    USE SparseDataStructure
    USE Constant
    USE IFPORT
    IMPLICIT none

    REAL (KIND = DBL) :: start_time,finish_time

    directory_name = 'experiment_test'
    output_path = '.\\'//trim(adjustl(directory_name))//'\\'
    ierr = MAKEDIRQQ (trim(directory_name))

    x = 200
    y = 200
    z = 200

    ALLOCATE (grid(1:x,1:y,1:z))
    ALLOCATE (neighbor_array(-1:1,-1:1,-1:1))
    ALLOCATE (sum_eta(x,y,z))
    ALLOCATE (bulk_energy(x,y,z))
    ALLOCATE (kp(x,y,z))
    ALLOCATE (lp(x,y,z))
    ALLOCATE (yp(x,y,z))
    ALLOCATE (mp(x,y,z))
    ALLOCATE (sharp_ori(x,y,z))

    CALL ReadFile()
    CALL AnisotropyInterface()

    WRITE (*,*) 'Initialization is finished.'

    start_time = DCLOCK()

    !DO t = 1, 500
    !    !CALL NucleationModel_2()
    !    CALL PhaseEvolution()

    !    IF (mod(t, TINTERVAL) == 0) CALL Output()
    !END do

    DO t = 1, 100
        CALL PhaseEvolution()
    END DO

    CALL NucleationModel_1()

    DO t = 1, TSTEP
        !CALL NucleationModel_2()
        CALL PhaseEvolution()

        IF (mod(t, TINTERVAL) == 0) CALL Output()
    END DO

    DEALLOCATE (grid)
    DEALLOCATE (neighbor_array)
    DEALLOCATE (sum_eta)
    DEALLOCATE (bulk_energy)
    DEALLOCATE (kp)
    DEALLOCATE (lp)
    DEALLOCATE (yp)
    DEALLOCATE (mp)
    DEALLOCATE (sharp_ori)
    DEALLOCATE(individual_radius)

    finish_time = DCLOCK()
    WRITE (*,*) 'The total time =', finish_time-start_time, ' seconds'
    WRITE (*,*) 'Press any key to quit...'
    read (*,*)

END PROGRAM main

SUBROUTINE ReadFile()
    USE SparseDataStructure
    USE Constant
    USE ExternalSub
    USE IFPORT
    IMPLICIT none

    INTEGER :: i, j, k, indices
    INTEGER, ALLOCATABLE, DIMENSION (:,:,:) :: input_ori
    INTEGER, ALLOCATABLE, DIMENSION (:) :: ori_list

    ALLOCATE (input_ori(x,y))

    open(unit=10, file="Ori-200.raw", form='binary', status='old', action='read', iostat=ioerr)
    IF (ioerr /= 0) THEN
        WRITE (*,*) "cannot find the input file!"
    ELSE
        DO k = 1, z
            DO j = 1, y
                DO i = 1, x
                    READ (10) input_ori(i,j,k)
                END DO
            END DO
        end do
    END IF
    CLOSE (10)

    matrix_q_number = 1
    ALLOCATE (ori_list(matrix_q_number))
    ori_list(1) = input_ori(1,1)

    DO k = 1, z
        DO j = 1, y
            DO i = 1, x
                indices = 0
                DO l = 1, matrix_q_number
                    IF (input_ori(i,j,k) == ori_list(l)) THEN
                        indices = 1
                    END IF
                END DO
                IF (indices == 0) THEN
                    matrix_q_number = matrix_q_number + 1
                    CALL IncreaseArrayRank_1D(matrix_q_number, ori_list)
                    ori_list(matrix_q_number) = input_ori(i,j,k)
                END IF
            END DO
        END DO
    end do

    DO k = 1, z
        DO j = 1, y
            DO i = 1, x
                NULLIFY (grid(i,j,k)%head_ptr) !initially nullify list (empty)
            END DO
        END DO
    end do

    total_q_number = matrix_q_number

    DO k = 1, z
        DO j = 1, y
            DO i = 1, x
                grid(i,j,k)%list_size = 0
                DO l = 1, matrix_q_number
                    IF (.NOT. ASSOCIATED(grid(i,j,k)%head_ptr)) THEN
                        ALLOCATE (grid(i,j,k)%head_ptr)
                        current_ptr => grid(i,j,k)%head_ptr
                        NULLIFY (current_ptr%next)
                        IF (ori_list(l) == input_ori(i,j,k)) THEN
                            current_ptr%eta = 1.0
                        ELSE
                            current_ptr%eta = 0.0
                        END IF
                        current_ptr%eta_id = l
                        current_ptr%es = ESTOR0_1
                        grid(i,j,k)%list_size = grid(i,j,k)%list_size + 1
                    ELSE
                        ALLOCATE (current_ptr%next)
                        current_ptr => current_ptr%next
                        NULLIFY (current_ptr%next)
                        IF (ori_list(l) == input_ori(i,j,k)) THEN
                            current_ptr%eta = 1.0
                        ELSE
                            current_ptr%eta = 0.0
                        END IF
                        current_ptr%eta_id = l
                        current_ptr%es = ESTOR0_1
                        grid(i,j,k)%list_size = grid(i,j,k)%list_size + 1
                    END IF
                END DO
            END DO
        END DO
    end do

    CALL UpdateSparseData()
    CALL UpdateSumEta()
    CALL UpdateBulkEnergy()

    allocate(individual_radius(total_q_number))

    CALL UpdateSharpOri()


    DEALLOCATE (input_ori)
    DEALLOCATE (ori_list)

END SUBROUTINE ReadFile

SUBROUTINE NeighborNode(a, b, c)
    USE SparseDataStructure
    USE Constant
    USE ExternalSub
    USE IFPORT
    IMPLICIT none

    INTEGER :: i, j, k, nx, ny, a, b
    TYPE (node), POINTER :: neighbor_ptr !used exclusively in the neighbor subroutine since it is called from other pointer loops

    neighbor_array = 0.d0

    DO k = 1, z
        DO j = -1, 1
            DO i = -1, 1
                nx = a+i
                ny = b+j
                nz = c+k
                IF (nx == 0) nx = x
                IF (nx == x+1) nx = 1
                IF (ny == 0) ny = y
                IF (ny == y+1) ny = 1
                IF (nz == 0) nz = z
                IF (nz == y+1) nz = 1
    
                neighbor_ptr => grid(nx,ny,nz)%head_ptr
                DO
                    IF (.NOT. ASSOCIATED(neighbor_ptr)) EXIT
                    IF (neighbor_ptr%eta_id == grid(a,b,c)%copy_ptr%eta_id) THEN
                        neighbor_array(i,j,k) = neighbor_ptr%eta
                        EXIT
                    END IF
                    neighbor_ptr => neighbor_ptr%next
                END DO
            END DO
        END DO
    end do

END SUBROUTINE NeighborNode

SUBROUTINE UpdateSparseData()
    USE SparseDataStructure
    USE Constant
    USE ExternalSub
    USE IFPORT
    IMPLICIT none

    INTEGER :: i, j, nx, ny, ii, jj, first_on_list, inside_loop, id_exists

    CALL CopyData()

    do k = 1, z
        DO j = 1, y
            DO i = 1, x
                first_on_list = 1
                DO
                    IF (.NOT.ASSOCIATED(grid(i,j,k)%copy_ptr)) EXIT
    
                    !Insert the order parameter
                    IF (grid(i,j,k)%copy_ptr%eta >= TOLERANCE) THEN
                        !order parameters from nearest & second nearest neighbors are added here
                        !but only added if they don't already exist and aren't in the ghost boundary
                        do kk = -1, 1
                            DO jj = -1, 1
                                DO ii = -1, 1
                                    id_exists = 0
                                    nx = i+ii
                                    ny = j+jj
                                    nz = k+kk
                                    IF (nx == 0) nx = x
                                    IF (nx == x+1) nx = 1
                                    IF (ny == 0) ny = y
                                    IF (ny == y+1) ny = 1
                                    IF (nz == 0) nz = z
                                    IF (nz == y+1) nz = 1
                                    current_ptr => grid(nx,ny,nz)%head_ptr
                                    DO
                                        !check to see if order parameter already exists at neighboring indices
                                        IF (.NOT.ASSOCIATED(current_ptr)) EXIT
                                        !IF (((i==1).AND.(ii<0)).OR.((i==x).AND.(ii>0))) id_exists = 1 !don't add to ghost boundary condition indices
                                        !IF (((j==1).AND.(jj<0)).OR.((j==y).AND.(jj>0))) id_exists = 1 !don't add to ghost boundary condition indices
        
                                        IF (current_ptr%eta_id == grid(i,j,k)%copy_ptr%eta_id) THEN
                                            id_exists = 1
                                            EXIT
                                        END IF
                                        current_ptr => current_ptr%next
                                    END DO
        
                                    !order parameter doesn't exist so add the order parameter here
                                    IF (id_exists == 0) THEN
                                        ALLOCATE (current_ptr)
                                        current_ptr%eta_id = grid(i,j,k)%copy_ptr%eta_id
                                        current_ptr%eta = 0.d0
                                        current_ptr%es = grid(i,j,k)%copy_ptr%es
                                        !current_ptr%es = ESTOR0
                                        current_ptr%next => grid(nx,ny,nz)%head_ptr !point to previous head memory position
                                        grid(nx,ny,nz)%head_ptr => current_ptr !update head of list
                                    END IF
                                END DO
                            END DO
                        end do
                    END IF
    
                    inside_loop = 0
    
                    IF (grid(i,j,k)%copy_ptr%eta < TOLERANCE) THEN
                        !check if all nearest neighbors are below tolerance as well, if not then don't remove
                        CALL NeighborNode(i,j,k)
                        IF (MAXVAL(neighbor_array) < TOLERANCE) THEN
                            IF (first_on_list == 1) THEN
                                current_ptr => grid(i,j,k)%copy_ptr
                                grid(i,j,k)%head_ptr => grid(i,j,k)%copy_ptr%next
                                grid(i,j,k)%copy_ptr => grid(i,j,k)%copy_ptr%next
                                DEALLOCATE (current_ptr) !prevent memory leak by releasing memory
                                inside_loop = 1
                            ELSE
                                current_ptr => grid(i,j,k)%copy_ptr
                                grid(i,j,k)%copy_ptr => grid(i,j,k)%copy_ptr%next
                                previous_ptr%next => grid(i,j,k)%copy_ptr !link last position with next position
                                DEALLOCATE (current_ptr) !prevent memory leak by releasing memory
                                inside_loop = 1
                            END IF
                        END IF
                    END IF
    
                    IF (inside_loop == 0) THEN
                        first_on_list = 0
                        previous_ptr => grid(i,j,k)%copy_ptr
                        grid(i,j,k)%copy_ptr => grid(i,j,k)%copy_ptr%next
                    END IF
    
                END DO
            END DO
        END DO
    end do

    grid(:,:,:)%list_size = 0
    do k = 1, z
        DO j = 1, y
            DO i = 1, x
                current_ptr => grid(i,j,k)%head_ptr
                DO
                    IF (.NOT.ASSOCIATED(current_ptr)) EXIT
                    grid(i,j,k)%list_size = grid(i,j,k)%list_size + 1
                    current_ptr => current_ptr%next
                END DO
            END DO
        END DO
    end do

END SUBROUTINE UpdateSparseData

SUBROUTINE CopyData()
    USE SparseDataStructure
    USE Constant
    USE ExternalSub
    USE IFPORT
    IMPLICIT none

    integer :: i, j, k

    do k = 1, z
        DO j = 1, y
            DO i = 1, x
                grid(i,j,k)%copy_ptr => grid(i,j,k)%head_ptr
            END DO
        END DO
    end do

END SUBROUTINE CopyData

SUBROUTINE UpdateSumEta()
    USE SparseDataStructure
    USE Constant
    USE ExternalSub
    USE IFPORT
    IMPLICIT none

    integer :: i, j, k, l

    sum_eta = 0.d0

    CALL CopyData()

    do k = 1, z
        DO j = 1, y
            DO i = 1, x
                DO l = 1, grid(i,j,k)%list_size
                    IF (.NOT.ASSOCIATED(grid(i,j,k)%copy_ptr)) EXIT
                    ASSOCIATE (eta => grid(i,j,k)%copy_ptr%eta)
                        sum_eta(i,j,k) = sum_eta(i,j,k) + eta*eta
                        grid(i,j,k)%copy_ptr => grid(i,j,k)%copy_ptr%next
                    END ASSOCIATE
                END DO
            END DO
        END DO
    end do
END SUBROUTINE UpdateSumEta

SUBROUTINE UpdateBulkEnergy()
    USE SparseDataStructure
    USE Constant
    USE ExternalSub
    USE IFPORT
    IMPLICIT none

    integer :: i, j, k, l

    bulk_energy = 0.d0

    CALL CopyData()

    do k = 1, z
        DO j = 1, y
            DO i = 1, x
                DO l = 1, grid(i,j,k)%list_size
                    IF (.NOT.ASSOCIATED(grid(i,j,k)%copy_ptr)) EXIT
                    ASSOCIATE (eta => grid(i,j,k)%copy_ptr%eta, es => grid(i,j,k)%copy_ptr%es)
                        bulk_energy(i,j,k) = bulk_energy(i,j,k) + es*eta*eta/sum_eta(i,j,k)
                        grid(i,j,k)%copy_ptr => grid(i,j,k)%copy_ptr%next
                    END ASSOCIATE
                END DO
            END DO
        END DO
    end do
END SUBROUTINE UpdateBulkEnergy

SUBROUTINE PhaseEvolution()
    USE SparseDataStructure
    USE Constant
    USE ExternalSub
    USE IFPORT
    IMPLICIT none

    integer :: i, j, l, ii, jj
    real :: f0, laplacian, fb

    CALL CopyData()
    do k = 1, z
        DO j = 1, y
            DO i = 1, x
                f0 = 0.D0
                DO l = 1, grid(i,j,k)%list_size
                    IF (.NOT.ASSOCIATED(grid(i,j,k)%copy_ptr)) EXIT
                    ASSOCIATE (eta => grid(i,j,k)%copy_ptr%eta, es => grid(i,j,k)%copy_ptr%es)
                        f0 = mp(i,j,k)*(-eta + eta*eta*eta + 2.D0*yp(i,j,k)*eta*(sum_eta(i,j,k) - eta*eta))
                        fb = 2.D0*eta/sum_eta(i,j,k)*(es-bulk_energy(i,j,k))
    
                        CALL NeighborNode(i,j,k)
                        laplacian = 0.D0
                        DO kk = -1,1
                            DO ii = -1,1
                                DO jj = -1,1
                                    IF ((ii == 0) .or. (jj == 0) .or. (jj == 0)) THEN
                                        laplacian = laplacian - 0.5D0*(neighbor_array(ii,jj,kk)-neighbor_array(0,0,0))
                                    ELSE
                                        laplacian = laplacian - 0.25D0*(neighbor_array(ii,jj,kk)-neighbor_array(0,0,0))
                                    END IF
                                END DO
                            END DO
                        end do
                        laplacian = kp(i,j,k)*laplacian/DX/DX
    
                        eta = eta - lp(i,j,k) * (f0+laplacian+fb) * DT
                        grid(i,j,k)%copy_ptr => grid(i,j,k)%copy_ptr%next
                    END ASSOCIATE
                END DO
            END DO
        END DO
    end do

    CALL UpdateSparseData()
    CALL UpdateSumEta()
    CALL UpdateBulkEnergy()
    CALL UpdateSharpOri()

END SUBROUTINE PhaseEvolution

SUBROUTINE Output()
    USE SparseDataStructure
    USE Constant
    USE ExternalSub
    USE IFPORT
    IMPLICIT none

    INTEGER :: i, j, k, ii, jj, nx, ny, gb_site, grain_count, rex_grain_count
    REAL (KIND = DBL):: radius, radius_r, r_frac, stress
    CHARACTER (LEN = 32) :: out_num

    IF (MOD(t, TINTERVAL) == 0) THEN
        WRITE (out_num,'(F6.3)') REAL(t)*DT
        OPEN (UNIT = 101, FILE = trim(output_path)//'phi_'//trim(adjustl(out_num))//'.raw', &
            & STATUS = 'replace', ACTION = 'write', FORM = 'binary')
        OPEN (UNIT = 102, FILE = trim(output_path)//'egy_'//trim(adjustl(out_num))//'.raw', &
            & STATUS = 'replace', ACTION = 'write', FORM = 'binary')
        OPEN (UNIT = 103, FILE = trim(output_path)//'eta_'//trim(adjustl(out_num))//'.raw', &
            & STATUS = 'replace', ACTION = 'write', FORM = 'binary')
        ! OPEN (UNIT = 105, FILE = trim(output_path)//'list_size_'//trim(adjustl(out_num))//'.raw', &
            ! & STATUS = 'replace', ACTION = 'write', FORM = 'binary')
        !open(unit=104, file=trim(output_path)//'phi_'//trim(adjustl(out_num))//'.txt', &
            !   & status='replace', action='write', form='formatted')
        !open(unit=105, file=trim(output_path)//'egy_'//trim(adjustl(out_num))//'.txt', &
            !   & status='replace's, action='write', form='formatted')
        !open(unit=106, file=trim(output_path)//'eta_'//trim(adjustl(out_num))//'.txt', &
            !   & status='replace', action='write', form='formatted')

        DO j = 1,y
            DO i = 1,x
                WRITE (101) sum_eta(i,j,k)
                WRITE (102) bulk_energy(i,j,k)
                !WRITE (105) grid(i,j,k)%list_size

                gb_site = 0
                gb: DO jj = j-1, j+1
                    DO ii = i-1, i+1
                        nx = ii
                        ny = jj

                        !periodic boundary
                        IF (nx == 0) nx = x
                        IF (nx == x+1) nx = 1
                        IF (ny == 0) ny = y
                        IF (ny == y+1) ny = 1

                        IF (((nx == i) .or. (ny == j)) .and. (sharp_ori(i,j,k) /= sharp_ori(nx,ny))) then
                            gb_site = 1
                            EXIT gb
                        END IF
                    END DO
                END DO gb

                IF (gb_site == 1) THEN
                    WRITE (103) 1
                ELSE IF (sharp_ori(i,j,k) <= matrix_q_number) THEN
                    WRITE (103) 0
                ELSE
                    WRITE (103) 2
                END IF
                !write (104,"(ES13.6)") sum_eta(i,j,k)
                !write (105,"(ES13.6)") bulk_energy(i,j,k)
                !do l = 1,q
                !write (103) eta(l,i,j)
                !write (106,"(ES13.6)") eta(l,i,j)
                !end do
            END DO
        END DO

        CLOSE (101)
        CLOSE (102)
        CLOSE (103)
        !CLOSE (105)
        !close(106)
    END IF

    r_frac = 0.0
    DO j = 1,y
        DO i = 1,x
            IF (sharp_ori(i,j,k) > matrix_q_number) r_frac = r_frac + 1.0
        END DO
    END DO

    grain_count = 0
    rex_grain_count = 0
    DO k = 1, total_q_number
        IF (individual_radius(k) /= 0.d0) THEN
            grain_count = grain_count + 1
            IF (k > matrix_q_number) rex_grain_count = rex_grain_count + 1
        END IF
    END DO

    r_frac = r_frac/REAL(x)/REAL(y)
    radius = sqrt(REAL(x)*REAL(y)*DX*DX/REAL(grain_count)/PI)*1.224D0*2.D0
    IF (rex_grain_count == 0) THEN
        radius_r = 0.D0
    ELSE
        radius_r = SQRT(r_frac*REAL(x)*REAL(y)*DX*DX/REAL(rex_grain_count)/PI)*1.224D0*2.D0
    END IF

    !stress = 1.411D0*M_TAYLOR*ALPHA*SQRT(GSHEAR*SUM(bulk_energy)/REAL(x)/REAL(y))

    IF (t == TINTERVAL) THEN
        OPEN (UNIT = 107, FILE = TRIM(output_path)//"GrainSize.txt", STATUS = 'replace', ACTION = 'write', FORM = 'formatted')
        !OPEN (UNIT = 108, FILE = TRIM(output_path)//"SS.txt", STATUS = 'replace', ACTION = 'write', FORM = 'formatted')
        OPEN (UNIT = 109, FILE = TRIM(output_path)//"r_frac.txt", STATUS = 'replace', ACTION = 'write', FORM = 'formatted')
    END IF

    WRITE (107,'(ES13.6, ES13.6)') REAL(t)*DT*STRAIN_RATE, radius
    !WRITE (108,'(ES13.6, ES13.6)') REAL(t)*DT*STRAIN_RATE, stress/1.0E6
    WRITE (109,'(ES13.6, ES13.6)') REAL(t)*DT*STRAIN_RATE, r_frac

    IF (t == TSTEP) THEN
        CLOSE (107)
        !CLOSE (108)
        CLOSE (109)
    END IF

    WRITE (*,*) 'The annealing time = ', REAL(t)*DT, ' finished.'
END SUBROUTINE Output

SUBROUTINE AnisotropyInterface()
    USE SparseDataStructure
    USE Constant
    USE ExternalSub
    USE IFPORT
    IMPLICIT none

    REAL :: s_gb, u_gb
    REAL :: ki, li, yi, mi

    s_gb = SGB_0
    u_gb = UGB_0

    CALL ModelParameter(s_gb, u_gb, ki, li, yi, mi)

    mp = mi
    kp = ki
    lp = li
    yp = yi

END SUBROUTINE AnisotropyInterface

SUBROUTINE ModelParameter(s_gb, u_gb, ki, li, yi, mi)
    USE SparseDataStructure
    USE Constant
    USE ExternalSub
    USE IFPORT
    IMPLICIT none

    REAL (KIND = DBL), PARAMETER :: p1 =      -5.288D0
    REAL (KIND = DBL), PARAMETER :: p2 =    -0.09364D0
    REAL (KIND = DBL), PARAMETER :: p3 =       9.965D0
    REAL (KIND = DBL), PARAMETER :: p4 =      -8.183D0
    REAL (KIND = DBL), PARAMETER :: p5 =       2.007D0

    REAL (KIND = DBL), PARAMETER :: pp1 =     0.05676D0
    REAL (KIND = DBL), PARAMETER :: pp2 =     -0.2924D0
    REAL (KIND = DBL), PARAMETER :: pp3 =      0.6367D0
    REAL (KIND = DBL), PARAMETER :: pp4 =     -0.7749D0
    REAL (KIND = DBL), PARAMETER :: pp5 =      0.6107D0
    REAL (KIND = DBL), PARAMETER :: pp6 =     -0.4324D0
    REAL (KIND = DBL), PARAMETER :: pp7 =      0.2792D0

    REAL (KIND = DBL) :: f_0, g_0, a_0
    REAL (KIND = DBL) :: a_star, k_star, gamma_star
    REAL (KIND = DBL) :: g, gr, f
    REAL, INTENT (inout) :: ki, li, yi, mi
    REAL, INTENT (in) :: s_gb, u_gb

    f_0 = (2.D0*GAMMA_0-1.D0)/4.D0/(2.D0*GAMMA_0+1.D0)
    g_0 = sqrt(f_0)*4.D0/3.D0
    a_0 = sqrt(f_0)/g_0
    mi = SGB_0/LGB/g_0/sqrt(f_0)

    a_star = a_0
    a_0 = 0.0
    DO WHILE (abs(a_star-a_0) > 1.0D-10)
        a_0 = a_star
        k_star = s_gb*LGB*a_0
        g = s_gb/sqrt(k_star*mi)
        gr = p1*g**8 + p2*g**6 + p3*g**4 + p4*g**2 + p5
        f = pp1*gr**6 + pp2*gr**5 + pp3*gr**4 + pp4*gr**3 + pp5*gr**2 + pp6*gr + pp7
        gamma_star = 1.D0/gr
        a_star = sqrt(f)/g
    END DO

    ki = k_star
    yi = gamma_star
    li = u_gb/LGB/a_star

END SUBROUTINE ModelParameter

SUBROUTINE UpdateSharpOri()
    USE SparseDataStructure
    USE Constant
    USE ExternalSub
    USE IFPORT
    IMPLICIT none

    INTEGER :: i, j, k, gb_site
    REAL (KIND = DBL) :: max_eta

    DO j = 1,y
        DO i = 1,x
            max_eta = 0.0
            current_ptr => grid(i,j,k)%head_ptr
            DO
                IF (.NOT. ASSOCIATED(current_ptr)) EXIT
                IF (current_ptr%eta > max_eta) THEN
                    max_eta = current_ptr%eta
                    sharp_ori(i,j,k) = current_ptr%eta_id
                END IF
                current_ptr => current_ptr%next
            END DO
        END DO
    END DO

    individual_radius = 0.d0

    DO j = 1,y
        DO i = 1,x
            do k = 1, total_q_number
                if (sharp_ori(i,j,k) == k) then
                    individual_radius(k) = individual_radius(k) + 1.d0
                end if
            end do
        end do
    end do

    do k = 1, total_q_number
        individual_radius(k) = sqrt(individual_radius(k)*DX*DX/PI)
    end do

END SUBROUTINE UpdateSharpOri

SUBROUTINE NucleationModel_1()
    USE SparseDataStructure
    USE Constant
    USE ExternalSub
    USE IFPORT
    IMPLICIT none

    INTEGER :: i, j, m, n, gb_site
    REAL (KIND = DBL) :: r_nuc, r_cri, rdn,p_nuc, r_cri_old
    REAL (KIND = DBL) :: r_ave, R_grain, nuclei_num

    r_cri = 4.d0 * DX

    DO j = 1,y
        DO i = 1,x
            gb_site = 0
            current_ptr => grid(i,j,k)%head_ptr
            DO
                IF ( .not. ASSOCIATED (current_ptr)) EXIT
                IF (current_ptr%eta > 0.2) gb_site = gb_site + 1
                current_ptr => current_ptr%next
            END DO
            if ((gb_site >= 0)) then
                    p_nuc = 50.d0 /x/y

                    CALL random_number(rdn)

                    IF (rdn < p_nuc) THEN
                        total_q_number = total_q_number + 1

                        DO n = 1,y
                            DO m = 1,x
                                r_nuc = DX*SQRT(REAL(m-i)**2+REAL(n-j)**2)
                                IF (r_nuc <= r_cri) THEN
                                    current_ptr => grid(m,n)%head_ptr
                                    DO
                                        IF ( .not. ASSOCIATED (current_ptr)) EXIT
                                        current_ptr%eta = 0.0
                                        current_ptr => current_ptr%next
                                    END DO

                                    current_ptr => grid(m,n)%head_ptr
                                    DO
                                        IF ( .not. ASSOCIATED (current_ptr%next) ) EXIT
                                        current_ptr => current_ptr%next
                                    END DO
                                    ALLOCATE (current_ptr%next)
                                    current_ptr%next%eta = 1.0
                                    current_ptr%next%es = ESTOR0
                                    current_ptr%next%eta_id = total_q_number
                                    NULLIFY (current_ptr%next%next)

                                    current_ptr => grid(m,n)%head_ptr
                                    sum_eta(m,n) = 0.0
                                    DO
                                        IF ( .not. ASSOCIATED (current_ptr)) EXIT
                                        sum_eta(m,n) = sum_eta(m,n) + current_ptr%eta*current_ptr%eta
                                        current_ptr => current_ptr%next
                                    END DO

                                    current_ptr => grid(m,n)%head_ptr
                                    bulk_energy(m,n) = 0.0
                                    DO
                                        IF ( .not. ASSOCIATED (current_ptr)) EXIT
                                        bulk_energy(m,n) = bulk_energy(m,n) + current_ptr%es*current_ptr%eta*current_ptr%eta/sum_eta(i,j,k)
                                        current_ptr => current_ptr%next
                                    END DO

                                    sharp_ori(m,n) = total_q_number
                                END IF

                            END DO
                        END DO

                    end if
            end if
        end do
    end do

    CALL UpdateSparseData()
    !CALL UpdateSharpOri()
END SUBROUTINE NucleationModel_1

SUBROUTINE NucleationModel_2()
    USE SparseDataStructure
    USE Constant
    USE ExternalSub
    USE IFPORT
    IMPLICIT none

    INTEGER :: i, j, m, n, gb_site
    REAL (KIND = DBL) :: r_nuc, r_cri, rdn,p_nuc, r_cri_old
    REAL (KIND = DBL) :: r_ave, R_grain, nuclei_num

    r_cri = 4.d0 * DX

    DO j = 1,y
        DO i = 1,x
            gb_site = 0
            current_ptr => grid(i,j,k)%head_ptr
            DO
                IF ( .not. ASSOCIATED (current_ptr)) EXIT
                IF (current_ptr%eta > 0.2) gb_site = gb_site + 1
                current_ptr => current_ptr%next
            END DO
            if ((gb_site >= 0) .and. (sharp_ori(i,j,k) <= matrix_q_number)) then
                    p_nuc = 0.05d0 /x/y

                    CALL random_number(rdn)

                    IF (rdn < p_nuc) THEN
                        total_q_number = total_q_number + 1

                        DO n = 1,y
                            DO m = 1,x
                                r_nuc = DX*SQRT(REAL(m-i)**2+REAL(n-j)**2)
                                IF (r_nuc <= r_cri) THEN
                                    current_ptr => grid(m,n)%head_ptr
                                    DO
                                        IF ( .not. ASSOCIATED (current_ptr)) EXIT
                                        current_ptr%eta = 0.0
                                        current_ptr => current_ptr%next
                                    END DO

                                    current_ptr => grid(m,n)%head_ptr
                                    DO
                                        IF ( .not. ASSOCIATED (current_ptr%next) ) EXIT
                                        current_ptr => current_ptr%next
                                    END DO
                                    ALLOCATE (current_ptr%next)
                                    current_ptr%next%eta = 1.0
                                    current_ptr%next%es = ESTOR0
                                    current_ptr%next%eta_id = total_q_number
                                    NULLIFY (current_ptr%next%next)

                                    current_ptr => grid(m,n)%head_ptr
                                    sum_eta(m,n) = 0.0
                                    DO
                                        IF ( .not. ASSOCIATED (current_ptr)) EXIT
                                        sum_eta(m,n) = sum_eta(m,n) + current_ptr%eta*current_ptr%eta
                                        current_ptr => current_ptr%next
                                    END DO

                                    current_ptr => grid(m,n)%head_ptr
                                    bulk_energy(m,n) = 0.0
                                    DO
                                        IF ( .not. ASSOCIATED (current_ptr)) EXIT
                                        bulk_energy(m,n) = bulk_energy(m,n) + current_ptr%es*current_ptr%eta*current_ptr%eta/sum_eta(i,j,k)
                                        current_ptr => current_ptr%next
                                    END DO

                                    sharp_ori(m,n) = total_q_number
                                END IF

                            END DO
                        END DO

                    end if
            end if
        end do
    end do

    CALL UpdateSparseData()
    !CALL UpdateSharpOri()
END SUBROUTINE NucleationModel_2
