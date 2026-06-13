!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine calcrhoelcomp(nef,vel,shcon,ielmatf,ntmat_,
     &  mi,nefa,nefb)
!
!     calculation of rho in the element centers (compressible
!     fluids)
!
      implicit none
!
      integer nef,i,imat,ntmat_,mi(*),ielmatf(mi(3),*),nefa,nefb
!
      real*8 t1l,vel(nef,0:7),shcon(0:3,ntmat_,*)
!
!
!     
      do i=nefa,nefb
         t1l=vel(i,0)
         imat=ielmatf(1,i)
         vel(i,5)=vel(i,4)/(shcon(3,1,imat)*t1l)
c         write(*,*) 'calcrhoelcomp ',i,t1l,vel(i,4),vel(i,5),
c     &         shcon(3,1,imat)
      enddo
!            
      return
      end
