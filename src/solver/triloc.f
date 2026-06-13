!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      function triloc(xp,yp,x,y,v,e,numtri)
!     
      implicit none
!     
      integer v(3,*),e(3,*),numtri,v1,v2,i,t,triloc
!     
      real*8 x(*),y(*),xp,yp
!     
      t=numtri
 10   continue
      do 20 i=1,3
         v1=v(i,t)
         v2=v(mod(i,3)+1,t)
         if((y(v1)-yp)*(x(v2)-xp).gt.(x(v1)-xp)*(y(v2)-yp)) then
            t=e(i,t)
            goto 10
         end if
 20   continue
      triloc=t
      end
      
