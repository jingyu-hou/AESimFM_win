      subroutine uhard(syield,hard,eqplas,eqplasrt,temp,nprops,
     &   props)

     
      implicit none
c     include "aba_param.inc"
      integer nprops
      real*8 syield, eqplas, eqplasrt,temp,hard(3) 
      real*8 props(nprops)
     
 
c     dimension hard(3),statev(nstatv),time(*),
c     &     predef(numfieldv),dpred(*)

      real*8 alpha,a,beta,en,em,AA,QR,numerator,denominator
      real*8 r, t
      real*8 xx, yy, zz, xyz
      real*8 eqplas_shift, eqplasrt_shift
      data r / 8.314d0 /


      if (props(1) < 1.5D0 .and. props(1) > 0.D0 ) then ! Hansen-Spittel
         t = temp
         a      = props(4) 
         alpha  = props(5)
         beta   = props(6)
         em     = props(7)
         en     = props(8)

         !variation of syield with respect to the equivalent plastic strain
         hard(1) = 0.d0 ! d \sigma / d ep

         !variation of syield with respect to the equivalent plastic strain rate
         hard(2) = 0.d0 ! d \sigma / d rate( ep) ! i don't know the use of it

         !variation of syield with respect to temperature
         hard(3) = 0.d0 ! d \sigma / d\theta

         syield  = 0.d0
        
c        shifted stress:

c        these values work for simple shear test
c         eqplas_shift   = 0.001d0
c         eqplasrt_shift = 1.d-4
         eqplas_shift   = 0.01d0
         eqplasrt_shift = 0.01d0

         xx = exp ( t * alpha + beta/(eqplas+eqplas_shift) )
         yy = ( eqplasrt + eqplasrt_shift ) ** en
         zz = ( eqplas + eqplas_shift ) ** em

         syield = a * xx * yy * zz

         zz  = ( eqplas + eqplas_shift ) ** (em - 2.d0)
         xyz = ( - beta + em * (eqplas+ eqplas_shift) )
         hard(1) = a * xx * yy * zz * xyz

         yy = ( eqplasrt + eqplasrt_shift ) ** (en-1.d0)
         zz = ( eqplas + eqplas_shift ) ** em
         hard(2) = a * xx * yy * en * zz


      else if ( props(1) > 1.5D0 .and. props(1)<1.D1 ) then ! Arrhenius
         t = temp + 273.d0
         alpha = props(4)
         AA = props(5)
         QR = props(6)
         en = props(7)

c     Initialization
!     Variation of SYIELD with respect to the equivalent plastic strain
         HARD(1) = 0.d0         ! d \sigma / d ep
!     Variation of SYIELD with respect to the equivalent plastic strain
!     rate
         HARD(2) = 0.d0         ! d \sigma / d rate( ep) 
!     Variation of SYIELD with respect to temperature
         HARD(3) = 0.d0         ! d \sigma / d\theta
         SYIELD  = 0.d0


c     shift values
      eqplas_shift   = 0.001d-2
      eqplasrt_shift = 0.001d-2

c     calculate yield stress
      xx = 1.D0/AA * ( eqplasrt + eqplasrt_shift ) * exp(QR/T)
      yy = asinh(xx**(1.D0/en))
      zz = yy / alpha
      syield = 1.D06 * zz


c     calculate hard(1)
      hard(1) = 0.D0

c     calculate hard(2)
      xx = 1.D0/AA * ( eqplasrt + eqplasrt_shift ) * exp(QR/T)
      numerator = xx ** ( 1.D0/en )
      yy = sqrt ( 1.D0 + xx ** ( 2.D0/en ) )
      zz = ( eqplasrt * en * alpha + eqplasrt_shift * en * alpha )
      denominator = yy * zz
      hard(2) = numerator / denominator

      hard(1) = hard(1) * 1.D6
      hard(2) = hard(2) * 1.D6
      hard(3) = hard(3) * 1.D6

      
      endif 


      return
      
      end
