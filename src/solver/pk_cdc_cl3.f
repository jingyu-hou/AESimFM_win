!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine pk_cdc_cl3(lqd,rqd,reynolds,p2p1,beta,kappa,cdc_cl3)
!     
      implicit none
!
      real*8  lqd,rqd,reynolds,p2p1,beta,kappa,cdc_cl3a,cdc_cl3b,
     &     cdc_cl3d,cdc_cl3
!     
      cdc_cl3a=0.d0
      cdc_cl3b=0.d0
      cdc_cl3d=0.d0
!
      if(lqd.le.0.28d0) then
         call pk_cdc_cl3a(lqd,rqd,reynolds,p2p1,beta,kappa,cdc_cl3a)
         cdc_cl3=cdc_cl3a
      elseif(lqd.le.0.5d0) then
         call pk_cdc_cl3b(lqd,rqd,reynolds,p2p1,beta,kappa,cdc_cl3b)
         cdc_cl3=cdc_cl3b
      else 
         call pk_cdc_cl3d(lqd,rqd,reynolds,p2p1,beta,cdc_cl3d)
         cdc_cl3=cdc_cl3d
!     
      endif
!     
      return
! 
      end
