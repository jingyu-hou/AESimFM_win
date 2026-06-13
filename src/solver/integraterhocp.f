!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!  
      subroutine integraterhocp(nrhcon,rhcon,nshcon,shcon,
     &  nsrhocp,srhocp,nmat,physcon,ntmat_,ithermal)
!
!     generate the (s rho*cp dT)-temperature chart. Merging
!     two ascending array(rhocon(0,..,..), shcon(0,..,..))
!     into a new one(srhocp(0,..,..)) is performed here.
!
      implicit none
!
      integer nrhcon(*),nshcon(*),nsrhocp(*),ithermal(*),
     &        nmat,ntmat_,i,j,k,imat
!
      real*8 rhcon(0:1,ntmat_,*),shcon(0:3,ntmat_,*),physcon(*),
     &       srhocp(0:1,2*ntmat_,*),
     &       temp,rho,cp,temp0,rho0,cp0,integral
!
      do imat=1,nmat
        i=1
        j=1
        k=1
c        print *,"processing imat",nmat,nrhcon(imat),nshcon(imat)
!
        if((nrhcon(imat).eq.1).and.(nshcon(imat).eq.1)) then
            call materialdata_cp(imat,ntmat_,temp,shcon,
     &               nshcon,cp)
            call materialdata_rho(rhcon,nrhcon,imat,rho,
     &               temp,ntmat_,ithermal)
            srhocp(0,k,imat)=0.d0
            srhocp(1,k,imat)=0.d0
            i=i+1
            j=j+1
            k=k+1
        endif
!
        do while((i.le.nrhcon(imat)).and.(j.le.nshcon(imat)))
            if(rhcon(0,i,imat).lt.shcon(0,j,imat)) then
                temp=rhcon(0,i,imat)
                srhocp(0,k,imat)=temp
                rho=rhcon(1,i,imat)
                call materialdata_cp(imat,ntmat_,temp,shcon,
     &               nshcon,cp)
                i=i+1
            elseif(rhcon(0,i,imat).gt.shcon(0,j,imat)) then
                temp=shcon(0,j,imat)
                srhocp(0,k,imat)=temp
                call materialdata_rho(rhcon,nrhcon,imat,rho,
     &               temp,ntmat_,ithermal)
                cp=shcon(1,j,imat)
                j=j+1
            else
                temp=rhcon(0,i,imat)
                srhocp(0,k,imat)=temp
                rho=rhcon(1,i,imat)
                cp=shcon(1,j,imat)
                i=i+1
                j=j+1
            endif
!
            if(k.eq.1) then
                srhocp(1,k,imat)=rho*cp*temp
c                print *,"rho cp temp",k,rho,cp,temp
            else
                call integratelinesproduct(rho0,rho,cp0,cp,
     &               temp0,temp,temp,integral)
                srhocp(1,k,imat)=srhocp(1,k-1,imat)+integral
            endif
!
c            print *,i,j,k,srhocp(0,k,imat),srhocp(1,k,imat),integral
            k=k+1
            rho0=rho
            cp0=cp
            temp0=temp
        end do
!
        do while(i.le.nrhcon(imat))
            temp=rhcon(0,i,imat)
            srhocp(0,k,imat)=temp
            rho=rhcon(1,i,imat)
            call materialdata_cp(imat,ntmat_,temp,shcon,
     &           nshcon,cp)
            call integratelinesproduct(rho0,rho,cp0,cp,
     &           temp0,temp,temp,integral)
            srhocp(1,k,imat)=srhocp(1,k-1,imat)+integral
!
            i=i+1
            k=k+1
            rho0=rho
            cp0=cp
            temp0=temp
        end do
!
        do while(j.le.nshcon(imat))
            temp=shcon(0,j,imat)
            srhocp(0,k,imat)=temp
            call materialdata_rho(rhcon,nrhcon,imat,rho,
     &           temp,ntmat_,ithermal)
            cp=shcon(1,j,imat)
            call integratelinesproduct(rho0,rho,cp0,cp,
     &           temp0,temp,temp,integral)
            srhocp(1,k,imat)=srhocp(1,k-1,imat)+integral
!
            j=j+1
            k=k+1
            rho0=rho
            cp0=cp
            temp0=temp
        end do
!
        nsrhocp(imat)=k-1
      enddo
!
c      do imat=1,nmat
c        do i=1,nsrhocp(imat)
c            print *,"srhocp:",srhocp(0,i,imat),srhocp(1,i,imat)
c        enddo
c      enddo
!
      return
      end
!