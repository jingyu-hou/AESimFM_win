!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine velsolve(nef,ipnei,bv,auv,adv,vel,temp,neiel)
!
!
      implicit none
!
      integer nef,ipnei(*),i,j,indexf,neiel(*),iel
!
      real*8 bv(nef,3),auv(*),adv(*),vel(nef,0:7),temp(nef,0:7)
!
      do i=1,nef
         do j=1,3
            temp(i,j)=bv(i,j)
         enddo
         do indexf=ipnei(i)+1,ipnei(i+1)
            iel=neiel(indexf)
            do j=1,3
               temp(i,j)=temp(i,j)-auv(indexf)*vel(iel,j)
            enddo
         enddo
         do j=1,3
            temp(i,j)=temp(i,j)/adv(i)
         enddo
      enddo
!            
      return
      end
