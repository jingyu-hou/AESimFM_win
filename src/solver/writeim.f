!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine writeim()
!
!     writes a header for each eigenfrequency in the .dat file
!
      implicit none
!
      write(5,*)
      write(5,100)
 100  format
     &  ('                    I M A G I N A R Y   P A R T')
      write(5,*)
!
      return
      end

