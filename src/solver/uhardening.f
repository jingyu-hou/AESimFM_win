!     
!     WeICME (Wedge Integrated Computational Materials Engineering)
!                 - A 3-dimensional finite element program.
!     
!     Developed and maintained by Shenzhen Wedge Central 
!     South Research Institute co., Ltd., Shenzhen, China
!     
!     Copy Right 2019-2023.
!
      subroutine uhardening(amat,iel,iint,t1l,epini,ep,dtime,fiso,dfiso,
     &                      fkin,dfkin,params,nparams,switch)
!
!     hardening user subroutine
!
!     INPUT:
!
!     amat:    material name (maximum 20 characters)
!     iel:     element number
!     iint:    integration point number
!     t1l:     temperature at the end of the increment
!     epini:   equivalent irreversible strain at the start 
!              of the increment
!     ep:      present equivalent irreversible strain
!     dtime:   time increment
!     params:  an array of parameters
!     nparams: number of parameters in params
!     switch:  an integer denoting the hardening type
!     1: isotropic hardening
!     2: kinematic hardening
!     3: combined hardening
!
!     OUTPUT:
!
!     fiso:    present isotropic hardening Von Mises stress
!     dfiso:   present isotropic hardening tangent (derivative
!              of the Von Mises stress with respect to the
!              equivalent irreversible strain)
!     fkin:    present kinematic hardening Von Mises stress
!     dfkin:   present kinematic hardening tangent (derivative
!              of the Von Mises stress with respect to the
!              equivalent irreversible strain)
!
      implicit none
!
      character*80 amat
      integer iel,iint
      real*8 t1l,epini,ep,dtime,fiso,dfiso,fkin,dfkin

      integer switch, nparams
      real*8 params(8)

!
c$$$      switch = 3
c$$$      params(1) = 0.0
c$$$      params(2) = 10.0
c$$$      params(3) = 7.0e8
c$$$      params(4) = 10.0e8
c$$$      params(5) = 0.0
c$$$      params(6) = 10.0
c$$$      params(7) = 0.0e8
c$$$      params(8) = 10.0e8

      
      IF ( switch == 1 ) THEN
!     isotropic hardening:
         dfiso = ( params(4) - params(3) ) / ( params(2) - params(1) ) 
         fiso  = params(3) + dfiso * ( ep - params(1) )
         dfkin = 0.0
         fkin = params(3)
      ELSE IF ( switch == 2 ) THEN
!     kinematic hardening:
         dfkin = ( params(4) - params(3) ) / ( params(2) - params(1) ) 
         fkin  = params(3) + dfkin * ( ep - params(1) )
         dfiso = 0.0
         fiso = params(3)
      ELSE IF ( switch == 3 ) THEN
         dfiso = ( params(4) - params(3) ) / ( params(2) - params(1) ) 
         fiso  = params(3) + dfiso * ( ep - params(1) )
         dfkin = ( params(8) - params(7) ) / ( params(6) - params(5) ) 
         fkin  = params(7) + dfkin * ( ep - params(5) )
      END IF


      return
      end
