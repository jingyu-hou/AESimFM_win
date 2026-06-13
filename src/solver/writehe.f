!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine writehe(j)
!
!     writes a header for each eigenfrequency in the .dat file
!
      implicit none
!
      integer j
!
      write(5,*)
      write(5,100) j+1 
 100  format
     &  ('                    E I G E N V A L U E    N U M B E R ',i5)
      write(5,*)
!
      return
      end

