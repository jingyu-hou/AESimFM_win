!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine fsuper(time,t,a,b,h1,h2,h3,h4,h5,h6,func,funcp)
!
      implicit none
!
      real*8 time,t,a,b,h1,h2,h3,h4,h5,h6,fexm,fexp,func,funcp
!
      fexm=dexp(h1*t)
      fexp=dexp(-h2*t)
!
!     function
!
      func=(a+b*time)*(fexm*h3+fexp*h4)
     &    -b*(fexm*(t*h3-h5)+fexp*(t*h4+h6))
!
!     derivative of the function
!
      funcp=(a+b*time)*(fexm-fexp)-b*(fexm*(t-h3)-fexp*(t+h4))

!
      return
      end
