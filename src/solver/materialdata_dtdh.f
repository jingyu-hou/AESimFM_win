!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine materialdata_dtdh(htcon,nhtcon,imat,dtdh,
     &  entha,ntmat_,ithermal)
!
      implicit none
!
!     determines the liquid fraction of the material from temperature
!
      integer nhtcon(*),imat,two,ntmat_,id,ithermal
!
      real*8 htcon(0:1,nhtcon(1),*),dtdh,entha
!
      two=2
!
      if(ithermal.eq.0) then
         dtdh=0.d0
      else
         call ident2(htcon(0,1,imat),entha,nhtcon(imat),two,id)
         if(nhtcon(imat).eq.0) then
            continue
         elseif(nhtcon(imat).eq.1) then
            dtdh=0.d0
         elseif(id.eq.0) then
            dtdh=(htcon(1,2,imat)-htcon(1,1,imat))/
     &           (htcon(0,2,imat)-htcon(0,1,imat))
         elseif(id.eq.nhtcon(imat)) then
            dtdh=(htcon(1,id,imat)-htcon(1,id-1,imat))/
     &           (htcon(0,id,imat)-htcon(0,id-1,imat))
         else
            dtdh=(htcon(1,id+1,imat)-htcon(1,id,imat))/
     &           (htcon(0,id+1,imat)-htcon(0,id,imat))
         endif
      endif
!
      return
      end
!     
