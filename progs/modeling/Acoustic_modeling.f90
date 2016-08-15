program Acoustic_modeling

  use sep
  use Readsouvelrho_mod
  use FDcoefs_assign
  use Propagator_mod
  use Interpolate_mod

  use DataSpace_types
  use ModelSpace_types
  use GeneralParam_types

  implicit none

  type(GeneralParam) :: genpar
  type(ModelSpace)   :: mod
  type(DataSpace)    :: dat
  type(FDbounds)     :: bounds
  type(ModelSpace_elevation) :: elev

  type(WaveSpace)                             :: wfld
  type(TraceSpace), dimension(:), allocatable :: datavec
  type(TraceSpace)                            :: sourcevec

  integer :: i,j,k 
  integer :: ntsnap

  call sep_init()
  
  genpar%lsinc=7

  call from_param('fmax',genpar%fmax,30.)
  call from_param('ntaper',genpar%ntaper,20)

  genpar%snapi=4

  mod%veltag='vel'
  mod%rhotag='rho'

  call from_param('twoD',genpar%twoD,.false.)

  if (.not.genpar%twoD) then     
     genpar%nbound=4
  else
     genpar%nbound=0
  end if

  call from_param('rec_type',genpar%rec_type,0)
  call from_param('shot_type',genpar%shot_type,0)
  call from_param('surf_type',genpar%surf_type,0)

  call readsou(sourcevec,genpar)
 
  if (genpar%withRho) then
     genpar%coefpower=1
  else
     genpar%coefpower=2
  end if

  call readvel(mod,genpar,bounds)
  call readsoucoord(sourcevec,mod) 

  allocate(datavec(mod%nx))

  do i=1,size(datavec)
     allocate(datavec(i)%trace(sourcevec%dimt%nt,1)) ! 1 component trace    
     datavec(i)%trace=0.
     datavec(i)%coord(1)=genpar%omodel(1)  ! Z
     datavec(i)%coord(2)=genpar%omodel(2)+(i-1)*mod%dx ! X
     datavec(i)%coord(3)=(mod%ny-1)*mod%dy/2+genpar%omodel(3)
  end do

  genpar%ntsnap=int(genpar%nt/genpar%snapi)

  allocate(wfld%wave(mod%nz,mod%nx,mod%ny,genpar%ntsnap,1))
  
  write(0,*) 'bounds%nmin1',bounds%nmin1,'bounds%nmax1',bounds%nmax1
  write(0,*) 'bounds%nmin2',bounds%nmin2,'bounds%nmax2',bounds%nmax2
  write(0,*) 'bounds%nmin3',bounds%nmin3,'bounds%nmax3',bounds%nmax3

  allocate(elev%elev(bounds%nmin2:bounds%nmax2, bounds%nmin3:bounds%nmax3))
  elev%elev=0.
  write(0,*) 'before wave propagator'
  if (genpar%twoD) then
     if (.not.genpar%withRho) then
        call propagator_acoustic(                        &
        & FD_acoustic_init_coefs,                        &
        & FD_2nd_2D_derivatives_scalar_forward,          &
        & Extraction_array_sinc,                       &
        & Injection_source_sinc_xz,                      &
        & FD_2nd_time_derivative,                        &
        & FDswaptime,                                    &
        & bounds,mod,sourcevec,datavec,wfld,elev,genpar)
     else
        call propagator_acoustic(                        &
        & FD_acoustic_rho_init_coefs,                    &
        & FD_2D_derivatives_acoustic_forward,            &
        & Extraction_array_sinc,                       &
        & Injection_source_rho_sinc_xz,                  &
        & FD_2nd_time_derivative,                        &
        & FDswaptime,                                    &
        & bounds,mod,sourcevec,datavec,wfld,elev,genpar)
     end if
  else
     if (.not.genpar%withRho) then
        call propagator_acoustic(                        &
        & FD_acoustic_init_coefs,                        &
        & FD_2nd_3D_derivatives_scalar_forward,          &
        & Extraction_array_sinc,                       &
        & Injection_source_sinc_xyz,                     &
        & FD_2nd_time_derivative_omp,                    &
        & FDswaptime_omp,                                &
        & bounds,mod,sourcevec,datavec,wfld,elev,genpar)
     else
        call propagator_acoustic(                        &
        & FD_acoustic_rho_init_coefs,                    &
        & FD_3D_derivatives_acoustic_forward,            &
        & Extraction_array_sinc,                       &
        & Injection_source_rho_sinc_xyz,                  &
        & FD_2nd_time_derivative,                        &
        & FDswaptime,                                    &
        & bounds,mod,sourcevec,datavec,wfld,elev,genpar)
     end if
  end if
  write(0,*) 'after wave propagator'
  
  do i=1,size(datavec)
     call srite('data',datavec(i)%trace(:,1),4*sourcevec%dimt%nt)
  end do

  do i=1,genpar%ntsnap
     call srite('wave',wfld%wave(1:mod%nz,1:mod%nx,1:mod%ny,i,1),4*mod%nx*mod%ny*mod%nz)
  end do

  call to_history('n1',sourcevec%dimt%nt,'data')
  call to_history('n2',size(datavec),'data')
  call to_history('d1',sourcevec%dimt%dt,'data')
  call to_history('d2',1.,'data')
  call to_history('o1',0.,'data')
  call to_history('o2',0.,'data')

  call to_history('n1',mod%nz,'wave')
  call to_history('n2',mod%nx,'wave')
  call to_history('n3',mod%ny,'wave')
  call to_history('d1',mod%dz,'wave')
  call to_history('d2',mod%dx,'wave')
  call to_history('d3',mod%dy,'wave')
  call to_history('o1',genpar%omodel(1),'wave')
  call to_history('o2',genpar%omodel(2),'wave')
  call to_history('o3',genpar%omodel(3),'wave')
  call to_history('n4',genpar%ntsnap,'wave')

  do i=1,size(datavec)
     call deallocateTraceSpace(datavec(i))
  end do
  call deallocateWaveSpace(wfld)
  call deallocateTraceSpace(sourcevec)
  deallocate(datavec)

end program Acoustic_modeling
