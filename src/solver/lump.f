!
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine lump(adb,aub,adl,irow,jq,neq)
!
!     lumping the matrix stored in adb,aub and storing the result
!     in adl
!
      implicit none
!
      integer irow(*),jq(*),neq,i,j,k
!
      real*8 adb(*),aub(*),adl(*)
!
!
!
      do i=1,neq
         adl(i)=adb(i)
      enddo
!
      do j=1,neq
         do k=jq(j),jq(j+1)-1
            i=irow(k)
            adl(i)=adl(i)+aub(k)
            adl(j)=adl(j)+aub(k)
         enddo
      enddo
!
!     change of meaning of adb and adl
!     first adb is replaced by adb-adl
!     then, adl is replaced by 1./adl
!
      do i=1,neq
         adb(i)=adb(i)-adl(i)
         adl(i)=1.d0/adl(i)
      enddo
!
      return
      end
