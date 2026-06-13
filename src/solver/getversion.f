!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine getversion(version)
!
!     this routine is called if an inconsistency is noticed between
!     the element count and the number of elements stored in the frd-
!     file. Such an inconsistency will lead to a crash while reading
!     a binary frd-file
!
      implicit none
!
      character*80 version
!
      integer i
!
      intent(inout) version
!
      do i=1,80
         version(i:i)=' '
      enddo
!
      version='Version 2020.0'
!
      return
      end
