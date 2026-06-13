!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine bsort(n,x,y,xmin,xmax,ymin,ymax,dmax,bin,list)
!     
      implicit none
!     
      integer list(*),bin(*),n,i,j,k,p,ndiv
!     
      real*8 x(*),y(*),factx,facty,xmin,xmax,ymin,ymax,dmax
!     
      ndiv=nint(real(n)**0.25d0)
      factx=real(ndiv)/((xmax-xmin)*1.01d0/dmax)
      facty=real(ndiv)/((ymax-ymin)*1.01d0/dmax)
      do 10 k=1,n
         p=list(k)
         i=int(y(p)*facty)
         j=int(x(p)*factx)
         if(mod(i,2).eq.0)then
            bin(p)=i*ndiv+j+1
         else
            bin(p)=(i+1)*ndiv-j
         end if
 10   continue
      call qsorti(n,list,bin)
      end
