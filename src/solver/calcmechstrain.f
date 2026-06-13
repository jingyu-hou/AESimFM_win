!
      subroutine calcmechstrain(xkl,eth)
!
!     calculates the mechanical deformation gradient from the thermal 
!     stretches
!
      implicit none
!
      real*8 elineng(6),vkl(3,3),xkl(3,3),xklme(3,3),eth(6),
     &     xklth(3,3),cklth(3,3),m(3,3),vjth
!
      intent(in) eth
!
      intent(inout) xkl
!      
      m=reshape((/1.d0,0.d0,0.d0,0.d0,1.d0,0.d0,0.d0,0.d0,1.d0/),
     1         (/3,3/))
!
!
!
c      write(*,*) vkl(1,1),eth(1)
      xklth(1,1)=1.d0+eth(1)
      xklth(2,2)=1.d0+eth(2)
      xklth(3,3)=1.d0+eth(3)
      xklth(1,2)=eth(4)
      xklth(1,3)=eth(5)
      xklth(2,3)=eth(6)
      xklth(2,1)=eth(4)
      xklth(3,1)=eth(5)
      xklth(3,2)=eth(6)

      vjth=xklth(1,1)*(xklth(2,2)*xklth(3,3)-xklth(2,3)*xklth(3,2))
     &    -xklth(1,2)*(xklth(2,1)*xklth(3,3)-xklth(2,3)*xklth(3,1))
     &    +xklth(1,3)*(xklth(2,1)*xklth(3,2)-xklth(2,2)*xklth(3,1))

      cklth(1,1)=(xklth(2,2)*xklth(3,3)-xklth(2,3)*xklth(3,2))/vjth
      cklth(2,2)=(xklth(1,1)*xklth(3,3)-xklth(1,3)*xklth(3,1))/vjth
      cklth(3,3)=(xklth(1,1)*xklth(2,2)-xklth(1,2)*xklth(2,1))/vjth
      cklth(1,2)=(xklth(1,3)*xklth(3,2)-xklth(1,2)*xklth(3,3))/vjth
      cklth(1,3)=(xklth(1,2)*xklth(2,3)-xklth(2,2)*xklth(1,3))/vjth
      cklth(2,3)=(xklth(2,1)*xklth(1,3)-xklth(1,1)*xklth(2,3))/vjth
      cklth(2,1)=(xklth(3,1)*xklth(2,3)-xklth(2,1)*xklth(3,3))/vjth
      cklth(3,1)=(xklth(2,1)*xklth(3,2)-xklth(2,2)*xklth(3,1))/vjth
      cklth(3,2)=(xklth(3,1)*xklth(1,2)-xklth(1,1)*xklth(3,2))/vjth

!     subtracting the thermal stretch from the deformation gradients
      xkl=matmul(cklth,xkl)
!      vkl=xkl-m
!     
      return
      end
