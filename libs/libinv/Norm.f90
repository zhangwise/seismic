module Norm_mod

  implicit none

contains
    
  function fct_compute(ntype,rd,nd,thresh) result (f)
    optional                       thresh
    integer   ::       ntype,   nd
    real, dimension(nd) :: rd
    double precision    :: f
    double precision    :: sized

    real                :: thresh,gamd,cauchy

    real, dimension(:), allocatable :: rtmp

    sized=dble(size(rd))

    select case (ntype)
    case (2) 
       ! L2 norm
       f = sum(dprod(rd,rd))/2
    case (1) 
       ! L1 norm
       f = sum(abs(rd))
    case (12) 
       if (.not.present(thresh)) then
          write(0,*) 'WARNING: thresh is not provided for Huber, uses maxval(rd) instead'
          gamd=maxval(rd)
       else
          if (thresh.eq.0.) then
             thresh=maxval(rd)
             write(0,*) 'WARNING: thresh can''t be zero, reset to maxval(rd) instead'
          end if
          gamd=thresh
       end if
       ! Huber norm
       allocate(rtmp(nd))
       where(abs(rd).gt.gamd)
          rtmp = abs(rd)-gamd/2.0
       elsewhere
          rtmp = rd*rd/(2.0*gamd)
       endwhere
       f = sum(rtmp)
       deallocate(rtmp)
    case(3)
       if (.not.present(thresh)) then
          write(0,*) 'WARNING: thresh is not provided for Cauchy, uses maxval(rd) instead'
          cauchy=maxval(rd)
       else
          if (thresh.eq.0.) then
             thresh=maxval(rd)
             write(0,*) 'WARNING: thresh can''t be zero, reset to maxval(rd) instead'
          end if
          cauchy=thresh
       end if
       ! Cauchy norm
       f = sum(log(1+(rd/cauchy)**2)/2)
    end select

  end function fct_compute

  function gdt_compute(ntype,rd,nd,thresh) result (stat)
    optional                       thresh
    integer       ::   ntype,   nd
    real, dimension(nd) ::   rd
    integer             :: stat,i
    double precision    :: sized

    real                :: thresh,gamd,cauchy

    sized=dble(size(rd))

    select case (ntype) 
    case (2)
       ! L2 norm
       rd = rd
    case (1)
       !L1 norm, sign(rd)
       do i=1,size(rd)
          if (rd(i).lt.0) then
             rd(i) = -1.
          else if (rd(i).gt.0.) then
             rd(i) = 1.
          else
             rd(i) = 0.
          end if
       end do
    case (12) 
       if (.not.present(thresh)) then
          write(0,*) 'WARNING: thresh is not provided for Huber, uses maxval(rd) instead'
          gamd=maxval(rd)
       else
          gamd=thresh
       end if
       ! Huber norm
       rd=max(-1.0,min(1.0,rd/gamd))
    case (3)
       if (.not.present(thresh)) then
          write(0,*) 'WARNING: thresh is not provided for Cauchy, uses maxval(rd) instead'
          cauchy=maxval(rd)
       else
          cauchy=thresh
       end if
       ! Cauchy norm
       rd=rd/(cauchy**2+rd**2)
    end select

    stat = 1

  end function gdt_compute

end module Norm_mod