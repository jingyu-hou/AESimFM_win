!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
!     
! cd inncompressible fro thin orifices with corner radiusing (eq 5)
!
!     author: Yannick Muller
!
      subroutine pk_cdi_r (rqd,reynolds,beta,cdi_r)
!
      implicit none
!
      real*8 rqd,reynolds,beta,cdi_r,frqd,cdi_se,cdi_noz
!      
      call pk_cdi_noz(reynolds,cdi_noz)
      call pk_cdi_se(reynolds,beta,cdi_se)
      
      frqd=0.008d0+0.992d0*exp(-5.5d0*rqd-3.5d0*rqd**2.d0)
!
      cdi_r=cdi_noz-frqd*(cdi_noz-cdi_se)
!      
      return 
      end
