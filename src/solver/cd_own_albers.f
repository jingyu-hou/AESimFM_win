!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine cd_own_albers(p1,p2,xl,d,cd,u,T1,R,kappa)
!
      implicit none
!
      real*8 d,xl,p1,p2,cd,T1,R,kappa,u
!
      p1=p1
      p2=p2
      xl=xl
      d=d
      u=u
      T1=T1
      R=R
      kappa=Kappa
      cd=1.d0
      write(*,*) '*WARNING while using subroutine cd_own_albers.f'
      write(*,*) 'cd implicitely taken equal to 1'

!     
      return
!
      end
      

      
      
