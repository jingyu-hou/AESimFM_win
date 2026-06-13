!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!  
      subroutine addimd(imd,nmd,node)
!
!     adds entity "node" to field imd. imd contains the
!     entities selected by the user in which results are to be
!     calculated in a modal dynamics calculation
!
      implicit none
!
      integer imd(*),nmd,node,id,l
!
      call nident(imd,node,nmd,id)
      do
         if(id.gt.0) then
            if(imd(id).eq.node)exit
         endif
         nmd=nmd+1
         do l=nmd,id+2,-1
            imd(l)=imd(l-1)
         enddo
         imd(id+1)=node
         exit
      enddo
!
      return
      end
