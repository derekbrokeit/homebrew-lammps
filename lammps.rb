require 'formula'

# Documentation: https://github.com/mxcl/homebrew/wiki/Formula-Cookbook
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!

class Lammps < Formula
    homepage 'http://lammps.sandia.gov'
    version ''
    sha1 ''
    head 'http://git.icms.temple.edu/lammps-ro.git'

    #depends_on "fftw"

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
    option "with-open-mpi", "Build lammps with open-mpi support"
    option "with-jpeg", "Build lammps with jpeg support"
    option "with-brewed-fftw", "Build lammps with brewed fftw support"

    def install
        ENV.j1      # not parallel safe (some packages have race conditions)
        ENV.fortran # we need fortran

        # create reax library
        ohai "Setting up necessary libraries"
        unless build.include? "no-reax"
            cd "lib/reax" do
                system "make", "-f", "Makefile.gfortran"
                mv "Makefile.lammps.gfortran", "Makefile.lammps"
            end
        end
        unless build.include? "no-meam"
            cd "lib/meam" do
                system "make", "-f", "Makefile.gfortran"
                mv "Makefile.lammps.gfortran", "Makefile.lammps"
            end
        end

        cd "src" do
            opoo "hello"

            ohai "Setting up packages"
            # setup default packages
            DEFAULT_PACKAGE.each do |pkg|
                system "make","yes-" + pkg 
            end
            # setup optional packages
            build.each do |pkg_opt|
                system "make", pkg_opt.name if build.include? pkg_opt.name
            end

            unless build.include? "with-open-mpi"
                cd "STUBS" do
                    system "make"
                end
            end

            system "make", "mac"
            bin.install("lmp_mac")

        end
        opoo "bye bye"

    end

    def paches
        p = []

        p << "https://gist.github.com/raw/4343711/0f8eaba9d3aa463fbb79d98c756948463902317a/lammps_fftw-none.diff" unless build.include? "with-open-mpi"

        p
    end

    def test
        # This test will fail and we won't accept that! It's enough to just replace
        # "false" with the main program this formula installs, but it'd be nice if you
        # were more thorough. Run the test with `brew test lammps`.
        system "false"
    end

    # make sure to put in caveats:
    # * location of docs with `open /usr/local/Cellar/...html`
    # * location of potential files
    # * location of examples directory
    # * location of benchmarking examples
    # * location of tools directory
end
