
      subroutine readphaseinf(inpc,textpart,pphase,cphase,
     &phaseother,nphase,nmat,irstrt,istep,istat,n,iline,ipol,
     &inl,ipoinp,inp,ipoinpc,ier,phase_inf,xstate,mi,ne,lakon,
     &ipkon,nstate_)
      implicit none
!
      character*1 inpc(*)
      character*8 lakon(*)
      character*132 textpart(26)

      integer phase_inf(4),phaseinf(3),i,j,indexe,
     &mint3d,ne,nstate_ 
      integer nphase(11,*),istep,istat,n,mi(*),ipkon(*),
     &ipoinpc(0:*),ier,ityp,key,irstrt(*),iline,ipol,
     &inl,ipoinp(2,*),inp(3,*),nmat,ntmat,ntmat_,ii,jj,kk
!
      real*8 pphase(2,phase_inf(3),7+phase_inf(4),phase_inf(1),*),
     & cphase(13+phase_inf(4),phase_inf(1),*),
     & phaseother(15+phase_inf(1)*phase_inf(4),*),
     & xstate(nstate_,mi(1),*)

      ntmat_=phase_inf(3)
      ntmat=0
      if((istep.gt.0).and.(irstrt(1).ge.0)) then
         write(*,*) 
     &     '  *ERROR reading Phase material parameters should be  '
         write(*,*) '  placed before all step definitions'
         ier=1
         return
      endif
!
      if(nmat.eq.0) then
         write(*,*)
     &      ' *ERROR reading Phase material parameters should be  '
         write(*,*) '  preceded by a *MATERIAL card'
         ier=1
         return
      endif
!
      if(textpart(1)(1:12).eq.'*PHASECURVE') then
          ityp=1
          if(nstate_.ge.13)then
            nstate_=max(nstate_,14+phase_inf(1))
          else
            nstate_=max(nstate_,phase_inf(1))
          endif
      elseif(textpart(1)(1:10).eq.'*PHASEPROP') then
          ityp=2
      elseif(textpart(1)(1:17).eq.'*PHASEEQUILIBRIUM') then
          ityp=3
          kk=4
      elseif(textpart(1)(1:17).eq.'*INCUBATIONPERIOD') then
          ityp=4
          kk=5
          if(nstate_.ge.13)then
            nstate_=max(nstate_,14+2*phase_inf(1)+2)
          else
            nstate_=max(nstate_,2*phase_inf(1))
          endif
      elseif(textpart(1)(1:16).eq.'*PHASELATENTHEAT') then
          ityp=5
      elseif(textpart(1)(1:11).eq.'*PHASECTROL') then
          ityp=6
      elseif(textpart(1)(1:9).eq.'*PHASEZBF') then
          ityp=7
      elseif(textpart(1)(1:8).eq.'*PHASEGS') then
          ityp=8
      elseif(textpart(1)(1:8).eq.'*PHASEYS') then
          ityp=9
          if(nstate_.ge.13)then
            nstate_=max(nstate_,14+phase_inf(1)+2)
          else
            nstate_=max(nstate_,phase_inf(1)+2)
          endif
       elseif(textpart(1)(1:14).eq.'*PHASEHARDNESS') then
          ityp=10
          if(nstate_.ge.13)then
            nstate_=max(nstate_,14+phase_inf(1)+3)
          else
            nstate_=max(nstate_,phase_inf(1)+3)
          endif
      endif

      if(ityp.eq.1)then
          if(textpart(2)(1:8).eq.'TYPE=TTT')then
              nphase(3,nmat)=1
          else
              nphase(3,nmat)=2
          endif
         do
           call getnewline(inpc,textpart,istat,n,key,iline,ipol,inl,
     &          ipoinp,inp,ipoinpc)
           if((istat.lt.0).or.(key.eq.1)) return
                       
           if(ntmat.gt.ntmat_) then
              write(*,*) 
     &       '*ERROR reading *PHASECURAVE: increase ntmat_'
              ier=1
             return
           endif
          if(n.lt.3)then
             write(*,*)'   Insufficient input parameters of the   '
             write(*,*)'first line of phase transition information'
             return
          endif
          do ii=1,3
            read(textpart(ii)(1:10),'(i10)',iostat=istat)phaseinf(ii)
            if(phaseinf(ii).lt.0)then
              write(*,*)'ERROR:phase change information(TTT/CCT) input'
              return
            endif
          enddo

           read(textpart(3)(1:20),*,iostat=istat)
     &       cphase(5+phaseinf(2),phaseinf(1),nmat)

           read(textpart(4)(1:20),*,iostat=istat)
     &       cphase(2+phaseinf(2),phaseinf(1),nmat)
           if(istat.gt.0) return

           read(textpart(5)(1:20),*,iostat=istat)
     &       cphase(1,phaseinf(1),nmat)
           if(istat.gt.0) return

           IF(phaseinf(3).ge.1)then     
             do ii=1,phaseinf(3)
               call getnewline(inpc,textpart,istat,n,key,iline,ipol,
     &                           inl,ipoinp,inp,ipoinpc)
               if((istat.lt.0).or.(key.eq.1)) return
                do jj=1,2
                  read(textpart(jj)(1:20),*,iostat=istat)
     &              pphase(jj,ii,phaseinf(2),phaseinf(1),nmat)
                enddo
             enddo
           endif  
          enddo
      
      elseif(ityp.eq.2.or.ityp.eq.3.or.ityp.eq.4)then
        if(ityp.eq.2)then
          if(textpart(2)(1:9).eq.'TYPE=COND')then
              nphase(2,nmat)=1
              kk=7
          else
              nphase(1,nmat)=1
              kk=6
          endif
        endif

        do
        call getnewline(inpc,textpart,istat,n,key,iline,ipol,inl,
     &         ipoinp,inp,ipoinpc)
        if((istat.lt.0).or.(key.eq.1)) exit
        read(textpart(1)(1:10),'(i10)',iostat=istat)phaseinf(1)
        read(textpart(2)(1:10),'(i10)',iostat=istat)phaseinf(3)
        if(ityp.eq.2)then
            if (kk.eq.7)then
              read(textpart(2)(1:20),*,iostat=istat)
     &         cphase(12,phaseinf(1),nmat)
            elseif(kk.eq.6)then
              read(textpart(2)(1:20),*,iostat=istat)
     &        cphase(11,phaseinf(1),nmat)
            endif
        elseif(ityp.eq.3)then
          read(textpart(2)(1:20),*,iostat=istat)
     &     cphase(9,phaseinf(1),nmat)
        elseif(ityp.eq.4)then
          read(textpart(2)(1:20),*,iostat=istat)
     &     cphase(10,phaseinf(1),nmat)
        endif
           do ii=1,phaseinf(3)
             call getnewline(inpc,textpart,istat,n,key,iline,ipol,
     &                   inl,ipoinp,inp,ipoinpc)
              do jj=1,2
                read(textpart(jj)(1:20),*,iostat=istat)
     &              pphase(jj,ii,kk,phaseinf(1),nmat)
              enddo
           enddo
        enddo
        if(ityp.eq.3)nphase(10,nmat)=1
      elseif(ityp.eq.5.or.ityp.eq.10)then
        if(ityp.eq.5)then
           ii=2
           nphase(5,nmat)=1
        elseif(ityp.eq.10)then
           ii=13
           nphase(11,nmat)=1
        endif

        do
          call getnewline(inpc,textpart,istat,n,key,iline,ipol,inl,
     &           ipoinp,inp,ipoinpc)
          if((istat.lt.0).or.(key.eq.1)) return
          read(textpart(1)(1:10),'(i10)',iostat=istat)phaseinf(1)
          read(textpart(2)(1:20),*,iostat=istat)
     &       cphase(ii,phaseinf(1),nmat)
        enddo
      elseif(ityp.eq.6)then
         call getnewline(inpc,textpart,istat,n,key,iline,ipol,inl,
     &         ipoinp,inp,ipoinpc)
          if((istat.lt.0).or.(key.eq.1)) return
         do ii=1,5
           read(textpart(ii)(1:10),'(i10)',iostat=istat)
     &      nphase(ii+3,nmat)
           if(istat.gt.0) return
         enddo
      elseif(ityp.eq.7)then
        do
           call getnewline(inpc,textpart,istat,n,key,iline,ipol,inl,
     &          ipoinp,inp,ipoinpc)
           if((istat.lt.0).or.(key.eq.1)) return
           do ii=1,3
             read(textpart(ii)(1:10),'(i10)',iostat=istat)phaseinf(ii)
           enddo
           read(textpart(3)(1:20),*,iostat=istat)
     &       cphase(12+phaseinf(2),phaseinf(1),nmat)      

           read(textpart(4)(1:20),*,iostat=istat)
     &      phaseother(12+phaseinf(1)+phaseinf(2),nmat)
           do ii=1,phaseinf(3)
             call getnewline(inpc,textpart,istat,n,key,iline,ipol,inl,
     &          ipoinp,inp,ipoinpc)
             do jj=1,2 
               read(textpart(jj)(1:20),*,iostat=istat)
     &         pphase(jj,ii,7+phaseinf(2),phaseinf(1),nmat)
             enddo
           enddo
        enddo
      elseif(ityp.eq.8)then
         call getnewline(inpc,textpart,istat,n,key,iline,ipol,inl,
     &         ipoinp,inp,ipoinpc)
          if((istat.lt.0).or.(key.eq.1)) return
         do ii=1,3
           read(textpart(ii)(1:20),*,iostat=istat)
     &      phaseother(ii,nmat)
           if(istat.gt.0) return
         enddo
      elseif(ityp.eq.9)then
         call getnewline(inpc,textpart,istat,n,key,iline,ipol,inl,
     &         ipoinp,inp,ipoinpc)
          if((istat.lt.0).or.(key.eq.1)) return
         do ii=1,n
           read(textpart(ii)(1:20),*,iostat=istat)
     &      phaseother(ii+3,nmat)
           if(istat.gt.0) return
         enddo
         nphase(9,nmat)=1
      endif
      return
      end
