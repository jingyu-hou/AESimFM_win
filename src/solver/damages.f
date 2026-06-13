!
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!
!     Developed and maintained by Shenzhen Wedge Central
!     South Research Institute co., Ltd., Shenzhen, China
!
!     Copy Right 2019-2023.
!
      subroutine damages(inpc,textpart,rdpcon,
     &  nmat,ncmat_,iperturb,irstrt,istep,istat,n,
     &  iline,ipol,inl,ipoinp,inp,ipoinpc,ier,nstate_)
!
!     reading the input deck: *DAMAGE
!
      implicit none
!
      character*1 inpc(*)
      character*132 textpart(26)
!
      integer nmat,istep,istat,n,key,i,ncmat_,nconstants,imax,isum,j,
     &   iperturb(*),ier,irstrt(*),iline,ipol,inl,ipoinp(2,*),inp(3,*),
     &   ipoinpc(0:*),nstate_
!
      real*8 rdpcon(10,3,*)
!
      iperturb(1)=3
      iperturb(2)=1
      nconstants=10
!
      write(*,*) '*INFO reading *DAMAGE: nonlinear'
      write(*,*) '      geometric effects are turned on'
      write(*,*)
!
      if((istep.gt.0).and.(irstrt(1).ge.0)) then
         write(*,*) '*ERROR reading *DAMAGE:'
         write(*,*) '       *DAMAGE'
         write(*,*) '  should be placed before all step definitions'
         ier=1
         return
      endif
!
      if(nmat.eq.0) then
         write(*,*) '*ERROR reading *DAMAGE:'
         write(*,*) '       *DAMAGE'
         write(*,*) '  should bepreceded by a *MATERIAL card'
         ier=1
         return
      endif
!
      do i=2,n
         write(*,*)
     &        '*WARNING reading *DAMAGE:'
         write(*,*) '         parameter not recognized:'
         write(*,*) '         ',
     &        textpart(i)(1:index(textpart(i),' ')-1)
         call inputwarning(inpc,ipoinpc,iline,
     &"DAMAGE%")
      enddo
!
      nstate_=max(nstate_,25)
!
      do j=1,(nconstants)/8+1
         call getnewline(inpc,textpart,istat,n,key,iline,ipol,
     &        inl,ipoinp,inp,ipoinpc)
         if((istat.lt.0).or.(key.eq.1)) exit
         imax=8
         if(8*j.gt.nconstants) then
            imax=nconstants-8*(j-1)
         endif
         do i=1,imax
            read(textpart(i)(1:20),'(f20.0)',iostat=istat)
     &           rdpcon(i+(j-1)*8,2,nmat)
            if(istat.gt.0) then
               call inputerror(inpc,ipoinpc,iline,
     &              "*DAMAGE%",ier)
               return
            endif
         enddo
!
      enddo
!
      return
      end
