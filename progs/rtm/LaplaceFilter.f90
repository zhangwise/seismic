! 
! -----------------------------------------------
! Copyright (c) 2016-2017 Bellevue Geophysics LLC
! -----------------------------------------------
! 
!----------------------------------------------------------------
program LaplaceFilter

  use Laplace_mod
  !
  implicit none
  integer :: opt, nx, ny, nz, n4, n5
  integer :: rect1, rect2, rect3
  real :: dx, dy, dz
  !
  ! Get parameters needed for memory allocation
  !
  call initpar()
  call sep_add_doc_line("NAME")
  call sep_add_doc_line("    LaplaceFilter.x - Post-process filters in 2D and 3D")
  call sep_add_doc_line("")
  call sep_add_doc_line("SYNOPSIS")
  call sep_add_doc_line("    LaplaceFilter.x  < input.H > output.H")
  call sep_add_doc_line("")
  call sep_add_doc_line("INPUT PARAMETERS")
  call sep_add_doc_line("    input.H - file")
  call sep_add_doc_line("               Input file")
  call sep_add_doc_line("")
  call sep_add_doc_line("    filter - string")
  call sep_add_doc_line("                Laplacian: Divergence of input.")
  call sep_add_doc_line("    n1 - integer")
  call sep_add_doc_line("                # of z grid points (becomes nz in the program) ")
  call sep_add_doc_line("")
  call sep_add_doc_line("    n2 - integer")
  call sep_add_doc_line("                # of x grid points (becomes nx in the program) ")
  call sep_add_doc_line("")
  call sep_add_doc_line("    n3 - integer")
  call sep_add_doc_line("                # of y grid points (becomes ny in the program) ")
  call sep_add_doc_line("")
  call sep_add_doc_line("    d1 - real")
  call sep_add_doc_line("                z grid point spacing (becomes dz in the program)")
  call sep_add_doc_line("")
  call sep_add_doc_line("    d2 - real")
  call sep_add_doc_line("                x grid point spacing (becomes dx in the program)")
  call sep_add_doc_line("")
  call sep_add_doc_line("    d3 - real")
  call sep_add_doc_line("                y grid point spacing (becomes dy in the program)")
  call sep_add_doc_line("")
  call sep_add_doc_line("")
  call sep_add_doc_line("OUTPUT PARAMETERS")
  call sep_add_doc_line("    output.H - file")
  call sep_add_doc_line("              filtered output file.")
  call sep_add_doc_line("")
  call sep_add_doc_line("DESCRIPTION")
  call sep_add_doc_line("       Program to filter data in 2D and in 3D.")
  call sep_add_doc_line("")
  call doc('SOURCE')
  !
  call InitFiles(opt, nx, ny, nz, n4, n5, dx, dy, dz, rect1, rect2, rect3)

  write(0,*) 'LaPlacian filter selected'
  call Laplace(nx, ny, nz, n4, n5, dx, dy, dz)

  !
end program LaplaceFilter
!
subroutine InitFiles(opt, nx, ny, nz, n4, n5, dx, dy, dz, rect1, rect2, rect3)
  !
  implicit none
  integer :: rect1, rect2, rect3
  integer :: hetch, getch
  integer :: opt, nx, ny, nz, n4, n5
  character(len=2) :: char
  real :: dx, dy, dz, oz, ox, oy
  !
  opt=3

  call putch('opt','i',opt)
  if (hetch('n1','i',nz).eq.0) &
  &  call erexit('need n1:nz')
  if (hetch('d1','r',dz).eq.0) dz=1.
  if (hetch('o1','r',oz).eq.0) oz=0.
  call putch('From stdin: nz','i',nz)
  call putch('From stdin: dz','r',dz)
  call putch('From stdin: oz','r',oz)

  if (hetch('n2','i',nx).eq.0) &
  &  call erexit('need n2:nx')
  if (hetch('d2','r',dx).eq.0) dx=1.
  if (hetch('o2','r',ox).eq.0) ox=0.
  call putch('From stdin: nx','i',nx)
  call putch('From stdin: dx','r',dx)
  call putch('From stdin: ox','r',ox)

  if (hetch('n3','i',ny).eq.0) ny=1
  if (hetch('d3','r',dy).eq.0) dy=1.
  if (hetch('o3','r',oy).eq.0) oy=0.
  call putch('From stdin: ny','i',ny)
  call putch('From stdin: dy','r',dy)
  call putch('From stdin: oy','r',oy)

  if (hetch('n4','i',n4).eq.0) n4=1
  if (hetch('n5','i',n5).eq.0) n5=1

end subroutine InitFiles
