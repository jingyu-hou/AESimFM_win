!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine posttransition(dgdxglob,nobject,nk,nodedesi,ndesi,
     &   objectset)
!
!     Normalizing the sensitivities      
!
      implicit none
!
      character*81 objectset(4,*)
!
      integer nobject,nk,nodedesi(*),i,ndesi,m
!
      real*8 dgdxglob(2,nk,nobject),dd
!
!     Scaling the greatest sensitivity value (absolute) to 1
!
      do m=1,nobject
         if(objectset(1,m)(1:9).eq.'THICKNESS') cycle
         dd=0.d0
         do i=1,ndesi
            dd=max(dd,abs(dgdxglob(2,nodedesi(i),m)))
         enddo
         do i=1,ndesi
            dgdxglob(2,nodedesi(i),m)=dgdxglob(2,nodedesi(i),m)/dd
         enddo
      enddo
!
      return        
      end




