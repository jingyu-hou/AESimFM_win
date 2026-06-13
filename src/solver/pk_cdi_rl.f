!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
     
!cd incompressible for long orifices (eq.6)
!
!     author: Yannick Muller
!
       subroutine pk_cdi_rl(lqd,rqd,reynolds,beta,cdi_rl)
!
       implicit none
!
      real*8 lqd,rqd,reynolds,beta,cdi_rl,rqd_cor,lrqd,cdi_r,glrqd
!
      rqd_cor=rqd
!
      if (rqd_cor.gt.lqd) then
         rqd_cor=lqd
      endif
!
      lrqd=lqd-rqd_cor
!      
      call pk_cdi_r(rqd_cor,reynolds,beta,cdi_r)
!      
      glrqd=(1d0+1.298d0*exp(-1.593d0*lrqd**2.33d0))
     &     *(0.435d0+0.021d0*lrqd)/(2.298d0*0.435d0)
!
      cdi_rl=1.d0-glrqd*(1.d0-cdi_r)
!
      return
!
      end
