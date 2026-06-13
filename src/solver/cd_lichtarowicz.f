!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine cd_lichtarowicz(cd,cdu,reynolds,amod,bdh) 
!
      implicit none
!
      real*8 cdu,reynolds,amod,bdh,eps,A1,cd_diff,cd0,cd
!
      cd0=cdu
      cd_diff=1.d0
!
      do
!        
         if(cd_diff.lt.1.d-3) exit
!
         cd=cd0
         A1=20/(reynolds*dsqrt(1.d0-Amod**2))*(1.d0+2.25d0*bdh)
         eps=(0.005d0*bdh)/(1.d0+7.5d0*(log10(0.00015d0*reynolds*
     &        dsqrt(1.d0-Amod**2)/cd))**2)
               
         cd=((-1/cdu+eps)+dsqrt((1/cdu-eps)**2.d0+4.d0*A1))/(2*A1)
!
         cd_diff=dabs(cd-cd0)
!
         cd0=cd
!
       enddo
!     
         return
         end
