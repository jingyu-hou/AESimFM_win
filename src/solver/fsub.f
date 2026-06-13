!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine fsub(time,t,a,b,dd,h1,h2,h3,h4,func,funcp)
!
      implicit none
!
      real*8 time,t,a,b,dd,h1,h2,h3,h4,fexp,fsin,fcos,func,funcp,
     &  h8,h9,h10,h11,h12,h13
!
      fexp=dexp(-h1*t)
      fsin=dsin(dd*t)
      fcos=dcos(dd*t)
      h8=(a+b*time)*fexp/h2
      h9=-b*fexp/h2
      h10=-h8*h1
      h11=h8*dd
      h12=h9*(-h1*t-h3/h2)
      h13=h9*(dd*t+h4)
!
!     function
!
c      fsub=(a+b*time)*fexp*(-h1*fsin-dd*fcos)/h2-b*fexp/h2*((-h1*t-h3/h2)*
c     &     fsin-(dd*t+h4)*fcos)
      func=h10*fsin-h11*fcos+h12*fsin-h13*fcos
!
!     derivative of the function
!
      funcp=-h1*func+dd*(h10*fcos+h11*fsin+h12*fcos+h13*fsin)
!
      return
      end
