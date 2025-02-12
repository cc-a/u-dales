!!> \file modEB.f90
!!!  Energy balance on facets
!
!>
!!  \author Ivo Suter
!
!
!  This file is part of uDALES.
!
! This program is free software: you can redistribute it and/or modify
! it under the terms of the GNU General Public License as published by
! the Free Software Foundation, either version 3 of the License, or
! (at your option) any later version.
!
! This program is distributed in the hope that it will be useful,
! but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
! GNU General Public License for more details.
!
! You should have received a copy of the GNU General Public License
! along with this program.  If not, see <http://www.gnu.org/licenses/>.
!
!  Copyright 2006-2021 the uDALES Team.
!
module modEB
  use modglobal
  use mpi

  implicit none
  public :: EB, initEB, intqH, updateGR

  integer :: nstatT=2, nstatEB=6, ncidT, ncidEB, nrecT=0, nrecEB=0
  character(80), allocatable :: ncstatT(:,:), ncstatEB(:,:)
  character(80) :: Tname = "facT.xxx.nc", EBname = 'facEB.xxx.nc'
  character(80),dimension(1,4) :: tncstatT, tncstatEB
  real, allocatable :: varsT(:,:,:), varsEB(:,:)

  save

contains
  !functions to invert matrices
  pure function matinv3(A) result(B) !pure makes sure that no variable outside the function can possibly be changed
    !! calculates the inverse of a 3×3 matrix.
    real, intent(in) :: A(3, 3) !! matrix
    real             :: B(3, 3) !! inverse matrix
    real             :: detinv

    !inverse determinant of the matrix
    detinv = 1/(A(1, 1)*A(2, 2)*A(3, 3) - A(1, 1)*A(2, 3)*A(3, 2) &
    - A(1, 2)*A(2, 1)*A(3, 3) + A(1, 2)*A(2, 3)*A(3, 1) &
    + A(1, 3)*A(2, 1)*A(3, 2) - A(1, 3)*A(2, 2)*A(3, 1))

    !inverse of the matrix
    B(1, 1) = +detinv*(A(2, 2)*A(3, 3) - A(2, 3)*A(3, 2))
    B(2, 1) = -detinv*(A(2, 1)*A(3, 3) - A(2, 3)*A(3, 1))
    B(3, 1) = +detinv*(A(2, 1)*A(3, 2) - A(2, 2)*A(3, 1))
    B(1, 2) = -detinv*(A(1, 2)*A(3, 3) - A(1, 3)*A(3, 2))
    B(2, 2) = +detinv*(A(1, 1)*A(3, 3) - A(1, 3)*A(3, 1))
    B(3, 2) = -detinv*(A(1, 1)*A(3, 2) - A(1, 2)*A(3, 1))
    B(1, 3) = +detinv*(A(1, 2)*A(2, 3) - A(1, 3)*A(2, 2))
    B(2, 3) = -detinv*(A(1, 1)*A(2, 3) - A(1, 3)*A(2, 1))
    B(3, 3) = +detinv*(A(1, 1)*A(2, 2) - A(1, 2)*A(2, 1))
  end function

  pure function matinv4(A) result(B)
    !! calculates the inverse of a 4×4 matrix.
    real, intent(in) :: A(4, 4) !! matrix
    real             :: B(4, 4) !! inverse matrix
    real             :: detinv

    !inverse determinant of the matrix
    detinv = &
    1/(A(1,1)*(A(2,2)*(A(3,3)*A(4,4)-A(3,4)*A(4,3))+A(2,3)*(A(3,4)*A(4,2) &
     - A(3,2)*A(4,4))+A(2,4)*(A(3,2)*A(4,3)-A(3,3)*A(4,2))) &
     - A(1,2)*(A(2,1)*(A(3,3)*A(4,4)-A(3,4)*A(4,3))+A(2,3)*(A(3,4)*A(4,1) &
     - A(3,1)*A(4,4))+A(2,4)*(A(3,1)*A(4,3)-A(3,3)*A(4,1))) &
     + A(1,3)*(A(2,1)*(A(3,2)*A(4,4)-A(3,4)*A(4,2))+A(2,2)*(A(3,4)*A(4,1) &
     - A(3,1)*A(4,4))+A(2,4)*(A(3,1)*A(4,2)-A(3,2)*A(4,1))) &
     - A(1,4)*(A(2,1)*(A(3,2)*A(4,3)-A(3,3)*A(4,2))+A(2,2)*(A(3,3)*A(4,1) &
     - A(3,1)*A(4,3))+A(2,3)*(A(3,1)*A(4,2)-A(3,2)*A(4,1))))

    !inverse of the matrix
    B(1,1) = detinv*(A(2,2)*(A(3,3)*A(4,4)-A(3,4)*A(4,3))+A(2,3)*(A(3,4)*A(4,2) &
                            -A(3,2)*A(4,4))+A(2,4)*(A(3,2)*A(4,3)-A(3,3)*A(4,2)))
    B(2,1) = detinv*(A(2,1)*(A(3,4)*A(4,3)-A(3,3)*A(4,4))+A(2,3)*(A(3,1)*A(4,4) &
                            -A(3,4)*A(4,1))+A(2,4)*(A(3,3)*A(4,1)-A(3,1)*A(4,3)))
    B(3,1) = detinv*(A(2,1)*(A(3,2)*A(4,4)-A(3,4)*A(4,2))+A(2,2)*(A(3,4)*A(4,1) &
                            -A(3,1)*A(4,4))+A(2,4)*(A(3,1)*A(4,2)-A(3,2)*A(4,1)))
    B(4,1) = detinv*(A(2,1)*(A(3,3)*A(4,2)-A(3,2)*A(4,3))+A(2,2)*(A(3,1)*A(4,3) &
                            -A(3,3)*A(4,1))+A(2,3)*(A(3,2)*A(4,1)-A(3,1)*A(4,2)))
    B(1,2) = detinv*(A(1,2)*(A(3,4)*A(4,3)-A(3,3)*A(4,4))+A(1,3)*(A(3,2)*A(4,4) &
                            -A(3,4)*A(4,2))+A(1,4)*(A(3,3)*A(4,2)-A(3,2)*A(4,3)))
    B(2,2) = detinv*(A(1,1)*(A(3,3)*A(4,4)-A(3,4)*A(4,3))+A(1,3)*(A(3,4)*A(4,1) &
                            -A(3,1)*A(4,4))+A(1,4)*(A(3,1)*A(4,3)-A(3,3)*A(4,1)))
    B(3,2) = detinv*(A(1,1)*(A(3,4)*A(4,2)-A(3,2)*A(4,4))+A(1,2)*(A(3,1)*A(4,4) &
                            -A(3,4)*A(4,1))+A(1,4)*(A(3,2)*A(4,1)-A(3,1)*A(4,2)))
    B(4,2) = detinv*(A(1,1)*(A(3,2)*A(4,3)-A(3,3)*A(4,2))+A(1,2)*(A(3,3)*A(4,1) &
                            -A(3,1)*A(4,3))+A(1,3)*(A(3,1)*A(4,2)-A(3,2)*A(4,1)))
    B(1,3) = detinv*(A(1,2)*(A(2,3)*A(4,4)-A(2,4)*A(4,3))+A(1,3)*(A(2,4)*A(4,2) &
                            -A(2,2)*A(4,4))+A(1,4)*(A(2,2)*A(4,3)-A(2,3)*A(4,2)))
    B(2,3) = detinv*(A(1,1)*(A(2,4)*A(4,3)-A(2,3)*A(4,4))+A(1,3)*(A(2,1)*A(4,4) &
                            -A(2,4)*A(4,1))+A(1,4)*(A(2,3)*A(4,1)-A(2,1)*A(4,3)))
    B(3,3) = detinv*(A(1,1)*(A(2,2)*A(4,4)-A(2,4)*A(4,2))+A(1,2)*(A(2,4)*A(4,1) &
                            -A(2,1)*A(4,4))+A(1,4)*(A(2,1)*A(4,2)-A(2,2)*A(4,1)))
    B(4,3) = detinv*(A(1,1)*(A(2,3)*A(4,2)-A(2,2)*A(4,3))+A(1,2)*(A(2,1)*A(4,3) &
                            -A(2,3)*A(4,1))+A(1,3)*(A(2,2)*A(4,1)-A(2,1)*A(4,2)))
    B(1,4) = detinv*(A(1,2)*(A(2,4)*A(3,3)-A(2,3)*A(3,4))+A(1,3)*(A(2,2)*A(3,4) &
                            -A(2,4)*A(3,2))+A(1,4)*(A(2,3)*A(3,2)-A(2,2)*A(3,3)))
    B(2,4) = detinv*(A(1,1)*(A(2,3)*A(3,4)-A(2,4)*A(3,3))+A(1,3)*(A(2,4)*A(3,1) &
                            -A(2,1)*A(3,4))+A(1,4)*(A(2,1)*A(3,3)-A(2,3)*A(3,1)))
    B(3,4) = detinv*(A(1,1)*(A(2,4)*A(3,2)-A(2,2)*A(3,4))+A(1,2)*(A(2,1)*A(3,4) &
                            -A(2,4)*A(3,1))+A(1,4)*(A(2,2)*A(3,1)-A(2,1)*A(3,2)))
    B(4,4) = detinv*(A(1,1)*(A(2,2)*A(3,3)-A(2,3)*A(3,2))+A(1,2)*(A(2,3)*A(3,1) &
                            -A(2,1)*A(3,3))+A(1,3)*(A(2,1)*A(3,2)-A(2,2)*A(3,1)))
  end function

  function gaussji(c,d,n) result(a)
    !Linear equation solution by Gauss-Jordan elimination, used to find inverse of matrix c.
    !possibly slow for large "c" (LAPACK better?)
    !c needs to be square and have dimension n
    !c(1:n,1:n) is an input matrix stored in an array of physical dimensions n by n.
    !d(1:n,1:n) is an input matrix containing the n by n identity matrix.
    !On  output, a(1:n,1:n) (and b(1:n,1:n)) are the inverse of c
    !Parameter: NMAX is  the  largest  anticipated  value  of n.

    integer :: n
    real, intent(in) :: c(n,n) !WILL BE OVERWRITTEN!!
    real, intent(in) :: d(n, n)
    real :: a(n,n),b(n,n)
    integer, parameter :: NMAX = 50
    integer :: m, i, icol, irow, j, k, l, ll, indxc(NMAX), indxr(NMAX), ipiv(NMAX)
    !The integer arrays ipiv, indxr, and indxc are  used for bookkeeping  on the pivoting.
    REAL :: big, dum, pivinv
    a=c
    b=d
    m=n
    do j = 1, n
      ipiv(j) = 0
    end do
    do i = 1, n !This  is  the  main  loop  over  the  columns  to  be  reduced.
      big = 0.
      do j = 1, n !This  is  the  outer  loop  of  the  search  for  a  pivot  element.
        if (ipiv(j) .ne. 1) then
          do k = 1, n
            if (ipiv(k) .eq. 0) then
              if (abs(a(j, k)) .ge. big) then
                big = abs(a(j, k))
                irow = j
                icol = k
              endif
              !else if (ipiv(k).gt.1) then
              !pause 'singular matrix in gaussj'
            end if
          end do
        end if
      end do
      ipiv(icol) = ipiv(icol) + 1
      !We  now  have  the  pivot  element,  so  we  interchange  rows,  if  needed,  to  put  the  pivot
      !element  on  the  diagonal.  The  columns  are  not  physically  interchanged,  only  relabeled:
      !indxc(i), the column of the ith pivot element, is the ith column that is reduced, while
      !indxr(i) is  the  row in  which  that  pivot  element  was  originally  located.  If
      !indxr(i) /= indxc(i) there  is  an  implied  column  interchange.  With  this  form  of  bookkeeping,  the
      !solution b's  will  end  up  in  the  correct  order,  and  the  inverse  matrix  will  be  scrambled by  columns
      if (irow .ne. icol) then
        do l = 1, n
          dum = a(irow, l)
          a(irow, l) = a(icol, l)
          a(icol, l) = dum
        end do
        do l = 1, m
          dum = b(irow, l)
          b(irow, l) = b(icol, l)
          b(icol, l) = dum
        enddo
      endif
      !We are now ready to divide the pivot row by the pivot element, located at irow and icol.
      indxr(i) = irow
      indxc(i) = icol
      !if (a(icol,icol).eq.0.) pause 'singular matrix in gaussj'
      pivinv = 1./a(icol, icol)
      a(icol, icol) = 1.
      do l = 1, n
        a(icol, l) = a(icol, l)*pivinv
      end do
      do l = 1, m
        b(icol, l) = b(icol, l)*pivinv
      end do
      do ll = 1, n
        !Next,  we  reduce  the  rows, except for the  pivot  one, of course.
        if (ll .ne. icol) then
          dum = a(ll, icol)
          a(ll, icol) = 0.
          do l = 1, n
            a(ll, l) = a(ll, l) - a(icol, l)*dum
          end do
          do l = 1, m
            b(ll, l) = b(ll, l) - b(icol, l)*dum
          end do
        end if
      end do
    end do
    !This is the end of the main loop over columns of the reduction.
    do l = n, 1, -1
      !It  only  remains  to  unscramble  the  solution  in  view
      !of  the  column  interchanges.  We  do  this  by  in-
      !terchanging pairs of columns in the reverse order
      !that the permutation was built  up.
      if (indxr(l) .ne. indxc(l)) then
        do k = 1, n
          dum = a(k, indxr(l))
          a(k, indxr(l)) = a(k, indxc(l))
          a(k, indxc(l)) = dum
        end do
      end if
    end do
    return
    !And  we  are  done.
  end function gaussji

  subroutine intqH !time integration of heat and latent heat from facets
    use modglobal, only:nfcts, dt, rk3step, lEB
    use initfac, only:faccth, fachfsum, fachf, fachfi, facef, facefi, facefsum
    use modmpi, only:nprocs, myid, comm3d, mpierr, mpi_sum, my_real
    real :: dummy
    integer :: n

    if (.not. lEB) return

    if (rk3step .eq. 3) then
      !sum over all processors since a facet can be split onto more than one processor
      fachfsum = 0.
      facefsum = 0.
      call MPI_ALLREDUCE(fachf(1:nfcts), fachfsum(1:nfcts), nfcts, MY_REAL, MPI_SUM, comm3d, mpierr)
      call MPI_ALLREDUCE(facef(1:nfcts), facefsum(1:nfcts), nfcts, MY_REAL, MPI_SUM, comm3d, mpierr)

      if (myid == 0) then
        !time summation of total facet heatlux (will be divided by dtEB in EB to get time mean flux)
        do n = 1, nfcts
          fachfi(n) = fachfi(n) + dt*fachfsum(n) !sum up the fluxes over time
          facefi(n) = facefi(n) + dt*facefsum(n)
        end do
      end if
    end if
    fachf = 0.
    fachfsum = 0.
    facefsum = 0.
    facef = 0.
  end subroutine intqH

  subroutine initEB
    !initialise everything necessary to calculate the energy balance
    use modglobal, only:AM, BM,CM,DM,EM,FM,GM, HM, IDM, inAM, bb,w,dumv,Tdash, bldT, nfcts,nfaclyrs
    use initfac, only:facd, faccp, faclam, fackappa, netsw, facem, fachf, facef, fachfi, facT, facLWin,facefi,facwsoil,facf,facets,facTdash,facqsat,facf,fachurel
    use modmpi, only:myid, comm3d, mpierr, MPI_INTEGER, MPI_DOUBLE_PRECISION, MY_REAL, nprocs, cmyid, MPI_REAL8, MPI_REAL4, MPI_SUM
    use modstat_nc,only: open_nc, define_nc,ncinfo,writestat_dims_nc
    integer :: i,j,k,l,m,n
    real :: dum

    if (.not. lEB) return

    allocate(AM(1:nfaclyrs+1,1:nfaclyrs+1))
    allocate(inAM(1:nfaclyrs+1,1:nfaclyrs+1))
    allocate(CM(1:nfaclyrs+1,1:nfaclyrs+1))
    allocate(bb(1:nfaclyrs+1))
    allocate(BM(1:nfaclyrs+1,1:nfaclyrs+1))
    allocate(DM(1:nfaclyrs+1,1:nfaclyrs+1))
    allocate(EM(1:nfaclyrs+1,1:nfaclyrs+1))
    allocate(FM(1:nfaclyrs+1,1:nfaclyrs+1))
    allocate(GM(1:nfaclyrs+1,1:nfaclyrs+1))
    allocate(HM(1:nfaclyrs+1,1:nfaclyrs+1))
    allocate(IDM(1:nfaclyrs+1,1:nfaclyrs+1))
    allocate(w(1:nfaclyrs+1))
    allocate(dumv(1:nfaclyrs+1))
    allocate(Tdash(1:nfaclyrs+1))

    BM=0.;DM=0.;EM=0.;FM=0.;GM=0.;HM=0.;w=0.;dumv=0.;Tdash=0.;
    AM=0.;inAM=0.;CM=0.;IDM=0.;bb=0.
    do j=1,nfaclyrs+1
      IDM(j,j)=1.0
    end do
    !Fortran is column major, i.e. left dimensions should be iterated first
    ! e.g.  (1,1)->(2,1)->(3,1)->(1,2)->... since they are next to each other on memory
    !first index moves "up and down" second "left and right" (as always)
    m=1; !position along columns
    do j=2,nfaclyrs+1
      AM(j,m)=0.5
      AM(j,m+1)=0.5
      m=m+1
    end do
    AM(1,1)=1.0
    if (nfaclyrs == 3) then
      inAM = matinv4(AM)
      !!alternatively
      !inAM=matinv3(AM)
      !!or
    else
      inAM=gaussji(AM,IDM,nfaclyrs+1)
    end if

    ! write facet temperatures to facT.xxx.nc, and energies to facEB.xxx.nc
    if (lwriteEBfiles) then
      Tname(6:8) = cexpnr
      EBname(7:9) = cexpnr

      allocate(ncstatT(nstatT,4))
      call ncinfo(tncstatT(1,:),'t', 'Time', 's', 'time')
      call ncinfo(ncstatT( 1,:),'T' ,'Temperature', 'K','flt')
      call ncinfo(ncstatT( 2,:),'dTdz','Temperature gradient','K/m','flt' )

      allocate(ncstatEB(nstatEB,4))
      call ncinfo(tncstatEB(1,:),'t', 'Time', 's', 'time')
      call ncinfo(ncstatEB( 1,:),'netsw', 'Net shortwave', 'W/m^2','ft')
      call ncinfo(ncstatEB( 2,:),'LWin', 'Incoming longwave', 'W/m^2','ft')
      call ncinfo(ncstatEB( 3,:),'LWout', 'Outgoing longwave', 'W/m^2','ft')
      call ncinfo(ncstatEB( 4,:),'hf', 'Sensible heat', 'W/m^2','ft')
      call ncinfo(ncstatEB( 5,:),'ef', 'Latent heat', 'W/m^2','ft')
      call ncinfo(ncstatEB( 6,:),'WGR','Water content', '?','ft')


      if (myid==0) then
        call open_nc(Tname, ncidT, nrecT, nfcts=nfcts, nlyrs=nfaclyrs+1)
        call open_nc(EBname, ncidEB, nrecEB, nfcts=nfcts)
        if (nrecT==0) then
          call define_nc( ncidT, 1, tncstatT)
          call writestat_dims_nc(ncidT)
        end if
        if (nrecEB==0) then
          call define_nc( ncidEB, 1, tncstatEB)
          call writestat_dims_nc(ncidEB)
        end if
        call define_nc( ncidT, nstatT, ncstatT)
        call define_nc( ncidEB, nstatEB, ncstatEB)
      endif !myid==0
    end if

  end subroutine initEB

  subroutine calclw
    !calculate the longwave exchange between facets
    use modglobal, only:nfcts, boltz, skyLW, nnz
    use initfac, only:facem, vf, svf, faca, facT, facLWin, facets, vfsparse, ivfsparse, jvfsparse
    integer :: n, m, i, j
    real :: ltemp = 0.

    if (lvfsparse) then
         facLWin = svf*skyLW*facem
         do n=1,nnz
            i = ivfsparse(n)
            j = jvfsparse(n)
            facLWin(i) = facLWin(i) + vfsparse(n)*facem(i)*facem(j)*boltz*facT(j,1)**4
         end do

      else
         do n = 1, nfcts
            !if (facets(n) < -100) cycle
            ltemp = 0.
            do m = 1, nfcts  !for n, sum over all other m facets
               !ltemp = ltemp + vf(m, n)*faca(m)/faca(n)*facem(m)*boltz*facT(m, 1)**4 ![W/m2]
               ltemp = ltemp + vf(n, m)*facem(m)*boltz*facT(m, 1)**4 ![W/m2]
            end do
            facLWin(n) = (ltemp + svf(n)*skyLW)*facem(n)

         end do
      end if

  end subroutine calclw


  subroutine updateGR
    !updates soil and vegetation resistance to evaporation
    !updates soil moisture
    !
    ! based on ERA40 surface scheme
    ! van den Hurk 2000
    ! plants
    ! E = max(0,vegetation% * rhoa * (qa-qsat(TGR)) * 1/(rc+ra)) !no dew!!
    ! rc=rsmin/LAI*f1(K)*f2(WGS)*f3(D)*f4(T)
    ! ra,qa,qsat
    ! f3(D) is 1 for small plants
    ! bare soil
    ! E = max(0,(1-vegetation%) * rhoa * (qa-qsat(TGR)*hu) * (1/(rs+ra))

    use modglobal, only:nfcts, rlv, rlvi, rhoa, cp, wfc, wwilt, wsoil, rsmin, GRLAI, tEB, rsmax, lconstW
    use initfac, only:netSW, faccth, fachurel, faclGR, facwsoil, facf, facef, facT, facefi, facqsat, facd, faca, qsat

    integer :: n
    real :: vfraction = 0.8 !fraction of GR covered in vegetation, should be made into a proper model parameter (-> modglobal)
    real :: dum
    do n = 1, nfcts

      if (faclGR(n)) then
        !facefi is actually the accumulated moisture flux, has to be converted to energy flux to calculate temperature
        !yet actually the moisture flux is needed for water budget, i.e. currently many operations cancel each other e.g. X*Lv/Lv
        !facefi is the sum over all gridcells of a facet, thus has to be averaged by dividing by number of cells in that facet
        !units of facefi are kgW/kgA*m/s
        facefi(n) = facefi(n)/tEB/faca(n)*rhoa*rlv !mean heat flux since last EB calculation (time average)

        if (.not. lconstW) then !remove water from soil
          facwsoil(n) = max(facwsoil(n) + facefi(n)*tEB*rlvi/facd(n, 1), 0.) !ils13, careful this assumes water only being present in the first layer!!!
        end if

        !update canopy resistance used in wf_gr
        fachurel(n) = max(min(1.0, 0.5*(1.0 - cos(3.14159*facwsoil(n)/wfc))), 0.) !relative humidity above soil
        facf(n, 1) = 1./min(1.0, (0.004*netSW(n) + 0.05)/(0.81*(0.004*netSW(n) + 1))) !f1
        facf(n, 2) = 1./min(max(0.001, (facwsoil(n) - wwilt)/(wfc - wwilt)), 1.0) !f2
        !f3 drops out because it is for high vegetation only
        facf(n, 3) = 1./max((1 - 0.0016*(298-facT(n, 1))**2), 0.001) !f4
        !store resistance for plants
        facf(n, 4) = min(rsmin/GRLAI*facf(n, 1)*facf(n, 2)*facf(n, 3), rsmax)
        !store resistance for soil
        facf(n, 5) = min(rsmin*facf(n, 2), rsmax)
        dum = facT(n, 1)
        facqsat(n) = qsat(dum)
      end if
    end do

  end subroutine updateGR

  subroutine EB
    !calculates the energy balance for every facet
    use modglobal, only: nfcts, boltz, tEB, AM, BM,CM,DM,EM,FM,GM,HM, inAM, bb,w, dumv,Tdash, timee, tnextEB, rk3step, rhoa, cp, lEB, ntrun, lwriteEBfiles,nfaclyrs
    use initfac, only: faclam, faccp, netsw, facem, fachf, facef, fachfi, facT, facLWin, faca,facefi,facf,facets,facTdash,facqsat,facwsoil,facf,fachurel,facd,fackappa
    use modmpi, only: myid, comm3d, mpierr, MPI_INTEGER, MPI_DOUBLE_PRECISION, MY_REAL, nprocs, cmyid, MPI_REAL8, MPI_REAL4, MPI_SUM
    use modstat_nc, only : writestat_nc, writestat_1D_nc, writestat_2D_nc
    real  :: ca = 0., cb = 0., cc = 0., cd = 0., ce = 0., cf = 0.
    real  :: ab = 0.
    integer :: l, n, m,i,j
    character(19) name

    if (.not. (lEB)) return
    !calculate latent heat flux from vegetation and soil
    call intqH
    !calculate energy balance, update facet temperature and soil moisture
    if ((rk3step .eq. 3) .and. (timee .ge. tnextEB)) then

      if (myid .eq. 0) then
        tEB = timee - tEB !time since last calculation of energy balance
        !write (*, *) "doing EB, time since last EB:", tEB

        !calculate time mean, facet area mean latent heat flux and update green roof
        !ILS13 02.05.18 ABOUT updateGR: convert latent heatflux E properly should be done before temperature calculatation. BUT the rest of updateGR should be done after!
        !update green roof
        call updateGR

        !get longwave fluxes for all facets
        call calclw

        !get time mean, facet area mean sensible heat flux
        do n = 1, nfcts
          fachfi(n) = fachfi(n)/tEB/faca(n)*rhoa*cp !mean heat flux since last EB calculation (time average)
          !since fachf is the sum over all cells making up a facet we need to divide by the number of cells, assuming a given density to convert to W/m2
        end do

        !solve the system:
        !see Suter 2018
        !A * T'= bb + B * T,   where T' = dT/dz
        !C * d/dtT + D d/dtT'= e * T'
        !
        !-> T(n+1)=(F-G*dt)^-1*(F*T+w*dt)
        !where F=(C + D*A^-1*B), G=(E*A^-1*B), w=(E*A^-1*bb)


        do n = 1, nfcts
          if (facets(n) < -100) cycle

          !calculate wallflux and update surface temperature
          !! define time dependent fluxes
          ab = boltz*facem(n)*(facT(n, 1)**3)/faclam(n, 1) ! ab*T is the Stefan-Boltzman law
          bb(1) = -(netsw(n) + facLWin(n) + fachfi(n) + facefi(n))/faclam(n, 1) !net surface flux

          !!define the matrices to solve wall heat flux
          !! CREATE MATRICES BASED ON WALL PROPERTIES
          i=1;m=0; !position along columns, placeholder for layerindex since only 3 layers implemented (initfac.f90)
          do j=1,nfaclyrs
            m=j  !!CARE!!! ONLY 3 LAYERS ARE CURRENTLY BEING READ FROM INPUT FILES. PROPERTIES OF LAYER 3 ARE USED FOR SUBSEQUENT LAYERS!!!
            ca=1./facd(n,m)
            BM(j+1,i)=-ca
            BM(j+1,i+1)=ca
            EM(j,i)=-faclam(n,m)
            EM(j,i+1)=faclam(n,m+1)
            cb=faccp(n,m)*facd(n,m)/2.
            CM(j,i)=cb
            CM(j,i+1)=cb
            ca=faccp(n,m)*facd(n,m)**2/12.
            DM(j,i)=ca
            DM(j,i+1)=-ca
            i=i+1
          end do
          CM(nfaclyrs+1,nfaclyrs+1)=1.
          BM(1,1)=ab


          w = matmul(EM, matmul(inAM,bb))*tEB !easier than loop and sum
          HM = matmul(inAM,BM)
          FM = CM + matmul(DM,HM)
          GM = matmul(EM,HM)
          HM = FM-GM*tEB
          if (nfaclyrs == 3) then
            GM = matinv4(HM)
          else
            GM = gaussji(HM,IDM,nfaclyrs+1)
          end if
          !instead of inverting matrix HM and multiplying by GM (=HM^-1) it would be waster to do a  left matrix division HM\x is faster than (HM^-1)*x
          dumv = matmul(GM, (matmul(FM,facT(n,:))+w))

          facT(n, :) = dumv
          !calculate Temperature gradient dT/dz=>Tdash so we can output it
          !ground heat flux = lambda dT/dz
          w = matmul(BM, dumv)
          facTdash(n, :) = matmul(inAM, (bb + w))

          !end if
        end do

        if (lwriteEBfiles) then
          if (myid == 0) then
            allocate(varsT(nfcts,nfaclyrs+1,nstatT))
            varsT(:,:,1) = facT(1:nfcts,1:nfaclyrs+1)
            varsT(:,:,2) = facTdash(1:nfcts,1:nfaclyrs+1)
            call writestat_nc(ncidT,1,tncstatT,(/timee/),nrecT,.true.)
            call writestat_2D_nc(ncidT,nstatT,ncstatT,varsT,nrecT,nfcts,nfaclyrs+1)
            deallocate(varsT)

            allocate(varsEB(nfcts,nstatEB))
            varsEB(:,1) = netsw(1:nfcts)
            varsEB(:,2) = facLWin(1:nfcts)
            varsEB(:,3) = boltz*facem(1:nfcts)*facT(1:nfcts,1)**4
            varsEB(:,4) = fachfi(1:nfcts)
            varsEB(:,5) = facefi(1:nfcts)
            varsEB(:,6) = facwsoil(1:nfcts)
            ! add longwave out
            call writestat_nc(ncidEB,1,tncstatEB,(/timee/),nrecEB,.true.)
            call writestat_1D_nc(ncidEB,nstatEB,ncstatEB,varsEB,nrecEB,nfcts)
            deallocate(varsEB)

          end if !myid
        end if

        tEB = timee !set time of last calculation of energy balance to current time
        tnextEB = NINT((timee + dtEB))*1.0  !rounded to nearest integer  (e.g. if current time is 10.013s and dtEb=10s, then the next energy balance will be calculated at t>=20s)
        !write (*, *) "time, time next EB", timee, tnextEB

        do n = 1, nfcts
          fachfi(n) = 0.
          facefi(n) = 0.
        end do
      end if !myid==0

      !write (*, *) "bcasting facT"
      call MPI_BCAST(facT(0:nfcts, 1:nfaclyrs+1), (nfaclyrs+1)*(nfcts + 1), MY_REAL, 0, comm3d, mpierr)
      call MPI_BCAST(tnextEB, 1, MY_REAL, 0, comm3d, mpierr)
      call MPI_BCAST(facqsat(0:nfcts), nfcts + 1, MY_REAL, 0, comm3d, mpierr)
      call MPI_BCAST(facf(0:nfcts, 1:5), (nfcts + 1)*5, MY_REAL, 0, comm3d, mpierr)
      call MPI_BCAST(fachurel(0:nfcts), nfcts + 1, MY_REAL, 0, comm3d, mpierr)
      !call MPI_BCAST(facwsoil(0:nfcts), nfcts + 1, MY_REAL, 0, comm3d, mpierr)
    end if !time>tnextEB

  end subroutine EB

end module modEB
