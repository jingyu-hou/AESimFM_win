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
!     x of integers; array x has two indices. The ordered array
!     is the first index 
!
!     id is such that x(1,id).le.px and x(1,id+1).gt.px
!
      subroutine nidentk(x,px,n,id,k)
      implicit none
!
      integer x,px,n,id,n2,m,k
!
      dimension x(k,n)
!
      intent(in) x,px,n
!
      intent(out) id
!
      id=0
      if(n.eq.0) return
      n2=n+1
      do
         m=(n2+id)/2
         if(px.ge.x(1,m)) then
            id=m
         else
            n2=m
         endif
         if((n2-id).eq.1) return
      enddo
      end
