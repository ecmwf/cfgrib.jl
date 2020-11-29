# CfGRIB.jl

[![lifecycle](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip)
[![latest release](https://img.shields.io/github/release/ecmwf/CfGRIB.jl.svg)](https://github.com/ecmwf/cfgrib.jl/releases/latest)
[![Apache 2 license](https://img.shields.io/github/license/ecmwf/CfGRIB.jl)](https://github.com/ecmwf/cfgrib.jl/blob/master/LICENSE)

[![Build Status](https://github.com/ecmwf/cfgrib.jl/workflows/Tests/badge.svg)](https://github.com/ecmwf/cfgrib.jl/actions?query=workflow%3ATests)
[![Build Status](https://github.com/ecmwf/cfgrib.jl/workflows/Nightly/badge.svg)](https://github.com/ecmwf/cfgrib.jl/actions?query=workflow%3ANightly)
[![Codecov](https://codecov.io/gh/ecmwf/CfGRIB.jl/branch/dev/graph/badge.svg)](https://codecov.io/gh/ecmwf/CfGRIB.jl)

[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://ecmwf.github.io/cfgrib.jl/dev/)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)

## Description
CfGRIB.jl is a julia interface to map GRIB files to the [Unidata's Common Data
Model v4](https://www.unidata.ucar.edu/software/thredds/current/netcdf-java/CDM/)
following the [CF Conventions](http://cfconventions.org).

This package is based on the python implementation in
[cfgrib.py](https://github.com/ecmwf/cfgrib) and closely follows the approaches
of that package, but in Julia instead. Parity tests are automatically performed
between the two to ensure that the data returned by the Julia version is
equivalent to that from Python.

In Python [xarray](http://xarray.pydata.org) has come out to be a standard
way to implement named arrays, however as Julia is a much younger language no
stable array interface has been adopted by the community yet, so the approach
here is more flexible and allows for multiple array backends to be used.

Currently two array backends are supported:
- [`AxisArrays`](https://github.com/JuliaArrays/AxisArrays.jl)
- [`DimensionalData`](https://github.com/rafaqz/DimensionalData.jl)

If a backend is found to be installed then its functionality will automatically
be enabled, otherwise only the built-in bare data types will be returned.

Low level access and decoding is performed by calling
[GRIB.jl](https://github.com/weech/GRIB.jl) which itself calls the
[ECMWF ecCodes library](https://software.ecmwf.int/wiki/display/ECC/).

## Installation
The package is currently under heavy development so it has not been added to the
Julia package registry yet. To install the package first clone this repository:

```shell
git clone https://github.com/ecmwf/cfgrib.jl/
cd CfGRIB.jl
```

Then start Julia, enter the
[pkg mode](https://docs.julialang.org/en/v1/stdlib/Pkg/), activate the
[project](https://julialang.github.io/Pkg.jl/stable/environments/) (projects are
similar to python `venv`'s), install the GRIB.jl package (as it is also not on
the registry), and then finally you can instantiate CfGRIB.jl to get the rest of
the dependencies:

```julia
#  Activate the current directory as a project
activate .
#  To enable backend support
add AxisArrays
add DimensionalData
instantiate
```

Finally exit pkg mode by pressing backspace, and use the package as usual:

```julia
using CfGRIB
```

## Development and Contribution
To install the package for development you can run:

```shell
git clone https://github.com/ecmwf/cfgrib.jl/
cd CfGRIB.jl
```

Then in Julia:

```julia
] activate .
] develop .
```

Will install the package as a development package. When you run `] test` the
tests will run locally. If you want to run the tests within a container similar
to the ones used when the CI runs via GitHub, then install
[nektos/act](https://github.com/nektos/act) and run the command
`act -P ubuntu-latest=nektos/act-environments-ubuntu:18.04 -j tests`, this will
set up a docker container and run the full test suite within it.
