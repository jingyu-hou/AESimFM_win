!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      function pop(topstk,stack)
!     
      implicit none
!     
      integer pop,topstk,stack(*)
!     
      if(topstk.gt.0) then
         pop=stack(topstk)
         topstk=topstk-1
      else
         write(6,'("0***error in function pop***")')
         write(6,'("***stack underflow***")')
         call exit(201)
      end if
      end
      
