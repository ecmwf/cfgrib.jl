# cfgrib

[![Build Status](https://travis-ci.com/robertrosca/cfgrib.jl.svg?branch=master)](https://travis-ci.com/robertrosca/cfgrib.jl)
[![Codecov](https://codecov.io/gh/robertrosca/cfgrib.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/robertrosca/cfgrib.jl)

## Dev Notes

Missing values (e.g. 9999) are probably not handled correctly

Investigate discrepancy between python and julia index

In julia time is [0, 1200], whereas in python it is multiple
large integers...


```
push!(LOAD_PATH, "/home/roscar/work/cfgrib-project/cfgrib.jl")
using cfgrib

dir_tests = abspath(joinpath(dirname(pathof(cfgrib)), "..", "test"))
dir_testfiles = abspath(joinpath(dir_tests, "sample-data"))
test_file = joinpath(dir_testfiles, "era5-levels-members.grib")
test_file = joinpath(dir_testfiles, "regular_gg_sfc.grib")

res = cfgrib.DataSet(test_file)

index = cfgrib.FileIndex(
    test_file,
    cfgrib.ALL_KEYS
)

cfgrib.filter!(index, paramId=130)

dims, data_var, coord_vars = cfgrib.build_variable_components(
    index; encode_cf=("geography", )
)
```


https://discourse.julialang.org/t/new-package-to-map-grib-files-to-the-unidatas-common-data-model-v4-following-the-cf-conventions/32375/9

https://github.com/rafaqz/DimensionalData.jl
