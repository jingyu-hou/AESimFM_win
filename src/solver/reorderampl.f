!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine reorderampl(amname,namta,nam)
!
!     reorders amname in alphabetical order
!
      implicit none
!
      character*80 amname(*),amnamecp
!
      integer namta(3,*),nam,id,namtacp(3),i,j
!
      call cident80(amname,amname(nam),nam-1,id)
!
      amnamecp=amname(nam)
      do i=1,3
         namtacp(i)=namta(i,nam)
      enddo
!
      do j=nam,id+2,-1
         amname(j)=amname(j-1)
         do i=1,3
            namta(i,j)=namta(i,j-1)
         enddo
      enddo
!
      amname(id+1)=amnamecp
      do i=1,3
         namta(i,id+1)=namtacp(i)
      enddo
!
      return
      end
