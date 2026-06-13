!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine uamplitude(time,name,amplitude)
!
!     user subroutine uamplitude: user defined amplitude definition
!
!     INPUT:
!
!     name               amplitude name
!     time               time at which the amplitude is to be
!                        evaluated
!
!     OUTPUT:
!
!     amplitude          value of the amplitude at time
!           
      implicit none
!
      character*80 name
!
      real*8 time,amplitude
!
      if(name(1:9).eq.'QUADRATIC') then
         amplitude=time**2
      else
         write(*,*) '*ERROR in uamplitude: unknown amplitude'
         call exit(201)
      endif
!
      return
      end

