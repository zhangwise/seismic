! 
! -----------------------------------------------
! Copyright (c) 2016-2017 Bellevue Geophysics LLC
! -----------------------------------------------
! 
program Mute3D

  use sep
  
  use Readsouvelrho_mod
  use GeneralParam_types
  use DataSpace_types

  type(GeneralParam) :: genpar
  type(DataSpace)    :: dat

  type(TraceSpace), dimension(:), allocatable :: datavec
  type(TraceSpace), dimension(:), allocatable :: sourcevec

  real :: vmute,tmute,t0,dt,ot,t
  real :: sx,gx,sy,gy,h
  integer :: i,j,nt,it,ntaper
  logical :: verb
  real :: pi=3.141592654

  call sep_init()

  allocate(sourcevec(1))
  call from_aux('traces','n1',sourcevec(1)%dimt%nt)
  call from_aux('traces','d1',sourcevec(1)%dimt%dt)
  call readtraces(datavec,sourcevec,genpar)
  call readcoords(datavec,sourcevec,genpar)

  nt=datavec(1)%dimt%nt
  ot=datavec(1)%dimt%ot
  dt=datavec(1)%dimt%dt

  call from_param('tmute',tmute,0.)
  call from_param('vmute',vmute,0.)
  call from_param('ntaper',ntaper,0)
  call from_param('verb',verb,.true.)
  call from_param('num_threads',genpar%nthreads,4)
  
  call omp_set_num_threads(genpar%nthreads)

  if (verb) then
     write(0,*) 'INFO:'
     write(0,*) 'INFO: Simple mute of 3D shot gathers'
     write(0,*) 'INFO:'
     write(0,*) 'INFO: Vmute=',vmute
     write(0,*) 'INFO: Tmute=',tmute
     write(0,*) 'INFO: Nthreads=',genpar%nthreads     
     write(0,*) 'INFO: Number of traces',size(datavec)
  end if

  !$OMP PARALLEL DO PRIVATE(i,h,t,it)
  do i=1,size(datavec)
     h=sqrt((datavec(i)%coord(2)-sourcevec(1)%coord(2))**2+(datavec(i)%coord(3)-sourcevec(1)%coord(3))**2)! Compute offset
     t=sqrt(tmute**2+(h/vmute)**2) ! Tmute as a function of offset
     it=(t-ot)/dt+1.5-ntaper              ! NN Mute
     it=min(max(1,it),nt)          ! Make sure within bounds
     datavec(i)%trace(1:it,1)=0.   ! Mute here
     do j=it,min(max(1,it+ntaper),nt)
        datavec(i)%trace(j,1)=sin((j-it)*pi/(2*max(ntaper,1)))**2
     end do
  end do
  !$OMP END PARALLEL DO

  do i=1,size(datavec)
     call srite('out',datavec(i)%trace(:,1),4*nt)
  end do
  call to_history('n1',nt,'out')
  call to_history('n2',size(datavec),'out')
  call to_history('d1',dt,'out')
  call to_history('d2',1.,'out')
  call to_history('o1',ot,'out')
  call to_history('o2',0.,'out')

  do i=1,size(datavec)
     call deallocateTraceSpace(datavec(i))
  end do

  call deallocateTraceSpace(sourcevec(1))
  deallocate(datavec,sourcevec)

  write(0,*) 'INFO:'
  write(0,*) 'INFO: -- Muting Done -- '
  write(0,*) 'INFO:'
end program Mute3D
