      subroutine rdplas(stress,statev,ddsdde,sse,spd,scd,
     1     rpl,ddsddt,drplde,drpldt,stran,dstran,
     2     time,dtime,temp,dtemp,predef,dpred,cmname,ndi,nshr,ntens,
     3     nstatv,elconloc,rdploc,gsloc,coords,drot,pnewdt,celent,
     4     dfgrd0,dfgrd1,noel,npt,kslay,kspt,kstep,kinc)
c

      implicit none
c     include 'aba_param.inc'

      character*80 cmname
      integer ndi, nshr
      integer ntens, nstatv, nprops
      integer noel, npt, kstep, kinc, layer, kspt, kslay
      real*8 dtime, temp, dtemp, pnewdt, celent
      real*8 stress(ntens),statev(nstatv),
     & ddsdde(ntens,ntens), ddsddt(ntens),drplde(ntens), drpldt(1),
     & stran(ntens),dstran(ntens),time(2),predef(1),dpred(1),
     & props(10),coords(3),drot(3,3),dfgrd0(3,3),dfgrd1(3,3),
     & sse(1),spd(1),scd(1),rpl(1),elconloc(21),rdploc(10,3),gsloc(30,5)
c
      integer k1, k2,criteria
      real*8 eelas, eplas, flow, toler, hard
      real*8 emod, enu, ebulk3, eg, eg2, eg3, elam
      real*8 eqplasrt0,eqplasrt,eqplas,smises
      real*8 effg, effg2, effg3, efflam, effhrd
      real*8 zero, one, two, three, six, half
      real*8 syiel0, syield, deqpl,shydro
      real*8 damag0,damag,dprop,soft(2),damage_eqplas,scal(2),c
      dimension eelas(6), eplas(6), flow(6), hard(3), dprop(2)
      parameter (zero=0.d0, one=1.0d0,two=2.0d0, three=3.0d0,
     &     six=6.0d0,half=0.5d0)

c
c     local arrays
c-----------------------------------------------------------------------
c     eelas -- elastic strains
c     eplas -- plastic strains
c     flow  -- direction of plastic flow
c-----------------------------------------------------------------------
c
c-----------------------------------------------------------------------
c     umat for johnson-cook model
c-----------------------------------------------------------------------
c     props(1) - uhardening type
c     props(2) - yang's modules
c     props(3) - poisson ratio
c     props(4) - a
c     props(5) - alpha
c     props(6) - beta
c     props(7) - m
c     props(8) - n
c-----------------------------------------------------------------------
c     depvars
c-----------------------------------------------------------------------
c     statev(1)   - equal platic strain
c     statev(2-7) - plastic strain arrays
c     statev(8)   - strain rate
c     statev(9)   - yield stress
c     statev(10)  - plastic dissipation
c     statev(11)  - drx fraction
c     statev(12)  - drx grain size
c     statev(13)  - average grain size
c     statev(14)  - average temperature for drx
c     statev(15)  - average strain rate for drx
c     statev(16)  - damage
c     statev(17)  - damage initiate strain
c     statev(18)  -
c     statev(19)  - mean stress before averaging
c     statev(20)  - mean stress after averaging
c     statev(21)  - current temperature

      ! record temperature
      statev(21) = temp

      nprops=9
      ddsdde = 0.d0

      do k1=1,10
         props(k1)=rdploc(k1,1)
      enddo

      criteria=rdploc(1,2)
      emod = props(2)
      enu  = props(3)
      ebulk3=emod/(one-two*enu)
      eg2=emod/(one+enu)
      eg=eg2/two
      eg3=three*eg
      elam = ( ebulk3 - eg2 ) / three

      do k1=1, ndi
         do k2=1, ndi
            ddsdde(k2, k1)=elam
         end do
         ddsdde(k1, k1)=eg2+elam
      end do
      do k1=ndi+1, ntens
         ddsdde(k1, k1)=eg
      end do

c     recover elastic and plastic strains and rotate forward
c     also recover equivalent plastic strain
c     set eqplasrt to be zero ( no plastic strain at first )
      call rot_sig(statev(2), drot, eplas, 2, ndi, nshr)
      eelas=stran+dstran-eplas
      eqplas=statev(1)
      eqplasrt0 = statev(8)
      syiel0 = statev(9)
      if (criteria.ne.0) then
         damage_eqplas= statev(17)
      else
         damage_eqplas=0.d0
      endif
      eqplasrt = zero
      deqpl = zero

c
c    calculate predictor stress and elastic strain
c
      do k1=1, ntens
!         stress(k1)=0.d0
         do k2=1, ntens
!            stress(k1)=stress(k1)+ddsdde(k1, k2)*eelas(k2)
            stress(k1)=stress(k1)+ddsdde(k1, k2)*dstran(k2)
         end do
      end do

c
c    calculate equivalent von mises stress
c
      smises=(stress(1)-stress(2))**2+(stress(2)-stress(3))**2
     &                               +(stress(3)-stress(1))**2
      do k1=ndi+1,ntens
        smises=smises+six*stress(k1)**2
      end do
      smises=dsqrt(smises/two)

      call uhard(syield,hard,eqplas+deqpl,eqplasrt,temp,nprops,
     &   props)

c yield stress decreased to soft(1) in satrain soft(2)
      soft(1)=0.1d0
      soft(2)=0.03d0

      call soften(scal,soft,eqplas,damage_eqplas)

      syield=syield*scal(1)

      if (eqplasrt0.eq.zero) then
         syiel0 = syield
      endif
c
c     determine if actively yielding
c     
      if(smises.gt.syield*(1.d0+1.d-6)) then
c     
c     actively yielding
c     separate the hydrostatic from the deviatoric stress
c     calculate the flow direction
c
         shydro=(stress(1)+stress(2)+stress(3))/three
         do k1=1,ndi
            flow(k1)=(stress(k1)-shydro)/smises
         end do
         do k1=ndi+1, ntens
            flow(k1)=stress(k1)/smises
         end do

c     calculate syield and hard(1) and hard(2)
         call newtonraphson(props,nprops,temp,dtime,smises,eqplas,
     &      deqpl,syield,hard,pnewdt,soft,damage_eqplas)
         if (pnewdt.gt.0.d0) then
            return
         endif

c        write ( 7, * ) "syield = ", syield, " hard=", hard


c
c     update stress, elastic and plastic strains and
c     equivalent plastic strain
c
         do k1=1,ndi
            stress(k1)=flow(k1)*syield+shydro
            eplas(k1)=eplas(k1)+three/two*flow(k1)*deqpl
            eelas(k1)=eelas(k1)-three/two*flow(k1)*deqpl
         end do
         do k1=ndi+1,ntens
            stress(k1)=flow(k1)*syield
            eplas(k1)=eplas(k1)+three*flow(k1)*deqpl
            eelas(k1)=eelas(k1)-three*flow(k1)*deqpl
         end do
         eqplas=eqplas+deqpl
         eqplasrt=deqpl/dtime
c
c     formulate the jacobian (material tangent)
c     first calculate effective moduli
c
!         smises=(stress(1)-stress(2))**2+(stress(2)-stress(3))**2
!     &                                  +(stress(3)-stress(1))**2
!         do k1=ndi+1,ntens
!           smises=smises+six*stress(k1)**2
!         end do
!         smises=sqrt(smises/two)

         effg=eg*syield/smises
         effg2=two*effg
         effg3=three/two*effg2
         efflam=(ebulk3-effg2)/three
         effhrd=eg3 * ( hard(1)+hard(2)/dtime ) /
     &        ( eg3+hard(1)+hard(2)/dtime )-effg3
         do k1=1, ndi
            do k2=1, ndi
               ddsdde(k2, k1)=efflam
            end do
            ddsdde(k1, k1)=effg2+efflam
         end do
         do k1=ndi+1, ntens
            ddsdde(k1, k1)=effg
         end do
         do k1=1, ntens
            do k2=1, ntens
               ddsdde(k2, k1)=ddsdde(k2, k1)+effhrd*flow(k2)*flow(k1)
            end do
         end do
c
c Dynamic recrystallization
c
         if (gsloc(1,1).ne.0.d0) then
           call drx(eqplas,eqplasrt,deqpl,
     &        temp+273.d0,dtime,statev,nstatv,kinc,gsloc)
         endif
c
c damage
c
         if (criteria.ne.0) then
            damag0=statev(16)
            damag=damag0
            c=rdploc(2,2)
            dprop(1)=rdploc(3,2)
            dprop(2)=rdploc(4,2)
            call damage(stress,eqplas,deqpl,criteria,damag,dprop)
            statev(16)=damag
            if ((damag-c)*(damag0-c).lt.zero) then
              if (damag.gt.c) then
                statev(17)=eqplas
              else
                statev(17)=-eqplas
              endif
            endif
         endif

      endif ! end of active yielding

c
c SRX/MRX recrystallization (K90 model, default off)
c Called every time step: deformation mode when deqpl>0,
c holding mode when deqpl=0
c
      if (gsloc(1,2).ne.0.d0) then
        call srx_mrx_k90(eqplas,eqplasrt,deqpl,
     &     temp+273.15d0,dtime,time(2),statev,nstatv,kinc,gsloc)
      endif
c
c     store elastic and (equivalent) plastic strains
c     in state variable array
c
      statev(1)=eqplas
      do k1=1, ntens
         statev(k1+1)=eplas(k1)
      end do

      statev(8) = eqplasrt
      statev(9) = syield
      statev(10) = deqpl*(syiel0+syield)/2.d0


      return

c      include "formatfile.f"

      end

ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

      subroutine rot_sig ( s, r, sprime, lstr, ndi, nshr )
      implicit none
      integer lstr, ndi, nshr
      real*8, dimension ( ndi + nshr ) :: s, sprime
      real*8, dimension ( ndi, ndi ) :: r

      real*8, dimension ( ndi, ndi ) :: tensor, tensor_prime
      integer k1

      if ( lstr == 1 ) then ! stress
         do k1=1, ndi
            tensor(k1, k1)=s(k1)
         end do
         if ( nshr == 1 ) then
            tensor(1,2) = s(ndi+1)
            tensor(2,1) = s(ndi+1)
         else if ( nshr == 3 ) then
            tensor(1,2) = s(ndi+1)
            tensor(2,1) = s(ndi+1)
            tensor(1,3) = s(ndi+2)
            tensor(3,1) = s(ndi+2)
            tensor(2,3) = s(ndi+3)
            tensor(3,2) = s(ndi+3)
         end if


      else if ( lstr == 2 ) then ! strain
         do k1=1, ndi
            tensor(k1, k1)=s(k1)
         end do
         if ( nshr == 1 ) then
            tensor(1,2) = s(ndi+1)/2.d0
            tensor(2,1) = s(ndi+1)/2.d0
         else if ( nshr == 3 ) then
            tensor(1,2) = s(ndi+1)/2.d0
            tensor(2,1) = s(ndi+1)/2.d0
            tensor(1,3) = s(ndi+2)/2.d0
            tensor(3,1) = s(ndi+2)/2.d0
            tensor(2,3) = s(ndi+3)/2.d0
            tensor(3,2) = s(ndi+3)/2.d0
         end if

      end if


      tensor_prime = matmul ( matmul ( r, tensor ), transpose(r) )


      if ( lstr == 1 ) then ! stress
         do k1=1, ndi
            sprime(k1) = tensor_prime(k1, k1)
         end do
         if ( nshr == 1 ) then
            sprime(ndi+1) = tensor_prime(1,2)
         else if ( nshr == 3 ) then
            sprime(ndi+1) = tensor_prime(1,2)
            sprime(ndi+2) = tensor_prime(1,3)
            sprime(ndi+3) = tensor_prime(2,3)
         end if


      else if ( lstr == 2 ) then ! strain
         do k1=1, ndi
            sprime(k1) = tensor_prime(k1, k1)
         end do
         if ( nshr == 1 ) then
            sprime(ndi+1) = tensor_prime(1,2) * 2.d0
         else if ( nshr == 3 ) then
            sprime(ndi+1) = tensor_prime(1,2) * 2.d0
            sprime(ndi+2) = tensor_prime(1,3) * 2.d0
            sprime(ndi+3) = tensor_prime(2,3) * 2.d0
         end if

      end if


      return
      end

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

      subroutine newtonraphson(props,nprops,temp,dtime,smises,eqplas,
     &      deqpl,syield,hard,pnewdt,soft,damage_eqplas)
      implicit none
      integer i,j,k,nprops
      real*8 props(nprops),temp,dtime,smises,eqplas,deqpl,syield,
     &   hard(3),pnewdt,emod,enu,m,xx,f,df,soft(2),damage_eqplas

      emod   = props(2)
      enu    = props(3)
      i=0
      deqpl=0.d0
      call func(f,df,temp,dtime,smises,eqplas,deqpl,props,nprops,
     &   syield,hard,soft,damage_eqplas)
      do while (dabs(f).gt.1.d-6*syield)
         m=1.d0
         xx=deqpl-m*f/df
         do while (xx.gt.smises/(3.d0*emod/(1.d0+enu)/2.d0))
            m=m/2.d0
            xx=deqpl-m*f/df
            if (m.lt.0.5d0**10) then
               pnewdt=0.5d0
               return
            endif
         enddo
         deqpl=xx
         i=i+1
         call func(f,df,temp,dtime,smises,eqplas,deqpl,props,nprops,
     &      syield,hard,soft,damage_eqplas)
         if (i.gt.30) then
            pnewdt=0.5d0
            return
         endif
      enddo

      return

      end

      subroutine func(f,df,temp,dtime,smises,eqplas,deqpl,props,nprops,
     &      syield,hard,soft,damage_eqplas)
      implicit none
      integer i,nprops
      real*8 f,df,temp,dtime,smises,eqplas,deqpl,props(nprops),
     &   syield,hard(3),scal(2),damage_eqplas,soft(2)
      real*8 emod,enu,eqplasrt

      emod   = props(2)
      enu    = props(3)
      eqplasrt = deqpl/dtime

      call uhard(syield,hard,eqplas+deqpl,eqplasrt,temp,nprops,
     &   props)

      call soften(scal,soft,eqplas,damage_eqplas)

!      f= smises-3.d0*emod/(1.d0+enu)/2.d0*deqpl-syield*scal
!      df=-3.d0*emod/(1.d0+enu)/2.d0-((hard(1)+hard(2)/dtime)*scal+
!     1   syield*scal2)
      hard(1)=hard(1)*scal(1)+syield*scal(2)
      hard(2)=hard(2)*scal(1)
      syield=syield*scal(1)

      f= smises-3.d0*emod/(1.d0+enu)/2.d0*deqpl-syield
      df=-3.d0*emod/(1.d0+enu)/2.d0-hard(1)-hard(2)/dtime

      return
      end
