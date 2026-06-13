! **********************************************************
! * Author        : Namin Xiao
! * Email         : <nmxiao@outlook.com>
! * Create time   : 2018-05-28 19:44
! * Last modified : 2018-05-28 19:44
! * Filename      : GGCA2D.f90
! * Description   : 2D Cellular Automaton modeling of Grain Growth
! **********************************************************
Module ModelConstant
    IMPLICIT none
    INTEGER, PARAMETER :: SP = SELECTED_REAL_KIND (p=6, r=37)             !Single data kind
    INTEGER, PARAMETER :: DP = SELECTED_REAL_KIND (p=13, r=200)                 !Double data kind

    real(DP), PARAMETER :: PI = 3.14159265358979
    real(DP), PARAMETER :: R = 8.314
    real(DP), PARAMETER :: KB = 1.380658D-23
    real(DP), PARAMETER :: LOGE = 2.71828183

    INTEGER, PARAMETER :: TSTEP = 100000 ! 总的时间步数
    INTEGER, PARAMETER :: TSAVE = 10000 ! 用于输出保存的时间间隔
    INTEGER, PARAMETER :: NUCLEI_NUM = 100

    real(DP), PARAMETER :: DT = 0.01
    real(DP), PARAMETER :: DX = 4.0E-6
    real(DP), PARAMETER :: NDX = 1.0E-7
    real(DP), PARAMETER :: DY = DX
    real(DP), PARAMETER :: COEF0 = 9.0E-11
    real(DP), PARAMETER :: COEF1 = 3.0E-10
    real(DP), PARAMETER :: MISORI = 70.0/180.0*PI
End Module

Module GlobalVariable
    use ModelConstant
    implicit none

    integer :: nx, ny, xi, yi, ii, jj, kk, xti, xbi, yli, yri, neix, neiy
    integer, allocatable, dimension (:,:) :: GrainOri
    real(dp), allocatable, dimension (:,:) :: GrainFrac
    real(dp), allocatable, dimension (:) :: GrainDiameter
end Module GlobalVariable

Program main
    use ModelConstant
    use GlobalVariable
    USE IFPORT
    implicit none

    integer :: indice, num, m, egn, t, ioerr, GrainNumber, ierr, m_Maxi, m_Max
    integer, allocatable, dimension (:) :: NeiOriCounter,NeiOri
    real(dp) :: ave_diameter, curvature, Vt, Vb, Vl, Vr
    CHARACTER (LEN = 32) :: out_num, output_path, directory_name

    nx =1024
    ny =1024
    GrainNumber = NUCLEI_NUM

    allocate(GrainOri(nx,ny))
    allocate(GrainFrac(nx,ny))
    allocate(NeiOri(4))
    allocate(NeiOriCounter(4))
    allocate(GrainDiameter(GrainNumber))

    directory_name = 'output'
    output_path = '.\\'//trim(adjustl(directory_name))//'\\'
    ierr = makedirqq (trim(directory_name))
    write(*, "(A)") "Output Directory Created Done."

    call VoronoiMap()
    GrainFrac = 1.0

    do t = 1, TSTEP
        do yi = 1, ny
            do xi = 1, nx
                xti = xi-1
                xbi = xi+1
                yli = yi-1
                yri = yi+1

                if (xti == 0)   xti = nx
                if (xbi == Nx+1) xbi = 1
                if (yli == 0)   yli = ny
                if (yri == Ny+1) yri = 1

                m = 0
                if(GrainOri(xi,yi) /= GrainOri(xti,yi)) m = m + 1
                if(GrainOri(xi,yi) /= GrainOri(xi,yli)) m = m + 1
                if(GrainOri(xi,yi) /= GrainOri(xbi,yi)) m = m + 1
                if(GrainOri(xi,yi) /= GrainOri(xi,yri)) m = m + 1

                if (m > 0) then
                    num = 0
                    indice = 0

                    do jj = -2, 2
                        do ii = -2, 2
                            num = num + 1
                            neix = xi + ii
                            neiy = yi + jj
                            if (neix == 0) neix = nx
                            if (neix == -1) neix = nx - 1
                            if (neix == nx+1) neix = 1
                            if (neix == nx+2) neix = 2
                            if (neiy == 0) neiy = ny
                            if (neiy == -1) neiy = ny - 1
                            if (neiy == ny+1) neiy = 1
                            if (neiy == ny+2) neiy = 2

                            if (GrainOri(neix,neiy) == GrainOri(xi,yi)) indice = indice + 1
                        end do
                    end do
                end if

                curvature = 1.28 / DX * (14.0 - real(indice)) / real(Num)

                if (curvature > 0.0) then 
                    Vt = 0.0
                    Vb = 0.0
                    Vl = 0.0
                    Vr = 0.0

                    if(GrainOri(xi,yi) /= GrainOri(xti,yi)) Vt = COEF0 * curvature
                    if(GrainOri(xi,yi) /= GrainOri(xbi,yi)) Vb = COEF0 * curvature
                    if(GrainOri(xi,yi) /= GrainOri(xi,yli)) Vl = COEF0 * curvature
                    if(GrainOri(xi,yi) /= GrainOri(xi,yri)) Vr = COEF0 * curvature

                    GrainFrac(xi,yi) = GrainFrac(xi,yi) - dt/dx*(Vt+Vb+Vl+Vr)+dt**2/(dx*dy)*(Vt*Vr+Vt*Vl+Vb*Vl+Vb*Vr)
                end if
            end do
        end do

                 
        do yi = 1, ny
            do xi = 1, nx
                xti = xi-1
                xbi = xi+1
                yli = yi-1
                yri = yi+1

                if (xti == 0)   xti = nx
                if (xbi == Nx+1) xbi = 1
                if (yli == 0)   yli = ny
                if (yri == Ny+1) yri = 1

                if (GrainFrac(xi,yi) < 0.01) then
                    NeiOri = 0
                    NeiOriCounter = 0

                    NeiOri(1) = GrainOri(xti,yi)
                    NeiOri(2) = GrainOri(xbi,yi)
                    NeiOri(3) = GrainOri(xi,yli)
                    NeiOri(4) = GrainOri(xi,yri)
                    do jj = -2, 2
                        do ii = -2, 2
                            neix = xi + ii
                            neiy = yi + jj
                            if (neix == 0) neix = nx
                            if (neix == -1) neix = nx - 1
                            if (neix == nx+1) neix = 1
                            if (neix == nx+2) neix = 2
                            if (neiy == 0) neiy = ny
                            if (neiy == -1) neiy = ny - 1
                            if (neiy == ny+1) neiy = 1
                            if (neiy == ny+2) neiy = 2

                            if (GrainOri(xti,yi) == GrainOri(neix,neiy)) NeiOriCounter(1) = NeiOriCounter(1) + 1
                            if (GrainOri(xbi,yi) == GrainOri(neix,neiy)) NeiOriCounter(2) = NeiOriCounter(2) + 1
                            if (GrainOri(xi,yli) == GrainOri(neix,neiy)) NeiOriCounter(3) = NeiOriCounter(3) + 1
                            if (GrainOri(xi,yri) == GrainOri(neix,neiy)) NeiOriCounter(4) = NeiOriCounter(4) + 1
                        end do
                    end do

                    if(NeiOri(1) /= GrainOri(xi,yi)) then
                        m_Max = NeiOriCounter(1)
                        m_Maxi = 1
                    end if
                    if(NeiOri(2) /= GrainOri(xi,yi)) then
                        m_Max = NeiOriCounter(2)
                        m_Maxi = 2
                    end if
                    if(NeiOri(3) /= GrainOri(xi,yi)) then
                        m_Max = NeiOriCounter(3)
                        m_Maxi = 3
                    end if
                    if(NeiOri(4) /= GrainOri(xi,yi)) then
                        m_Max = NeiOriCounter(4)
                        m_Maxi = 4
                    end if

                    do kk = 1, 4
                        if((NeiOriCounter(kk) > m_Max) .and. (NeiOri(kk) /= GrainOri(xi,yi))) then
                            m_Max = NeiOriCounter(kk)
                            m_Maxi = kk
                        end if
                    end do

                    GrainOri(xi,yi) = NeiOri(m_Maxi)
                    GrainFrac(xi,yi) = 1.0
                end if
            end do
        end do

        if(mod(t,TSAVE) == 0) then

            WRITE (out_num,'(I8)') t
            OPEN (unit=101, file=trim(output_path)//'phi_'//trim(adjustl(out_num))//'.raw', status='replace', action='WRITE', form = 'unformatted', access = 'stream')
            open (unit=102, file=trim(output_path)//'phi_'//trim(adjustl(out_num))//'.txt', status='replace', action='write', form='formatted')

            GrainDiameter = 0.0

            DO yi = 1,ny
                DO xi = 1,nx
                    WRITE (101) GrainOri(xi,yi)
                    write (102,"(I8)") GrainOri(xi,yi)
                    GrainDiameter(GrainOri(xi,yi)) = GrainDiameter(GrainOri(xi,yi)) + 1.0
                END DO
            END DO

            egn = 0.0
            do jj = 1, GrainNumber
                if(GrainDiameter(jj) /= 0.0) egn = egn + 1.0
            end do

            open (unit = 103, file = 'average_grain_size.txt', &
                & status = 'old', action = 'write', form = 'formatted', position = 'append', iostat = ioerr)

            if (ioerr /= 0) then
                open (unit = 103, file = 'average_grain_size.txt', &
                    & status = 'new', action = 'write', form = 'formatted')
            end if
            ave_diameter = sqrt(real(nx*ny)*NDX*NDX/PI/real(egn))*1.224D0*2.0D0
            write (103, '(I5, ES13.6)') t, ave_diameter

            CLOSE(101)
            CLOSE(102)
            CLOSE(103)

            WRITE (*,*) 'The step ', t, ' finished.'
        end if
    end do

    deallocate(GrainOri)
    deallocate(GrainFrac)
    deallocate(NeiOri)
    deallocate(NeiOriCounter)
    deallocate(GrainDiameter)
end program

subroutine VoronoiMap
    use ModelConstant
    use GlobalVariable
    USE IFPORT
    implicit none

    integer :: i, j
    real(dp) :: rdn, min_distance
    real(dp), allocatable, dimension (:) :: distance
    integer, allocatable, dimension (:) :: Xcoord, Ycoord, nuclei
    integer, allocatable, dimension (:,:) :: VoronoiGrain

    allocate(Xcoord(9*NUCLEI_NUM))
    allocate(Ycoord(9*NUCLEI_NUM))
    allocate(distance(9*NUCLEI_NUM))
    allocate(nuclei(9*NUCLEI_NUM))
    allocate(VoronoiGrain(9*nx, 9*ny))

    do i = 1, NUCLEI_NUM
        call random_number(rdn)
        Xcoord(i) = ceiling(real(nx)*rdn)
        call random_number(rdn)
        Ycoord(i) = ceiling(real(ny)*rdn)

        Xcoord(NUCLEI_NUM+i) = Xcoord(i) + nx
        Ycoord(NUCLEI_NUM+i) = Ycoord(i)

        Xcoord(2*NUCLEI_NUM+i) = Xcoord(i) + 2*nx
        Ycoord(2*NUCLEI_NUM+i) = Ycoord(i)

        Xcoord(3*NUCLEI_NUM+i) = Xcoord(i)
        Ycoord(3*NUCLEI_NUM+i) = Ycoord(i) + ny

        Xcoord(4*NUCLEI_NUM+i) = Xcoord(i) + nx
        Ycoord(4*NUCLEI_NUM+i) = Ycoord(i) + ny

        Xcoord(5*NUCLEI_NUM+i) = Xcoord(i) + 2*nx
        Ycoord(5*NUCLEI_NUM+i) = Ycoord(i) + ny

        Xcoord(6*NUCLEI_NUM+i) = Xcoord(i)
        Ycoord(6*NUCLEI_NUM+i) = Ycoord(i) + 2*ny

        Xcoord(7*NUCLEI_NUM+i) = Xcoord(i) + nx
        Ycoord(7*NUCLEI_NUM+i) = Ycoord(i) + 2*ny

        Xcoord(8*NUCLEI_NUM+i) = Xcoord(i) + 2*nx
        Ycoord(8*NUCLEI_NUM+i) = Ycoord(i) + 2*ny

        do j = 0, 8
            nuclei(j*NUCLEI_NUM+i) = i
        end do
    end do

    do xi = 1, 9*nx
        do yi = 1, 9*ny
            do kk = 1, 9*NUCLEI_NUM
                distance(kk) = (xi-Xcoord(kk))**2 + (yi-Ycoord(kk))**2
                distance(kk) = sqrt(distance(kk))
            end do
            min_distance = distance(1)
            do kk = 1, 9*NUCLEI_NUM
                if(distance(kk) <= min_distance) then
                    min_distance = distance(kk)
                    VoronoiGrain(xi,yi) = nuclei(kk)
                end if
            end do
        end do
    end do

    do xi = 1, nx
        do yi = 1, ny
            GrainOri(xi,yi) = VoronoiGrain(nx+xi, ny+yi)
        end do
    end do

    deallocate(Xcoord)
    deallocate(Ycoord)
    deallocate(distance)
    deallocate(nuclei)
    deallocate(VoronoiGrain)
end subroutine VoronoiMap





