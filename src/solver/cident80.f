!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
!
!     identifies the position id of px in an ordered array
!     x of integers; 
!
!     id is such that x(id).le.px and x(id+1).gt.px
!
      subroutine cident80(x,px,n,id)
      implicit none
      character*80 x,px
      integer n,id,n2,m
      dimension x(n)
      id=0
      if(n.eq.0) return
      n2=n+1
      do
         m=(n2+id)/2
         if(px.ge.x(m)) then
            id=m
         else
            n2=m
         endif
         if((n2-id).eq.1) return
      enddo
      end
