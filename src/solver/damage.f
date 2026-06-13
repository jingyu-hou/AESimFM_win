c     weicme (wedge integrated computational materials engineering)
c                 - a 3-dimensional finite element program.
c     
c     developed and maintained by shenzhen wedge central 
c     south research institute co., ltd., shenzhen, china
c     
c     copy right 2019-2023.
c

      subroutine damage(s,eqplas,deqpl,criteria,c,a)

      implicit none 
      real*8 s(6),eqplas,deqpl,c,a(2),smises,sm,sp(3),ss(6,1),n
      integer criteria,i
      real*8, external :: pressure, mises
      
      do i=1,6
        ss(i,1)=s(i)
      enddo
      sm=-pressure(ss)
      smises=mises(ss)
      call principal(ss,sp)
      
      select case (criteria)
c normalized C&L damage model
        case (1)
          c=c+max(0.d0,sp(1)/smises*deqpl)
        
c Cockroft & Latham damage model
        case(2)
          c=c+max(0.d0,sp(1)*deqpl)

c McClintock damage model
        case(3)
          n=a(1)
          if (sm.gt.0.d0)then
            c=c+(2.d0/dsqrt(3.d0)/(1.d0-n)*dsinh(dsqrt(3.d0)*(1.d0-n)
     1        /2.d0*(sp(3)+sp(1))/smises)+(sp(3)-sp(1))/smises)*deqpl
          endif
         
c Freudenthal damage model
        case(4)
          c=c+smises*deqpl

c Rice & Tracy damage model
        case(5)
          if (sm.gt.0.d0)then
            c=c+dexp(a(1)*sm/smises)*deqpl
          endif

c Oyane damage model
        case(6)
!          c=c+max(0.d0,(1.d0+sm/a(1)/smises))*deqpl
          if (sm.gt.0.d0)then
            c=c+(1.d0+sm/a(1)/smises)*deqpl
          endif
          
c Oyane (negative) damage model
        case(7)
          c=c+(1.d0+sm/a(1)/smises)*deqpl

c Ayada damage model
        case(8)
          c=c+max(0.d0,sm/smises)*deqpl

c Ayada (negative) damage model
        case(9)
          c=c+sm/smises*deqpl

c Osakada damage model
        case(10)
          c=c+max(0.d0,eqplas+a(1)*sm-a(2))*deqpl 

c Brozzo damage model
        case(11)
          c=c+2.d0*sp(1)/3.d0/(sp(1)-sm)*deqpl

c Zhao&Kuhn damage model
        case(12)
          c=sp(1)/smises

c Maximum principal stress / ultimate tensile strength
        case(13)
          if (c.gt.a(2)) then
            c=a(2)+1.d-9
          else
            c=sp(1)/a(1)
          endif

      end select
      
      return

      end subroutine

      subroutine soften(scal,soft,eqplas,damage_eqplas)
      implicit none
      real*8 scal(2),soft(2),eqplas,damage_eqplas,threshold
      parameter (threshold=1.d-10)

      scal(1)=1.d0
      scal(2)=0.d0
      
      if (damage_eqplas.gt.threshold) then
! stress soften
        if (eqplas.lt.damage_eqplas) then
          scal(1)=1.d0
          scal(2)=0.d0
        elseif (eqplas.lt.(damage_eqplas+soft(2))) then
          scal(1)=1.d0-(1.d0-soft(1))/soft(2)*(eqplas-damage_eqplas)
          scal(2)=-(1.d0-soft(1))/soft(2)
        else
          scal(1)=soft(1)
          scal(2)=0.d0
        endif

      elseif (damage_eqplas.lt.-threshold) then
! stress recover        
        if (eqplas.lt.(-damage_eqplas)) then
          scal(1)=soft(1)
          scal(2)=0.d0
        elseif (eqplas.lt.(-damage_eqplas+soft(2))) then
          scal(1)=0.1+(1.d0-soft(1))/soft(2)*(eqplas+damage_eqplas)
          scal(2)=(1.d0-soft(1))/soft(2)
        else
          scal(1)=1.d0
          scal(2)=0.d0
        endif

      endif

      return
      end subroutine
