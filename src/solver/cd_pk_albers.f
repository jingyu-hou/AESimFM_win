!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!     
      subroutine cd_pk_albers(rad,d,xl,reynolds,p2,p1,beta,kappa,cd,u,
     &     T1,R)
!      
      implicit none
!
      real*8 rad,d,xl,reynolds,p2,p1,beta,kappa,
     &     cd,R,u,T1
!     
      rad=rad
      d=d
      xl=xl
      reynolds=reynolds
      p2=p2
      p1=p1
      beta=beta
      kappa=kappa
      R=R
      u=u
      T1=T1

      
      cd=1.d0

      write(*,*) '*WARNING while using subroutine cd_pk_albers.f'
      write(*,*) 'cd implicitely taken equal to 1'
!
      return
      end
      
