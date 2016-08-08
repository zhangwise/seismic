module GeneralParam_types
  implicit none

  type GeneralParam
 
     logical :: twoD

     real    :: dt
     real    :: dx
     real    :: dy
     real    :: dz

     integer :: nt

     integer :: lsinc
     integer :: nbound
     integer :: ntaper
     integer :: snapi

     integer :: rec_type   ! Mirror or not
     integer :: surf_type  ! Absorbing or not
     integer :: shot_type  ! Mirror or not

  end type GeneralParam

  type HigdonParam
     real, allocatable :: gx(:,:,:)
     real, allocatable :: gy(:,:,:)
     real, allocatable :: gz(:,:,:)

  end type HigdonParam

contains

  subroutine deallocateHigdonParam(hig)
    type(HigdonParam)   :: hig
    if (allocated(hig%gx)) deallocate(hig%gx)
    if (allocated(hig%gy)) deallocate(hig%gy)
    if (allocated(hig%gz)) deallocate(hig%gz)
  end subroutine deallocateHigdonParam
end module GeneralParam_types
