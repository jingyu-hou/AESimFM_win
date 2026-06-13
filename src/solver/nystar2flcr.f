!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine nystar2flcr(nyscon,n_nyscon,flcr,nystar)
!
      implicit none
!
!     determines the liquid fraction of the material from temperature
!
      integer n_nyscon,two,id
!
      real*8 nyscon(0:1,n_nyscon),flcr,nystar
!
      two=2
!
        call ident2_decr(nyscon(0,1),nystar,n_nyscon,two,id)
        if(n_nyscon.eq.0) then
            continue
        elseif(n_nyscon.eq.1) then
            flcr=nyscon(1,1)
        elseif(id.eq.0) then
            flcr=nyscon(1,1)
        elseif(id.eq.n_nyscon) then
            flcr=nyscon(1,id)
        else
            flcr=nyscon(1,id)+
     &         (nyscon(1,id+1)-nyscon(1,id))*
     &         (nystar-nyscon(0,id))/
     &         (nyscon(0,id+1)-nyscon(0,id))
        endif
!
c      print *,"id=",id,"flcr=",flcr
!
      return
      end
!     
   