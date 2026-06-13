!
!     AESim_FM solver
!     creepsoftenings.f: read *CREEP-SOFTENING keyword and parameters
!
!     Copyright (C) 2026 AESim_FM
!
      subroutine creepsoftenings(inpc,textpart,
     &  nmat,ncmat_,iperturb,irstrt,istep,istat,n,
     &  iline,ipol,inl,ipoinp,inp,ipoinpc,ier,nstate_,nelcon)
!
!     reads the input deck: *CREEP-SOFTENING
!     stores 16 parameters into common block /creepdata/
!
      implicit none
!
      integer nmat,ncmat_,istep,istat,n,iline,ipol,inl,ipoinp(2),
     &  inp(3,*),ipoinpc(0:*),ier,nstate_,i,j,imax,key,
     &  iperturb(*),nelcon(2,*),irstrt(*),nconstants
!
      real*8 creepcon_temp(16),creepcon
      integer creep_nmat_active,creep_powder_coupled(100)
      common /creepdata/ creepcon(16,100),
     &  creep_nmat_active,creep_powder_coupled
!
      character*1 inpc(*)
      character*132 textpart(*)
!
      iperturb(1)=3
      iperturb(2)=1
!
      write(*,*) '*INFO reading *CREEP-SOFTENING: nonlinear'
!
      if(istep.gt.0) then
         write(*,*) '*ERROR reading *CREEP-SOFTENING:'
         write(*,*) '       *CREEP-SOFTENING'
         write(*,*) '       should be before the step definitions'
         ier=1
         return
      endif
!
      if(nmat.eq.0) then
         write(*,*) '*ERROR reading *CREEP-SOFTENING:'
         write(*,*) '       *CREEP-SOFTENING'
         write(*,*) '       must be preceded by a *MATERIAL card'
         ier=1
         return
      endif
!
!     warn about unknown parameters in the keyword line
!
      do i=2,n
         if(textpart(i)(1:1).ne.' ') then
            write(*,*)
     &        '*WARNING reading *CREEP-SOFTENING:'
            write(*,*)
     &        '         parameter not recognized:'
            write(*,*) textpart(i)(1:20)
         endif
      enddo
!
!     read 16 parameter constants (8 per line, 2 lines)
!
      nconstants=16
      do j=1,(nconstants+7)/8
         call getnewline(inpc,textpart,istat,n,key,iline,ipol,
     &        inl,ipoinp,inp,ipoinpc)
         if((istat.lt.0).or.(key.eq.1)) then
            if(j.eq.1) then
               write(*,*) '*ERROR reading *CREEP-SOFTENING:'
               write(*,*) '       no parameter data found'
               ier=1
            endif
            return
         endif
         imax=8
         if(8*j.gt.nconstants) then
            imax=nconstants-8*(j-1)
         endif
         do i=1,imax
            read(textpart(i)(1:20),'(f20.0)',iostat=istat)
     &           creepcon_temp(i+(j-1)*8)
            if(istat.gt.0) then
               call inputerror(inpc,ipoinpc,iline,
     &              "*CREEP-SOFTENING%",ier)
               return
            endif
         enddo
      enddo
!
!     store parameters into common block for this material
!
      do i=1,nconstants
         creepcon(i,nmat)=creepcon_temp(i)
      enddo
      creep_nmat_active=nmat
      creep_powder_coupled(nmat)=int(creepcon(13,nmat))
!
!     set material code:
!       -72 = creep/softening independent
!       -73 = creep/softening coupled with metal powder (DENSITY_COUPLING=1)
!
      if(creep_powder_coupled(nmat).eq.1) then
         nelcon(1,nmat)=-73
         nstate_=max(nstate_,24)
      else
         nelcon(1,nmat)=-72
         nstate_=max(nstate_,53)
      endif
!
      write(*,*) '*INFO *CREEP-SOFTENING: stored for material',nmat
      write(*,*) '       ENABLE=',creepcon(1,nmat),
     &           ' MODEL_TYPE=',creepcon(2,nmat),
     &           ' DENSITY_COUPLING=',creep_powder_coupled(nmat)
!
      return
      end
