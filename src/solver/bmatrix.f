      
      subroutine bmatrix(xl,voldl,mi,nope,kk,b,shpc,xsjc)
      implicit none

      integer nope,i,j,k,kk,mi(*),iflag
      real*8 shpc(4,26),ba(6,3),b(6,24),xj(3,26),voldl(0:mi(2),26),
     &       xl(3,26),xi,et,ze,weight,xsjc
      
      include "gauss.f"
      
      iflag=3
    
      do i=1,nope
         do j=1,3
            xj(j,i)=xl(j,i)+voldl(j,i)
         enddo
      enddo
               
      xi=gauss3d2(1,kk)
      et=gauss3d2(2,kk)
      ze=gauss3d2(3,kk)
      weight=weight3d2(kk)
      call shape8h(xi,et,ze,xj,xsjc,shpc,iflag)

      do k=1,nope

         ba=0.d0

         ba(1,1)=shpc(1,k)
         ba(2,2)=shpc(2,k)
         ba(3,3)=shpc(3,k)
         ba(4,1)=shpc(2,k)
         ba(4,2)=shpc(1,k)
         ba(5,1)=shpc(3,k)
         ba(5,3)=shpc(1,k)
         ba(6,2)=shpc(3,k)
         ba(6,3)=shpc(2,k)
      
         do i=1,6
            do j=1,3
               b(i,(k-1)*3+j)=ba(i,j)
            enddo
         enddo
      enddo

      return
      end subroutine
