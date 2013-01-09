require 'formula'

# Documentation: https://github.com/mxcl/homebrew/wiki/Formula-Cookbook
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!

class Lammps < Formula
    homepage 'http://lammps.sandia.gov'
    head 'http://git.icms.temple.edu/lammps-ro.git'


    # setup packages
    DEFAULT_PACKAGE = %W[ manybody meam molecule reax opt ]
    OTHER_PACKAGES = %W[
    asphere
    class2
    colloid
    dipole
    fld
    gpu
    granular
    kim
    kspace
    mc
    peri
    poems
    replica
    rigid
    shock
    srd
    xtc
    user-misc
    user-atc
    user-awpmd
    user-cg-cmm
    user-colvars
    user-cuda
    user-eff
    user-omp
    user-molfile
    user-reaxc
    user-sph
    ]
    DEFAULT_PACKAGE.each do |package|
        option "no-#{package}", "Build lammps without the #{package} package"
    end
    OTHER_PACKAGES.each do |package|
        option "yes-#{package}", "Build lammps with the #{package} package"
    end

    # additional options
    option "with-mpi", "Build lammps with MPI support"

    depends_on 'fftw'
    depends_on 'jpeg'
    depends_on MPIDependency.new(:cxx, :f90) if build.include? "with-mpi"

    def build_f90_lib(lmp_lib)
        cd "lib/"+lmp_lib do
            if build.include? "with-mpi"
                inreplace "Makefile.gfortran" do |s|
                    s.change_make_var! "F90", ENV["MPIFC"]
                end
            end
            system "make", "-f", "Makefile.gfortran"
            mv "Makefile.lammps.gfortran", "Makefile.lammps"

            flags = "-L#{HOMEBREW_PREFIX}/opt/gfortran/gfortran/lib -lgfortran"
            flags += " " + "-L#{HOMEBREW_PREFIX}/lib -lmpi_f90" if build.include? "with-mpi"
            inreplace "Makefile.lammps" do |s|
                s.change_make_var! lmp_lib+"_SYSLIB", flags
            end
        end
    end

    def install
        ENV.j1      # not parallel safe (some packages have race conditions :meam:)
        ENV.fortran # we need fortran for many packages, so just bring it along
        ldflags = ""

        # create reax librar
        ohai "Setting up necessary libraries"
        unless build.include? "no-reax"
            build_f90_lib "reax"
        end
        unless build.include? "no-meam"
            build_f90_lib "meam"
        end

        # build the lammps program
        cd "src" do
            # setup the make file variabls for fftw, jpeg, and mpi
            inreplace "MAKE/Makefile.mac" do |s|
                # we will stick with the "mac" type and forget about "mac_mpi".
                # this is because they are essentially the same, but "mac_mpi"
                # installs jpeg support by default and changes some other
                # settings unnecessarily. We get a nice clean slate with "mac"
                if build.include? "with-open-mpi"
                    # compiler info
                    s.change_make_var! "CC"       , ENV["MPICXX"]
                    s.change_make_var! "LINK"     , ENV["MPICXX"]

                    #-DOMPI_SKIP_MPICXX is to speed up c++ compilation
                    s.change_make_var! "MPI_INC"  , "-DOMPI_SKIP_MPICXX -I#{HOMEBREW_PREFIX}/include"
                    s.change_make_var! "MPI_PATH" , "-L#{HOMEBREW_PREFIX}/lib"
                    s.change_make_var! "MPI_LIB"  , "-lmpi_cxx"
                end

                # installing with FFTW and JPEG
                s.change_make_var! "FFT_INC"  , "-DFFT_FFTW3 -I#{Formula.factory('fftw').opt_prefix}/include"
                s.change_make_var! "FFT_PATH" , "-L#{Formula.factory('fftw').opt_prefix}/lib"
                s.change_make_var! "FFT_LIB"  , "-lfftw3"

                s.change_make_var! "JPG_INC"  , "-DLAMMPS_JPEG -I#{HOMEBREW_PREFIX}/include"
                s.change_make_var! "JPG_PATH" , "-L#{HOMEBREW_PREFIX}/lib"
                s.change_make_var! "JPG_LIB"  , "-ljpeg"
            end

            ohai "Setting up packages"
            # setup default packages
            DEFAULT_PACKAGE.each do |pkg|
                system "make","yes-" + pkg
            end
            # setup optional packages
            build.each do |pkg_opt|
                system "make", pkg_opt.name if build.include? pkg_opt.name and (pkg_opt.name.include? "yes-" or pkg_opt.name.include? "no-")
            end

            unless build.include? "with-open-mpi"
                cd "STUBS" do
                    system "make"
                end
            end

            ohai "Building lammps ... get yourself a beverage, it may take some time"
            system "make", "mac"
            mv "lmp_mac", "lammps" # rename it to make it easier to find

            # build the lammps library
            system "make", "makeshlib"
            system "make", "-f", "Makefile.shlib", "mac"

            # install them
            bin.install("lammps")
            lib.install("liblammps_mac.so")
            lib.install("liblammps.so") # this is just a soft-link to liblamps_mac.so

        end

        # get the python module
        cd "python" do
            temp_site_packages = lib/which_python/'site-packages'
            mkdir_p temp_site_packages
            ENV['PYTHONPATH'] = temp_site_packages

            system "python", "install.py", lib, temp_site_packages
            mv "examples", "python-examples"
            prefix.install("python-examples")
        end

        # install additional materials
        prefix.install("doc")
        prefix.install("potentials")
        prefix.install("tools")
        prefix.install("bench")
    end

    def which_python
        "python" + `python -c 'import sys;print(sys.version[:3])'`.strip
    end

    def test
        system "lammps","-in","#{prefix}/bench/in.lj"
        system "python","-c","import lammps"
    end

    def caveats
        <<-EOS.undent
        Lammps is always updating to fix old problems and add features.
        Make sure to keep lammps up to date by reinstalling the HEAD
        occasionally with your desired options.

            brew rm lammps && brew install lammps --HEAD @OPTIONS@

        You should run a benchmark test or two. There are plenty available.

            cd #{prefix}/bench
            lammps -in in.lj

        The following directories could come in handy

            Documentation
                #{prefix}/doc/Manual.html

            Potential files
                #{prefix}/potentials

            Python examples
                #{prefix}/python-examples

            Additional tools (may require manual installation)
                #{prefix}/tools

        EOS
    end

end
