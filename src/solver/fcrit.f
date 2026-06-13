!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine fcrit(time,t,a,b,ze,d,dd,h1,h2,h3,h4,func,funcp)
!
      implicit none
!
      real*8 time,t,a,b,ze,d,dd,h1,h2,h3,h4,fexp,func,funcp
!
      fexp=dexp(-h1*t)
!
!     function
!
      func=((a+b*time)*(-t*h2-h3)-b*(-t*t*h2-2.d0*t*h3-2.d0*h4))*fexp
!
!     derivative of the function
!
      funcp=((a+b*time)*t-b*(h3+t*h2+t*t))*fexp
!
      return
      end
