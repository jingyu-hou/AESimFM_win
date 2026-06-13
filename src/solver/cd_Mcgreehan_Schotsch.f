!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
      
      subroutine cd_Mcgreehan_Schotsch(rzdh,bdh,reynolds,cdu)
!     
      implicit none
!     
      real*8 cdu,bdh,reynolds,cd_re,rzdh,cd_r
!     
      cd_re=0.5885d0+372d0/reynolds
!
!     the radius correction 
!
      cd_r=1-(0.008d0+0.992d0*exp(-5.5d0*rzdh-3.5d0*rzdh**2))
     &     *(1-cd_re)
!   
      cdu=1.d0-(1.d0-cd_r)*(1d0+1.3d0*exp(-1.606d0*(bdh*bdh)))
     &     *(0.435d0+0.021d0*bdh)
!     
      return 
!     
      end
      
