!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine inputerror(inpc,ipoinpc,iline,text)
!
!     input error message subroutine
!
      implicit none
!
      character*(*) text
!
      character*1 inpc(*)
      character*132 textpart(26)
!
      integer ipoinpc(0:*),iline,i,ier
!
      write(*,*) '*ERROR reading ',text(1:index(text,'%')-1),
     &      '. Card image:'
      write(*,'(8x,1320a1)') 
     &    (inpc(i),i=ipoinpc(iline-1)+1,ipoinpc(iline))
      write(*,*)
!
!     set error flag to 1
!
      ier=1
!
!     look for the next keyword
!
c      do
c         call getnewline(inpc,textpart,istat,n,key,iline,ipol,inl,
c     &        ipoinp,inp,ipoinpc)
c         if(key.eq.1) exit
c      enddo
!
c      call exit(201)
      return
      end
