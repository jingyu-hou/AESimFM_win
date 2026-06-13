!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine createialnk(nk,iponoel,inoel,istartnk,ialnk,ipkon)
!
      implicit none
!
      integer nk,iponoel(*),inoel(2,*),ipkon(*),ielem,
     &   istartnk(*),ialnk(*),ifree,index,i
!
!     determining the elements belonging to a nk.
!     They are stored in ialnk(istartnk(i))..
!     ...up to..... ialnk(istartnk(i+1)-1)
!
      ifree=1
      do i=1,nk
         istartnk(i)=ifree
         index=iponoel(i)
         do
            if(index.eq.0) exit
            ielem=inoel(1,index)
            if(ipkon(ielem).ge.0) then
               ialnk(ifree)=ielem
               ifree=ifree+1
            endif
            index=inoel(2,index)
         enddo
      enddo
      istartnk(nk+1)=ifree
!
      return
      end
