require 'formula'

# Documentation: https://github.com/mxcl/homebrew/wiki/Formula-Cookbook
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!

class Lammps < Formula
    homepage 'http://lammps.sandia.gov'
    url 'http://lammps.sandia.gov/tars/lammps-11Jan13.tar.gz'
    version '04-Jan-2013_1750'
    sha1 '6ee291fe91360c241a6c5a6f3caac11048c004d8'
    head 'svn://svn.icms.temple.edu/lammps-ro/trunk'

    # setup packages
    DEFAULT_PACKAGES = %W[ manybody meam molecule reax opt kspace ]
    STANDARD_PACKAGES = %W[
        asphere
        colloid 
        class2
        dipole
        fld
        granular
        mc
        peri
        poems
        replica
        rigid
        shock
        srd
        xtc
    ]
    USER_PACKAGES= %W[
        user-misc
        user-awpmd
        user-cg-cmm
        user-colvars
        user-eff
        user-omp
        user-molfile
        user-reaxc
        user-sph
    ]

    # the following are available packages that have not been tested
    # Currently no machines available to test gpu and user-cuda (need
    # nvidia graphics cards) KIM software is necessary for kim, probably
    # useless user-atc needs some work to get to install (it seems to
    # only install libs with mpi AND I couldn't get the final build to
    # link to blas or lapack)
    DISABLED_PACKAGES = %W[
        gpu
        kim
    ]
    DISABLED_USER_PACKAGES = %W[
        user-atc
        user-cuda
    ]

    # setup user-packages as options
    USER_PACKAGES.each do |package|
        option "enable-#{package}", "Build lammps with the '#{package}' package"
    end

    # additional options
    option "with-mpi", "Build lammps with MPI support"
    option "all-standard", "Build lammps with all of the standard (non-user-submitted) packages (gpu and kim are disabled)"

    ####
    # not a real dependency, but needed to get MPIDependency to work right
    depends_on 'scons' => :build
    ####

    depends_on 'fftw'
    depends_on 'jpeg'
    depends_on MPIDependency.new(:cxx, :f90) if build.include? "with-mpi"

    def build_f90_lib(lmp_lib)
        # we currently assume gfortran is our fortran library
        cd "lib/"+lmp_lib do
            make_file = "Makefile.gfortran"
            if build.include? "with-mpi"
                inreplace make_file do |s|
                    s.change_make_var! "F90", ENV["MPIFC"]
                end
            end
            system "make", "-f", make_file

            ENV.append 'LDFLAGS', "-lgfortran -L#{Formula.factory('gfortran').opt_prefix}/gfortran/lib"

            # empty it to reduce chance of conflicts
            inreplace "Makefile.lammps" do |s|
                s.change_make_var! lmp_lib+"_SYSINC", ""
                s.change_make_var! lmp_lib+"_SYSLIB", "-lgfortran"
                s.change_make_var! lmp_lib+"_SYSPATH", ""
            end
        end
    end

    def build_cxx_lib(lmp_lib)
        # we currently assume gfortran is our fortran library
        cd "lib/"+lmp_lib do
            make_file = "Makefile.g++"
            if build.include? "with-mpi"
                make_file = "Makefile.openmpi" if File.exists? "Makefile.openmpi"
                inreplace make_file do |s|
                    s.change_make_var! "CC" , ENV["MPICXX"]
                end
            end
            system "make", "-f", make_file
        end
    end

    def install
        ENV.j1      # not parallel safe (some packages have race conditions :meam:)
        ENV.fortran # we need fortran for many packages, so just bring it along

        ohai "Setting up necessary libraries"
        build_f90_lib "reax"
        build_f90_lib "meam"
        build_cxx_lib "poems" if build.include? "all-standard"
        build_cxx_lib "awpmd" if build.include? "enable-user-awpmd" and build.include? "with-mpi"
        if build.include? "enable-user-colvars"
            # the makefile is craeted by a user and is not of standard format
            cd "lib/colvars" do
                make_file = "Makefile.g++"
                if build.include? "with-mpi"
                    inreplace make_file do |s|
                        s.change_make_var! "CXX" , ENV["MPICXX"]
                    end
                end
                system "make", "-f", make_file
            end
        end

        # build the lammps program
        cd "src" do
            # setup the make file variabls for fftw, jpeg, and mpi
            inreplace "MAKE/Makefile.mac" do |s|
                # We will stick with "make mac" type and forget about
                # "make mac_mpi" because it has some unnecessary
                # settings. We get a nice clean slate with "mac"
                if build.include? "with-mpi"
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

                # add link-flags
                s.change_make_var! "LINKFLAGS"  , ENV["LDFLAGS"]
                s.change_make_var! "SHLIBFLAGS" , "-shared #{ENV['LDFLAGS']}"
            end

            ohai "Setting up packages"
            # setup packages
            if build.include? "all-standard"
                # This includes all standard (not user-submitted) packages
                # which includes default packages as well
                system "make", "yes-standard"
                DISABLED_PACKAGES.each do |pkg|
                    system "make", "no-" + pkg
                end
            else
                DEFAULT_PACKAGES.each do |pkg|
                    system "make","yes-" + pkg
                end
            end
            # setup optional packages
            USER_PACKAGES.each do |pkg|
                system "make", "yes-" + pkg if build.include? "enable-" + pkg
            end

            unless build.include? "with-mpi"
                # build fake mpi library
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
        system "python","-c","from lammps import lammps ; lammps().file('#{prefix}/bench/in.lj')"
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

    def patches
        DATA
    end
end

__END__
diff --git a/python/lammps.py b/python/lammps.py
index c65e84c..b2b28a2 100644
--- a/python/lammps.py
+++ b/python/lammps.py
@@ -23,8 +23,8 @@ class lammps:
     # if name = "g++", load liblammps_g++.so
 
     try:
-      if not name: self.lib = CDLL("liblammps.so",RTLD_GLOBAL)
-      else: self.lib = CDLL("liblammps_%s.so" % name,RTLD_GLOBAL)
+      if not name: self.lib = CDLL("HOMEBREW_PREFIX/lib/liblammps.so",RTLD_GLOBAL)
+      else: self.lib = CDLL("HOMEBREW_PREFIX/lib/liblammps_%s.so" % name,RTLD_GLOBAL)
     except:
       type,value,tb = sys.exc_info()
       traceback.print_exception(type,value,tb)
