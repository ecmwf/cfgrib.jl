# cfgrib.jl

[![lifecycle](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip)
[![Build Status](https://travis-ci.com/robertrosca/cfgrib.jl.svg?branch=dev)](https://travis-ci.com/robertrosca/cfgrib.jl)
[![Codecov](https://codecov.io/gh/robertrosca/cfgrib.jl/branch/dev/graph/badge.svg)](https://codecov.io/gh/robertrosca/cfgrib.jl)
[![latest release](https://img.shields.io/github/release/robertrosca/cfgrib.jl.svg)](https://github.com/robertrosca/cfgrib.jl/releases/latest)
[![Apache 2 license](https://img.shields.io/github/license/robertrosca/cfgrib.jl)](https://github.com/robertrosca/cfgrib.jl/blob/master/LICENSE)


## Description
cfgrib.jl is a julia interface to map GRIB files to the [Unidata's Common Data
Model v4](https://www.unidata.ucar.edu/software/thredds/current/netcdf-java/CDM/)
following the [CF Conventions](http://cfconventions.org).

This package is based on the python implementation in [cfgrib.py](https://github.com/ecmwf/cfgrib)
and closely follows the approaches of that package, but in Julia instead. Parity
tests are automatically performed between the two to ensure that the data
returned by the Julia version is equivalent to that from Python.

In Python [xarray](http://xarray.pydata.org) has come out to be a standard
way to implement named arrays, however as Julia is a much younger language no
stable array interface has been adopted by the community yet, so the approach
here is more flexible and allows for multiple array backends to be used.

Low level access and decoding is performed by calling [GRIB.jl](https://github.com/weech/GRIB.jl)
which itself calls the [ECMWF ecCodes library](https://software.ecmwf.int/wiki/display/ECC/).


## Installation
The package is currently under heavy development so it has not been added to the
Julia package registry yet. To install the package first clone this repository:

```shell
git clone https://github.com/robertrosca/cfgrib.jl/
cd cfgrib.jl
```

Then start Julia, enter the [pkg mode](https://docs.julialang.org/en/v1/stdlib/Pkg/),
activate the [project](https://julialang.github.io/Pkg.jl/stable/environments/)
(projects are similar to python `venv`'s), install the GRIB.jl package (as it is
also not on the registry), and then finally you can instantiate cfgrib.jl to get
the rest of the dependencies:

```julia
activate .
add https://github.com/weech/GRIB.jl
instantiate
```

Finally exit pkg mode by pressing backspace, and use the package as usual:

```julia
using cfgrib
```

## TODO

- Documentation:
  - add badges for:
    - stable docs
    - latest docs
    - documentation build status
  - for auto-generation:
    - additional docstrings where required
    - set up doc build and deploy through CI
  - write up manual pages
    - examples
    - additional context around docstrings
- Package:
  - see random todo's scattered through code
  - major:
    - filter_by_index
    - index file generation and loading
    - xarray-like backend
    - make code more idiomatic to julia
