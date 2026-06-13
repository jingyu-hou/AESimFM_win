!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine metalpowders(inpc,textpart,rhcon,nrhcon,elcon,nelcon,
     &  nmat,ntmat_,ncmat_,irstrt,istep,istat,n,iperturb,iline,ipol,
     &  inl,ipoinp,inp,ipoinpc,ier,nstate_) 
!
!     reading the input deck: *METAL POWDER
!
      implicit none
!
      character*1 inpc(*)
      character*132 textpart(26)
!
      integer nelcon(2,*),nmat,ntmat,ntmat_,istep,istat,ier,
     &  n,key,i,iperturb(2),ncmat_,irstrt(*),iline,ipol,inl,
     &  ipoinp(2,*),inp(3,*),ipoinpc(0:*),id,k,nrhcon(*),nstate_
!
      real*8 elcon(0:ncmat_,ntmat_,*),t1l,temperature,
     &   rhcon(0:1,ntmat_,*)
!
      ntmat=0
      iperturb(1)=3
      iperturb(2)=1
      write(*,*) '*INFO reading *METAL POWDER: nonlinear'
      write(*,*) '      geometric effects are turned on'
      write(*,*)
!
      if((istep.gt.0).and.(irstrt(1).ge.0)) then
         write(*,*) '*ERROR reading *METAL POWDER:'
         write(*,*) '       *METAL POWDER'
         write(*,*) '  should be placed before all step definitions'
         ier=1
         return
      endif
!
      if(nmat.eq.0) then
         write(*,*) '*ERROR reading *METAL POWDER:'
         write(*,*) '       *METAL POWDER'
         write(*,*) '  should bepreceded by a *MATERIAL card'
         ier=1
         return
      endif
!
      do i=2,n
         write(*,*) 
     &        '*WARNING reading *METAL POWDER:'
         write(*,*) '         parameter not recognized:'
         write(*,*) '         ',
     &        textpart(i)(1:index(textpart(i),' ')-1)
         call inputwarning(inpc,ipoinpc,iline,
     &"METAL POWDER%")
      enddo
!
      nelcon(1,nmat)=ncmat_
!

      do
         call getnewline(inpc,textpart,istat,n,key,iline,ipol,inl,
     &        ipoinp,inp,ipoinpc)
         if((istat.lt.0).or.(key.eq.1)) exit
         ntmat=ntmat+1
         if(ntmat.gt.ntmat_) then
            write(*,*) '*ERROR reading *METAL POWDER:
     &                 increase ntmat_'
            ier=1
            return
         endif
         do i=1,5
            read(textpart(i)(1:20),'(f20.0)',iostat=istat) 
     &            elcon(i+7,ntmat,nmat)
            if(istat.gt.0) then
               call inputerror(inpc,ipoinpc,iline,
     &              "*METAL POWDER%",ier)
               return
            endif
         enddo
!         if((elcon(8,ntmat,nmat).le.0.d0) .or. 
!     &       (elcon(8,ntmat,nmat).ge.90.d0)) then
!            write(*,*) '*ERROR reading *METAL POWDER: parameter beta'
!            write(*,*) '       is out of range'
!            ier=1
!            return
!         endif
!         if(elcon(9,ntmat,nmat).le.0.d0) then
!            write(*,*) '*ERROR reading *METAL POWDER: parameter R'
!            write(*,*) '       is out of range'
!            ier=1
!            return
!         endif
!         if((elcon(10,ntmat,nmat).le.0.d0) .or. 
!     &       (elcon(10,ntmat,nmat).ge.1.d0)) then
!            write(*,*) '*ERROR reading *METAL POWDER: initial density'
!            write(*,*) '       is out of range'
!            ier=1
!            return
!         endif
!         if((elcon(11,ntmat,nmat).le.0.d0) .or. 
!     &       (elcon(11,ntmat,nmat).ge.1.d0)) then
!            write(*,*) '*ERROR reading *METAL POWDER: parameter d0'
!            write(*,*) '       is out of range'
!            ier=1
!            return
!         endif
!         if((elcon(12,ntmat,nmat).le.0.d0) .or. 
!     &       (elcon(12,ntmat,nmat).ge.1.d0)) then
!            write(*,*) '*ERROR reading *METAL POWDER: parameter d_th'
!            write(*,*) '       is out of range'
!            ier=1
!            return
!         endif
         if(textpart(6)(1:1).ne.' ') then
            read(textpart(6)(1:20),'(f20.0)',iostat=istat)
     &            temperature
            if(istat.gt.0) then
               call inputerror(inpc,ipoinpc,iline,
     &              "*METAL POWDER%",ier)
               return
            endif
         else
            temperature=0.d0
         endif
         elcon(13,ntmat,nmat)=temperature
      enddo
!
      if(ntmat.eq.0) then
         write(*,*) '*ERROR reading *METAL POWDER: ,'
         write(*,*) '       yet no constants given'
         ier=1
         return
      endif
!
!     interpolating the powder data at the elastic temperature
!     data points
!
      write(*,*) '*INFO: interpolating the powder data at the'
      write(*,*) '       elastic temperature data points;'
      write(*,*) '       please note that it is preferable'
      write(*,*) '       to use exactly the same temperature'
      write(*,*) '       data points for the elastic and powder'
      write(*,*) '       data (if not already done so)'
      write(*,*)
      write(*,*) 'interpolated metal powder data'
      write(*,*) 'temperature    beta R dens0 d0 d_th'
!
      nelcon(1,nmat)=-70
      nstate_=max(nstate_,20)

      do i=1,nelcon(2,nmat)
         t1l=elcon(0,i,nmat)
         call ident2(elcon(13,1,nmat),t1l,ntmat,ncmat_+1,id)
         if(ntmat.eq.0) then
            continue
         elseif((ntmat.eq.1).or.(id.eq.0)) then
            elcon(3,i,nmat)=elcon(8,1,nmat)
            elcon(4,i,nmat)=elcon(9,1,nmat)
            elcon(5,i,nmat)=elcon(10,1,nmat)
            elcon(6,i,nmat)=elcon(11,1,nmat)
            elcon(7,i,nmat)=elcon(12,1,nmat)
         elseif(id.eq.ntmat) then
            elcon(3,i,nmat)=elcon(8,id,nmat)
            elcon(4,i,nmat)=elcon(9,id,nmat)
            elcon(5,i,nmat)=elcon(10,id,nmat)
            elcon(6,i,nmat)=elcon(11,id,nmat)
            elcon(7,i,nmat)=elcon(12,id,nmat)
         else
            do k=3,7
               elcon(k,i,nmat)=elcon(k+5,id,nmat)+
     &            (elcon(k+5,id+1,nmat)-elcon(k+5,id,nmat))*
     &            (t1l-elcon(13,id,nmat))/
     &            (elcon(13,id+1,nmat)-elcon(13,id,nmat))
            enddo
         endif
         write(*,*) t1l,(elcon(k,i,nmat),k=3,7)
      enddo
    
! Change the density by muliplying the ininital relative density 
      write(*,*) 'temperature    powder_density'
      do i=1,nrhcon(nmat)
         t1l=rhcon(0,i,nmat)
         call ident2(elcon(13,1,nmat),t1l,ntmat,ncmat_+1,id)
         if(ntmat.eq.0) then
            continue
         elseif((ntmat.eq.1).or.(id.eq.0)) then
            rhcon(1,i,nmat)=elcon(12,1,nmat)*rhcon(1,i,nmat)
         elseif(id.eq.ntmat) then
            rhcon(1,i,nmat)=elcon(12,id,nmat)*rhcon(1,i,nmat)
         else
            rhcon(1,i,nmat)=(elcon(12,id,nmat)+
     &            (elcon(12,id+1,nmat)-elcon(12,id,nmat))*
     &            (t1l-elcon(13,id,nmat))/
     &            (elcon(13,id+1,nmat)-elcon(13,id,nmat)))*
     &            rhcon(1,i,nmat)
         endif
         write(*,*) t1l,rhcon(1,i,nmat)
      enddo
      
      write(*,*)


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      return
      end

