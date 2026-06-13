!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      integer function modf(m,ix)
!     
      implicit none
!     
      integer ix,m,ia
!     
      ia=0
      if(ix.le.0)ia=m
      modf=ix+ia-(int((ix+ia-1)/m))*m
      if(modf.lt.1)modf=modf+m
!     
      return
      end  
      
