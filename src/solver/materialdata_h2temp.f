!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine materialdata_h2temp(rhcon,nrhcon,shcon,nshcon,
     &  flcon,nflcon,htcon,nhtcon,srhocp,nsrhocp,lh,temp,entha,
     &  imat,ntmat_,ithermal)
!
      implicit none
!
!     determines the temperature of the material from enthalpy
!
      integer nrhcon(*),nshcon(*),nflcon(*),nhtcon(*),nsrhocp(*),
     &        imat,two,ntmat_,id,ithermal
      integer i,j
!
      real*8 rhcon(0:1,ntmat_,*),shcon(0:3,ntmat_,*),
     &       flcon(0:1,ntmat_,*),htcon(0:1,nhtcon(1),*),
     &       srhocp(0:1,2*ntmat_,*),lh(*),
     &       temp,entha,rho,cp,t1,t2,tm,e1,e2,em
!
      two=2
!
c      print *,"input H:",entha,"temp",temp
c      do j=1,nhtcon(imat)
c         print *,j,htcon(0,j,imat),htcon(1,j,imat)
c      enddo
!
      if(ithermal.eq.0) then
         temp=htcon(1,1,imat)
      else
         call ident2(htcon(0,1,imat),entha,nhtcon(imat),two,id)
         if(nhtcon(imat).eq.0) then
            continue
         elseif(nhtcon(imat).eq.1) then
            temp=htcon(1,1,imat)
         elseif(id.eq.0) then
            temp=htcon(1,1,imat)
         elseif(id.eq.nhtcon(imat)) then
            temp=htcon(1,id,imat)
         else
!
!     Linear interpolation using temperature-enthalpy line chart
!     cannot find correct temperature because of integration of
!     cp. A iteration-like method is employed as follow with the
!     idea of gradually narrowing the linear interpolation interval
!
!     if enthalpy value is fortunately found by line chart point,
!     return temperation value directly.
c            if(dabs(
c     &               (entha-htcon(0,id,imat))
c     &               /(htcon(0,id+1,imat)-htcon(0,id,imat))
c     &             ).lt.1.d-8) then
c               temp=htcon(1,id,imat)
c               print *,"on source points",temp
c               return
c            endif
!
            temp=htcon(1,id,imat)+
     &           (htcon(1,id+1,imat)-htcon(1,id,imat))*
     &           (entha-htcon(0,id,imat))/
     &           (htcon(0,id+1,imat)-htcon(0,id,imat))
!
c            t1=htcon(1,id,imat)
c            t2=htcon(1,id+1,imat)
c            tm=0.5d0*(t1+t2)
c            e1=htcon(0,id,imat)
c            e2=htcon(0,id+1,imat)
c            i=0
!
c            do
c              call materialdata_temp2h(nsrhocp,srhocp,nflcon,flcon,
c     &        nrhcon,rhcon,nshcon,shcon,lh,em,
c     &        imat,tm,ntmat_,ithermal)
c              print *,id,t1,e1,t2,e2
c              print *,"correction",i,"tm=",tm,"em",em,"lh",lh(imat)
c              if((dabs((em-entha)/entha).lt.1.d-8)) exit
!
c              i=i+1
c              if(i.gt.50) then
c                 write(*,*) 
c     &             '*ERROR in materialdata_h2temp:'
c                 write(*,*) '       temperature not determined'
c                 write(*,*) '       by enthalpy value',entha,imat
c                 stop
c              endif
!
c              if(em.gt.entha) then
c                 t2=tm
c                 e2=em
c              else
c                 t1=tm
c                 e1=em
c              endif
c              tm=0.5d0*(t1+t2)
c            enddo
c            temp=tm
         endif
      endif
!
c      if(id.eq.0) then
c         entha=htcon(0,id+1,imat)/htcon(1,id+1,imat)
c      else
c         entha=(htcon(0,id+1,imat)-htcon(0,id,imat))/
c     &         (htcon(1,id+1,imat)-htcon(1,id,imat))
c      endif
c      print *,"H=",entha,"id=",id,"temp=",temp
!
      return
      end
!     
