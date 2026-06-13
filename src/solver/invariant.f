!
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
C!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
C     hydrostatic pressure, Mises stress, pricipal components
C!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

      subroutine invariant(nk,stn,sinv,ncomp,icomp)
        implicit none
        integer nk,i,j,ncomp
        integer icomp(ncomp)
        real*8 stn(6,nk),sinv(ncomp,nk),ss(6,1),sp(3)
        real*8, external :: pressure, mises
        
        do i=1,nk

          do j=1,6
            ss(j,1)=stn(j,i)
          enddo

          if (maxval(icomp).gt.2) then
            call principal(ss,sp)
          endif 
          
          do j=1,ncomp
            select case (icomp(j))
              case (0)
                sinv(j,i)=-pressure(ss)
              case (1)
                sinv(j,i)=mises(ss)
              case (2)
                sinv(j,i)=(sp(1)-sp(3))/2.d0
              case (3)
                sinv(j,i)=sp(1)
              case (4)
                sinv(j,i)=sp(2)
              case (5)
                sinv(j,i)=sp(3)
            end select
          enddo
         
        enddo
        
        return

      end subroutine


      function pressure(s)
        implicit none
        integer i
        real*8 pressure, s(6,1)

        pressure = 0.d0
        do i = 1,3
            pressure = pressure + s(i,1)
        end do
        pressure = -pressure/3.d0
        return
      end

      function mises(s)
        implicit none
        integer i
        real*8 s(6,1),mises

        mises = (s(1,1)-s(2,1))**2+(s(2,1)-s(3,1))**2+(s(3,1)-s(1,1))**2

        do i=4,6
          mises = mises+6.d0*s(i,1)**2
        end do
        mises = sqrt(0.5d0*mises)
        
        return
      end

      subroutine principal(s,wr)
c calculate the principal components of a stress or strain tensor

        implicit none
        integer i,j,n,lda,ldvl,ldvr,lwork,info
        real*8 s(6,1),a(3,3),wr(3),wi(3),vl(3,3),vr(3,3),work(12),t
        CHARACTER*1 jobvl,jobvr
          
        n=3
        lda=n
        ldvl=3
        ldvr=3
        lwork=12
        jobvl="n"
        jobvr="n"

        a(1,1)=s(1,1)
        a(1,2)=s(4,1)
        a(1,3)=s(5,1)
        a(2,1)=s(4,1)
        a(2,2)=s(2,1)
        a(2,3)=s(6,1)
        a(3,1)=s(5,1)
        a(3,2)=s(6,1)
        a(3,3)=s(3,1)

        call dgeev(jobvl,jobvr,n,a,lda,wr,wi,vl,ldvl,vr,ldvr,
     1    work,lwork,info)
        
        do i = 1,3
          do j=i,3
            if (wr(i).lt.wr(j)) then
              t=wr(i)
              wr(i)=wr(j)
              wr(j)=t
            endif
          enddo
        enddo

        return
      end subroutine
