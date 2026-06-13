!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine randomval(randval,nev)              
!
!     Creation of normal ditributed unit variance gaussian       
!     random variables using the Box-Muller-Transformation
!
      implicit none
!
      integer nev,i
!
      real*8 randval(*),fac,v1,v2,rsq
!      
      call random_seed()
!
      do i=1,nev
         do
            call random_number(v1)
            call random_number(v2)
            rsq=v1**2+v2**2
            if((rsq.ge.1.d0).or.(rsq.le.0.d0)) cycle
            fac=sqrt(-2.d0*dlog(rsq)/rsq)  
            randval(i)=v1*fac
            exit
         enddo
      enddo
!
      return        
      end




