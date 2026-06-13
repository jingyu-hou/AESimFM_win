!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
       subroutine writemaccs(mac,nev,nm)
!
!      writes the results of MAC-caculation in *_mac.dat
!
!      nm is the nodal diameter in case of complex frequency
!      nev is the number of eigenvectors
!      mac contains the MAC-Values
!
       implicit none
!
       integer i,j,nev,nm(*)
       real*8 mac(nev,*)
!      
       write(5,*)
       write(5,*)'    Modal Assurance Criterium'
       write(5,*)'       Nodal Diameter',nm(1)
!
       do i=1,nev
          write(5,100) (mac(i,j),j=1,nev)
       enddo
!
 100   format(15(1x,e11.4))
       return
       end
