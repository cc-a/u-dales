!!> \file modibm.f90
!!!  adds forcing terms for immersed boundaries
!
!>
!!  \author Jasper Thomas TU Delft / Ivo Suter Imperial College London
!
!  This file is part of DALES.
!
! DALES is free software; you can redistribute it and/or modify
! it under the terms of the GNU General Public License as published by
! the Free Software Foundation; either version 3 of the License, or
! (at your option) any later version.
!
! DALES is distributed in the hope that it will be useful,
! but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
! GNU General Public License for more details.
!
! You should have received a copy of the GNU General Public License
! along with this program.  If not, see <http://www.gnu.org/licenses/>.
!
!  Copyright 1993-2009 Delft University of Technology, Wageningen University, Utrecht University, KNMI
!
module modibm
   use modibmdata
   !use wf_uno
   implicit none
   save
   public :: initibm, ibmnorm, ibmwallfun, bottom, lbottom, createmasks, &
             nsolpts_u, nsolpts_v, nsolpts_w, nsolpts_c, &
             nbndpts_u, nbndpts_v, nbndpts_w, nbndpts_c, &
             nfctsecs_u, nfctsecs_v, nfctsecs_w, nfctsecs_c, &
             mask_u, mask_v, mask_w, mask_c

    abstract interface
      function interp_velocity(i,j,k)
        real :: interp_velocity(3)
        integer, intent(in) :: i, j, k
      end function interp_velocity
    end interface

    abstract interface
      real function interp_temperature(i,j,k)
        integer, intent(in) :: i, j, k
      end function interp_temperature
    end interface

   logical :: lbottom = .true.

   ! read from namoptions
   integer :: nsolpts_u, nsolpts_v, nsolpts_w, nsolpts_c, &
              nbndpts_u, nbndpts_v, nbndpts_w, nbndpts_c, &
              nfctsecs_u, nfctsecs_v, nfctsecs_w, nfctsecs_c

   real, allocatable, target, dimension(:,:,:) :: mask_u, mask_v, mask_w, mask_c

   TYPE solid_info_type
     integer :: nsolpts
     integer, allocatable :: solpts(:,:)
     logical, allocatable :: lsolptsrank(:) !
     integer, allocatable :: solptsrank(:) ! indices of points on current rank
     integer :: nsolptsrank
   end TYPE solid_info_type

   type(solid_info_type) :: solid_info_u, solid_info_v, solid_info_w, solid_info_c

   TYPE bound_info_type
     integer :: nbndpts
     integer, allocatable :: bndpts(:,:) ! ijk location of fluid boundary point
     real, allocatable    :: intpts(:,:) ! xyz location of boundary intercept point
     real, allocatable    :: bndvec(:,:) ! vector from boundary to fluid point (normalised)
     real, allocatable    :: recpts(:,:) ! xyz location of reconstruction point
     integer, allocatable :: recids(:,:) ! ijk location of cell that rec point is in
     real, allocatable    :: bnddst(:) ! distance between surface & bound point
     integer, allocatable :: bndptsrank(:) ! indices of points on current rank
     logical, allocatable :: lcomprec(:) ! Switch whether reconstruction point is a computational point
     logical, allocatable :: lskipsec(:) ! Switch whether to skip finding the shear stress at this point
     integer :: nbndptsrank

     integer :: nfctsecs
     integer, allocatable :: secbndptids(:)
     integer, allocatable :: secfacids(:)
     real,    allocatable :: secareas(:)
     integer, allocatable :: fctsecsrank(:)
     integer :: nfctsecsrank
   end TYPE bound_info_type

   type(bound_info_type) :: bound_info_u, bound_info_v, bound_info_w, bound_info_c

   ! !u
   ! integer, allocatable :: solpts_u(:,:)
   ! logical, allocatable :: lsolptsrank_u(:) !
   ! integer, allocatable :: solptsrank_u(:) ! indices of points on current rank
   ! integer :: nsolptsrank_u
   !
   !
   ! integer, allocatable :: bndpts_u(:,:) ! ijk location of fluid boundary point
   ! real, allocatable    :: intpts_u(:,:) ! xyz location of boundary intercept point
   ! real, allocatable    :: bndvec_u(:,:) ! vector from boundary to fluid point (normalised)
   ! real, allocatable    :: recpts_u(:,:) ! xyz location of reconstruction point
   ! integer, allocatable :: recids_u(:,:) ! ijk location of cell that rec point is in
   ! real, allocatable    :: bnddst_u(:) ! distance between surface & bound point
   ! !logical, allocatable :: lbndptsrank_u(:) !
   ! integer, allocatable :: bndptsrank_u(:) ! indices of points on current rank
   ! logical, allocatable :: lcomprec_u(:) ! Switch whether reconstruction point is a computational point
   ! logical, allocatable :: lskipsec_u(:) ! Switch whether to skip finding the shear stress at this point
   ! integer :: nbndptsrank_u
   !
   ! integer, allocatable :: secbndptids_u(:)
   ! integer, allocatable :: secfacids_u(:)
   ! real,    allocatable :: secareas_u(:)
   !
   ! !logical, allocatable :: lfctsecsrank_u(:)
   ! integer, allocatable :: fctsecsrank_u(:)
   ! integer :: nfctsecsrank_u
   !
   !
   ! ! v
   ! integer, allocatable :: solpts_v(:,:)
   ! logical, allocatable :: lsolptsrank_v(:) !
   ! integer, allocatable :: solptsrank_v(:) ! indices of points on current rank
   ! integer :: nsolptsrank_v
   !
   ! integer, allocatable :: bndpts_v(:,:) ! ijk location of fluid boundary point
   ! real, allocatable    :: intpts_v(:,:) ! xyz location of boundary intercept point
   ! real, allocatable    :: bndvec_v(:,:) ! vector from boundary point to fluid point (normalised)
   ! real, allocatable    :: recpts_v(:,:) ! xyz location of reconstruction point
   ! integer, allocatable :: recids_v(:,:) ! ijk location of cell that rec point is in
   ! real, allocatable    :: bnddst_v(:) ! distance between surface & bound point
   ! !logical, allocatable :: lbndptsrank_v(:) !
   ! integer, allocatable :: bndptsrank_v(:) ! indices of points on current rank
   ! logical, allocatable :: lcomprec_v(:) ! Switch whether reconstruction point is a computational point
   ! logical, allocatable :: lskipsec_v(:) ! Switch whether to skip finding the shear stress at this point
   ! integer :: nbndptsrank_v
   !
   ! integer, allocatable :: secbndptids_v(:)
   ! integer, allocatable :: secfacids_v(:)
   ! real,    allocatable :: secareas_v(:)
   !
   ! !logical, allocatable :: lfctsecsrank_v(:)
   ! integer, allocatable :: fctsecsrank_v(:)
   ! integer :: nfctsecsrank_v
   !
   ! !w
   ! integer, allocatable :: solpts_w(:,:)
   ! logical, allocatable :: lsolptsrank_w(:) !
   ! integer, allocatable :: solptsrank_w(:) !
   ! integer :: nsolptsrank_w
   !
   ! integer, allocatable :: bndpts_w(:,:) ! ijk location of fluid boundary point
   ! real, allocatable    :: intpts_w(:,:) ! xyz location of reconstruction point
   ! real, allocatable    :: bndvec_w(:,:) ! vector from boundary to fluid point (normalised)
   ! real, allocatable    :: recpts_w(:,:) ! xyz location of reconstruction point
   ! integer, allocatable :: recids_w(:,:) ! ijk location of cell that rec point is in
   ! real, allocatable    :: bnddst_w(:) ! distance between surface & bound point
   ! !logical, allocatable :: lbndptsrank_w(:) !
   ! integer, allocatable :: bndptsrank_w(:) ! indices of points on current rank
   ! logical, allocatable :: lcomprec_w(:) ! Switch whether reconstruction point is a computational point
   ! logical, allocatable :: lskipsec_w(:) ! Switch whether to skip finding the shear stress at this point
   ! integer :: nbndptsrank_w
   !
   ! integer, allocatable :: secbndptids_w(:)
   ! integer, allocatable :: secfacids_w(:)
   ! real,    allocatable :: secareas_w(:)
   !
   ! !logical, allocatable :: lfctsecsrank_w(:)
   ! integer, allocatable :: fctsecsrank_w(:)
   ! integer :: nfctsecsrank_w
   !
   ! ! c
   ! integer, allocatable :: solpts_c(:,:)
   ! logical, allocatable :: lsolptsrank_c(:) !
   ! integer, allocatable :: solptsrank_c(:) !
   ! integer :: nsolptsrank_c
   !
   ! integer, allocatable :: bndpts_c(:,:) ! ijk location of fluid boundary point
   ! real, allocatable    :: intpts_c(:,:) ! xyz location of boundary point
   ! real, allocatable    :: bndvec_c(:,:) ! vector from boundary to fluid point (normalised)
   ! real, allocatable    :: recpts_c(:,:) ! xyz location of reconstruction point
   ! integer, allocatable :: recids_c(:,:) ! ijk location of cell that rec point is in
   ! real, allocatable    :: bnddst_c(:) ! distance between surface & bound point
   ! !logical, allocatable :: lbndptsrank_w(:) !
   ! integer, allocatable :: bndptsrank_c(:) ! indices of points on current rank
   ! logical, allocatable :: lcomprec_c(:) ! Switch whether reconstruction point is a computational point
   ! logical, allocatable :: lskipsec_c(:) ! Switch whether to skip finding the shear stress at this point
   ! integer :: nbndptsrank_c
   !
   ! integer, allocatable :: secbndptids_c(:)
   ! integer, allocatable :: secfacids_c(:)
   ! real,    allocatable :: secareas_c(:)
   !
   ! !logical, allocatable :: lfctsecsrank_w(:)
   ! integer, allocatable :: fctsecsrank_c(:)
   ! integer :: nfctsecsrank_c
   ! !real, allocatable :: fctsecscth(:)

   contains

   subroutine initibm
     use modglobal, only : libm, xh, xf, yh, yf, zh, zf, xhat, yhat, zhat, &
                           ib, ie, ih, ihc, jb, je, jh, jhc, kb, ke, kh, khc, iwallmom, lmoist, ltempeq
     use decomp_2d, only : exchange_halo_z

     real, allocatable :: rhs(:,:,:)

     if (.not. libm) return


     ! call initibmnorm_old('solid_u.txt', nsolpts_u, solpts_u, nsolptsrank_u, solptsrank_u)
     ! call initibmnorm_old('solid_v.txt', nsolpts_v, solpts_v, nsolptsrank_v, solptsrank_v)
     ! call initibmnorm_old('solid_w.txt', nsolpts_w, solpts_w, nsolptsrank_w, solptsrank_w)

     solid_info_u%nsolpts = nsolpts_u
     solid_info_v%nsolpts = nsolpts_v
     solid_info_w%nsolpts = nsolpts_w
     call initibmnorm('solid_u.txt', solid_info_u)
     call initibmnorm('solid_v.txt', solid_info_v)
     call initibmnorm('solid_w.txt', solid_info_w)

     write(*,*) 'done initibmnorm'
     ! Define (real) masks
     ! Hopefully this can be removed eventually if (integer) IIx halos can be communicated
     ! These are only used in modibm, to cancel subgrid term across solid boundaries
     allocate(mask_u(ib-ihc:ie+ihc,jb-jhc:je+jhc,kb-khc:ke+khc)); mask_u = 1.
     allocate(mask_v(ib-ihc:ie+ihc,jb-jhc:je+jhc,kb-khc:ke+khc)); mask_v = 1.
     allocate(mask_w(ib-ihc:ie+ihc,jb-jhc:je+jhc,kb-khc:ke+khc)); mask_w = 1.
     mask_w(:,:,kb) = 0.     ! In future this shouldn't be needed?
     mask_u(:,:,kb-khc) = 0.
     mask_v(:,:,kb-khc) = 0.
     mask_w(:,:,kb-khc) = 0.

     allocate(rhs(ib-ih:ie+ih,jb-jh:je+jh,kb:ke+kh))
     ! call solid_old(nsolpts_u, solpts_u, nsolptsrank_u, solptsrank_u, mask_u, rhs, 0.)
     ! call solid_old(nsolpts_v, solpts_v, nsolptsrank_v, solptsrank_v, mask_v, rhs, 0.)
     ! call solid_old(nsolpts_w, solpts_w, nsolptsrank_w, solptsrank_w, mask_w, rhs, 0.)
     call solid(solid_info_u, mask_u, rhs, 0.)
     call solid(solid_info_v, mask_v, rhs, 0.)
     call solid(solid_info_w, mask_w, rhs, 0.)

          write(*,*) 'done masks'
     call exchange_halo_z(mask_u, opt_zlevel=(/ihc,jhc,0/))
     call exchange_halo_z(mask_v, opt_zlevel=(/ihc,jhc,0/))
     call exchange_halo_z(mask_w, opt_zlevel=(/ihc,jhc,0/))

     if (iwallmom > 1) then
     ! call initibmwallfun('fluid_boundary_u.txt', 'facet_sections_u.txt', xh, yf, zf, xhat, &
     !                     nbndpts_u, bndpts_u, bnddst_u, intpts_u, bndvec_u, lcomprec_u, lskipsec_u, nbndptsrank_u, bndptsrank_u, &
     !                     nfctsecs_u, secfacids_u, secareas_u, secbndptids_u, recpts_u, recids_u, nfctsecsrank_u, fctsecsrank_u)
     !
     ! call initibmwallfun('fluid_boundary_v.txt', 'facet_sections_v.txt', xf, yh, zf, yhat, &
     !                     nbndpts_v, bndpts_v, bnddst_v, intpts_v, bndvec_v, lcomprec_v, lskipsec_v, nbndptsrank_v, bndptsrank_v, &
     !                     nfctsecs_v, secfacids_v, secareas_v, secbndptids_v, recpts_v, recids_v, nfctsecsrank_v, fctsecsrank_v)
     !
     ! call initibmwallfun('fluid_boundary_w.txt', 'facet_sections_w.txt', xf, yf, zh, zhat, &
     !                    nbndpts_w, bndpts_w, bnddst_w, intpts_w, bndvec_w, lcomprec_w, lskipsec_w, nbndptsrank_w, bndptsrank_w, &
     !                    nfctsecs_w, secfacids_w, secareas_w, secbndptids_w, recpts_w, recids_w, nfctsecsrank_w, fctsecsrank_w)

       bound_info_u%nbndpts = nbndpts_u
       bound_info_v%nbndpts = nbndpts_v
       bound_info_w%nbndpts = nbndpts_w
       bound_info_u%nfctsecs = nfctsecs_u
       bound_info_v%nfctsecs = nfctsecs_v
       bound_info_w%nfctsecs = nfctsecs_w
       call initibmwallfun('fluid_boundary_u.txt', 'facet_sections_u.txt', xh, yf, zf, xhat, bound_info_u)
       call initibmwallfun('fluid_boundary_v.txt', 'facet_sections_v.txt', xf, yh, zf, yhat, bound_info_v)
       call initibmwallfun('fluid_boundary_w.txt', 'facet_sections_w.txt', xf, yf, zh, zhat, bound_info_w)
     end if

     if (ltempeq .or. lmoist) then
       !call initibmnorm_old('solid_c.txt', nsolpts_c, solpts_c, nsolptsrank_c, solptsrank_c)
       solid_info_c%nsolpts = nsolpts_c
       call initibmnorm('solid_c.txt', solid_info_c)
       ! call initibmwallfun_old('fluid_boundary_c.txt', 'facet_sections_c.txt', xf, yf, zf, (/0.,0.,0./), &
       ! nbndpts_c, bndpts_c, bnddst_c, intpts_c, bndvec_c, lcomprec_c, lskipsec_c, nbndptsrank_c, bndptsrank_c, &
       ! nfctsecs_c, secfacids_c, secareas_c, secbndptids_c, recpts_c, recids_c, nfctsecsrank_c, fctsecsrank_c)
       bound_info_c%nbndpts = nbndpts_c
       bound_info_c%nfctsecs = nfctsecs_c
       call initibmwallfun('fluid_boundary_c.txt', 'facet_sections_c.txt', xf, yf, zf, (/0.,0.,0./), bound_info_c)

       allocate(mask_c(ib-ihc:ie+ihc,jb-jhc:je+jhc,kb-khc:ke+khc)); mask_c = 1.
       mask_c(:,:,kb-khc) = 0.
       !call solid_old(nsolpts_c, solpts_c, nsolptsrank_c, solptsrank_c, mask_c, rhs, 0.)
       call solid(solid_info_c, mask_c, rhs, 0.)
       call exchange_halo_z(mask_c, opt_zlevel=(/ihc,jhc,0/))
     end if

     deallocate(rhs)

               write(*,*) 'done initibm'

   end subroutine initibm


   ! subroutine initibmnorm_old(fname, nsolpts, solpts, nsolptsrank, solptsrank)
   !
   !   use modglobal, only : ifinput
   !   use modmpi,    only : myid, comm3d, MPI_INTEGER, mpierr
   !   use decomp_2d, only : zstart, zend
   !
   !   character(11), intent(in) :: fname
   !   integer, intent(in)  :: nsolpts
   !   integer, intent(out) :: nsolptsrank
   !   integer, intent(out), dimension(:,:), allocatable :: solpts
   !   integer, intent(out), dimension(:), allocatable :: solptsrank
   !
   !   logical :: lsolptsrank(nsolpts)
   !   integer n, m
   !
   !   character(80) chmess
   !
   !   allocate(solpts(nsolpts,3))
   !
   !   ! read u points
   !   if (myid == 0) then
   !     open (ifinput, file=fname)
   !     read (ifinput, '(a80)') chmess
   !     do n = 1, nsolpts
   !       read (ifinput, *) solpts(n,1), solpts(n,2), solpts(n,3)
   !     end do
   !     close (ifinput)
   !   end if
   !
   !   call MPI_BCAST(solpts, nsolpts*3, MPI_INTEGER, 0, comm3d, mpierr)
   !
   !   ! Determine whether points are on this rank
   !   nsolptsrank = 0
   !   do n = 1, nsolpts
   !     if ((solpts(n,1) >= zstart(1) .and. solpts(n,1) <= zend(1)) .and. &
   !        (solpts(n,2) >= zstart(2) .and. solpts(n,2) <= zend(2))) then
   !        lsolptsrank(n) = .true.
   !        nsolptsrank = nsolptsrank + 1
   !      else
   !        lsolptsrank(n) = .false.
   !     end if
   !   end do
   !
   !   ! Store indices of points on current rank - only loop through these points
   !   allocate(solptsrank(nsolptsrank))
   !   m = 0
   !   do n = 1, nsolpts
   !     if (lsolptsrank(n)) then
   !        m = m + 1
   !        solptsrank(m) = n
   !     end if
   !   end do
   !
   !   !write(*,*) "rank ", myid, " has ", nsolptsrank, " solid points from ", fname
   !
   ! end subroutine initibmnorm_old

   !
   subroutine initibmnorm(fname, solid_info)

     use modglobal, only : ifinput
     use modmpi,    only : myid, comm3d, MPI_INTEGER, mpierr
     use decomp_2d, only : zstart, zend

     character(11), intent(in) :: fname

     type(solid_info_type), intent(inout) :: solid_info

     logical :: lsolptsrank(solid_info%nsolpts)
     integer n, m

     character(80) chmess

     allocate(solid_info%solpts(solid_info%nsolpts,3))

     ! read u points
     if (myid == 0) then
       open (ifinput, file=fname)
       read (ifinput, '(a80)') chmess
       do n = 1, solid_info%nsolpts
         read (ifinput, *) solid_info%solpts(n,1), solid_info%solpts(n,2), solid_info%solpts(n,3)
       end do
       close (ifinput)
     end if

     call MPI_BCAST(solid_info%solpts, solid_info%nsolpts*3, MPI_INTEGER, 0, comm3d, mpierr)

     ! Determine whether points are on this rank
     solid_info%nsolptsrank = 0
     do n = 1, solid_info%nsolpts
       if ((solid_info%solpts(n,1) >= zstart(1) .and. solid_info%solpts(n,1) <= zend(1)) .and. &
           (solid_info%solpts(n,2) >= zstart(2) .and. solid_info%solpts(n,2) <= zend(2))) then
          lsolptsrank(n) = .true.
          solid_info%nsolptsrank = solid_info%nsolptsrank + 1
        else
          lsolptsrank(n) = .false.
       end if
     end do

     ! Store indices of points on current rank - only loop through these points
     allocate(solid_info%solptsrank(solid_info%nsolptsrank))
     m = 0
     do n = 1, solid_info%nsolpts
       if (lsolptsrank(n)) then
          m = m + 1
          solid_info%solptsrank(m) = n
       end if
     end do

     write(*,*) "rank ", myid, " has ", solid_info%nsolptsrank, " solid points from ", fname

   end subroutine initibmnorm


   ! subroutine initibmwallfun_old(fname_bnd, fname_sec, x, y, z, dir, &
   !                           nbndpts, bndpts, bnddst, intpts, bndvec, lcomprec, lskipsec, nbndptsrank, bndptsrank, &
   !                           nfctsecs, secfacids, secareas, secbndptids, recpts, recids, nfctsecsrank, fctsecsrank)
   !   use modglobal, only : ifinput, ib, itot, ih, jb, jtot, jh, kb, ktot, kh, dx, dy, dzh, dzf
   !   use modmpi,    only : myid, comm3d, MPI_INTEGER, MY_REAL, MPI_LOGICAL, mpierr
   !   use initfac,   only : facnorm
   !   use decomp_2d, only : zstart, zend
   !
   !   character(20), intent(in) :: fname_bnd, fname_sec
   !   integer, intent(in) :: nbndpts, nfctsecs
   !   real,    intent(in), dimension(3) :: dir
   !   real,    intent(in), dimension(ib:itot+ih) :: x
   !   real,    intent(in), dimension(jb:jtot+jh) :: y
   !   real,    intent(in), dimension(kb:ktot+kh) :: z
   !   integer, intent(out) :: nfctsecsrank, nbndptsrank
   !   real,    intent(out), dimension(:),   allocatable :: bnddst, secareas
   !   real,    intent(out), dimension(:,:), allocatable :: intpts, bndvec, recpts
   !   integer, intent(out), dimension(:),   allocatable :: secfacids, secbndptids, fctsecsrank, bndptsrank
   !   integer, intent(out), dimension(:,:), allocatable :: bndpts, recids
   !   logical, intent(out), dimension(:),   allocatable :: lcomprec, lskipsec
   !
   !   logical, dimension(nbndpts) :: lbndptsrank
   !   logical, dimension(nfctsecs) :: lfctsecsrank
   !   real, dimension(3) :: norm
   !   integer i, j, k, n, m, norm_align, dir_align
   !   real dst
   !
   !   character(80) chmess
   !
   !   allocate(bndpts(nbndpts,3))
   !
   !   ! read u points
   !   if (myid == 0) then
   !     open (ifinput, file=fname_bnd)
   !     read (ifinput, '(a80)') chmess
   !     do n = 1, nbndpts
   !       read (ifinput, *) bndpts(n,1), bndpts(n,2), bndpts(n,3)
   !     end do
   !     close (ifinput)
   !   end if
   !
   !   call MPI_BCAST(bndpts, nbndpts*3, MPI_INTEGER, 0, comm3d, mpierr)
   !
   !   ! Determine whether points are on this rank
   !   nbndptsrank = 0
   !   do n = 1, nbndpts
   !     if ((bndpts(n,1) >= zstart(1) .and. bndpts(n,1) <= zend(1)) .and. &
   !        (bndpts(n,2) >= zstart(2) .and. bndpts(n,2) <= zend(2))) then
   !        lbndptsrank(n) = .true.
   !        nbndptsrank = nbndptsrank + 1
   !      else
   !        lbndptsrank(n) = .false.
   !     end if
   !   end do
   !
   !   !write(*,*) "rank ", myid, " has ", nbndptsrank, "points from ", fname_bnd
   !
   !   ! Store indices of points on current rank - only loop through these points
   !   allocate(bndptsrank(nbndptsrank))
   !   m = 0
   !   do n = 1, nbndpts
   !     if (lbndptsrank(n)) then
   !        m = m + 1
   !        bndptsrank(m) = n
   !     end if
   !   end do
   !
   !   allocate(secfacids(nfctsecs))
   !   allocate(secareas(nfctsecs))
   !   allocate(secbndptids(nfctsecs))
   !   allocate(intpts(nfctsecs,3))
   !   allocate(bnddst(nfctsecs))
   !   allocate(bndvec(nfctsecs,3))
   !   allocate(recpts(nfctsecs,3))
   !   allocate(recids(nfctsecs,3))
   !
   !   dir_align = alignment(dir)
   !   allocate(lcomprec(nfctsecs))
   !   allocate(lskipsec(nfctsecs))
   !
   !   ! read u facet sections
   !   if (myid == 0) then
   !     open (ifinput, file=fname_sec)
   !     read (ifinput, '(a80)') chmess
   !     do n = 1, nfctsecs
   !       read (ifinput, *) secfacids(n), secareas(n), secbndptids(n), intpts(n,1), intpts(n,2), intpts(n,3)
   !     end do
   !     close (ifinput)
   !
   !     ! Calculate vector
   !     do n = 1,nfctsecs
   !       m = secbndptids(n)
   !       bndvec(n,1) = x(bndpts(m,1)) - intpts(n,1)
   !       bndvec(n,2) = y(bndpts(m,2)) - intpts(n,2)
   !       bndvec(n,3) = z(bndpts(m,3)) - intpts(n,3)
   !       bnddst(n) = norm2(bndvec(n,:))
   !       bndvec(n,:) = bndvec(n,:) / bnddst(n)
   !
   !       norm = facnorm(secfacids(n),:)
   !       norm_align = alignment(norm)
   !
   !       if (norm_align /= 0) then ! this facet normal is in x, y, or z direction
   !         lcomprec(n) = .true. ! simple reconstruction
   !         if (dir_align == norm_align) then ! the normal is in the same direction
   !           ! don't need to calculate shear stress as no tangential component
   !           lskipsec(n) = .true.
   !         else
   !           lskipsec(n) = .false.
   !
   !           ! Don't think we have to do this
   !           ! recids(n,:) = bndpts(m,:)
   !           !
   !           ! select case(abs(norm_align))
   !           ! case(1)
   !           !    dst = dx/2.
   !           ! case(2)
   !           !    dst = dy/2.
   !           ! case(3)
   !           !   dst = dzf(bndpts(secbndptids(n),3))/2. ! don't need to consider dzh because we know we're not on w-grid
   !           ! end select
   !
   !           ! if (bnddst(n) < dst) then
   !           !   write(*,*) "facet aligned but inside boundary"
   !           !   ! points in the direction of the surface are inside the surface
   !           !   ! reconstruction point = adjacent point in the normal direction
   !           !   recids(n, abs(norm_align)) = recids(n, abs(norm_align)) + sign(1, norm_align)
   !           ! end if
   !
   !         end if
   !
   !       else ! need to reconstruct
   !         write(0, *) 'ERROR: more complicated reconstruction not supported yet'
   !         stop 1
   !
   !         ! lcomprec(n) = .false.
   !         ! ! project one diagonal length away and identify which cell we land in
   !         ! if (dir_align == 3) then
   !         !   recvec = bndvec(n,:) * sqrt(3.)*(dx*dy*dzf(k))
   !         ! else
   !         !   recvec = bndvec(n,:) * sqrt(3.)*(dx*dy*dzh(k))
   !         ! end if
   !         !
   !         ! recpts(n,1) = x(bndpts(m,1)) + recvec(1)
   !         ! recpts(n,2) = y(bndpts(m,2)) + recvec(2)
   !         ! recpts(n,3) = z(bndpts(m,3)) + recvec(3)
   !         ! write(*,*) "recpts", recpts(n,:)
   !         !
   !         ! recids(n,1) = findloc(recpts(n,1) >= x, .true., 1, back=.true.)
   !         ! recids(n,2) = findloc(recpts(n,2) >= y, .true., 1, back=.true.)
   !         ! recids(n,3) = findloc(recpts(n,3) >= z, .true., 1, back=.true.)
   !         !
   !         ! write(*,*) "recids", recids(n,:)
   !
   !
   !       end if
   !     end do
   !   end if ! myid==0
   !
   !   call MPI_BCAST(secfacids,   nfctsecs,   MPI_INTEGER, 0, comm3d, mpierr)
   !   call MPI_BCAST(secareas,    nfctsecs,   MY_REAL,     0, comm3d, mpierr)
   !   call MPI_BCAST(secbndptids, nfctsecs,   MPI_INTEGER, 0, comm3d, mpierr)
   !   call MPI_BCAST(intpts,      nfctsecs*3, MY_REAL,     0, comm3d, mpierr)
   !   call MPI_BCAST(bndvec,      nfctsecs*3, MY_REAL,     0, comm3d, mpierr)
   !   call MPI_BCAST(bnddst,      nfctsecs,   MY_REAL,     0, comm3d, mpierr)
   !   call MPI_BCAST(recpts,      nfctsecs*3, MY_REAL,     0, comm3d, mpierr)
   !   call MPI_BCAST(recids,      nfctsecs*3, MPI_INTEGER, 0, comm3d, mpierr)
   !   call MPI_BCAST(lskipsec,    nfctsecs,   MPI_LOGICAL, 0, comm3d, mpierr)
   !   call MPI_BCAST(lcomprec,    nfctsecs,   MPI_LOGICAL, 0, comm3d, mpierr)
   !
   !   ! Determine whether section needs to be updated by this rank
   !   nfctsecsrank = 0
   !   do n = 1, nfctsecs
   !     if (lbndptsrank(secbndptids(n))) then
   !        lfctsecsrank(n) = .true.
   !        nfctsecsrank = nfctsecsrank + 1
   !      else
   !        lfctsecsrank(n) = .false.
   !     end if
   !   end do
   !
   !   ! Store indices of sections on current rank - only loop through these sections
   !   allocate(fctsecsrank(nfctsecsrank))
   !   m = 0
   !   do n = 1, nfctsecs
   !     if (lfctsecsrank(n)) then
   !        m = m + 1
   !        fctsecsrank(m) = n
   !     end if
   !   end do
   !
   ! end subroutine initibmwallfun_old

   !
   subroutine initibmwallfun(fname_bnd, fname_sec, x, y, z, dir, bound_info)
     use modglobal, only : ifinput, ib, itot, ih, jb, jtot, jh, kb, ktot, kh, dx, dy, dzh, dzf
     use modmpi,    only : myid, comm3d, MPI_INTEGER, MY_REAL, MPI_LOGICAL, mpierr
     use initfac,   only : facnorm
     use decomp_2d, only : zstart, zend

     character(20), intent(in) :: fname_bnd, fname_sec
     type(bound_info_type) :: bound_info
     real,    intent(in), dimension(3) :: dir
     real,    intent(in), dimension(ib:itot+ih) :: x
     real,    intent(in), dimension(jb:jtot+jh) :: y
     real,    intent(in), dimension(kb:ktot+kh) :: z
     logical, dimension(bound_info%nbndpts)  :: lbndptsrank
     logical, dimension(bound_info%nfctsecs) :: lfctsecsrank
     real, dimension(3) :: norm
     integer i, j, k, n, m, norm_align, dir_align
     real dst

     character(80) chmess

     allocate(bound_info%bndpts(bound_info%nbndpts,3))

     ! read u points
     if (myid == 0) then
       open (ifinput, file=fname_bnd)
       read (ifinput, '(a80)') chmess
       do n = 1, bound_info%nbndpts
         read (ifinput, *) bound_info%bndpts(n,1), bound_info%bndpts(n,2), bound_info%bndpts(n,3)
       end do
       close (ifinput)
     end if

     call MPI_BCAST(bound_info%bndpts, bound_info%nbndpts*3, MPI_INTEGER, 0, comm3d, mpierr)

     ! Determine whether points are on this rank
     bound_info%nbndptsrank = 0
     do n = 1, bound_info%nbndpts
       if ((bound_info%bndpts(n,1) >= zstart(1) .and. bound_info%bndpts(n,1) <= zend(1)) .and. &
           (bound_info%bndpts(n,2) >= zstart(2) .and. bound_info%bndpts(n,2) <= zend(2))) then
          lbndptsrank(n) = .true.
          bound_info%nbndptsrank = bound_info%nbndptsrank + 1
        else
          lbndptsrank(n) = .false.
       end if
     end do

     write(*,*) "rank ", myid, " has ", bound_info%nbndptsrank, "points from ", fname_bnd

     ! Store indices of points on current rank - only loop through these points
     allocate(bound_info%bndptsrank(bound_info%nbndptsrank))
     m = 0
     do n = 1, bound_info%nbndpts
       if (lbndptsrank(n)) then
          m = m + 1
          bound_info%bndptsrank(m) = n
       end if
     end do

     allocate(bound_info%secfacids(bound_info%nfctsecs))
     allocate(bound_info%secareas(bound_info%nfctsecs))
     allocate(bound_info%secbndptids(bound_info%nfctsecs))
     allocate(bound_info%intpts(bound_info%nfctsecs,3))
     allocate(bound_info%bnddst(bound_info%nfctsecs))
     allocate(bound_info%bndvec(bound_info%nfctsecs,3))
     allocate(bound_info%recpts(bound_info%nfctsecs,3))
     allocate(bound_info%recids(bound_info%nfctsecs,3))

     dir_align = alignment(dir)
     allocate(bound_info%lcomprec(bound_info%nfctsecs))
     allocate(bound_info%lskipsec(bound_info%nfctsecs))

     ! read u facet sections
     if (myid == 0) then
       open (ifinput, file=fname_sec)
       read (ifinput, '(a80)') chmess
       do n = 1, bound_info%nfctsecs
         read (ifinput, *) bound_info%secfacids(n), bound_info%secareas(n), bound_info%secbndptids(n), &
                           bound_info%intpts(n,1),  bound_info%intpts(n,2), bound_info%intpts(n,3)
       end do
       close (ifinput)

       ! Calculate vector
       do n = 1,bound_info%nfctsecs
         m = bound_info%secbndptids(n)
         bound_info%bndvec(n,1) = x(bound_info%bndpts(m,1)) - bound_info%intpts(n,1)
         bound_info%bndvec(n,2) = y(bound_info%bndpts(m,2)) - bound_info%intpts(n,2)
         bound_info%bndvec(n,3) = z(bound_info%bndpts(m,3)) - bound_info%intpts(n,3)
         bound_info%bnddst(n) = norm2(bound_info%bndvec(n,:))
         bound_info%bndvec(n,:) = bound_info%bndvec(n,:) / bound_info%bnddst(n)

         norm = facnorm(bound_info%secfacids(n),:)
         norm_align = alignment(norm)

         if (norm_align /= 0) then ! this facet normal is in x, y, or z direction
           bound_info%lcomprec(n) = .true. ! simple reconstruction
           if (dir_align == norm_align) then ! the normal is in the same direction
             ! don't need to calculate shear stress as no tangential component
             bound_info%lskipsec(n) = .true.
           else
             bound_info%lskipsec(n) = .false.
           end if

         else ! need to reconstruct
           write(0, *) 'ERROR: more complicated reconstruction not supported yet'
           stop 1

           ! lcomprec(n) = .false.
           ! ! project one diagonal length away and identify which cell we land in
           ! if (dir_align == 3) then
           !   recvec = bndvec(n,:) * sqrt(3.)*(dx*dy*dzf(k))
           ! else
           !   recvec = bndvec(n,:) * sqrt(3.)*(dx*dy*dzh(k))
           ! end if
           !
           ! recpts(n,1) = x(bndpts(m,1)) + recvec(1)
           ! recpts(n,2) = y(bndpts(m,2)) + recvec(2)
           ! recpts(n,3) = z(bndpts(m,3)) + recvec(3)
           ! write(*,*) "recpts", recpts(n,:)
           !
           ! recids(n,1) = findloc(recpts(n,1) >= x, .true., 1, back=.true.)
           ! recids(n,2) = findloc(recpts(n,2) >= y, .true., 1, back=.true.)
           ! recids(n,3) = findloc(recpts(n,3) >= z, .true., 1, back=.true.)
           !
           ! write(*,*) "recids", recids(n,:)


         end if
       end do
     end if ! myid==0

     call MPI_BCAST(bound_info%secfacids,   bound_info%nfctsecs,   MPI_INTEGER, 0, comm3d, mpierr)
     call MPI_BCAST(bound_info%secareas,    bound_info%nfctsecs,   MY_REAL,     0, comm3d, mpierr)
     call MPI_BCAST(bound_info%secbndptids, bound_info%nfctsecs,   MPI_INTEGER, 0, comm3d, mpierr)
     call MPI_BCAST(bound_info%intpts,      bound_info%nfctsecs*3, MY_REAL,     0, comm3d, mpierr)
     call MPI_BCAST(bound_info%bndvec,      bound_info%nfctsecs*3, MY_REAL,     0, comm3d, mpierr)
     call MPI_BCAST(bound_info%bnddst,      bound_info%nfctsecs,   MY_REAL,     0, comm3d, mpierr)
     call MPI_BCAST(bound_info%recpts,      bound_info%nfctsecs*3, MY_REAL,     0, comm3d, mpierr)
     call MPI_BCAST(bound_info%recids,      bound_info%nfctsecs*3, MPI_INTEGER, 0, comm3d, mpierr)
     call MPI_BCAST(bound_info%lskipsec,    bound_info%nfctsecs,   MPI_LOGICAL, 0, comm3d, mpierr)
     call MPI_BCAST(bound_info%lcomprec,    bound_info%nfctsecs,   MPI_LOGICAL, 0, comm3d, mpierr)

     ! Determine whether section needs to be updated by this rank
     bound_info%nfctsecsrank = 0
     do n = 1, bound_info%nfctsecs
       if (lbndptsrank(bound_info%secbndptids(n))) then
          lfctsecsrank(n) = .true.
          bound_info%nfctsecsrank = bound_info%nfctsecsrank + 1
        else
          lfctsecsrank(n) = .false.
       end if
     end do

     ! Store indices of sections on current rank - only loop through these sections
     allocate(bound_info%fctsecsrank(bound_info%nfctsecsrank))
     m = 0
     do n = 1, bound_info%nfctsecs
       if (lfctsecsrank(n)) then
          m = m + 1
          bound_info%fctsecsrank(m) = n
       end if
     end do

   end subroutine initibmwallfun


   subroutine ibmnorm
     use modglobal,   only : libm, ltempeq
     use modfields,   only : thl0, um, vm, wm, thlm, up, vp, wp, thlp
     use modboundary, only : halos
     use decomp_2d,   only : zstart, zend
     use modmpi, only : myid

     integer i, j, k, n, m

     if (.not. libm) return

     ! Set internal velocities to zero
     !call solid_old(nsolpts_u, solpts_u, nsolptsrank_u, solptsrank_u, um, up, 0.)
     !call solid_old(nsolpts_v, solpts_v, nsolptsrank_v, solptsrank_v, vm, vp, 0.)
     !call solid_old(nsolpts_w, solpts_w, nsolptsrank_w, solptsrank_w, wm, wp, 0.)

     ! Set internal velocities to zero
     call solid(solid_info_u, um, up, 0.)
     call solid(solid_info_v, vm, vp, 0.)
     call solid(solid_info_w, wm, wp, 0.)

     ! scalars
     if (ltempeq) then
        !call solid_old(nsolpts_c, solpts_c, nsolptsrank_c, solptsrank_c, thlm, thlp, 288.) ! should be set to thl0av?
        call solid(solid_info_c, thlm, thlp, 288.) ! should be set to thl0av?
        !call advection_correction(thl0, thlp)
        ! above accounts for non-zero wall velocities, to ensure heat conservation in fluid
        ! this makes the IBM true-blue Thatcherite conservative,
        ! however like Thatcher it can have drastic effects, notably a very cool
        ! canopy layer initially, so it is commented out for now (sorry Chris).
        ! Also, it wasn't present in uDALES 1.
     end if

   end subroutine ibmnorm


   subroutine advection_correction(var,rhs)
     ! scalars only
     use modglobal,      only : eps1, ib, ie, ih, jb, je, jh, kb, ke, kh, &
                                dx2i, dxi5, dy2i, dyi5, dzf, dzh2i, dzfi, dzhi, dzfi5
     use modfields,      only : u0, v0, w0
     use modsubgriddata, only : ekh
     use decomp_2d,      only : zstart

     real :: var(ib-ih:ie+ih,jb-jh:je+jh,kb-kh:ke+kh), rhs(ib-ih:ie+ih,jb-jh:je+jh,kb:ke+kh)
     integer :: i, j, k, n, m
     type(bound_info_type) :: bound_info

     bound_info = bound_info_c

     do m = 1,bound_info%nbndptsrank
      n = bound_info%bndptsrank(m)
         i = bound_info%bndpts(n,1) - zstart(1) + 1
         j = bound_info%bndpts(n,2) - zstart(2) + 1
         k = bound_info%bndpts(n,3) - zstart(3) + 1

     ! do m = 1,nbndptsrank_c
     !   n = bndptsrank_c(m)
     !   i = bndpts_c(n,1) - zstart(1) + 1
     !   j = bndpts_c(n,2) - zstart(2) + 1
     !   k = bndpts_c(n,3) - zstart(3) + 1

         if (abs(mask_u(i+1,j,k)) < eps1) then ! can't use u0(i+1)
           rhs(i,j,k) = rhs(i,j,k) + u0(i+1,j,k)*(var(i+1,j,k) + var(i,j,k))*dxi5
         end if

         if (abs(mask_u(i,j,k)) < eps1) then ! can't use u0(i)
           rhs(i,j,k) = rhs(i,j,k) - u0(i,j,k)*(var(i-1,j,k) + var(i,j,k))*dxi5
         end if

         if (abs(mask_v(i,j+1,k)) < eps1) then
           rhs(i,j,k) = rhs(i,j,k) + v0(i,j+1,k)*(var(i,j+1,k) + var(i,j,k))*dyi5
         end if

         if (abs(mask_v(i,j,k)) < eps1) then
           rhs(i,j,k) = rhs(i,j,k) - v0(i,j,k)*(var(i,j-1,k) + var(i,j,k))*dyi5
         end if

         if (abs(mask_w(i,j,k+1)) < eps1) then
           rhs(i,j,k) = rhs(i,j,k) + w0(i,j,k+1)*(var(i,j,k+1)*dzf(k) + var(i,j,k)*dzf(k+1))*dzhi(k+1)*dzfi5(k)
         end if

         if (abs(mask_w(i,j,k)) < eps1) then
           rhs(i,j,k) = rhs(i,j,k) - w0(i,j,k)*(var(i,j,k-1)*dzf(k) + var(i,j,k)*dzf(k-1))*dzhi(k)*dzfi5(k)
         end if

     end do
   end subroutine advection_correction

   ! subroutine solid_old(nsolpts, solpts, nsolptsrank, solptsrank, var, rhs, val)
   !   use modglobal, only : ib, ie, ih, jb, je, jh, kb, ke, kh
   !   use decomp_2d, only : zstart
   !
   !   real, intent(in) :: val
   !   integer, intent(in) :: nsolpts, nsolptsrank
   !   integer, intent(in) :: solpts(nsolpts,3), solptsrank(nsolptsrank)
   !   real, intent(inout) :: var(ib-ih:ie+ih,jb-jh:je+jh,kb-kh:ke+kh)
   !   real, intent(inout) :: rhs(ib-ih:ie+ih,jb-jh:je+jh,kb:ke+kh)
   !
   !   integer :: i, j, k, n, m
   !
   !   do m=1,nsolptsrank
   !    n = solptsrank(m)
   !     !if (lsolptsrank_u(n)) then
   !       i = solpts(n,1) - zstart(1) + 1
   !       j = solpts(n,2) - zstart(2) + 1
   !       k = solpts(n,3) - zstart(3) + 1
   !       var(i,j,k) = val
   !       rhs(i,j,k) = 0.
   !     !end if
   !   end do
   !
   ! end subroutine solid_old


   subroutine solid(solid_info, var, rhs, val)
     use modglobal, only : ib, ie, ih, jb, je, jh, kb, ke, kh
     use decomp_2d, only : zstart

     type(solid_info_type), intent(in) :: solid_info
     real, intent(inout) :: var(ib-ih:ie+ih,jb-jh:je+jh,kb-kh:ke+kh)
     real, intent(inout) :: rhs(ib-ih:ie+ih,jb-jh:je+jh,kb:ke+kh)
     real, intent(in) :: val

     integer :: i, j, k, n, m

     do m=1,solid_info%nsolptsrank
      n = solid_info%solptsrank(m)
       !if (lsolptsrank_u(n)) then
         i = solid_info%solpts(n,1) - zstart(1) + 1
         j = solid_info%solpts(n,2) - zstart(2) + 1
         k = solid_info%solpts(n,3) - zstart(3) + 1
         var(i,j,k) = val
         rhs(i,j,k) = 0.
       !end if
     end do

   end subroutine solid


   subroutine diffu_corr
     ! Negate subgrid rhs contributions from solid points (added by diffc in modsubgrid)
     use modglobal,      only : eps1, ib, ie, ih, jb, je, jh, kb, ke, kh, &
                                dx2i, dxi5, dy2i, dyi5, dzf, dzh2i, dzfi, dzhi, dzfi5, dzhiq
     use modfields,      only : u0, up
     use modsubgriddata, only : ekm
     use decomp_2d,      only : zstart

     ! real, intent(in) :: var(ib-ih:ie+ih,jb-jh:je+jh,kb-kh:ke+kh) ! Practically will always be u(?)
     ! real, intent(inout) :: rhs(ib-ih:ie+ih,jb-jh:je+jh,kb:ke+kh)

     real :: empo, emmo, emop, emom
     integer :: i, j, k, n, m
     type(bound_info_type) :: bound_info

     bound_info = bound_info_u

     do m = 1,bound_info%nbndptsrank
      n = bound_info%bndptsrank(m)
         i = bound_info%bndpts(n,1) - zstart(1) + 1
         j = bound_info%bndpts(n,2) - zstart(2) + 1
         k = bound_info%bndpts(n,3) - zstart(3) + 1

     ! do m = 1,nbndptsrank_u
     !   n = bndptsrank_u(m)
     !   i = bndpts_u(n,1) - zstart(1) + 1
     !   j = bndpts_u(n,2) - zstart(2) + 1
     !   k = bndpts_u(n,3) - zstart(3) + 1

         ! Account for solid u points
         if (abs(mask_u(i+1,j,k)) < eps1) then ! u0(i+1) is solid
            ! Not sure about this
            ! This effectively sets a reflecting boundary condition (?),
            ! because same as u0(i+1) = u0(i)
            !up(i,j,k) = up(i,j,k) - ekm(i,j,k) * (u0(i+1,j,k) - u0(i,j,k)) * 2. * dx2i
         end if

         if (abs(mask_u(i-1,j,k)) < eps1) then ! u0(i-1) is solid
           ! Not sure about this
           !up(i,j,k) = up(i,j,k) + ekm(i-1,j,k) * (u0(i,j,k) - u0(i-1,j,k)) * 2. * dx2i
         end if

         if (abs(mask_u(i,j+1,k)) < eps1) then
           empo = 0.25 * ((ekm(i,j,k) + ekm(i,j+1,k)) + (ekm(i-1,j,k) + ekm(i-1,j+1,k)))
           up(i,j,k) = up(i,j,k) - empo * (u0(i,j+1,k) - u0(i,j,k))*dy2i
         end if

         if (abs(mask_u(i,j-1,k)) < eps1) then
           emmo = 0.25 * ((ekm(i,j,k) + ekm(i,j-1,k)) + (ekm(i-1,j-1,k) + ekm(i-1,j,k)))
           up(i,j,k) = up(i,j,k) + emmo * (u0(i,j,k) - u0(i,j-1,k))*dy2i
         end if

         if (abs(mask_u(i,j,k+1)) < eps1) then
           emop = (dzf(k+1) * ( ekm(i,j,k)   + ekm(i-1,j,k  ))  + &
                   dzf(k)   * ( ekm(i,j,k+1) + ekm(i-1,j,k+1))) * dzhiq(k+1)
           up(i,j,k) = up(i,j,k) - emop * (u0(i,j,k+1) - u0(i,j,k))*dzhi(k+1)*dzfi(k)
         end if

         if (abs(mask_u(i,j,k-1)) < eps1) then ! u(k-1) is solid
           emom = (dzf(k-1) * (ekm(i,j,k  ) + ekm(i-1,j,k  ))  + &
                   dzf(k)   * (ekm(i,j,k-1) + ekm(i-1,j,k-1))) * dzhiq(k)
           up(i,j,k) = up(i,j,k) + emom * (u0(i,j,k) - u0(i,j,k-1))*dzhi(k)*dzfi(k)
         end if

     end do


   end subroutine diffu_corr


   subroutine diffv_corr
     ! Negate subgrid rhs contributions from solid points (added by diffc in modsubgrid)
     use modglobal,      only : eps1, ib, ie, ih, jb, je, jh, kb, ke, kh, &
                                dx2i, dxi5, dy2i, dyi5, dzf, dzh2i, dzfi, dzhi, dzfi5, dzhiq
     use modfields,      only : v0, vp
     use modsubgriddata, only : ekm
     use decomp_2d,      only : zstart

     ! real, intent(in) :: var(ib-ih:ie+ih,jb-jh:je+jh,kb-kh:ke+kh) ! Practically will always be u(?)
     ! real, intent(inout) :: rhs(ib-ih:ie+ih,jb-jh:je+jh,kb:ke+kh)

     real :: epmo, emmo, eomp, eomm
     integer :: i, j, k, n, m
     type(bound_info_type) :: bound_info

     bound_info = bound_info_v

     do m = 1,bound_info%nbndptsrank
      n = bound_info%bndptsrank(m)
         i = bound_info%bndpts(n,1) - zstart(1) + 1
         j = bound_info%bndpts(n,2) - zstart(2) + 1
         k = bound_info%bndpts(n,3) - zstart(3) + 1

     ! do m = 1,nbndptsrank_v
     !  n = bndptsrank_v(m)
     !     i = bndpts_v(n,1) - zstart(1) + 1
     !     j = bndpts_v(n,2) - zstart(2) + 1
     !     k = bndpts_v(n,3) - zstart(3) + 1

         ! Account for solid v points
         if (abs(mask_v(i+1,j,k)) < eps1) then ! v0(i+1) is solid
           epmo = 0.25 * (ekm(i,j,k) + ekm(i,j-1,k) + ekm(i+1,j-1,k) + ekm(i+1,j,k))
           vp(i,j,k) = vp(i,j,k) - epmo * (v0(i+1,j,k) - v0(i,j,k))*dx2i
         end if

         if (abs(mask_v(i-1,j,k)) < eps1) then ! v0(i-1) is solid
           emmo = 0.25 * (ekm(i,j,k) + ekm(i,j-1,k) + ekm(i-1,j-1,k) + ekm(i-1,j,k))
           vp(i,j,k) = vp(i,j,k) + emmo * (v0(i,j,k) - v0(i-1,j,k))*dx2i
         end if

         if (abs(mask_v(i,j+1,k)) < eps1) then
         end if

         if (abs(mask_v(i,j-1,k)) < eps1) then
         end if

         if (abs(mask_v(i,j,k+1)) < eps1) then
           eomp = ( dzf(k+1) * ( ekm(i,j,k)   + ekm(i,j-1,k)  )  + &
                    dzf(k  ) * ( ekm(i,j,k+1) + ekm(i,j-1,k+1))) * dzhiq(k+1)
           vp(i,j,k) = vp(i,j,k) - eomp * (v0(i,j,k+1) - v0(i,j,k))*dzhi(k+1)*dzfi(k)
         end if

         if (abs(mask_v(i,j,k-1)) < eps1) then
           eomm = ( dzf(k-1) * ( ekm(i,j,k  )  + ekm(i,j-1,k)   ) + &
                    dzf(k)   * ( ekm(i,j,k-1)  + ekm(i,j-1,k-1))) * dzhiq(k)
           vp(i,j,k) = vp(i,j,k) + eomm * (v0(i,j,k) - v0(i,j,k-1))*dzhi(k)*dzfi(k)
         end if

     end do

   end subroutine diffv_corr


   subroutine diffw_corr
     ! Negate subgrid rhs contributions from solid points (added by diffc in modsubgrid)
     use modglobal,      only : eps1, ib, ie, ih, jb, je, jh, kb, ke, kh, &
                                dx2i, dxi5, dy2i, dyi5, dzf, dzh2i, dzfi, dzhi, dzfi5, dzhiq
     use modfields,      only : w0, wp
     use modsubgriddata, only : ekm
     use decomp_2d,      only : zstart

     ! real, intent(in) :: var(ib-ih:ie+ih,jb-jh:je+jh,kb-kh:ke+kh) ! Practically will always be u(?)
     ! real, intent(inout) :: rhs(ib-ih:ie+ih,jb-jh:je+jh,kb:ke+kh)

     real :: epom, emom, eopm, eomm
     integer :: i, j, k, n, m
     type(bound_info_type) :: bound_info

     bound_info = bound_info_w

     do m = 1,bound_info%nbndptsrank
      n = bound_info%bndptsrank(m)
         i = bound_info%bndpts(n,1) - zstart(1) + 1
         j = bound_info%bndpts(n,2) - zstart(2) + 1
         k = bound_info%bndpts(n,3) - zstart(3) + 1

     ! do m = 1,nbndptsrank_w
     !  n = bndptsrank_w(m)
     !     i = bndpts_w(n,1) - zstart(1) + 1
     !     j = bndpts_w(n,2) - zstart(2) + 1
     !     k = bndpts_w(n,3) - zstart(3) + 1

         ! Account for solid v points
         if (abs(mask_w(i+1,j,k)) < eps1) then ! w0(i+1) is solid
           epom = ( dzf(k-1) * ( ekm(i,j,k  ) + ekm(i+1,j,k  ))    + &
                    dzf(k  ) * ( ekm(i,j,k-1) + ekm(i+1,j,k-1))) * dzhiq(k)
           wp(i,j,k) = wp(i,j,k) - epom * (w0(i+1,j,k) - w0(i,j,k))*dx2i
         end if

         if (abs(mask_w(i-1,j,k)) < eps1) then ! w0(i-1) is solid
           emom = ( dzf(k-1) * ( ekm(i,j,k  ) + ekm(i-1,j,k  ))  + &
                    dzf(k  ) * ( ekm(i,j,k-1) + ekm(i-1,j,k-1))) * dzhiq(k)
           wp(i,j,k) = wp(i,j,k) + emom * (w0(i,j,k) - w0(i-1,j,k))*dx2i
         end if

         if (abs(mask_w(i,j+1,k)) < eps1) then
           eopm = ( dzf(k-1) * ( ekm(i,j,k  ) + ekm(i,j+1,k  ))  + &
                    dzf(k  ) * ( ekm(i,j,k-1) + ekm(i,j+1,k-1))) * dzhiq(k)
           wp(i,j,k) = wp(i,j,k) - eopm * (w0(i,j+1,k) - w0(i,j,k))*dy2i
         end if

         if (abs(mask_w(i,j-1,k)) < eps1) then
           eomm = ( dzf(k-1) * ( ekm(i,j,k  ) + ekm(i,j-1,k  ))  + &
                    dzf(k  ) * ( ekm(i,j,k-1) + ekm(i,j-1,k-1))) * dzhiq(k)
           wp(i,j,k) = wp(i,j,k) + eomm * (w0(i,j,k) - w0(i,j-1,k))*dy2i
         end if

         if (abs(mask_w(i,j,k+1)) < eps1) then

         end if

         if (abs(mask_w(i,j,k-1)) < eps1) then

         end if

     end do

   end subroutine diffw_corr


   subroutine diffc_corr(var, rhs)
     ! Negate subgrid rhs contributions from solid points (added by diffc in modsubgrid)
     use modglobal,      only : eps1, ib, ie, ih, jb, je, jh, kb, ke, kh, &
                                dx2i, dxi5, dy2i, dyi5, dzf, dzh2i, dzfi, dzhi, dzfi5
     use modsubgriddata, only : ekh
     use decomp_2d,      only : zstart

     real, intent(in) :: var(ib-ih:ie+ih,jb-jh:je+jh,kb-kh:ke+kh)
     real, intent(inout) :: rhs(ib-ih:ie+ih,jb-jh:je+jh,kb:ke+kh)
     integer :: i, j, k, n, m
     type(bound_info_type) :: bound_info

     bound_info = bound_info_c

     do m = 1,bound_info%nbndptsrank
      n = bound_info%bndptsrank(m)
         i = bound_info%bndpts(n,1) - zstart(1) + 1
         j = bound_info%bndpts(n,2) - zstart(2) + 1
         k = bound_info%bndpts(n,3) - zstart(3) + 1

     ! do m = 1,nbndptsrank_c
     !  n = bndptsrank_c(m)
     !     i = bndpts_c(n,1) - zstart(1) + 1
     !     j = bndpts_c(n,2) - zstart(2) + 1
     !     k = bndpts_c(n,3) - zstart(3) + 1

         if (abs(mask_c(i+1,j,k)) < eps1) then ! var(i+1) is solid
           rhs(i,j,k) = rhs(i,j,k) - 0.5 * (ekh(i+1,j,k) + ekh(i,j,k)) * (var(i+1,j,k) - var(i,j,k))*dx2i
         end if

         if (abs(mask_c(i-1,j,k)) < eps1) then ! var(i-1) is solid
           rhs(i,j,k) = rhs(i,j,k) + 0.5 * (ekh(i,j,k) + ekh(i-1,j,k)) * (var(i,j,k) - var(i-1,j,k))*dx2i
         end if

         if (abs(mask_c(i,j+1,k)) < eps1) then
           rhs(i,j,k) = rhs(i,j,k) - 0.5 * (ekh(i,j+1,k) + ekh(i,j,k)) * (var(i,j+1,k) - var(i,j,k))*dy2i
         end if

         if (abs(mask_c(i,j-1,k)) < eps1) then
           rhs(i,j,k) = rhs(i,j,k) + 0.5 * (ekh(i,j,k) + ekh(i,j-1,k)) * (var(i,j,k) - var(i,j-1,k))*dy2i
         end if

         if (abs(mask_c(i,j,k+1)) < eps1) then
           rhs(i,j,k) = rhs(i,j,k) - 0.5 * (dzf(k+1)*ekh(i,j,k) + dzf(k)*ekh(i,j,k+1)) &
                                         * (var(i,j,k+1) - var(i,j,k))*dzh2i(k+1)*dzfi(k)
         end if

         if (abs(mask_c(i,j,k-1)) < eps1) then ! bottom
           rhs(i,j,k) = rhs(i,j,k) + 0.5 * (dzf(k-1)*ekh(i,j,k) + dzf(k)*ekh(i,j,k-1)) &
                                         * (var(i,j,k) - var(i,j,k-1))*dzh2i(k)*dzfi(k)
         end if

     end do


   end subroutine diffc_corr


   subroutine ibmwallfun
     use modglobal, only : libm, iwallmom, iwalltemp, xhat, yhat, zhat, ltempeq, lmoist, ib, ie, ih, jb, je, jh, kb, ke, kh
     use modfields, only : u0, v0, w0, thl0, qt0, up, vp, wp, thlp, qtp, tau_x, tau_y, tau_z, thl_flux
     use modsubgriddata, only : ekm, ekh

     real, allocatable :: rhs(:,:,:)

      if (.not. libm) return

      allocate(rhs(ib-ih:ie+ih,jb-jh:je+jh,kb:ke+kh))

      if (iwallmom > 1) then
        rhs = up
        ! call wallfunmom(xhat, up, nbndpts_u, bndpts_u, bnddst_u, bndvec_u, lcomprec_u, lskipsec_u, &
        ! nfctsecs_u, secfacids_u, secareas_u, secbndptids_u, recpts_u, recids_u, nfctsecsrank_u, fctsecsrank_u)
        call wallfunmom(xhat, up, bound_info_u)
        tau_x(:,:,kb:ke+kh) = tau_x(:,:,kb:ke+kh) + (up - rhs)

        rhs = vp
        ! call wallfunmom(yhat, vp, nbndpts_v, bndpts_v, bnddst_v, bndvec_v, lcomprec_v, lskipsec_v, &
        ! nfctsecs_v, secfacids_v, secareas_v, secbndptids_v, recpts_v, recids_v, nfctsecsrank_v, fctsecsrank_v)
        call wallfunmom(yhat, vp, bound_info_v)
        tau_y(:,:,kb:ke+kh) = tau_y(:,:,kb:ke+kh) + (vp - rhs)

        rhs = wp
        ! call wallfunmom(zhat, wp, nbndpts_w, bndpts_w, bnddst_w, bndvec_w, lcomprec_w, lskipsec_w, &
        ! nfctsecs_w, secfacids_w, secareas_w, secbndptids_w, recpts_w, recids_w, nfctsecsrank_w, fctsecsrank_w)
        call wallfunmom(zhat, wp, bound_info_w)
        tau_z(:,:,kb:ke+kh) = tau_z(:,:,kb:ke+kh) + (wp - rhs)

        ! This replicates uDALES 1 behaviour, but probably should be done even if not using wall functions
        call diffu_corr
        call diffv_corr
        call diffw_corr
      end if

      ! if (ltempeq) then
      !   rhs = thlp
      !   call wallfuntemp
      !   thl_flux(:,:,kb:ke+kh) = thl_flux(:,:,kb:ke+kh) + (thlp - rhs)
      !   call diffc_corr(thl0, thlp)
      ! end if

      ! if (lmoist) then
      !   !rhs = qtp
      !   call wallfunmoist
      !   !qt_flux(:,:,kb:ke+kh) = qt_flux(:,:,kb:ke+kh) + (qtp - rhs)
      !   call diffc_corr(qt0, qtp)
      ! end if

      if (ltempeq .or. lmoist) then
        rhs = thlp
        call wallfunheat
        thl_flux(:,:,kb:ke+kh) = thl_flux(:,:,kb:ke+kh) + (thlp - rhs)
        if (ltempeq) call diffc_corr(thl0, thlp)
        if (lmoist)  call diffc_corr(qt0, qtp)
      end if

      deallocate(rhs)

    end subroutine ibmwallfun


   ! subroutine wallfunmom(dir, rhs, nbndpts, bndpts, bnddst, bndvec, lcomprec, lskipsec, &
   !                       nfctsecs, secfacids, secareas, secbndptids, recpts, recids, nfctsecsrank, fctsecsrank)
   !   use modglobal, only : ib, ie, ih, jb, je, jh, kb, ke, kh, eps1, fkar, dx, dy, dzf, iwallmom, xhat, yhat, zhat
   !   use modfields, only : u0, v0, w0, thl0, tau_x, tau_y, tau_z
   !   use initfac,   only : facT, facz0, facz0h, facnorm
   !   use decomp_2d, only : zstart
   !
   !   real, intent(in)    :: dir(3)
   !   real, intent(inout) :: rhs(ib-ih:ie+ih,jb-jh:je+jh,kb:ke+kh)
   !   integer, intent(in) :: nbndpts, nfctsecs, nfctsecsrank
   !   integer, intent(in), dimension(nbndpts,3)  :: bndpts
   !   integer, intent(in), dimension(nfctsecs,3) :: recids
   !   real,    intent(in), dimension(nfctsecs)   :: secareas, bnddst
   !   real,    intent(in), dimension(nfctsecs,3) :: bndvec, recpts
   !   integer, intent(in), dimension(nfctsecs)   :: secfacids, secbndptids, fctsecsrank
   !   logical, intent(in), dimension(nfctsecs)   :: lcomprec, lskipsec
   !
   !   integer i, j, k, n, m, sec, pt, fac
   !   real dist, stress, stress_dir, stress_aligned, area, vol, momvol, Tair, Tsurf, x, y, z, &
   !        utan, udir, ctm, a, a_is, a_xn, a_yn, a_zn, stress_ix, stress_iy, stress_iz
   !   real, dimension(3) :: uvec, norm, strm, span, stressvec
   !   logical :: valid
   !
   !   procedure(interp_velocity), pointer :: interp_velocity_ptr => null()
   !   procedure(interp_temperature), pointer :: interp_temperature_ptr => null()
   !
   !   select case(alignment(dir))
   !   case(1)
   !     interp_velocity_ptr => interp_velocity_u
   !     interp_temperature_ptr => interp_temperature_u
   !   case(2)
   !     interp_velocity_ptr => interp_velocity_v
   !     interp_temperature_ptr => interp_temperature_v
   !   case(3)
   !     interp_velocity_ptr => interp_velocity_w
   !     interp_temperature_ptr => interp_temperature_w
   !   end select
   !
   !   do m = 1,nfctsecsrank
   !     sec = fctsecsrank(m) ! index of section
   !     if (lskipsec(sec)) cycle
   !
   !     n = secbndptids(sec) ! index of boundary point
   !     fac = secfacids(sec) ! index of facet
   !     norm = facnorm(fac,:) ! facet normal
   !
   !     i = bndpts(n,1) - zstart(1) + 1
   !     j = bndpts(n,2) - zstart(2) + 1
   !     k = bndpts(n,3) - zstart(3) + 1
   !     if ((i < ib) .or. (i > ie) .or. (j < jb) .or. (j > je)) write(*,*) "problem", i, j
   !
   !     if (lcomprec(sec)) then
   !       uvec = interp_velocity_ptr(i, j, k)
   !       if (iwallmom == 2) Tair = interp_temperature_ptr(i, j, k)
   !     else
   !       ! do different interpolation
   !     end if
   !
   !     if (is_equal(uvec, (/0.,0.,0./))) cycle
   !
   !     call local_coords(uvec, norm, span, strm, valid)
   !     if (.not. valid) cycle
   !
   !     utan = dot_product(uvec, strm)
   !     dist = bnddst(sec)
   !
   !     ! calcualate momentum transfer coefficient
   !     ! make into interface somehow? because iwallmom doesn't change in the loop
   !     if (iwallmom == 2) then ! stability included
   !       ctm = mom_transfer_coef_stability(utan, dist, facz0(fac), facz0h(fac), Tair, facT(fac,1))
   !     else if (iwallmom == 3) then ! neutral
   !       !ctm = (fkar / log(dist / z0))**2
   !       ctm = mom_transfer_coef_neutral(dist, facz0(fac))
   !     end if
   !
   !     stress = ctm * utan**2
   !
   !     if (lcomprec(sec)) then
   !       a = dot_product(dir, strm)
   !       stress_dir = a * stress
   !       !write(*,*) "stress_dir", sign(stress_dir, dot_product(uvec, dir))
   !     else
   !       ! Rotation from local (strm,span,norm) to global (xhat,yhat,zhat) basis
   !       ! \tau'_ij = a_ip a_jq \tau_pq
   !       ! \tau_pq in local coordinates is something like \tau \delta_13, because we only have \tau_{strm,norm})
   !       a_is = dot_product(dir, strm)
   !       a_xn = dot_product(xhat, norm)
   !       a_yn = dot_product(yhat, norm)
   !       a_zn = dot_product(zhat, norm)
   !
   !       stress_ix = a_is * a_xn * stress
   !       stress_iy = a_is * a_yn * stress
   !       stress_iz = a_is * a_zn * stress
   !
   !       stressvec(1) = stress_ix
   !       stressvec(2) = stress_iy
   !       stressvec(3) = stress_iz
   !       stress_dir = norm2(stressvec)
   !       !write(*,*) "stress_dir", sign(stress_dir, dot_product(uvec, dir))
   !     end if
   !
   !     stress_dir = sign(stress_dir, dot_product(uvec, dir))
   !
   !       ! if (iwallmom == 2) then
   !       !   stress_aligned = calc_stress_aligned(dir, uvec, norm, dist, facz0(fac), facz0h(fac), Tair, facT(fac, 1))
   !       !   stress = calc_stress(dir, uvec, norm, dist, facz0(fac), facz0h(fac), Tair, facT(fac, 1))
   !       !   write(*,*) "stress_aligned, stress_nonaligned", stress_aligned, stress
   !       ! else if (iwallmom == 3) then
   !       !   stress_aligned = calc_stress_aligned(dir, uvec, norm, dist, facz0(fac))
   !       !   stress = calc_stress(dir, uvec, norm, dist, facz0(fac))
   !       !   write(*,*) "stress_aligned, stress_nonaligned", stress_aligned, stress
   !       ! end if
   !
   !     area = secareas(sec)
   !     vol = dx*dy*dzf(k)
   !     momvol = stress * area / vol
   !     rhs(i,j,k) = rhs(i,j,k) - momvol
   !
   !   end do
   !
   ! end subroutine wallfunmom


   subroutine wallfunmom(dir, rhs, bound_info)
     use modglobal, only : ib, ie, ih, jb, je, jh, kb, ke, kh, eps1, fkar, dx, dy, dzf, iwallmom, xhat, yhat, zhat
     use modfields, only : u0, v0, w0, thl0, tau_x, tau_y, tau_z
     use initfac,   only : facT, facz0, facz0h, facnorm
     use decomp_2d, only : zstart

     real, intent(in)    :: dir(3)
     real, intent(inout) :: rhs(ib-ih:ie+ih,jb-jh:je+jh,kb:ke+kh)
     type(bound_info_type) :: bound_info

     integer i, j, k, n, m, sec, pt, fac
     real dist, stress, stress_dir, stress_aligned, area, vol, momvol, Tair, Tsurf, x, y, z, &
          utan, udir, ctm, a, a_is, a_xn, a_yn, a_zn, stress_ix, stress_iy, stress_iz
     real, dimension(3) :: uvec, norm, strm, span, stressvec
     logical :: valid

     procedure(interp_velocity), pointer :: interp_velocity_ptr => null()
     procedure(interp_temperature), pointer :: interp_temperature_ptr => null()

     select case(alignment(dir))
     case(1)
       interp_velocity_ptr => interp_velocity_u
       interp_temperature_ptr => interp_temperature_u
     case(2)
       interp_velocity_ptr => interp_velocity_v
       interp_temperature_ptr => interp_temperature_v
     case(3)
       interp_velocity_ptr => interp_velocity_w
       interp_temperature_ptr => interp_temperature_w
     end select

     do m = 1,bound_info%nfctsecsrank
       sec = bound_info%fctsecsrank(m) ! index of section
       if (bound_info%lskipsec(sec)) cycle

       n = bound_info%secbndptids(sec) ! index of boundary point
       fac = bound_info%secfacids(sec) ! index of facet
       norm = facnorm(fac,:) ! facet normal

       i = bound_info%bndpts(n,1) - zstart(1) + 1
       j = bound_info%bndpts(n,2) - zstart(2) + 1
       k = bound_info%bndpts(n,3) - zstart(3) + 1
       if ((i < ib) .or. (i > ie) .or. (j < jb) .or. (j > je)) write(*,*) "problem", i, j

       if (bound_info%lcomprec(sec)) then
         uvec = interp_velocity_ptr(i, j, k)
         if (iwallmom == 2) Tair = interp_temperature_ptr(i, j, k)
       else
         ! do different interpolation
       end if

       if (is_equal(uvec, (/0.,0.,0./))) cycle

       call local_coords(uvec, norm, span, strm, valid)
       if (.not. valid) cycle

       utan = dot_product(uvec, strm)
       dist = bound_info%bnddst(sec)

       ! calcualate momentum transfer coefficient
       ! make into interface somehow? because iwallmom doesn't change in the loop
       if (iwallmom == 2) then ! stability included
         ctm = mom_transfer_coef_stability(utan, dist, facz0(fac), facz0h(fac), Tair, facT(fac,1))
       else if (iwallmom == 3) then ! neutral
         !ctm = (fkar / log(dist / z0))**2
         ctm = mom_transfer_coef_neutral(dist, facz0(fac))
       end if

       stress = ctm * utan**2

       if (bound_info%lcomprec(sec)) then
         a = dot_product(dir, strm)
         stress_dir = a * stress
         !write(*,*) "stress_dir", sign(stress_dir, dot_product(uvec, dir))
       else
         ! Rotation from local (strm,span,norm) to global (xhat,yhat,zhat) basis
         ! \tau'_ij = a_ip a_jq \tau_pq
         ! \tau_pq in local coordinates is something like \tau \delta_13, because we only have \tau_{strm,norm})
         a_is = dot_product(dir, strm)
         a_xn = dot_product(xhat, norm)
         a_yn = dot_product(yhat, norm)
         a_zn = dot_product(zhat, norm)

         stress_ix = a_is * a_xn * stress
         stress_iy = a_is * a_yn * stress
         stress_iz = a_is * a_zn * stress

         stressvec(1) = stress_ix
         stressvec(2) = stress_iy
         stressvec(3) = stress_iz
         stress_dir = norm2(stressvec)
         !write(*,*) "stress_dir", sign(stress_dir, dot_product(uvec, dir))
       end if

       stress_dir = sign(stress_dir, dot_product(uvec, dir))

         ! if (iwallmom == 2) then
         !   stress_aligned = calc_stress_aligned(dir, uvec, norm, dist, facz0(fac), facz0h(fac), Tair, facT(fac, 1))
         !   stress = calc_stress(dir, uvec, norm, dist, facz0(fac), facz0h(fac), Tair, facT(fac, 1))
         !   write(*,*) "stress_aligned, stress_nonaligned", stress_aligned, stress
         ! else if (iwallmom == 3) then
         !   stress_aligned = calc_stress_aligned(dir, uvec, norm, dist, facz0(fac))
         !   stress = calc_stress(dir, uvec, norm, dist, facz0(fac))
         !   write(*,*) "stress_aligned, stress_nonaligned", stress_aligned, stress
         ! end if

       area = bound_info%secareas(sec)
       vol = dx*dy*dzf(k)
       momvol = stress * area / vol
       rhs(i,j,k) = rhs(i,j,k) - momvol

     end do

   end subroutine wallfunmom


   ! real function calc_stress_aligned(dir, uvec, norm, dist, z0, z0h, Tair, Tsurf) ! make interface which excludes z0h and Tsurf for neutral cases
   !   use modglobal, only : iwallmom, xhat, yhat, zhat, eps1, fkar
   !
   !   real, intent(in) :: dist, z0
   !   real, intent(in), optional :: z0h, Tair, Tsurf
   !   real, dimension(3), intent(in) :: uvec, dir, norm
   !
   !   real :: utan, udir, ctm, stress, a
   !   real, dimension(3) :: strm, span, stressvec
   !   logical :: valid
   !
   !   !udir = dot_product(uvec, dir)
   !   call local_coords(uvec, norm, span, strm, valid)
   !   utan = dot_product(uvec, strm)
   !   write(*,*) "utan", utan
   !
   !   if (.not. valid) then
   !     calc_stress_aligned = 0.
   !     return
   !   end if
   !
   !   ! make interface
   !   if (iwallmom == 2) then ! stability included
   !     ctm = mom_transfer_coef_stability(utan, dist, z0, z0h, Tair, Tsurf)
   !   else if (iwallmom == 3) then ! neutral
   !     !ctm = (fkar / log(dist / z0))**2
   !     ctm = mom_transfer_coef_neutral(dist, z0)
   !   end if
   !   ! Possibly output transfer coefficient (ctm) here?
   !   write(*,*) "ctm", ctm
   !   !stress = ctm * udir**2 ! uDALES 1 - don't think this is right!
   !   stress = ctm * utan**2
   !   write(*,*) "stress", stress
   !
   !   a = dot_product(dir, strm) ! angle factor
   !   calc_stress_aligned = sign(a*stress, dot_product(uvec, dir))
   !
   ! end function calc_stress_aligned
   !
   !
   !
   !
   ! real function calc_stress(dir, uvec, norm, dist, z0, z0h, Tair, Tsurf) ! make interface which excludes z0h and Tsurf for neutral cases
   !   use modglobal, only : iwallmom, xhat, yhat, zhat, eps1, fkar
   !
   !   real, intent(in) :: dist, z0
   !   real, intent(in), optional :: z0h, Tair, Tsurf
   !   real, dimension(3), intent(in) :: uvec, dir, norm
   !
   !   real :: utan, a_is, a_xn, a_yn, a_zn, ctm, stress_ix, stress_iy, stress_iz, stress
   !   real, dimension(3) :: strm, span, stressvec
   !   logical :: valid
   !
   !   ! span = cross_product(norm, uvec)
   !   ! if (norm2(span) < eps1) then
   !   !   calc_stress = 0.        ! velocity is pointing into or outof the surface, so no tangential component
   !   !   return
   !   ! else
   !   !   span = span / norm2(span)
   !   ! end if
   !   ! strm = cross_product(span, norm)
   !
   !   call local_coords(uvec, norm, span, strm, valid)
   !   utan = dot_product(uvec, strm)
   !   write(*,*) "utan", utan
   !
   !   if (.not. valid) then
   !     calc_stress = 0.
   !     return
   !   end if
   !
   !   write(*,*) "a_is, a_xn, a_yn, a_zn", a_is, a_xn, a_yn, a_zn
   !
   !   if (iwallmom == 2) then ! stability included
   !     ctm = mom_transfer_coef_stability(utan, dist, z0, z0h, Tair, Tsurf)
   !   else if (iwallmom == 3) then ! neutral
   !     !ctm = (fkar / log(dist / z0))**2
   !     ctm = mom_transfer_coef_neutral(dist, z0)
   !   end if
   !
   !   ! Possibly output transfer coefficient (ctm) here?
   !   write(*,*) "ctm", ctm
   !   stress = ctm * utan**2
   !   write(*,*) "stress", stress
   !
   !   ! Rotation from local (strm,span,norm) to global (xhat,yhat,zhat) basis
   !   ! \tau'_ij = a_ip a_jq \tau_pq
   !   ! \tau_pq in local coordinates is something like \tau \delta_13, because we only have \tau_{strm,norm})
   !   a_is = dot_product(dir, strm)
   !   a_xn = dot_product(xhat, norm)
   !   a_yn = dot_product(yhat, norm)
   !   a_zn = dot_product(zhat, norm)
   !
   !   stress_ix = a_is * a_xn * stress
   !   stress_iy = a_is * a_yn * stress
   !   stress_iz = a_is * a_zn * stress
   !
   !   stressvec(1) = stress_ix
   !   stressvec(2) = stress_iy
   !   stressvec(3) = stress_iz
   !   write(*,*) "stressvec", stressvec
   !   calc_stress  = sign(norm2(stressvec), dot_product(uvec, dir))
   !
   ! end function calc_stress


   ! subroutine wallfuntemp
   !   use modglobal, only : ib, ie, ih, jb, je, jh, kb, ke, kh, eps1, fkar, dx, dy, dzh, xhat, yhat, zhat, lEB, iwalltemp
   !   use modfields, only : u0, v0, w0, thl0, thlp
   !   use initfac,   only : facT, facz0, facz0h, faca, fachf, facqsat, fachurel
   !   use modsurfdata, only : z0, z0h
   !   use modibmdata, only : bctfxm, bctfxp, bctfym, bctfyp, bctfz
   !   use decomp_2d, only : zstart
   !
   !
   !   integer i, j, k, n, m, sec, fac
   !   real :: dist, flux, area, vol, tempvol, Tair, Tsurf, utan, cth
   !   real, dimension(3) :: uvec, norm, span, strm
   !
   !   do m = 1,nfctsecsrank_c
   !     sec = fctsecsrank_c(m) ! index of section
   !     n = secbndptids_c(sec) ! index of boundary point
   !     fac = secfacids_c(sec) ! index of facet
   !
   !     i = bndpts_c(n,1) - zstart(1) + 1 ! should be on this rank!
   !     j = bndpts_c(n,2) - zstart(2) + 1 ! should be on this rank!
   !     k = bndpts_c(n,3) - zstart(3) + 1 ! should be on this rank!
   !     if ((i < ib) .or. (i > ie) .or. (j < jb) .or. (j > je)) write(*,*) "problem", i, j
   !
   !     if (lcomprec_c(sec)) then ! Section aligned with grid - don't interpolate, use this point's velocity
   !         ! currently assumes all no other neighbouring solid points?
   !         uvec(1) = 0.125 * sum(u0(i-1:i,j-1:j,k-1:k))
   !         uvec(2) = 0.125 * sum(v0(i-1:i,j-1:j,k-1:k))
   !         uvec(3) = 0.125 * sum(w0(i-1:i,j-1:j,k-1:k))
   !         Tair = thl0(i,j,k)
   !         dist = bnddst_c(sec)
   !     else ! Interpolate velocities at reconstruction point
   !       write(0, *) 'ERROR: interp at reconstruction point not supported'
   !       stop 1
   !     end if
   !
   !     if (all(abs(uvec) < eps1)) cycle
   !
   !     ! local coordinate system
   !     norm(1) = bndvec_c(sec,1)
   !     norm(2) = bndvec_c(sec,2)
   !     norm(3) = bndvec_c(sec,3)
   !     span = cross_product(norm, uvec)
   !     if (norm2(span) < eps1) then
   !       return ! velocity is pointing into or outof the surface, so no tangential component
   !     else
   !       span = span / norm2(span)
   !     end if
   !     strm = cross_product(span, norm)
   !     utan = dot_product(uvec, strm)
   !
   !     ! Wall function
   !     if (iwalltemp == 1) then
   !        if     (all(abs(norm - xhat) < eps1)) then
   !          flux = bctfxp
   !        elseif (all(abs(norm + xhat) < eps1)) then
   !          flux = bctfxm
   !        elseif (all(abs(norm - yhat) < eps1)) then
   !            flux = bctfyp
   !        elseif (all(abs(norm + yhat) < eps1)) then
   !            flux = bctfxm
   !        elseif (all(abs(norm - zhat) < eps1)) then
   !            flux = bctfz
   !        end if
   !
   !     elseif (iwalltemp == 2) then
   !        call unoh(utan, dist, facz0(fac), facz0h(fac), Tair, facT(fac, 1), cth, flux) ! Outputs heat transfer coefficient (cth) as well as flux
   !        fctsecscth(m) = cth
   !     end if
   !     ! Heat transfer coefficient (cth) could be output here
   !     ! flux [Km/s]
   !     ! fluid volumetric sensible heat source/sink = flux * area / volume [K/s]
   !     ! facet sensible heat flux = volumetric heat capacity of air * flux * sectionarea / facetarea [W/m^2]
   !     thlp(i,j,k) = thlp(i,j,k) - flux * secareas_c(sec) / (dx*dy*dzh(k))
   !
   !     if (lEB) then
   !       fachf(fac) = fachf(fac) + flux * secareas_c(sec) ! [Km^2/s] (will be divided by facetarea(fac) in modEB)
   !     end if
   !
   !   end do
   !
   ! end subroutine wallfuntemp


   ! subroutine wallfunmoist
   !   use modglobal, only : ib, ie, ih, jb, je, jh, kb, ke, kh, eps1, fkar, dx, dy, dzh, xhat, yhat, zhat, lEB, iwalltemp
   !   use modfields, only : u0, v0, w0, qt0, qtp
   !   use initfac,   only : facT, facz0, facz0h, fachf, faca
   !   use modsurfdata, only : z0, z0h
   !   use modibmdata, only : bcqfxm, bcqfxp, bcqfym, bcqfyp, bcqfz
   !   use decomp_2d, only : zstart
   !
   !
   !   integer i, j, k, n, m, sec, fac
   !   real :: dist, flux, area, vol, tempvol, Tair, Tsurf, utan, cth, cveg, hurel, qtair, qwall, resc, ress
   !   real, dimension(3) :: uvec, norm, span, strm
   !
   !   do m = 1,nfctsecsrank_c
   !     sec = fctsecsrank_c(m) ! index of section
   !     n = secbndptids_c(sec) ! index of boundary point
   !     fac = secfacids_c(sec) ! index of facet
   !
   !     i = bndpts_c(n,1) - zstart(1) + 1 ! should be on this rank!
   !     j = bndpts_c(n,2) - zstart(2) + 1 ! should be on this rank!
   !     k = bndpts_c(n,3) - zstart(3) + 1 ! should be on this rank!
   !     if ((i < ib) .or. (i > ie) .or. (j < jb) .or. (j > je)) write(*,*) "problem", i, j
   !
   !     if (lcomprec_c(sec)) then ! Section aligned with grid - don't interpolate, use this point's velocity
   !         ! currently assumes all no other neighbouring solid points?
   !         uvec(1) = 0.125 * sum(u0(i-1:i,j-1:j,k-1:k))
   !         uvec(2) = 0.125 * sum(v0(i-1:i,j-1:j,k-1:k))
   !         uvec(3) = 0.125 * sum(w0(i-1:i,j-1:j,k-1:k))
   !         qtair = qt0(i,j,k)
   !         dist = bnddst_c(sec)
   !     else ! Interpolate velocities at reconstruction point
   !       write(0, *) 'ERROR: interp at reconstruction point not supported'
   !       stop 1
   !     end if
   !
   !     if (all(abs(uvec) < eps1)) cycle
   !
   !     ! local coordinate system
   !     norm(1) = bndvec_c(sec,1)
   !     norm(2) = bndvec_c(sec,2)
   !     norm(3) = bndvec_c(sec,3)
   !     span = cross_product(norm, uvec)
   !     if (norm2(span) < eps1) then
   !       return ! velocity is pointing into or outof the surface, so no tangential component
   !     else
   !       span = span / norm2(span)
   !     end if
   !     strm = cross_product(span, norm)
   !     utan = dot_product(uvec, strm)
   !
   !     ! Wall function
   !     if (iwallmoist == 1) then
   !        if     (all(abs(norm - xhat) < eps1)) then
   !          flux = bcqfxp
   !        elseif (all(abs(norm + xhat) < eps1)) then
   !          flux = bcqfxm
   !        elseif (all(abs(norm - yhat) < eps1)) then
   !            flux = bcqfyp
   !        elseif (all(abs(norm + yhat) < eps1)) then
   !            flux = bcqfxm
   !        elseif (all(abs(norm - zhat) < eps1)) then
   !            flux = bcqfz
   !        end if
   !
   !     elseif (iwallmoist == 2) then
   !       qwall = facqsat(fac)
   !       hurel = fachurel(fac)
   !       resc = facf(fac,4)
   !       ress = facf(fac,5)
   !       cth = fctsecscth(m) ! should have been defined in wallfuntemp
   !       cveg = 0.8
   !        !flux = min(0., cveg*(qtair - qwall) * 1 / (1 / icth(i,j,k) + resc)+(1-cveg)*(qcell(i,j,k)-qwall*hurel)*1/(1/icth(i,j,k)+ress))
   !        flux = min(0., cveg * (qtair - qwall)         / (1/cth + resc) + &
   !                  (1 - cveg)* (qtair - qwall * hurel) / (1/cth + ress))
   !     end if
   !
   !     ! flux [kg/kg m/s]
   !     ! fluid volumetric latent heat source/sink = flux * area / volume [kg/kg / s]
   !     ! facet latent heat flux = volumetric heat capacity of air * flux * sectionarea / facetarea [W/m^2]
   !     qtp(i,j,k) = qtp(i,j,k) - flux * secareas_c(sec) / (dx*dy*dzh(k))
   !
   !     if (lEB) then
   !       facef(fac) = facef(fac) + flux * secareas_c(sec) ! [Km^2/s] (will be divided by facetarea(fac) in modEB)
   !     end if
   !
   !   end do
   !
   ! end subroutine wallfunmoist


   ! subroutine wallfunheat_old
   !   use modglobal, only : ib, ie, ih, jb, je, jh, kb, ke, kh, dx, dy, dzh, xhat, yhat, zhat,  &
   !                        eps1, fkar, ltempeq, lmoist, iwalltemp, iwallmoist, lEB
   !   use modfields, only : u0, v0, w0, thl0, thlp, qt0, qtp
   !   use initfac,   only : facT, facz0, facz0h, facnorm, faca, fachf, facef, facqsat, fachurel, facf
   !   use modsurfdata, only : z0, z0h
   !   use modibmdata, only : bctfxm, bctfxp, bctfym, bctfyp, bctfz
   !   use decomp_2d, only : zstart
   !
   !
   !   integer i, j, k, n, m, sec, fac
   !   real :: dist, flux, area, vol, tempvol, Tair, Tsurf, utan, cth, cveg, hurel, qtair, qwall, resc, ress
   !   real, dimension(3) :: uvec, norm, span, strm
   !   logical :: valid
   !
   !   do m = 1,nfctsecsrank_c
   !     sec = fctsecsrank_c(m) ! index of section
   !     n = secbndptids_c(sec) ! index of boundary point
   !     fac = secfacids_c(sec) ! index of facet
   !     norm = facnorm(fac,:)
   !
   !     i = bndpts_c(n,1) - zstart(1) + 1 ! should be on this rank!
   !     j = bndpts_c(n,2) - zstart(2) + 1 ! should be on this rank!
   !     k = bndpts_c(n,3) - zstart(3) + 1 ! should be on this rank!
   !     if ((i < ib) .or. (i > ie) .or. (j < jb) .or. (j > je)) write(*,*) "problem", i, j
   !
   !     if (lcomprec_c(sec)) then ! section aligned with grid - use this cell's velocity
   !       uvec = interp_velocity_c(i, j, k)
   !       Tair = thl0(i,j,k)
   !       qtair = qt0(i,j,k)
   !       dist = bnddst_c(sec)
   !     else ! use velocity at reconstruction point
   !       write(0, *) 'ERROR: interp at reconstruction point not supported'
   !       stop 1
   !       ! uvec(1) = trilinear_interp(x, y, z, xh(ig), yf(jg), zf(kg), xh(ig+1), yf(jg+1), zf(kg+1), eval_corners(u, i, j, k))
   !       ! uvec(2) = trilinear_interp(x, y, z, xf(ig), yh(jg), zf(kg), xf(ig+1), yh(jg+1), zf(kg+1), eval_corners(v, i, j, k))
   !       ! uvec(3) = trilinear_interp(x, y, z, xf(ig), yf(jg), zh(kg), xf(ig+1), yf(jg+1), zh(kg+1), eval_corners(w, i, j, k))
   !       ! dist = bnddst_c(sec) + ...
   !     end if
   !
   !     if (all(abs(uvec) < eps1)) cycle
   !
   !     ! span = cross_product(norm, uvec)
   !     ! if (norm2(span) < eps1) then
   !     !   return ! velocity is pointing into or outof the surface, so no tangential component
   !     ! else
   !     !   span = span / norm2(span)
   !     ! end if
   !     ! strm = cross_product(span, norm)
   !
   !     call local_coords(uvec, norm, span, strm, valid)
   !     if (.not. valid) cycle
   !     utan = dot_product(uvec, strm)
   !
   !     ! Sensible heat
   !     if (ltempeq) then
   !       if (iwalltemp == 1) then ! probably remove this eventually, only relevant to grid-aligned facets
   !         if     (all(abs(norm - xhat) < eps1)) then
   !           flux = bctfxp
   !         elseif (all(abs(norm + xhat) < eps1)) then
   !           flux = bctfxm
   !         elseif (all(abs(norm - yhat) < eps1)) then
   !           flux = bctfyp
   !         elseif (all(abs(norm + yhat) < eps1)) then
   !           flux = bctfxm
   !         elseif (all(abs(norm - zhat) < eps1)) then
   !           flux = bctfz
   !         end if
   !
   !       elseif (iwalltemp == 2) then
   !         call heat_transfer_coef_flux(utan, dist, facz0(fac), facz0h(fac), Tair, facT(fac, 1), cth, flux) ! Outputs heat transfer coefficient (cth) as well as flux
   !         !fctsecscth(m) = cth
   !       end if
   !
   !       ! Heat transfer coefficient (cth) could be output here
   !       ! flux [Km/s]
   !       ! fluid volumetric sensible heat source/sink = flux * area / volume [K/s]
   !       ! facet sensible heat flux = volumetric heat capacity of air * flux * sectionarea / facetarea [W/m^2]
   !       thlp(i,j,k) = thlp(i,j,k) - flux * secareas_c(sec) / (dx*dy*dzh(k))
   !
   !       if (lEB) then
   !         fachf(fac) = fachf(fac) + flux * secareas_c(sec) ! [Km^2/s] (will be divided by facetarea(fac) in modEB)
   !       end if
   !     end if
   !
   !     ! Latent heat
   !     if (lmoist) then
   !       if (iwallmoist == 1) then ! probably remove this eventually, only relevant to grid-aligned facets
   !         if     (all(abs(norm - xhat) < eps1)) then
   !           flux = bcqfxp
   !         elseif (all(abs(norm + xhat) < eps1)) then
   !           flux = bcqfxm
   !         elseif (all(abs(norm - yhat) < eps1)) then
   !           flux = bcqfyp
   !         elseif (all(abs(norm + yhat) < eps1)) then
   !           flux = bcqfxm
   !         elseif (all(abs(norm - zhat) < eps1)) then
   !           flux = bcqfz
   !         end if
   !
   !       elseif (iwallmoist == 2) then
   !         qwall = facqsat(fac)
   !         hurel = fachurel(fac)
   !         resc = facf(fac,4)
   !         ress = facf(fac,5)
   !         !cth = fctsecscth(m) ! should have been defined in wallfuntemp
   !         cveg = 0.8
   !         !flux = min(0., cveg*(qtair - qwall) * 1 / (1 / icth(i,j,k) + resc)+(1-cveg)*(qcell(i,j,k)-qwall*hurel)*1/(1/icth(i,j,k)+ress))
   !         flux = min(0., cveg * (qtair - qwall)         / (1/cth + resc) + &
   !                   (1 - cveg)* (qtair - qwall * hurel) / (1/cth + ress))
   !       end if
   !
   !       ! flux [kg/kg m/s]
   !       ! fluid volumetric latent heat source/sink = flux * area / volume [kg/kg / s]
   !       ! facet latent heat flux = volumetric heat capacity of air * flux * sectionarea / facetarea [W/m^2]
   !       qtp(i,j,k) = qtp(i,j,k) - flux * secareas_c(sec) / (dx*dy*dzh(k))
   !
   !       if (lEB) then
   !         facef(fac) = facef(fac) + flux * secareas_c(sec) ! [Km^2/s] (will be divided by facetarea(fac) in modEB)
   !       end if
   !     end if
   !
   !   end do
   !
   ! end subroutine wallfunheat_old


   subroutine wallfunheat
     use modglobal, only : ib, ie, ih, jb, je, jh, kb, ke, kh, dx, dy, dzh, xhat, yhat, zhat,  &
                          eps1, fkar, ltempeq, lmoist, iwalltemp, iwallmoist, lEB
     use modfields, only : u0, v0, w0, thl0, thlp, qt0, qtp
     use initfac,   only : facT, facz0, facz0h, facnorm, faca, fachf, facef, facqsat, fachurel, facf
     use modsurfdata, only : z0, z0h
     use modibmdata, only : bctfxm, bctfxp, bctfym, bctfyp, bctfz
     use decomp_2d, only : zstart

     type(bound_info_type) :: bound_info
     integer i, j, k, n, m, sec, fac
     real :: dist, flux, area, vol, tempvol, Tair, Tsurf, utan, cth, cveg, hurel, qtair, qwall, resc, ress
     real, dimension(3) :: uvec, norm, span, strm
     logical :: valid

     bound_info = bound_info_c

     do m = 1,bound_info%nfctsecsrank
       sec = bound_info%fctsecsrank(m) ! index of section
       n =   bound_info%secbndptids(sec) ! index of boundary point
       fac = bound_info%secfacids(sec) ! index of facet
       norm = facnorm(fac,:)

       i = bound_info%bndpts(n,1) - zstart(1) + 1 ! should be on this rank!
       j = bound_info%bndpts(n,2) - zstart(2) + 1 ! should be on this rank!
       k = bound_info%bndpts(n,3) - zstart(3) + 1 ! should be on this rank!
       if ((i < ib) .or. (i > ie) .or. (j < jb) .or. (j > je)) write(*,*) "problem", i, j

       if (bound_info%lcomprec(sec)) then ! section aligned with grid - use this cell's velocity
         uvec = interp_velocity_c(i, j, k)
         Tair = thl0(i,j,k)
         qtair = qt0(i,j,k)
         dist = bound_info%bnddst(sec)
       else ! use velocity at reconstruction point
         write(0, *) 'ERROR: interp at reconstruction point not supported'
         stop 1
         ! uvec(1) = trilinear_interp(x, y, z, xh(ig), yf(jg), zf(kg), xh(ig+1), yf(jg+1), zf(kg+1), eval_corners(u, i, j, k))
         ! uvec(2) = trilinear_interp(x, y, z, xf(ig), yh(jg), zf(kg), xf(ig+1), yh(jg+1), zf(kg+1), eval_corners(v, i, j, k))
         ! uvec(3) = trilinear_interp(x, y, z, xf(ig), yf(jg), zh(kg), xf(ig+1), yf(jg+1), zh(kg+1), eval_corners(w, i, j, k))
         ! dist = bnddst_c(sec) + ...
       end if

       if (all(abs(uvec) < eps1)) cycle

       ! span = cross_product(norm, uvec)
       ! if (norm2(span) < eps1) then
       !   return ! velocity is pointing into or outof the surface, so no tangential component
       ! else
       !   span = span / norm2(span)
       ! end if
       ! strm = cross_product(span, norm)

       call local_coords(uvec, norm, span, strm, valid)
       if (.not. valid) cycle
       utan = dot_product(uvec, strm)

       ! Sensible heat
       if (ltempeq) then
         if (iwalltemp == 1) then ! probably remove this eventually, only relevant to grid-aligned facets
           if     (all(abs(norm - xhat) < eps1)) then
             flux = bctfxp
           elseif (all(abs(norm + xhat) < eps1)) then
             flux = bctfxm
           elseif (all(abs(norm - yhat) < eps1)) then
             flux = bctfyp
           elseif (all(abs(norm + yhat) < eps1)) then
             flux = bctfxm
           elseif (all(abs(norm - zhat) < eps1)) then
             flux = bctfz
           end if

         elseif (iwalltemp == 2) then
           call heat_transfer_coef_flux(utan, dist, facz0(fac), facz0h(fac), Tair, facT(fac, 1), cth, flux) ! Outputs heat transfer coefficient (cth) as well as flux
           !fctsecscth(m) = cth
         end if

         ! Heat transfer coefficient (cth) could be output here
         ! flux [Km/s]
         ! fluid volumetric sensible heat source/sink = flux * area / volume [K/s]
         ! facet sensible heat flux = volumetric heat capacity of air * flux * sectionarea / facetarea [W/m^2]
         thlp(i,j,k) = thlp(i,j,k) - flux * bound_info%secareas(sec) / (dx*dy*dzh(k))

         if (lEB) then
           fachf(fac) = fachf(fac) + flux * bound_info%secareas(sec) ! [Km^2/s] (will be divided by facetarea(fac) in modEB)
         end if
       end if

       ! Latent heat
       if (lmoist) then
         if (iwallmoist == 1) then ! probably remove this eventually, only relevant to grid-aligned facets
           if     (all(abs(norm - xhat) < eps1)) then
             flux = bcqfxp
           elseif (all(abs(norm + xhat) < eps1)) then
             flux = bcqfxm
           elseif (all(abs(norm - yhat) < eps1)) then
             flux = bcqfyp
           elseif (all(abs(norm + yhat) < eps1)) then
             flux = bcqfxm
           elseif (all(abs(norm - zhat) < eps1)) then
             flux = bcqfz
           end if

         elseif (iwallmoist == 2) then
           qwall = facqsat(fac)
           hurel = fachurel(fac)
           resc = facf(fac,4)
           ress = facf(fac,5)
           !cth = fctsecscth(m) ! should have been defined in wallfuntemp
           cveg = 0.8
           !flux = min(0., cveg*(qtair - qwall) * 1 / (1 / icth(i,j,k) + resc)+(1-cveg)*(qcell(i,j,k)-qwall*hurel)*1/(1/icth(i,j,k)+ress))
           flux = min(0., cveg * (qtair - qwall)         / (1/cth + resc) + &
                     (1 - cveg)* (qtair - qwall * hurel) / (1/cth + ress))
         end if

         ! flux [kg/kg m/s]
         ! fluid volumetric latent heat source/sink = flux * area / volume [kg/kg / s]
         ! facet latent heat flux = volumetric heat capacity of air * flux * sectionarea / facetarea [W/m^2]
         qtp(i,j,k) = qtp(i,j,k) - flux * bound_info%secareas(sec) / (dx*dy*dzh(k))

         if (lEB) then
           facef(fac) = facef(fac) + flux * bound_info%secareas(sec) ! [Km^2/s] (will be divided by facetarea(fac) in modEB)
         end if
       end if

     end do

   end subroutine wallfunheat


   real function trilinear_interp(x, y, z, x0, y0, z0, x1, y1, z1, corners)
     real, intent(in) :: x, y, z, x0, y0, z0, x1, y1, z1, corners(8)
     real :: xd, yd, zd

     xd = (x - x0) / (x1 - x0)
     yd = (y - y0) / (y1 - y0)
     zd = (z - z0) / (z1 - z0)
     ! check all positive

     trilinear_interp = corners(1) * (1-xd)*(1-yd)*(1-zd) + &
                        corners(2) * (  xd)*(1-yd)*(1-zd) + &
                        corners(3) * (1-xd)*(  yd)*(1-zd) + &
                        corners(4) * (1-xd)*(1-yd)*(  zd) + &
                        corners(5) * (  xd)*(1-yd)*(  zd) + &
                        corners(6) * (1-xd)*(  yd)*(  zd) + &
                        corners(7) * (  xd)*(1-yd)*(1-zd) + &
                        corners(8) * (  xd)*(  yd)*(  zd)

   end function trilinear_interp


   ! real(8) function eval_corners(var, i, j, k)
   !   use modglobal, only : ib, ie, ih, jb, je, jh, kb, ke, kh
   !   real, intent(in)    :: var(ib-ih:ie+ih,jb-jh,je+jh,kb-kh,kb+kh)
   !   integer, intent(in) :: i, j, k ! LOCAL indices
   !
   !   ! Not actually this simple...
   !   eval_corners(1) = var(i-1,j-1,k-1)
   !   eval_corners(2) = var(i  ,j-1,k-1)
   !   eval_corners(3) = var(i-1,j  ,k-1)
   !   eval_corners(4) = var(i  ,j  ,k-1)
   !   eval_corners(5) = var(i-1,j-1,k  )
   !   eval_corners(6) = var(i  ,j-1,k  )
   !   eval_corners(7) = var(i-1,j  ,k  )
   !   eval_corners(8) = var(i  ,j  ,k  )
   !
   ! end function eval_corners


   integer function alignment(n)
     use modglobal, only : xhat, yhat, zhat
     implicit none
     real, dimension(3), intent(in) :: n ! must be unit vector

     if     (is_equal(n, xhat)) then
       alignment = 1
     elseif (is_equal(n, yhat)) then
       alignment = 2
     elseif (is_equal(n, zhat)) then
       alignment = 3
     elseif (is_equal(n, -xhat)) then
       alignment = -1
     elseif (is_equal(n, -yhat)) then
       alignment = -2
     elseif (is_equal(n, -zhat)) then
       alignment = -3
     else
       alignment = 0
     end if

   end function alignment


   logical function is_equal(a,b)
     use modglobal, only : eps1
     implicit none
     real, dimension(3), intent(in) :: a, b

     if (all(abs(a - b) < eps1)) then
       is_equal = .true.
     else
       is_equal = .false.
     end if

   end function is_equal


   function cross_product(a,b)
     implicit none
     real, dimension(3) :: cross_product
     real, dimension(3), intent(in) :: a, b

     cross_product(1) = a(2)*b(3) - a(3)*b(2)
     cross_product(2) = a(3)*b(1) - a(1)*b(3)
     cross_product(3) = a(1)*b(2) - a(2)*b(1)

   end function cross_product



      function interp_velocity_u(i, j, k)
        use modfields, only :  u0, v0, w0
        real ::  interp_velocity_u(3)
        integer, intent(in) :: i, j, k

        interp_velocity_u(1) = u0(i,j,k)
        interp_velocity_u(2) = 0.25 * (v0(i,j,k) + v0(i,j+1,k) + v0(i-1,j,k) + v0(i-1,j+1,k))
        interp_velocity_u(3) = 0.25 * (w0(i,j,k) + w0(i,j,k+1) + w0(i-1,j,k) + w0(i-1,j,k+1)) !only for equidistant grid!

        return
      end function interp_velocity_u


      function interp_velocity_v(i, j, k)
        use modfields, only :  u0, v0, w0
        real ::  interp_velocity_v(3)
        integer, intent(in) :: i, j, k

        interp_velocity_v(1) = 0.25 * (u0(i,j,k) + u0(i+1,j,k) + u0(i,j-1,k) + u0(i+1,j-1,k))
        interp_velocity_v(2) = v0(i,j,k)
        interp_velocity_v(3) = 0.25 * (w0(i,j,k) + w0(i,j,k+1) + w0(i,j-1,k) + w0(i,j-1,k+1)) !only for equidistant grid!

        return
      end function interp_velocity_v


      function interp_velocity_w(i, j, k)
        use modfields, only :  u0, v0, w0
        real ::  interp_velocity_w(3)
        integer, intent(in) :: i, j, k

        interp_velocity_w(1) = 0.25 * (u0(i,j,k) + u0(i+1,j,k) + u0(i,j-1,k) + u0(i+1,j-1,k))
        interp_velocity_w(2) = v0(i,j,k)
        interp_velocity_w(3) = 0.25 * (w0(i,j,k) + w0(i,j,k+1) + w0(i,j-1,k) + w0(i,j-1,k+1)) !only for equidistant grid!

        return
      end function interp_velocity_w


      function interp_velocity_c(i, j, k)
        use modfields, only :  u0, v0, w0
        real ::  interp_velocity_c(3)
        integer, intent(in) :: i, j, k

        interp_velocity_c(1) = 0.5 * (u0(i,j,k) + u0(i+1,j,k))
        interp_velocity_c(2) = 0.5 * (v0(i,j,k) + v0(i,j+1,k))
        interp_velocity_c(3) = 0.5 * (w0(i,j,k) + w0(i,j,k+1))

        return
      end function interp_velocity_c


      real function interp_temperature_u(i, j, k)
        use modfields, only :  thl0
        integer, intent(in) :: i, j, k

        interp_temperature_u = 0.5 * (thl0(i,j,k) + thl0(i-1,j,k))

        return
      end function interp_temperature_u


      real function interp_temperature_v(i, j, k)
        use modfields, only :  thl0
        integer, intent(in) :: i, j, k

        interp_temperature_v = 0.5 * (thl0(i,j,k) + thl0(i,j-1,k))

        return
      end function interp_temperature_v


      real function interp_temperature_w(i, j, k)
        use modfields, only :  thl0
        integer, intent(in) :: i, j, k

        interp_temperature_w = 0.5 * (thl0(i,j,k) + thl0(i,j,k-1))

        return
      end function interp_temperature_w


      subroutine local_coords(uvec, norm, span, strm, valid)
        real, intent(in),  dimension(3) :: uvec, norm
        real, intent(out), dimension(3) :: span, strm
        logical, intent(out) :: valid

        span = cross_product(norm, uvec)
        !if (norm2(span) < eps1) then ! velocity is pointing into or outof the surface
        if (is_equal(span, (/0.,0.,0./))) then
          strm = 0.
          valid = .false.
        else
          span = span / norm2(span)
          valid = .true.
        end if
        strm = cross_product(span, norm)

      end subroutine local_coords


   real function mom_transfer_coef_stability(utan, dist, z0, z0h, Tair, Tsurf)
     use modglobal, only : grav, prandtlmol, fkar

      implicit none
      real, intent(in) :: dist, z0, z0h, Tsurf, Tair, utan
      real, parameter :: b1 = 9.4 !parameters from uno1995
      real, parameter :: b2 = 4.7
      real, parameter :: dm = 7.4
      real, parameter :: dh = 5.3
      real :: dT, Ribl0, logdz, logdzh, logzh, sqdz, fkar2, Ribl1, Fm, Fh, cm, ch, Ctm, M

      dT = Tair - Tsurf
      Ribl0 = grav * dist * dT / (Tsurf * utan**2) !Eq. 6, guess initial Ri

      logdz = LOG(dist/z0)
      logdzh = LOG(dist/z0h)
      logzh = LOG(z0/z0h)
      sqdz = SQRT(dist/z0)
      fkar2 = fkar**2

      IF (Ribl0 > 0.21) THEN !0.25 approx critical for bulk Richardson number  => stable
         Fm = 1./(1. + b2*Ribl0)**2 !Eq. 4
         Fh = Fm !Eq. 4
      ELSE ! => unstable
         cm = (dm*fkar2)/(logdz**2)*b1*sqdz !Eq. 5
         ch = (dh*fkar2)/(logdz**2)*b1*sqdz !Eq. 5
         Fm = 1. - (b1*Ribl0)/(1. + cm*SQRT(ABS(Ribl0))) !Eq. 3
         Fh = 1. - (b1*Ribl0)/(1. + ch*SQRT(ABS(Ribl0))) !Eq. 3
      END IF

      M = prandtlmol*logdz*SQRT(Fm)/Fh !Eq. 14

      Ribl1 = Ribl0 - Ribl0*prandtlmol*logzh/(prandtlmol*logzh + M) !Eq. 17

      !interate to get new Richardson number
      IF (Ribl1 > 0.21) THEN !0.25 approx critical for bulk Richardson number  => stable
         Fm = 1./(1. + b2*Ribl1)**2 !Eq. 4
      ELSE ! => unstable
         cm = (dm*fkar2)/(logdz**2)*b1*sqdz !Eq. 5
         Fm = 1. - (b1*Ribl1)/(1. + cm*SQRT(ABS(Ribl1))) !Eq. 3
      END IF

      mom_transfer_coef_stability = fkar2/(logdz**2)*Fm !Eq. 7

   end function mom_transfer_coef_stability


   real function mom_transfer_coef_neutral(dist, z0)
     use modglobal, only : fkar

     implicit none
     real, intent(in) :: dist, z0

     mom_transfer_coef_neutral = (fkar / log(dist / z0))**2

   end function mom_transfer_coef_neutral


   ! !for scalar
   subroutine heat_transfer_coef_flux(utan, dist, z0, z0h, Tair, Tsurf, cth, flux)
     use modglobal, only : grav, prandtlmol, prandtlmoli, fkar

      implicit none
      real, intent(in)  :: dist, z0, z0h, Tsurf, Tair, utan
      real, intent(out) :: cth, flux
      real, parameter :: b1 = 9.4 !parameters from Uno1995
      real, parameter :: b2 = 4.7
      real, parameter :: dm = 7.4
      real, parameter :: dh = 5.3
      real :: dT, Ribl0, logdz, logdzh, logzh, sqdz, fkar2, Ribl1, Fm, Fh, cm, ch, M, dTrough


      dT = Tair - Tsurf
      Ribl0 = grav * dist * dT / (Tsurf * utan**2) !Eq. 6, guess initial Ri

      logdz = LOG(dist/z0)
      logdzh = LOG(dist/z0h)
      logzh = LOG(z0/z0h)
      sqdz = SQRT(dist/z0)
      fkar2 = fkar**2

      cth = 0.
      flux = 0.
      IF (Ribl0 > 0.21) THEN !0.25 approx critical for bulk Richardson number  => stable
         Fm = 1./(1. + b2*Ribl0)**2 !Eq. 4
         Fh = Fm !Eq. 4
      ELSE ! => unstable
         cm = (dm*fkar2)/(logdz**2)*b1*sqdz !Eq. 5
         ch = (dh*fkar2)/(logdz**2)*b1*sqdz !Eq. 5
         Fm = 1. - (b1*Ribl0)/(1. + cm*SQRT(ABS(Ribl0))) !Eq. 3
         Fh = 1. - (b1*Ribl0)/(1. + ch*SQRT(ABS(Ribl0))) !Eq. 3
      END IF

      M = prandtlmol*logdz*SQRT(Fm)/Fh !Eq. 14

      Ribl1 = Ribl0 - Ribl0*prandtlmol*logzh/(prandtlmol*logzh + M) !Eq. 17

      !interate to get new Richardson number
      IF (Ribl1 > 0.21) THEN !0.25 approx critical for bulk Richardson number  => stable
         Fm = 1./(1. + b2*Ribl1)**2 !Eq. 4
         Fh = Fm !Eq. 4
      ELSE ! => unstable
         cm = (dm*fkar2)/(logdz**2)*b1*sqdz !Eq. 5
         ch = (dh*fkar2)/(logdz**2)*b1*sqdz !Eq. 5
         Fm = 1. - (b1*Ribl1)/(1. + cm*SQRT(ABS(Ribl1))) !Eq. 3
         Fh = 1. - (b1*Ribl1)/(1. + ch*SQRT(ABS(Ribl1))) !Eq. 3
      END IF
      M = prandtlmol*logdz*SQRT(Fm)/Fh !Eq. 14

      dTrough = dT*1./(prandtlmol*logzh/M + 1.) !Eq. 13a

      cth = abs(utan)*fkar2/(logdz*logdzh)*prandtlmoli*Fh !Eq. 8
      flux = cth*dTrough !Eq. 2, Eq. 8

   END SUBROUTINE heat_transfer_coef_flux




   subroutine bottom
      !kind of obsolete when road facets are being used
      !vegetated floor not added (could simply be copied from vegetated horizontal facets)
      use modglobal, only:ib, ie, ih, jh, kb,ke,kh, jb, je, kb, numol, prandtlmol, dzh, nsv, &
         dxf, dxhi, dzf, dzfi, numoli, ltempeq, khc, lmoist, BCbotT, BCbotq, BCbotm, BCbots, dzh2i
      use modfields, only : u0,v0,e120,um,vm,w0,wm,e12m,thl0,qt0,sv0,thlm,qtm,svm,up,vp,wp,thlp,qtp,svp,shear,momfluxb,tfluxb,cth,tau_x,tau_y,tau_z,thl_flux
      use modsurfdata, only:thlflux, qtflux, svflux, ustar, thvs, wtsurf, wqsurf, thls, z0, z0h
      use modsubgriddata, only:ekm, ekh
      use modmpi, only:myid
      implicit none
      integer :: i, j, jp, jm, m

      e120(:, :, kb - 1) = e120(:, :, kb)
      e12m(:, :, kb - 1) = e12m(:, :, kb)
      ! wm(:, :, kb) = 0. ! SO moved to modboundary
      ! w0(:, :, kb) = 0.
      tau_x(:,:,kb:ke+kh) = up
      tau_y(:,:,kb:ke+kh) = vp
      tau_z(:,:,kb:ke+kh) = wp
      thl_flux(:,:,kb:ke+kh) = thlp

      if (lbottom) then
      !momentum
      if (BCbotm.eq.2) then
      call wfuno(ih, jh, kh, up, vp, thlp, momfluxb, tfluxb, cth, bcTfluxA, u0, v0, thl0, thls, z0, z0h, 0, 1, 91)
      elseif (BCbotm.eq.3) then
      call wfmneutral(ih, jh, kh, up, vp, momfluxb, u0, v0, z0, 0, 1, 91)
      else
      write(0, *) "ERROR: bottom boundary type for momentum undefined"
      stop 1
      end if


      if (ltempeq) then
         if (BCbotT.eq.1) then !neumann/fixed flux bc for temperature
            do j = jb, je
               do i = ib, ie
                  thlp(i, j, kb) = thlp(i, j, kb) &
                                   + ( &
                                   0.5*(dzf(kb - 1)*ekh(i, j, kb) + dzf(kb)*ekh(i, j, kb - 1)) &
                                   *(thl0(i, j, kb) - thl0(i, j, kb - 1)) &
                                   *dzh2i(kb) &
                                   - wtsurf &
                                   )*dzfi(kb)
               end do
            end do
         else if (BCbotT.eq.2) then !wall function bc for temperature (fixed temperature)
            call wfuno(ih, jh, kh, up, vp, thlp, momfluxb, tfluxb, cth, bcTfluxA, u0, v0, thl0, thls, z0, z0h, 0, 1, 92)
         else
         write(0, *) "ERROR: bottom boundary type for temperature undefined"
         stop 1
         end if
      end if ! ltempeq

      if (lmoist) then
         if (BCbotq.eq.1) then !neumann/fixed flux bc for moisture
            do j = jb, je
               do i = ib, ie
                  qtp(i, j, kb) = qtp(i, j, kb) + ( &
                                  0.5*(dzf(kb - 1)*ekh(i, j, kb) + dzf(kb)*ekh(i, j, kb - 1)) &
                                  *(qt0(i, j, kb) - qt0(i, j, kb - 1)) &
                                  *dzh2i(kb) &
                                  + wqsurf &
                                  )*dzfi(kb)
               end do
            end do
         else
          write(0, *) "ERROR: bottom boundary type for moisture undefined"
          stop 1
         end if !
      end if !lmoist

      if (nsv>0) then
         if (BCbots.eq.1) then !neumann/fixed flux bc for moisture
            do j = jb, je
               do i = ib, ie
                  do m = 1, nsv
                      svp(i, j, kb, m) = svp(i, j, kb, m) + ( &
                                      0.5*(dzf(kb - 1)*ekh(i, j, kb) + dzf(kb)*ekh(i, j, kb - 1)) &
                                     *(sv0(i, j, kb, m) - sv0(i, j, kb - 1, m)) &
                                     *dzh2i(kb) &
                                     + 0. &
                                     )*dzfi(kb)
                  end do
               end do
            end do
         else
          write(0, *) "ERROR: bottom boundary type for scalars undefined"
          stop 1
         end if !
      end if

      end if

      tau_x(:,:,kb:ke+kh) = up - tau_x(:,:,kb:ke+kh)
      tau_y(:,:,kb:ke+kh) = vp - tau_y(:,:,kb:ke+kh)
      tau_z(:,:,kb:ke+kh) = wp - tau_z(:,:,kb:ke+kh)
      thl_flux(:,:,kb:ke+kh) = thlp - thl_flux(:,:,kb:ke+kh)

      return
   end subroutine bottom


   subroutine createmasks
      use modglobal, only : libm, ib, ie, ih, ihc, jb, je, jh, jhc, kb, ke, kh, khc, itot, jtot, rslabs
      use modfields, only : IIc,  IIu,  IIv,  IIw,  IIuw,  IIvw,  IIuv,  &
                            IIcs, IIus, IIvs, IIws, IIuws, IIvws, IIuvs, &
                            IIct, IIut, IIvt, IIwt, IIuwt, um, u0, vm, v0, wm, w0
      use modmpi,    only : myid, comm3d, mpierr, MPI_INTEGER, MPI_DOUBLE_PRECISION, MY_REAL, nprocs, MPI_SUM
      use decomp_2d, only : zstart, exchange_halo_z

      integer :: IIcl(kb:ke + khc), IIul(kb:ke + khc), IIvl(kb:ke + khc), IIwl(kb:ke + khc), IIuwl(kb:ke + khc), IIvwl(kb:ke + khc), IIuvl(kb:ke + khc)
      integer :: IIcd(ib:ie, kb:ke)
      integer :: IIwd(ib:ie, kb:ke)
      integer :: IIuwd(ib:ie, kb:ke)
      integer :: IIud(ib:ie, kb:ke)
      integer :: IIvd(ib:ie, kb:ke)
      integer :: i, j, k, n, m

      ! II*l needn't be defined up to ke_khc, but for now would require large scale changes in modstatsdump so if works leave as is ! tg3315 04/07/18

      if (.not. libm) then
         IIc(:, :, :) = 1
         IIu(:, :, :) = 1
         IIv(:, :, :) = 1
         IIw(:, :, :) = 1
         IIuw(:, :, :) = 1
         IIvw(:, :, :) = 1
         IIuv(:, :, :) = 1
         IIcs(:) = nint(rslabs)
         IIus(:) = nint(rslabs)
         IIvs(:) = nint(rslabs)
         IIws(:) = nint(rslabs)
         IIuws(:) = nint(rslabs)
         IIvws(:) = nint(rslabs)
         IIuvs(:) = nint(rslabs)
         IIct(:, :) = jtot
         IIut(:, :) = jtot
         IIvt(:, :) = jtot
         IIwt(:, :) = jtot
         IIuwt(:, :) = jtot
         return
      end if
      ! Create masking matrices
      IIc = 1; IIu = 1; IIv = 1; IIct = 1; IIw = 1; IIuw = 1; IIvw = 1; IIuv = 1; IIwt = 1; IIut = 1; IIvt = 1; IIuwt = 1; IIcs = 1; IIus = 1; IIvs = 1; IIws = 1; IIuws = 1; IIvws = 1; IIuvs = 1

      ! do m = 1,nsolptsrank_u
      !  n = solptsrank_u(m)
      !     i = solpts_u(n,1) - zstart(1) + 1
      !     j = solpts_u(n,2) - zstart(2) + 1
      !     k = solpts_u(n,3) - zstart(3) + 1
      !     IIu(i,j,k) = 0
      ! end do
      !
      ! do m = 1,nsolptsrank_v
      !  n = solptsrank_v(m)
      !     i = solpts_v(n,1) - zstart(1) + 1
      !     j = solpts_v(n,2) - zstart(2) + 1
      !     k = solpts_v(n,3) - zstart(3) + 1
      !     IIv(i,j,k) = 0
      ! end do
      !
      ! do m = 1,nsolptsrank_w
      !  n = solptsrank_w(m)
      !     i = solpts_w(n,1) - zstart(1) + 1
      !     j = solpts_w(n,2) - zstart(2) + 1
      !     k = solpts_w(n,3) - zstart(3) + 1
      !     IIw(i,j,k) = 0
      ! end do
      !
      ! do m = 1,nsolptsrank_c
      !  n = solptsrank_c(m)
      !     i = solpts_c(n,1) - zstart(1) + 1
      !     j = solpts_c(n,2) - zstart(2) + 1
      !     k = solpts_c(n,3) - zstart(3) + 1
      !     IIc(i,j,k) = 0
      ! end do
      !
      ! ! Can't do this because no interface for integers
      ! ! call exchange_halo_z(IIu, opt_zlevel=(/ihc,jhc,0/)) ! Won't communicate ke+kh level halos in x & y (fine as there can't be solid points there)
      ! ! call exchange_halo_z(IIv, opt_zlevel=(/ihc,jhc,0/))
      ! ! call exchange_halo_z(IIw, opt_zlevel=(/ihc,jhc,0/))
      !
      ! IIw(:, :, kb) = 0; IIuw(:, :, kb) = 0; IIvw(:, :, kb) = 0
      !
      ! do i=ib,ie
      !   do j=jb,je
      !     IIuv(i,j,kb) = IIu(i,j,kb) * IIu(i,j-1,kb) * IIv(i,j,kb) * IIv(i-1,j,kb)
      !     do k=kb+1,ke
      !       ! Classed as solid (set to zero) unless ALL points in the stencil are fluid
      !       IIuv(i,j,k) = IIu(i,j,k) * IIu(i,j-1,k) * IIv(i,j,k) * IIv(i-1,j,k)
      !       IIuw(i,j,k) = IIu(i,j,k) * IIu(i,j,k-1) * IIw(i,j,k) * IIw(i-1,j,k)
      !       IIvw(i,j,k) = IIv(i,j,k) * IIv(i,j,k-1) * IIw(i,j,k) * IIw(i,j-1,k)
      !     end do
      !   end do
      ! end do

      ! Can't do this because no interface for integers
      ! call exchange_halo_z(IIuv, opt_zlevel=(/ihc,jhc,0/))
      ! call exchange_halo_z(IIuv, opt_zlevel=(/ihc,jhc,0/))
      ! call exchange_halo_z(IIvw, opt_zlevel=(/ihc,jhc,0/))

      do k = kb, ke + khc
         IIcl(k) = sum(IIc(ib:ie, jb:je, k))
         IIul(k) = sum(IIu(ib:ie, jb:je, k))
         IIvl(k) = sum(IIv(ib:ie, jb:je, k))
         IIwl(k) = sum(IIw(ib:ie, jb:je, k))
         IIuwl(k) = sum(IIuw(ib:ie, jb:je, k))
         IIvwl(k) = sum(IIvw(ib:ie, jb:je, k))
         IIuvl(k) = sum(IIuv(ib:ie, jb:je, k))
      enddo

      call MPI_ALLREDUCE(IIcl, IIcs, ke + khc - kb + 1, MPI_INTEGER, &
                         MPI_SUM, comm3d, mpierr)
      call MPI_ALLREDUCE(IIul, IIus, ke + khc - kb + 1, MPI_INTEGER, &
                         MPI_SUM, comm3d, mpierr)
      call MPI_ALLREDUCE(IIvl, IIvs, ke + khc - kb + 1, MPI_INTEGER, &
                         MPI_SUM, comm3d, mpierr)
      call MPI_ALLREDUCE(IIwl, IIws, ke + khc - kb + 1, MPI_INTEGER, &
                         MPI_SUM, comm3d, mpierr)
      call MPI_ALLREDUCE(IIuwl, IIuws, ke + khc - kb + 1, MPI_INTEGER, &
                         MPI_SUM, comm3d, mpierr)
      call MPI_ALLREDUCE(IIvwl, IIvws, ke + khc - kb + 1, MPI_INTEGER, &
                         MPI_SUM, comm3d, mpierr)
      call MPI_ALLREDUCE(IIuvl, IIuvs, ke + khc - kb + 1, MPI_INTEGER, &
                         MPI_SUM, comm3d, mpierr)

      IIcd(ib:ie, kb:ke) = sum(IIc(ib:ie, jb:je, kb:ke), DIM=2)
      IIwd(ib:ie, kb:ke) = sum(IIw(ib:ie, jb:je, kb:ke), DIM=2)
      IIuwd(ib:ie, kb:ke) = sum(IIuw(ib:ie, jb:je, kb:ke), DIM=2)
      IIud(ib:ie, kb:ke) = sum(IIu(ib:ie, jb:je, kb:ke), DIM=2)
      IIvd(ib:ie, kb:ke) = sum(IIv(ib:ie, jb:je, kb:ke), DIM=2)

      call MPI_ALLREDUCE(IIwd(ib:ie, kb:ke), IIwt(ib:ie, kb:ke), (ke - kb + 1)*(ie - ib + 1), MPI_INTEGER, MPI_SUM, comm3d, mpierr)
      call MPI_ALLREDUCE(IIcd(ib:ie, kb:ke), IIct(ib:ie, kb:ke), (ke - kb + 1)*(ie - ib + 1), MPI_INTEGER, MPI_SUM, comm3d, mpierr)
      call MPI_ALLREDUCE(IIuwd(ib:ie, kb:ke), IIuwt(ib:ie, kb:ke), (ke - kb + 1)*(ie - ib + 1), MPI_INTEGER, MPI_SUM, comm3d, mpierr)
      call MPI_ALLREDUCE(IIud(ib:ie, kb:ke), IIut(ib:ie, kb:ke), (ke - kb + 1)*(ie - ib + 1), MPI_INTEGER, MPI_SUM, comm3d, mpierr)
      call MPI_ALLREDUCE(IIvd(ib:ie, kb:ke), IIvt(ib:ie, kb:ke), (ke - kb + 1)*(ie - ib + 1), MPI_INTEGER, MPI_SUM, comm3d, mpierr)

   end subroutine createmasks

end module modibm
