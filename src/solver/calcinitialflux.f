!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine calcinitialflux(area,vfa,xxna,
     &  ipnei,nef,neifa,lakonf,flux)
!
!     correction of v due to the balance of mass
!     the correction is in normal direction to the face
!
      implicit none
!
      character*8 lakonf(*)
!
      integer i,j,indexf,ipnei(*),ifa,nef,neifa(*),numfaces
!
      real*8 area(*),vfa(0:7,*),xxna(3,*),flux(*)
!
      do i=1,nef
         do indexf=ipnei(i)+1,ipnei(i+1)
            ifa=neifa(indexf)
            flux(indexf)=vfa(5,ifa)*
     &               (vfa(1,ifa)*xxna(1,indexf)+
     &                vfa(2,ifa)*xxna(2,indexf)+
     &                vfa(3,ifa)*xxna(3,indexf))
         enddo
      enddo
!  
      return
      end
