!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!  
      subroutine time2solidus(nk,vold,mi,templiq,tempsol,
     &  solstart,solend,time)
!
!     determine starting and ending time of solidification
!
      implicit none
!
      integer nk,mi(*),i
!
      real*8 vold(0:mi(2),*),templiq,tempsol,solstart(*),
     &       solend(*),time,temp
!
      do i=1,nk
        if(solend(i).gt.0.d0) cycle
!
        temp=vold(0,i)
        if(solstart(i).gt.0.d0) then
            if(temp.le.tempsol) solend(i)=time
        else
c            if(dabs(temp-templiq).le.0.8d0) solstart(i)=time
            if(temp.le.templiq) solstart(i)=time
            if((temp.le.templiq).and.(temp.le.tempsol)) then
                solstart(i)=time
                solend(i)=time
            endif
        endif
      enddo
!
      return
      end
!