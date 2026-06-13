!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine push(item,maxstk,topstk,stack)
!     
      implicit none
!     
      integer topstk,maxstk,stack(*),item
!     
      topstk=topstk+1
      if(topstk.gt.maxstk) then
         write(6,'("0***error in subroutine push***")')
         write(6,'("***stack overflow***")')
         call exit(201)
      else
         stack(topstk)=item
      endif
      end
