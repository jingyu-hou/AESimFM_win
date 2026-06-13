!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
C           tranformation between Kirchhoff stress and true stress
C!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      subroutine transformation(amat,iel,iint,kode,elconloc,plconloc,
     &        mpconloc,emec,emec0,ckl,beta,xokl,voj,xkl,vj,ithermal,t1l,
     &        dtime,time,ttime,icmd,ielas,mi,nstate_,xstateini,xstate,
     &        stre,stiff,pgauss,istep,kinc,pnewdt,nmethod,iperturb,
     &        rdploc,gsloc)
!
!
      implicit none
!
      character*80 amat
!
      integer ithermal,icmd,kode,ielas,iel,iint,nstate_,mi(*),i,
     &  nmethod,iperturb(*),istep,nprops,
     &  ndi,nshr,ntens,layer,kspt,jstep(4),kinc,kal(2,6),
     &  kel(4,21),j1,j2,j3,j4,j5,j6,j7,j8,jj,n,ier,j,matz,k,l
!
      real*8 elconloc(21),stiff(21),emec(6),emec0(6),
     &  vj,t0l,t1l,dtime,xkl(3,3),xokl(3,3),voj,pgauss(3),
     &  time,ttime,skl(3,3),xa(3,3),ya(3,3,3,3),xstate(nstate_,mi(1),*),
     &  xstateini(nstate_,mi(1),*),w(3),fv1(3),fv2(3),d(3,3),v1,v2,v3,
     &  c(3,3),r(3,3),r0(3,3),eln0(3,3),eln(3,3),e(3,3),ckl(3,3),
     &  u(3,3),c2(3,3),dd,um1(3,3),z(3,3),u0(3,3),yy(3,3,3,3),stre(6),
     &  beta(6),plconloc(802),mpconloc(800),rdploc(10,3),gsloc(30,5)
!
      real*8 ddsdde(6,6),sse,spd,scd,rpl,ddsddt(6),drplde(6),
     &  drpldt,stran(6),dstran(6),abqtime(2),predef(1),temp,dtemp,temp0,
     &  dpred(1),drot(3,3),celent,pnewdt
      real*8 ee(6,1),pr(6,1),cprime(3,3,3,3),cpri(6,6),streini(6)
!
      kal=reshape((/1,1,2,2,3,3,1,2,1,3,2,3/),(/2,6/))
!
      kel=reshape((/1,1,1,1,1,1,2,2,2,2,2,2,1,1,3,3,2,2,3,3,3,3,3,3,
     &          1,1,1,2,2,2,1,2,3,3,1,2,1,2,1,2,1,1,1,3,2,2,1,3,
     &          3,3,1,3,1,2,1,3,1,3,1,3,1,1,2,3,2,2,2,3,3,3,2,3,
     &          1,2,2,3,1,3,2,3,2,3,2,3/),(/4,21/))
!
      d=reshape((/1.d0,0.d0,0.d0,0.d0,1.d0,0.d0,0.d0,0.d0,1.d0/),
     1         (/3,3/))
      
!
!     filling field jstep
!
      jstep(1)=istep
      jstep(2)=nmethod
      jstep(3)=iperturb(2)
      if(iperturb(1).eq.1) then
         jstep(4)=1
      else
         jstep(4)=0
      endif
!
!     calculating the square of the right Cauchy-Green tensor at the
!     start of the increment
!
      do i = 1,3
         do j = 1,3
            c(i,j)=xokl(1,i)*xokl(1,j)+xokl(2,i)*xokl(2,j)
     1            +xokl(3,i)*xokl(3,j)
         enddo
      enddo
!
!     calculating the eigenvalues and eigenvectors
!
      n=3
      matz=1
!
      call rs(n,n,c,w,matz,z,fv1,fv2,ier)
!
      if(ier.ne.0) then
         write(*,*) '
     &  *ERROR calculating the eigenvalues/vectors in umat_abaqusnl'
         call exit(201)
      endif
!
!     calculating the invariants at the start of the increment
!
      do i = 1,3
         w(i)=w(i)**0.5
      enddo
      v1=w(1)+w(2)+w(3)
      v2=w(1)*w(2)+w(2)*w(3)+w(3)*w(1)
      v3=w(1)*w(2)*w(3)
!
!     calculating the square of the right Cauchy-Green tensor at the
!     start of the increment
!
      do i = 1,3
         do j = 1,3
            c2(i,j) = c(i,1)*c(1,j)+c(i,2)*c(2,j)+c(i,3)*c(3,j) 
         enddo
      enddo
!
!     calculating the right stretch tensor at the start of the increment
!     (cf. Simo and Hughes, Computational Inelasticity)
!
      dd=v1*v2-v3
      do i=1,3
         do j=1,3
            u0(i,j)=(-c2(i,j)+(v1*v1-v2)*c(i,j)+v1*v3*d(i,j))/dd
         enddo
      enddo
!
!     calculating the inverse of the right stretch tensor at the start
!     of the increment
!
      dd=v1*v2-v3
      do i=1,3
         do j=1,3
            um1(i,j)=(c(i,j)-v1*u0(i,j)+v2*d(i,j))/v3
         enddo
      enddo
!
!     calculation of the local rotation tensor at the start of the
!     increment
!
      do i=1,3
         do j=1,3
            r0(i,j)=xokl(i,1)*um1(1,j)+xokl(i,2)*um1(2,j)+
     &              xokl(i,3)*um1(3,j)
         enddo
      enddo

      e(1,1)=emec0(1)
      e(2,2)=emec0(2)
      e(3,3)=emec0(3)
      e(1,2)=emec0(4)
      e(1,3)=emec0(5)
      e(2,3)=emec0(6)
      e(2,1)=emec0(4)
      e(3,1)=emec0(5)
      e(3,2)=emec0(6)
      call rs(n,n,e,w,matz,z,fv1,fv2,ier)
!
      if(ier.ne.0) then
         write(*,*) '
     &  *ERROR calculating the eigenvalues/vectors in umat_abaqusnl'
         call exit(201)
      endif
      
!      do i=1,3
!         do j=1,3
!            e(i,j)=0.d0
!         enddo
!         e(i,i)=dsqrt(2.d0*w(i)+1.d0)
!      enddo
!      u0=matmul(z,matmul(e,transpose(z)))
!
!
!     calculating the principal stretches at the end of the increment
!
      do i=1,3
         w(i)=dlog(dsqrt(2.d0*w(i)+1.d0))
c         w(i)=log(w(i))   
      enddo
!
      do i=1,3
        do j=1,3
          xa(i,j)=0.0d0
        enddo
        xa(i,i)=w(i)
      enddo
      eln0=matmul(z,matmul(xa,transpose(z)))
!      eln0(1)=z(1,1)*z(1,1)*w(1)+z(1,2)*z(1,2)*w(2)+
!     &        z(1,3)*z(1,3)*w(3)          
!      eln0(2)=z(2,1)*z(2,1)*w(1)+z(2,2)*z(2,2)*w(2)+
!     &        z(2,3)*z(2,3)*w(3)          
!      eln0(3)=z(3,1)*z(3,1)*w(1)+z(3,2)*z(3,2)*w(2)+
!     &        z(3,3)*z(3,3)*w(3)          
!      eln0(4)=z(1,1)*z(2,1)*w(1)+z(1,2)*z(2,2)*w(2)+
!     &        z(1,3)*z(2,3)*w(3)          
!      eln0(5)=z(1,1)*z(3,1)*w(1)+z(1,2)*z(3,2)*w(2)+
!     &        z(1,3)*z(3,3)*w(3)          
!      eln0(6)=z(2,1)*z(3,1)*w(1)+z(2,2)*z(3,2)*w(2)+
!     &        z(2,3)*z(3,3)*w(3)         
!
!     calculating the right Cauchy-Green tensor at the end of the
!     increment
!
      do i = 1,3
         do j = 1,3
            c(i,j)=xkl(1,i)*xkl(1,j)+xkl(2,i)*xkl(2,j)
     1            +xkl(3,i)*xkl(3,j)
         enddo
      enddo
!
!     calculating the eigenvalues and eigenvectors
!
      call rs(n,n,c,w,matz,z,fv1,fv2,ier)
!
!
      if(ier.ne.0) then
         write(*,*) '
     &  *ERROR calculating the eigenvalues/vectors in metal powder'
         call exit(201)
      endif
!
!     calculating the invariants at the end of the increment
!
      do i = 1,3
         w(i)=w(i)**0.5
      enddo
      v1=w(1)+w(2)+w(3)
      v2=w(1)*w(2)+w(2)*w(3)+w(3)*w(1)
      v3=w(1)*w(2)*w(3)
!
!     calculating the square of the right Cauchy-Green tensor at the
!     end of the increment
!
      do i = 1,3
         do j = 1,3
            c2(i,j) = c(i,1)*c(1,j)+c(i,2)*c(2,j)+c(i,3)*c(3,j) 
         enddo
      enddo

!
!     calculating the right stretch tensor at the end of the increment
!     (cf. Simo and Hughes, Computational Inelasticity)
!
      dd=v1*v2-v3
      do i=1,3
         do j=1,3
            u(i,j)=(-c2(i,j)+(v1*v1-v2)*c(i,j)+v1*v3*d(i,j))/dd
         enddo
      enddo
!
!     calculating the inverse of the right stretch tensor at the end
!     of the increment
!
      do i=1,3
         do j=1,3
            um1(i,j)=(c(i,j)-v1*u(i,j)+v2*d(i,j))/v3
         enddo
      enddo
!
!
!     calculation of the local rotation tensor at the end of the
!     increment
!
      do i=1,3
         do j=1,3
            r(i,j)=xkl(i,1)*um1(1,j)+xkl(i,2)*um1(2,j)+
     &              xkl(i,3)*um1(3,j)
         enddo
      enddo
!
!     calculating the logarithmic strain at the end of the increment
!     Elog=Z.ln(w).Z^T
!
      e(1,1)=emec(1)
      e(2,2)=emec(2)
      e(3,3)=emec(3)
      e(1,2)=emec(4)
      e(1,3)=emec(5)
      e(2,3)=emec(6)
      e(2,1)=emec(4)
      e(3,1)=emec(5)
      e(3,2)=emec(6)
      
      call rs(n,n,e,w,matz,z,fv1,fv2,ier)
!
      if(ier.ne.0) then
         write(*,*) '
     &  *ERROR calculating the eigenvalues/vectors in umat_abaqusnl'
         call exit(201)
      endif

!      do i=1,3
!         do j=1,3
!            e(i,j)=0.d0
!         enddo
!         e(i,i)=dsqrt(2.d0*w(i)+1.d0)
!      enddo
!      u=matmul(z,matmul(e,transpose(z)))
!     
!
!     calculating the principal stretches at the end of the increment
!
      do i=1,3
         w(i)=dlog(dsqrt(2.d0*w(i)+1.d0))
c         w(i)=log(w(i))
      enddo

!
!     logarithmic strain in global coordinates at the end of the
!     increment
!
      do i=1,3
        do j=1,3
          xa(i,j)=0.0d0
        enddo
        xa(i,i)=w(i)
      enddo
      
      eln0=matmul(r,matmul(eln0,(transpose(r))))
      eln=matmul(r,matmul(matmul(z,matmul(xa,transpose(z))),
     &      transpose(r)))
      
      drot=matmul(r,transpose(r0))

!
!
      ntens=6
!
      do i=1,nstate_
         xstate(i,iint,iel)=xstateini(i,iint,iel)
      enddo
!
      abqtime(1)=time-dtime
      abqtime(2)=ttime+time-dtime
!
      temp=t1l
      temp0=t0l
      dtemp=0.d0
!
      ndi=3
      nshr=3
      ntens=ndi+nshr
!
!
!     taking local material orientations into account
!
      do jj=1,6
         j1=kal(1,jj)
         j2=kal(2,jj)
         stran(jj)=eln0(j1,j2)
         dstran(jj)=eln(j1,j2)-eln0(j1,j2)
      enddo
!
!     rotating the stress into the local system
!     s'=J^(-1).F.S.F^T
!
      xa(1,1)=stre(1)
      xa(1,2)=stre(4)
      xa(1,3)=stre(5)
      xa(2,1)=stre(4)
      xa(2,2)=stre(2)
      xa(2,3)=stre(6)
      xa(3,1)=stre(5)
      xa(3,2)=stre(6)
      xa(3,3)=stre(3)
      xa=matmul(xokl,matmul(xa,transpose(xokl)))/voj
      xa=matmul(drot,matmul(xa,transpose(drot)))
      stre(1)=xa(1,1)
      stre(4)=xa(1,2)
      stre(5)=xa(1,3)
      stre(2)=xa(2,2)
      stre(6)=xa(2,3)
      stre(3)=xa(3,3)
      
!      xa(1,1)=-beta(1)
!      xa(1,2)=-beta(4)
!      xa(1,3)=-beta(5)
!      xa(2,1)=-beta(4)
!      xa(2,2)=-beta(2)
!      xa(2,3)=-beta(6)
!      xa(3,1)=-beta(5)
!      xa(3,2)=-beta(6)
!      xa(3,3)=-beta(3)
!      xa=matmul(xokl,matmul(xa,transpose(xokl)))/voj
!      xa=matmul(drot,matmul(xa,transpose(drot)))
!      streini(1)=xa(1,1)
!      streini(4)=xa(1,2)
!      streini(5)=xa(1,3)
!      streini(2)=xa(2,2)
!      streini(6)=xa(2,3)
!      streini(3)=xa(3,3)
!
!     changing physical strain into engineering strain
!     ABAQUS uses the engineering strain!
!
      do i=4,6
         stran(i)=2.d0*stran(i)
         dstran(i)=2.d0*dstran(i)
      enddo

      pnewdt=-1.d0
      
      nprops=-kode-100
     
      if (kode.eq.-70) then
        call metal_powder(stre,xstate(1:nstate_,iint,iel),ddsdde,sse,
     &       spd,scd,
     &       rpl,ddsddt,drplde,drpldt,stran,dstran,abqtime,dtime,temp,
     &       dtemp,temp0,predef,dpred,amat,ndi,nshr,ntens,nstate_,
     &       elconloc,plconloc,mpconloc,pgauss,drot,pnewdt,
     &       celent,xokl,xkl,iel,iint,layer,kspt,jstep,kinc)
      elseif (kode.eq.-71) then
        call rdplas(stre,xstate(1:nstate_,iint,iel),ddsdde,sse,spd,scd,
     &       rpl,ddsddt,drplde,drpldt,stran,dstran,
     &       abqtime,dtime,temp,dtemp,predef,dpred,amat,ndi,nshr,ntens,
     &       nstate_,elconloc(1:7),rdploc,gsloc,pgauss,drot,pnewdt,
     &       celent,xokl,xkl,iel,iint,layer,kspt,jstep,kinc)
      elseif (kode.eq.-72) then
        call creep_softening_model(stre,
     &       xstate(1:nstate_,iint,iel),ddsdde,sse,spd,scd,
     &       rpl,ddsddt,drplde,drpldt,stran,dstran,
     &       abqtime,dtime,temp,dtemp,temp0,predef,dpred,amat,
     &       ndi,nshr,ntens,nstate_,
     &       elconloc,plconloc,mpconloc,pgauss,drot,pnewdt,
     &       celent,xokl,xkl,iel,iint,layer,kspt,jstep,kinc)
      elseif (kode.eq.-73) then
        call metal_powder(stre,xstate(1:nstate_,iint,iel),ddsdde,sse,
     &       spd,scd,
     &       rpl,ddsddt,drplde,drpldt,stran,dstran,abqtime,dtime,temp,
     &       dtemp,temp0,predef,dpred,amat,ndi,nshr,ntens,nstate_,
     &       elconloc,plconloc,mpconloc,pgauss,drot,pnewdt,
     &       celent,xokl,xkl,iel,iint,layer,kspt,jstep,kinc)
        call creep_softening_model(stre,
     &       xstate(1:nstate_,iint,iel),ddsdde,sse,spd,scd,
     &       rpl,ddsddt,drplde,drpldt,stran,dstran,
     &       abqtime,dtime,temp,dtemp,temp0,predef,dpred,amat,
     &       ndi,nshr,ntens,nstate_,
     &       elconloc,plconloc,mpconloc,pgauss,drot,pnewdt,
     &       celent,xokl,xkl,iel,iint,layer,kspt,jstep,kinc)
      else
        call umat(stre,xstate(1:nstate_,iint,iel),ddsdde,sse,spd,scd,
     &       rpl,ddsddt,drplde,drpldt,stran,dstran,
     &       abqtime,dtime,temp,dtemp,predef,dpred,amat,ndi,nshr,ntens,
     &       nstate_,elconloc,nprops,pgauss,drot,pnewdt,celent,
     &       xokl,xkl,iel,iint,layer,kspt,jstep,kinc)
      endif

!      if (iint.eq.1) then
!        open(2222, file='transformation.txt')
!        write(2222,*)"iinc", kinc
!        write(2222,*)"stress"
!        write(2222,"(6e12.4)")stre(1:6)
!        do i=1,6
!          write(2222,"(6e12.4)")ddsdde(i,:)
!        enddo
!        write(2222,*)""
!      endif
!            
      if (pnewdt.gt.0.d0) then
        write(*,*) '*ERROR: no convergence in material subroutine in 
     &      step',kinc
        open(333, file='pnewdt.txt')
        write(333,*)"kinc,iel,iint,temp,dtime"
        write(333,*)kinc,iel,iint,temp,dtime
!        write(333,*)"stress"
!        write(333,*)stre
!        write(333,*)"elconloc"
!        write(333,*)elconloc
!        write(333,*)"plconloc(1:4)"
!        write(333,*)plconloc(1:4)
        write(333,*)"stran"
        write(333,*)stran
        write(333,*)"dstran"
        write(333,*)dstran
!        write(333,*)"oldpe"
!        write(333,*)xstateini(1:nstate_,iint,iel)
        write(333,*)"drot"
        write(333,*)drot(1,1:3)
        write(333,*)drot(2,1:3)
        write(333,*)drot(3,1:3)
        write(333,*)""
        return
      endif
      
      ckl(1,1)=(xkl(2,2)*xkl(3,3)-xkl(2,3)*xkl(3,2))/vj
      ckl(1,2)=(xkl(1,3)*xkl(3,2)-xkl(1,2)*xkl(3,3))/vj
      ckl(1,3)=(xkl(1,2)*xkl(2,3)-xkl(1,3)*xkl(2,2))/vj 
      ckl(2,1)=(xkl(2,3)*xkl(3,1)-xkl(2,1)*xkl(3,3))/vj 
      ckl(2,2)=(xkl(1,1)*xkl(3,3)-xkl(1,3)*xkl(3,1))/vj 
      ckl(2,3)=(xkl(2,1)*xkl(1,3)-xkl(1,1)*xkl(2,3))/vj 
      ckl(3,1)=(xkl(2,1)*xkl(3,2)-xkl(2,2)*xkl(3,1))/vj 
      ckl(3,2)=(xkl(1,2)*xkl(3,1)-xkl(1,1)*xkl(3,2))/vj 
      ckl(3,3)=(xkl(1,1)*xkl(2,2)-xkl(2,1)*xkl(1,2))/vj
!                                                   
      do i=1,6
        j1=kal(1,i)
        j2=kal(2,i)
        xa(j1,j2)=stre(i)
        xa(j2,j1)=stre(i)
      enddo
!
!     calculate the stiffness matrix (the matrix is symmetrized)
!
      if(icmd.ne.3) then

         do i=1,6
           j1=kal(1,i)
           j2=kal(2,i)
           do j=1,6
             j3=kal(1,j)
             j4=kal(2,j)
             ya(j1,j2,j3,j4)=ddsdde(i,j)
             ya(j2,j1,j3,j4)=ya(j1,j2,j3,j4)
             ya(j1,j2,j4,j3)=ya(j1,j2,j3,j4)
             ya(j2,j1,j4,j3)=ya(j1,j2,j3,j4)
           enddo
         enddo

         do i=1,3
           do j=1,3
             do k=1,3
               do l=1,3
                 cprime(i,j,k,l)=0.5d0*(d(i,k)*xa(j,l)+
     1             d(i,l)*xa(j,k)+d(j,k)*xa(i,l)+d(j,l)*xa(i,k))
                 yy(i,j,k,l)=ya(i,j,k,l)-cprime(i,j,k,l)
!                 yy(i,j,k,l)=ya(i,j,k,l)
               enddo
             enddo
           enddo
         enddo
         
         do j1=1,3
           do j2=1,3
             do j3=1,3
               do j4=1,3
                 ya(j1,j2,j3,j4)=0.d0
                 do j5=1,3
                   do j6=1,3
                     do j7=1,3
                       do j8=1,3
                         ya(j1,j2,j3,j4)=ya(j1,j2,j3,j4)+
     &                     vj*yy(j5,j6,j7,j8)*
     &                     ckl(j1,j5)*ckl(j2,j6)*ckl(j3,j7)*ckl(j4,j8)
                       enddo
                     enddo
                   enddo
                 enddo
               enddo
             enddo
           enddo
         enddo
!
         do i=1,6
           j1=kal(1,i)
           j2=kal(2,i)
           do j=1,6
             j3=kal(1,j)
             j4=kal(2,j)
             ddsdde(i,j)=ya(j1,j2,j3,j4)
           enddo  
         enddo
         stiff(1)=ddsdde(1,1)
         stiff(2)=(ddsdde(1,2)+ddsdde(2,1))/2.d0
         stiff(3)=ddsdde(2,2)
         stiff(4)=(ddsdde(1,3)+ddsdde(3,1))/2.d0
         stiff(5)=(ddsdde(2,3)+ddsdde(3,2))/2.d0
         stiff(6)=ddsdde(3,3)
         stiff(7)=(ddsdde(1,4)+ddsdde(4,1))/2.d0
         stiff(8)=(ddsdde(2,4)+ddsdde(4,2))/2.d0
         stiff(9)=(ddsdde(3,4)+ddsdde(4,3))/2.d0
         stiff(10)=ddsdde(4,4)
         stiff(11)=(ddsdde(1,5)+ddsdde(5,1))/2.d0
         stiff(12)=(ddsdde(2,5)+ddsdde(5,2))/2.d0
         stiff(13)=(ddsdde(3,5)+ddsdde(5,3))/2.d0
         stiff(14)=(ddsdde(4,5)+ddsdde(5,4))/2.d0
         stiff(15)=ddsdde(5,5)
         stiff(16)=(ddsdde(1,6)+ddsdde(6,1))/2.d0
         stiff(17)=(ddsdde(2,6)+ddsdde(6,2))/2.d0
         stiff(18)=(ddsdde(3,6)+ddsdde(6,3))/2.d0
         stiff(19)=(ddsdde(4,6)+ddsdde(6,4))/2.d0
         stiff(20)=(ddsdde(5,6)+ddsdde(6,5))/2.d0
         stiff(21)=ddsdde(6,6)
         
c         stiff(1)=ddsdde(1,1)
c         stiff(2)=ddsdde(1,2)
c         stiff(3)=ddsdde(2,2)
c         stiff(4)=ddsdde(1,3)
c         stiff(5)=ddsdde(2,3)
c         stiff(6)=ddsdde(3,3)
c         stiff(7)=ddsdde(1,4)
c         stiff(8)=ddsdde(2,4)
c         stiff(9)=ddsdde(3,4)
c         stiff(10)=ddsdde(4,4)
c         stiff(11)=ddsdde(1,5)
c         stiff(12)=ddsdde(2,5)
c         stiff(13)=ddsdde(3,5)
c         stiff(14)=ddsdde(4,5)
c         stiff(15)=ddsdde(5,5)
c         stiff(16)=ddsdde(1,6)
c         stiff(17)=ddsdde(2,6)
c         stiff(18)=ddsdde(3,6)
c         stiff(19)=ddsdde(4,6)
c         stiff(20)=ddsdde(5,6)
c         stiff(21)=ddsdde(6,6)
!
!         rotating the stiffness coefficients into the global system
!
!          call anisotropic(stiff,ya)
      endif
      
!     rotating the stress into the global system
!     S=J.F^(-1).s'.F^(-T)
!
      xa=matmul(ckl,matmul(xa,transpose(ckl)))*vj
      
      do i=1,6
        j1=kal(1,i)
        j2=kal(2,i)
        stre(i)=xa(j1,j2)
      enddo

      return
      end

