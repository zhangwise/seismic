! 
! -----------------------------------------------
! Copyright (c) 2016-2017 Bellevue Geophysics LLC
! -----------------------------------------------
! 
module to_disk_to_memory_AFWI_mod

  use sep

  use Readsouvelrho_mod
  use ExtractPadModel_mod
  use FDcoefs_assign
  use Propagator_mod
  use Interpolate_mod
  use Injection_mod
  use Imaging_mod
  use Taper_mod

  use Inversion_mod
  use DataSpace_types
  use ModelSpace_types
  use GeneralParam_types

  implicit none

  contains

    subroutine AFWI_to_disk(mod,invparam,mutepar,genpar,dat,bounds,elev,datavec,sourcevec)

      type(MuteParam)     :: mutepar
      type(InversionParam):: invparam
      type(GeneralParam)  :: genpar
      type(ModelSpace)    :: mod
      type(DataSpace)     :: dat
      type(FDbounds)      :: bounds
      type(ModelSpace_elevation) :: elev

      type(TraceSpace), dimension(:), allocatable :: datavec
      type(TraceSpace), dimension(:), allocatable :: sourcevec

      type(TraceSpace), dimension(:), allocatable :: dmodvec

      integer :: ntraces,i
      
      call to_history('n1',mod%nz,'wave_fwd')
      call to_history('n2',mod%nxw,'wave_fwd')
      call to_history('d1',mod%dz,'wave_fwd')
      call to_history('d2',mod%dx,'wave_fwd')
      call to_history('o1',genpar%omodel(1),'wave_fwd')
      call to_history('o2',genpar%omodel(2),'wave_fwd')
      if (genpar%twoD) then
         call to_history('n3',genpar%ntsnap,'wave_fwd')
      else
         call to_history('n3',mod%nyw,'wave_fwd')
         call to_history('d3',mod%dy,'wave_fwd')
         call to_history('o3',genpar%omodel(3),'wave_fwd')
         call to_history('n4',genpar%ntsnap,'wave_fwd')
      end if

      genpar%tmin=1
      genpar%tmax=sourcevec(1)%dimt%nt
      genpar%tstep=1
      
      ntraces=size(datavec)
      allocate(dmodvec(ntraces))
      do i=1,ntraces
         allocate(dmodvec(i)%trace(datavec(i)%dimt%nt,1))
         dmodvec(i)%dimt%nt=datavec(i)%dimt%nt
         dmodvec(i)%dimt%ot=datavec(i)%dimt%ot
         dmodvec(i)%dimt%dt=datavec(i)%dimt%dt
         dmodvec(i)%trace=0.
      end do

      write(0,*) 'INFO: Starting forward modeling'
      if (genpar%twoD) then
         if (.not.genpar%withRho) then
            call propagator_acoustic(                        &
            & FD_acoustic_init_coefs,                        &
            & FD_2nd_2D_derivatives_scalar_forward_grid,     &
            & Injection_sinc,                                &
            & FD_2nd_time_derivative_grid,                   &
            & FDswaptime_pointer,                            &
            & bounds,mod,elev,genpar,                        &    
            & sou=sourcevec,datavec=dmodvec,                 &
            & ExtractData=Extraction_array_sinc,             &
            & ExtractWave=Extraction_wavefield_copy_to_disk) 
         else
            call propagator_acoustic(                        &
            & FD_acoustic_rho_init_coefs,                    &
            & FD_2D_derivatives_acoustic_forward_grid,       &
            & Injection_sinc,                                &
            & FD_2nd_time_derivative_grid,                   &
            & FDswaptime_pointer,                            &
            & bounds,mod,elev,genpar,                        &    
            & sou=sourcevec,datavec=dmodvec,                 &
            & ExtractData=Extraction_array_sinc,             &
            & ExtractWave=Extraction_wavefield_copy_to_disk)
         end if
      else
         if (.not.genpar%withRho) then
            call propagator_acoustic(                        &
            & FD_acoustic_init_coefs,                        &
            & FD_2nd_3D_derivatives_scalar_forward_grid,     &
            & Injection_sinc,                                &
            & FD_2nd_time_derivative_grid,                   &
            & FDswaptime_pointer,                            &
            & bounds,mod,elev,genpar,                        &    
            & sou=sourcevec,datavec=dmodvec,                 &
            & ExtractData=Extraction_array_sinc,             &
            & ExtractWave=Extraction_wavefield_copy_to_disk) 
         else
            call propagator_acoustic(                        &
            & FD_acoustic_rho_init_coefs,                    &
            & FD_3D_derivatives_acoustic_forward_grid,       &
            & Injection_sinc,                                &
            & FD_2nd_time_derivative_grid,                   &
            & FDswaptime_pointer,                            &
            & bounds,mod,elev,genpar,                        &    
            & sou=sourcevec,datavec=dmodvec,                 &
            & ExtractData=Extraction_array_sinc,             &
            & ExtractWave=Extraction_wavefield_copy_to_disk)
         end if
      end if

      write(0,*) 'INFO: Done with forward modeling'

      call Compute_OF_RES_3D(invparam,datavec,dmodvec,mutevec%maskgath(1),f)

      allocate(mod%imagesmall(mod%nz,mod%nxw,mod%nyw))
      allocate(mod%illumsmall(mod%nz,mod%nxw,mod%nyw))
      mod%imagesmall=0.
      mod%illumsmall=0.

      genpar%tmax=1
      genpar%tmin=sourcevec(1)%dimt%nt
      genpar%tstep=-1

      mod%counter=0

      ! Copy vel2 to vel for backward propagation if needed
      if (mod%exist_vel2) mod%vel=mod%vel2

      call compute_taper(mod)

      write(0,*) 'INFO: Starting backward propagation'
      if (genpar%twoD) then
         if (.not.genpar%withRho) then
            call propagator_acoustic(                        &
            & FD_acoustic_init_coefs,                        &
            & FD_2nd_2D_derivatives_scalar_adjoint_grid,     &
            & Injection_sinc,                                &
            & FD_2nd_time_derivative_grid,                   &
            & FDswaptime_pointer,                            &
            & bounds,mod,elev,genpar,                        &
            & sou=dmodvec,ImagingCondition=Imaging_condition_AFWI_from_disk)
         else
            call propagator_acoustic(                        &
            & FD_acoustic_rho_init_coefs,                    &
            & FD_2D_derivatives_acoustic_forward_grid,       &
            & Injection_sinc,                            &
            & FD_2nd_time_derivative_grid,                   &
            & FDswaptime_pointer,                            &
            & bounds,mod,elev,genpar,                        &
            & sou=dmodvec,ImagingCondition=Imaging_condition_AFWI_RHOVP_from_disk)
         end if
      else
         if (.not.genpar%withRho) then
            call propagator_acoustic(                        &
            & FD_acoustic_init_coefs,                        &
            & FD_2nd_3D_derivatives_scalar_forward_grid,     &
            & Injection_sinc,                                &
            & FD_2nd_time_derivative_grid,                   &
            & FDswaptime_pointer,                            &
            & bounds,mod,elev,genpar,                        &
            & sou=dmodvec,ImagingCondition=Imaging_condition_AFWI_from_disk)
         else
            call propagator_acoustic(                        &
            & FD_acoustic_rho_init_coefs,                    &
            & FD_3D_derivatives_acoustic_forward_grid,       &
            & Injection_sinc,                            &
            & FD_2nd_time_derivative_grid,                   &
            & FDswaptime_pointer,                            &
            & bounds,mod,elev,genpar,                        &
            & sou=dmodvec,ImagingCondition=Imaging_condition_AFWI_RHOVP_from_disk)
         end if
      end if
      write(0,*) 'INFO: Done with backward propagation'

      do i=1,size(dmodvec)
         call deallocateTraceSpace(dmodvec(i))
      end do
      deallocate(dmodvec)

    end subroutine AFWI_to_disk

    subroutine AFWI_to_memory(mod,invparam,mutepar,genpar,dat,bounds,elev,datavec,sourcevec)

      type(MuteParam)     :: mutepar
      type(InversionParam):: invparam
      type(GeneralParam)  :: genpar
      type(ModelSpace)    :: mod
      type(DataSpace)     :: dat
      type(FDbounds)      :: bounds
      type(ModelSpace_elevation) :: elev

      type(TraceSpace), dimension(:), allocatable :: datavec
      type(TraceSpace), dimension(:), allocatable :: sourcevec
      type(WaveSpace), target                     :: wfld_fwd
      
      type(TraceSpace), dimension(:), allocatable :: dmodvec

      integer :: ntraces,i

      genpar%tmin=1
      genpar%tmax=sourcevec(1)%dimt%nt
      genpar%tstep=1

      ntraces=size(datavec)
      allocate(dmodvec(ntraces))
      do i=1,ntraces
         allocate(dmodvec(i)%trace(datavec(i)%dimt%nt,1))
         dmodvec(i)%dimt%nt=datavec(i)%dimt%nt
         dmodvec(i)%dimt%ot=datavec(i)%dimt%ot
         dmodvec(i)%dimt%dt=datavec(i)%dimt%dt
         dmodvec(i)%trace=0.
      end do

      allocate(wfld_fwd%wave(mod%nz,mod%nxw,mod%nyw,genpar%ntsnap,1))

      wfld_fwd%wave=0.
      write(0,*) 'INFO: Starting forward modeling'
      if (genpar%twoD) then
         if (.not.genpar%withRho) then
            call propagator_acoustic(                        &
            & FD_acoustic_init_coefs,                        &
            & FD_2nd_2D_derivatives_scalar_forward_grid,     &
            & Injection_sinc,                                &
            & FD_2nd_time_derivative_grid,                   &
            & FDswaptime_pointer,                            &
            & bounds,mod,elev,genpar,                        &    
            & sou=sourcevec,datavec=dmodvec,                 &
            & ExtractData=Extraction_array_sinc,             &
            & ExtractWave=Extraction_wavefield,wfld=wfld_fwd) 
         else
            call propagator_acoustic(                        &
            & FD_acoustic_rho_init_coefs,                    &
            & FD_2D_derivatives_acoustic_forward_grid,       &
            & Injection_sinc,                            &
            & FD_2nd_time_derivative_grid,                   &
            & FDswaptime_pointer,                            &
            & bounds,mod,elev,genpar,                        &    
            & sou=sourcevec,datavec=dmodvec,                 &
            & ExtractData=Extraction_array_sinc,             &
            & ExtractWave=Extraction_wavefield,wfld=wfld_fwd)
         end if
      else
         if (.not.genpar%withRho) then
            call propagator_acoustic(                        &
            & FD_acoustic_init_coefs,                        &
            & FD_2nd_3D_derivatives_scalar_forward_grid,     &
            & Injection_sinc,                                &
            & FD_2nd_time_derivative_grid,                   &
            & FDswaptime_pointer,                            &
            & bounds,mod,elev,genpar,                        &    
            & sou=sourcevec,datavec=dmodvec,                 &
            & ExtractData=Extraction_array_sinc,             &
            & ExtractWave=Extraction_wavefield,wfld=wfld_fwd) 
         else
            call propagator_acoustic(                        &
            & FD_acoustic_rho_init_coefs,                    &
            & FD_3D_derivatives_acoustic_forward_grid,       &
            & Injection_sinc,                            &
            & FD_2nd_time_derivative_grid,                   &
            & FDswaptime_pointer,                            &
            & bounds,mod,elev,genpar,                        &    
            & sou=sourcevec,datavec=dmodvec,                 &
            & ExtractData=Extraction_array_sinc,             &
            & ExtractWave=Extraction_wavefield,wfld=wfld_fwd)
         end if
      end if

      write(0,*) 'INFO: Done with forward modeling'

      call Compute_OF_RES_3D(invparam,datavec,dmodvec,mutevec%maskgath(1),f)

      allocate(mod%imagesmall(mod%nz,mod%nxw,mod%nyw))
      allocate(mod%illumsmall(mod%nz,mod%nxw,mod%nyw))
      mod%imagesmall=0.
      mod%illumsmall=0.

      genpar%tmax=1
      genpar%tmin=sourcevec(1)%dimt%nt
      genpar%tstep=-1

      mod%counter=0
      mod%wvfld=>wfld_fwd

      ! Copy vel2 to vel for backward propagation if needed
      if (mod%exist_vel2) mod%vel=mod%vel2

      call compute_taper(mod)

      write(0,*) 'INFO: Starting backward propagation'
      if (genpar%twoD) then
         if (.not.genpar%withRho) then
            call propagator_acoustic(                        &
            & FD_acoustic_init_coefs,                        &
            & FD_2nd_2D_derivatives_scalar_adjoint_grid,     &
            & Injection_sinc,                                &
            & FD_2nd_time_derivative_grid,                   &
            & FDswaptime_pointer,                            &
            & bounds,mod,elev,genpar,                        &
            & sou=dmodvec,ImagingCondition=Imaging_condition_AFWI_from_memory)
         else
            call propagator_acoustic(                        &
            & FD_acoustic_rho_init_coefs,                    &
            & FD_2D_derivatives_acoustic_forward_grid,       &
            & Injection_sinc,                            &
            & FD_2nd_time_derivative_grid,                   &
            & FDswaptime_pointer,                            &
            & bounds,mod,elev,genpar,                        &
            & sou=dmodvec,ImagingCondition=Imaging_condition_AFWI_RHOVP_from_memory)
         end if
      else
         if (.not.genpar%withRho) then
            call propagator_acoustic(                        &
            & FD_acoustic_init_coefs,                        &
            & FD_2nd_3D_derivatives_scalar_forward_grid,     &
            & Injection_sinc,                                &
            & FD_2nd_time_derivative_grid,                   &
            & FDswaptime_pointer,                            &
            & bounds,mod,elev,genpar,                        &
            & sou=dmodvec,ImagingCondition=Imaging_condition_AFWI_from_memory)
         else
            call propagator_acoustic(                        &
            & FD_acoustic_rho_init_coefs,                    &
            & FD_3D_derivatives_acoustic_forward_grid,       &
            & Injection_sinc,                            &
            & FD_2nd_time_derivative_grid,                   &
            & FDswaptime_pointer,                            &
            & bounds,mod,elev,genpar,                        &
            & sou=dmodvec,ImagingCondition=Imaging_condition_AFWI_RHOVP_from_memory)
         end if
      end if
      write(0,*) 'INFO: Done with backward propagation'

      do i=1,size(dmodvec)
         call deallocateTraceSpace(dmodvec(i))
      end do
      deallocate(dmodvec)

      call deallocateWaveSpace(wfld_fwd)
    end subroutine AFWI_to_memory
    
  end module to_disk_to_memory_AFWI_mod