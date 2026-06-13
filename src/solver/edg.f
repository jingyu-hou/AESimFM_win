!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      function edg(l,k,e)
!     
      implicit none
!     
      integer l,k,i,e(3,*),edg
!     
      do 10 i=1,3
         if(e(i,l).eq.k) then
            edg=i
            return
         end if
 10   continue
      write(6,'("0***error in function edg***")')
      write(6,'("***elements not adjacent***")')
      call exit(201)
      end
