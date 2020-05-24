# cfgrib

[![Build Status](https://travis-ci.com/robertrosca/cfgrib.jl.svg?branch=dev)](https://travis-ci.com/robertrosca/cfgrib.jl)
[![Codecov](https://codecov.io/gh/robertrosca/cfgrib.jl/branch/dev/graph/badge.svg)](https://codecov.io/gh/robertrosca/cfgrib.jl)

## Dev Notes

Question about cfgrib.py:

For the sample file `regular_gg_wrong_increment.grib` the message contains a
list of 18 432 values, but the given shape of the data is (64, 192), so there
are 6144 more values than the data shape suggests.

In the python version, the OnDiskArray is read with:

```
array_field.__getitem__(tuple(array_field_indexes)).flat[:] = values
```

Which means that the last values are discarded. Is this expected behaviour?


Investigate discrepancy between python and julia index

In julia time is [0, 1200], whereas in python it is multiple
large integers...

https://discourse.julialang.org/t/new-package-to-map-grib-files-to-the-unidatas-common-data-model-v4-following-the-cf-conventions/32375/9

https://github.com/rafaqz/DimensionalData.jl
