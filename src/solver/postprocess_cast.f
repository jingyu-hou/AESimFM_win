!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine postprocess_cast(kode,time,nk,mi,inomat,n_nyscon,
     &  nyscon,coolingrate,gtemp,solstart,solend,ny_coeff,
     &  istep,iinc,icounter)
!
      implicit none
!
      character*3 m1,m3
      character*8 fmat
      character*132 text
!
      integer kode,nk,mi(*),inomat(*),n_nyscon,
     &        istep,iinc,icounter,nout,i
!
      real*8 time,nyscon(0:1,*),gtemp(2,*),coolingrate(2,*),
     &       solstart(*),solend(*),ny_coeff(*),nystar,writevalue
!
      save nout
!
      kode=kode+1
!
      print *,"Simulation finished. Calculate postprocessing variable"
      m1=' -1'
      m3=' -3'
!
      nout=0
      do i=1,nk
         if(inomat(i).le.0) cycle
         nout=nout+1
      enddo
!
      if(time.le.0.d0) then
         fmat(1:8)='(e12.5) '
      elseif((dlog10(time).ge.0.d0).and.(dlog10(time).lt.11.d0)) then
         fmat(1:5)='(f12.'
         write(fmat(6:7),'(i2)') 10-int(dlog10(time)+1.d0)
         fmat(8:8)=')'
      else
         fmat(1:8)='(e12.5) '
      endif
!
!     write niyama data
!
      text='    1PSTEP'
c      write(text(25:36),'(i12)') kode
c      write(13,'(a132)') text
      write(text(25:36),'(3i12)') icounter
      write(text(37:48),'(i12)') iinc
      write(text(49:60),'(i12)') istep
      icounter=icounter+1
      write(13,'(a80)') text
!
      text=
     & '  100CL       .00000E+00                                 3    1'
      text(75:75)='1'
      write(text(25:36),'(i12)') nout
      write(text(8:12),'(i5)') 100+kode
      write(text(13:24),fmat) time
      write(text(59:63),'(i5)') kode
      write(13,'(a132)') text
      text=' -4  NY3DF       1    1'
      write(13,'(a132)') text
      text=' -5  TS          1    1    0    0'
      write(13,'(a132)') text
!
      do i=1,nk
         if(inomat(i).le.0) cycle
         if(coolingrate(1,i).le.1e-10) then
            writevalue=0.d0
         else
            writevalue=gtemp(1,i)/coolingrate(1,i)**0.5d0
         endif
         write(13,100) m1,i,writevalue
      enddo
!
      write(13,'(a3)') m3
!
!     write niyama star data
!
      text='    1PSTEP'
c      write(text(25:36),'(i12)') kode
c      write(13,'(a132)') text
      write(text(25:36),'(3i12)') icounter
      write(text(37:48),'(i12)') iinc
      write(text(49:60),'(i12)') istep
      icounter=icounter+1
      write(13,'(a80)') text
!
      text=
     & '  100CL       .00000E+00                                 3    1'
      text(75:75)='1'
      write(text(25:36),'(i12)') nout
      write(text(8:12),'(i5)') 100+kode
      write(text(13:24),fmat) time
      write(text(59:63),'(i5)') kode
      write(13,'(a132)') text
      text=' -4  NYS3DF      1    1'
      write(13,'(a132)') text
      text=' -5  TS          1    1    0    0'
      write(13,'(a132)') text
!
      do i=1,nk
         if(inomat(i).le.0) cycle
         if(coolingrate(2,i).le.1e-10) then
            writevalue=0.d0
         else
            writevalue=ny_coeff(1)*gtemp(2,i)
     &                /(coolingrate(2,i)**(5.d0/6.d0))
         endif
         write(13,100) m1,i,writevalue
      enddo
!
      write(13,'(a3)') m3
!
!     write porosity shrinkage data
!
      text='    1PSTEP'
c      write(text(25:36),'(i12)') kode
c      write(13,'(a132)') text
      write(text(25:36),'(3i12)') icounter
      write(text(37:48),'(i12)') iinc
      write(text(49:60),'(i12)') istep
      icounter=icounter+1
      write(13,'(a80)') text
!
      text=
     & '  100CL       .00000E+00                                 3    1'
      text(75:75)='1'
      write(text(25:36),'(i12)') nout
      write(text(8:12),'(i5)') 100+kode
      write(text(13:24),fmat) time
      write(text(59:63),'(i5)') kode
      write(13,'(a132)') text
      text=' -4  POROS       1    1'
      write(13,'(a132)') text
      text=' -5  TS          1    1    0    0'
      write(13,'(a132)') text
!
      do i=1,nk
         if(inomat(i).le.0) cycle
         if(coolingrate(2,i).le.1e-10) then
            nystar=0.d0
         else
            nystar=ny_coeff(1)*gtemp(2,i)
     &            /(coolingrate(2,i)**(5.d0/6.d0))
         endif
         nystar=nystar**2.d0
         call nystar2flcr(nyscon,n_nyscon,writevalue,nystar)
         writevalue=ny_coeff(2)*writevalue
         write(13,100) m1,i,writevalue
      enddo
!
      write(13,'(a3)') m3
!
!     write solidification time data 
!
      text='    1PSTEP'
c      write(text(25:36),'(i12)') kode
c      write(13,'(a132)') text
      write(text(25:36),'(3i12)') icounter
      write(text(37:48),'(i12)') iinc
      write(text(49:60),'(i12)') istep
      icounter=icounter+1
      write(13,'(a80)') text
!
      text=
     & '  100CL       .00000E+00                                 3    1'
      text(75:75)='1'
      write(text(25:36),'(i12)') nout
      write(text(8:12),'(i5)') 100+kode
      write(text(13:24),fmat) time
      write(text(59:63),'(i5)') kode
      write(13,'(a132)') text
      text=' -4  SOLT        1    1'
      write(13,'(a132)') text
      text=' -5  TS          1    1    0    0'
      write(13,'(a132)') text
!
      do i=1,nk
         if(inomat(i).le.0) cycle
         write(13,100) m1,i,solend(i)-solstart(i)
      enddo
!
      write(13,'(a3)') m3
!
!
!     write time to solidus data
!
      text='    1PSTEP'
c      write(text(25:36),'(i12)') kode
c      write(13,'(a132)') text
      write(text(25:36),'(3i12)') icounter
      write(text(37:48),'(i12)') iinc
      write(text(49:60),'(i12)') istep
      icounter=icounter+1
      write(13,'(a80)') text
!
      text=
     & '  100CL       .00000E+00                                 3    1'
      text(75:75)='1'
      write(text(25:36),'(i12)') nout
      write(text(8:12),'(i5)') 100+kode
      write(text(13:24),fmat) time
      write(text(59:63),'(i5)') kode
      write(13,'(a132)') text
      text=' -4  T2SOL       1    1'
      write(13,'(a132)') text
      text=' -5  TS          1    1    0    0'
      write(13,'(a132)') text
!
      do i=1,nk
         if(inomat(i).le.0) cycle
         write(13,100) m1,i,solend(i)
      enddo
!
      write(13,'(a3)') m3
!      
 100  format(a3,i10,1p,6e12.5)
!
      return
      end
!