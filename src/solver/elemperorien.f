!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine elemperorien(ipoorel,iorel,ielorien,ne,mi)
!
      implicit none
!
      integer ipoorel(*),iorel(2,*),i,ne,mi(*),ielorien(mi(3),*),
     &  iorelfree,iorien
!
      intent(in) ielorien,ne,mi
!
      intent(inout) ipoorel,iorel
!
!     determining the elements belonging to the nodes of
!     the elements
!
      iorelfree=1
      do i=1,ne
         iorien=ielorien(1,i)
         if(iorien.eq.0) cycle
         iorel(1,iorelfree)=i
         iorel(2,iorelfree)=ipoorel(iorien)
         ipoorel(iorien)=iorelfree
         iorelfree=iorelfree+1
      enddo
!
      return
      end
