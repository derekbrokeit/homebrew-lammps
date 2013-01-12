# Deprication warning

**Warning**: This tap is **depricated** because it has been incorporated into
the main [homebrew/science][hbsci] tap. This repository remains in order to preserve
the history of the lammps formula since it was squashed into a single commit
for [homebrew/science][hbsci]. To get the lammps package now with whatever desired 
options, run:

```
brew untap scicalculator/lammps
brew tap homebrew/science
brew install lammmps @options@
```

The following is the original descriptions of this brew, it may not be up to
date about options. To check options for the current version of lammps on homebrew
use:

```
brew info lammps
```


*Enjoy*!

---

homebrew-lammps
===============

A hombrew formula for [lammps][lammps]. Lammps is a power molecular
dynamics simulator, but it can be tricky to install properly. That's
where brew comes in to help you manage all of it to get the most out of
your simulatior. Eventually, I hope to include this in homebrew/science,
but let's make sure it works first ...

```
# get this repo
brew tap scicalculator/lammps

# check out the available options
# Please test them for me and leave feedback!
brew info lammps

# install
brew install lammps --HEAD ${opts}
```

Right now all lammps packages can be switched on or off with
`--yes-@option@` flags. Not all of them have been tested, and it would
be helpful to know which ones have problems. There very well may be
certain packages that can never be used, so we need to figure it out
eventually.

Additionally, you can install with open-mpi, jpeg, or fftw libraries
optionally. You just need to use `--with-open-mpi`, `--with-jpeg`,
and/or `--with-fftw` options when running install.

This installation also installs the lammps library and python modules
by default and cannot be disabled at this time. If you think we should
allow disabling of this feature please give me some feedback. Right
now, I like the way it is because they shouldn't cause side effects.
One thing you may notice is that if you install with open-mpi, both the
library and python modules will also be parallelizable with mpi. For
python, this means you need an mpi capable python module that is not
provided here. I prefere `mpi4py` [here][mpipy], but pick your favorite!

Please help me make this work better by testing options and giving
feedback. Hopefully, when all is said and done, we can add this to the
[homebrew/science][hbsci] repository!

[lammps]: http://lammps.sandia.gov/
[hbsci]: http://github.com/homebrew/homebrew-science
[mpipy]: http://code.google.com/p/mpi4py
