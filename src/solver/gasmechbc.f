!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
    
      subroutine gasmechbc(vold,nload,sideload,
     &     nelemload,xload,mi)
!     
      implicit none
!     
      character*20 sideload(*) 
!     
      integer i,nload,node,nelemload(2,*),mi(*)
!     
      real*8 vold(0:mi(2),*),xload(2,*)
!
!     updating the boudary conditions in a mechanical
!     calculation coming from a previous thermal calculation
!     
!     updating the pressure boundary conditions
!     
      do i=1,nload
         if(sideload(i)(3:4).eq.'NP') then
            node=nelemload(2,i)
            xload(1,i)=vold(2,node)
         endif
      enddo
!      
      return
      end








