!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!  
      subroutine templiquidussolidus(nrhcon,rhcon,nflcon,flcon,
     &  templiq,tempsol,icastpost,ntmat_,ithermal,enthactrl,ny_coeff)
!
!     determine temperature of liquidus and solidus
!
      implicit none
!
      integer nflcon(*),nrhcon,icastpost,ntmat_,ithermal(*),imat,i
!
      real*8 flcon(0:1,ntmat_,*),rhcon(0:1,ntmat_,*),
     &       templiq,tempsol,enthactrl(*),ny_coeff(*),
     &       rholiq,rhosol,beta
!
!     ny_coeff(1):C_lambda*sqrt(delta_Pcr/(miu*beta*(Tl-Ts)))
!     ny_coeff(2):beta_prime
!
!
c      do imat=1,nmat
        imat=1
!
        if(nflcon(imat).eq.1) then
            icastpost=0
            templiq=-1.d0
            tempsol=-1.d0
c            cycle
            return
        endif
!
        i=1
        do while(dabs(flcon(1,i,imat)).lt.1.d-6)
            i=i+1
        end do
        if(i.eq.1) then
            tempsol=-1.d0
            write(*,*) 
     &           '*ERROR in templiquidussolidus:'
            write(*,*) '       in *LIQUIDFRACTION, chart points'
            write(*,*) '       where fl=0.0 is not found,'
            write(*,*) '       time to solidus and solidification'
            write(*,*) '       time will not calculated'
        else
            tempsol=flcon(0,i-1,imat)
        endif
!
        i=nflcon(imat)
        do while(dabs(flcon(1,i,imat)-1.d0).lt.1.d-6)
            i=i-1
        end do
        if(i.eq.nflcon(imat)) then
            templiq=-1.d0
            write(*,*) 
     &           '*ERROR in templiquidussolidus:'
            write(*,*) '       in *LIQUIDFRACTION, chart points'
            write(*,*) '       where fl=1.0 is not found,'
            write(*,*) '       time to solidus and solidification'
            write(*,*) '       time will not calculated'
        else
            templiq=flcon(0,i+1,imat)
        endif
!
        if((tempsol.gt.0.d0).and.(templiq.gt.0.d0)) then
            icastpost=1
        else 
            icastpost=0
        endif
c      enddo
!
      call materialdata_rho(rhcon,nrhcon,imat,rholiq,
     &  templiq,ntmat_,ithermal)
      call materialdata_rho(rhcon,nrhcon,imat,rhosol,
     &  tempsol,ntmat_,ithermal)
      beta=(rhosol-rholiq)/rholiq
      ny_coeff(1)=enthactrl(5)
     &           *(1.d5/enthactrl(6)/beta/(templiq-tempsol))**0.5d0
      ny_coeff(2)=beta/(1.d0+beta)
!
      return
      end
!