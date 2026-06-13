!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!     
      subroutine initialh(nsrhocp,srhocp,nflcon,flcon,nrhcon,rhcon,
     &  nshcon,shcon,lh,enthaold,mi,vold,inomat,nk,ielmat,ne,
     &  kon,ipkon,lakon,ntmat_,ithermal,nboun,ndirboun,nodeboun,xboun)
!
      implicit none
!
!     initailize the enthalpy field
!
      character*8 lakon(*)
!
      integer nsrhocp(*),nflcon(*),nrhcon(*),nshcon(*),
     &        mi(*),inomat(*),nk,ielmat(*),ne,ntmat_,
     &        kon(*),ipkon(*),ithermal(*),nboun,ndirboun(*),
     &        nodeboun(*),node,elem,imat,nope,indexe,i
!
      real*8 srhocp(0:1,2*ntmat_,*),flcon(0:1,ntmat_,*),
     &       rhcon(0:1,ntmat_,*),shcon(0:1,ntmat_,*),
     &       enthaold(*),vold(0:mi(2),*),xboun(*),temp,entha,lh(*)
!
!     filling inomat: asigns a material to nodes.
!
      do elem=1,ne
        if(ipkon(elem).lt.0) cycle
      !
        indexe=ipkon(elem)
        read(lakon(elem)(4:4),'(i1)') nope
      !
        do node=1,nope
          inomat(kon(indexe+node))=ielmat(elem)
        enddo
      enddo
!
!     initialize the enthalpy field
!
      do node=1,nk
        if(inomat(node).eq.0) cycle
        imat=inomat(node)
        temp=vold(0,node)
        call materialdata_temp2h(nsrhocp,srhocp,nflcon,flcon,
     &       nrhcon,rhcon,nshcon,shcon,lh,entha,
     &       imat,temp,ntmat_,ithermal)
        enthaold(node)=entha
      enddo
!
!     insert enthalpy boundary conditions
!     
      do i=1,nboun
        if(ndirboun(i).ne.0) cycle
        node=nodeboun(i)
        imat=inomat(node)
        temp=xboun(i)
        call materialdata_temp2h(nsrhocp,srhocp,nflcon,flcon,
     &       nrhcon,rhcon,nshcon,shcon,lh,entha,
     &       imat,temp,ntmat_,ithermal)
        enthaold(node)=entha
c        print *,"initialh BC:",i,node,temp,enthaold(node)
      enddo
!
      return
      end
!