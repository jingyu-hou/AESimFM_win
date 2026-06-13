!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine sensitivity_glob(dgdx,dgdxglob,nobject,ndesi,
     &  nodedesi,nk)
!
!    prepares the sensitivities for the output in the frd-file      
!
      implicit none
!
      integer nobject,ndesi,nodedesi(*),nk,
     &  iobject,node,idesvar
!
      real*8 dgdx(ndesi,nobject),dgdxglob(2,nk,nobject)
!
!     copy the sensitivities in a global node vector
!
      do idesvar=1,ndesi
         node=nodedesi(idesvar)
         do iobject=1,nobject
            dgdxglob(1,node,iobject)=dgdx(idesvar,iobject)
         enddo
      enddo
!
      return        
      end
