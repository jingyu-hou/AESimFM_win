!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine nystarflcrchart(n_nyscon,nyscon,nflcon,flcon,ntmat_)
!
      implicit none
!
!     calculating shrinkage porosity needs flcr, which is determined
!     by niyamastar-flcr chart
!
!     References:
!     [1]Guo, Jianzheng & Beckermann, C & Carlson, Kent & Hirvo, D 
!        & Bell, K & Moreland, T & Gu, J & Clews, J & Scott, S 
!        & Couturier, G & Backman, D. (2015). Microporosity Prediction
!        and Validation for Ni-based Superalloy Castings. IOP Conference
!        Series: Materials Science and Engineering. 84. 10.1088/
!        1757-899X/84/1/012003. 
!     [2]Carlson, K.D.; Beckermann, C. Prediction of shrinkage pore
!        volume fraction using a dimensionless niyama criterion. Metall. 
!        Mater.Trans. A 2009, 40, 163–175
!
      integer n_nyscon,nflcon(*),ntmat_,i,two,id
!
      real*8 nyscon(0:1,*),flcon(0:1,ntmat_,*),dfl,fl,ifunc1,ifunc2
!
      two=2
      dfl=1.d0/real(n_nyscon-1)
!
      nyscon(0,n_nyscon)=0.d0
      nyscon(0,1)=1.d10
      nyscon(1,n_nyscon)=1.d0
      nyscon(1,1)=0.d0
!
!     ifunc1,ifun2:values of two adjacent points on the function to be
!     integrate numerically
!
      ifunc2=0.d0
      do i=n_nyscon-1,1,-1
         nyscon(1,i)=1.d0-dfl*(n_nyscon-i)
         fl=nyscon(1,i)
         call ident2(flcon(1,1,1),fl,nflcon(1),two,id)
c         print *,fl,id,flcon(0,id+1,1),flcon(0,id,1)
         ifunc1=180.d0*(1.d0-fl)**2/(fl**2+1.d-8)
     &          *(flcon(0,id+1,1)-flcon(0,id,1))
     &          /(flcon(1,id+1,1)-flcon(1,id,1))/65.d0
         nyscon(0,i)=nyscon(0,i+1)+(ifunc1+ifunc2)/2.d0
c         print *,i,ifunc1,ifunc2,nyscon(0,i)
         ifunc2=ifunc1
      enddo
!     
      return
      end
!