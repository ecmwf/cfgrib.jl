```@meta
Author = "Robert Rosca"
```

# [Indexing](@id lib_indexing)

[GRIB.jl](https://github.com/weech/GRIB.jl) is by CfGRIB to read the GRIB files,
GRIB.jl provides its own ways to create, read, and filter an index, however
cfgrib.py uses a different approach to indexing. So, CfGRIB.jl, being based on
the python implementation, recreates the python approach instead of integrating
with the GRIB.jl indexing approach.

The indexing file defines the `FileIndex` type, as well as the constructors for
that type.

```@index
Modules = [CfGRIB]
Pages   = ["indexing.jl"]
```

```@autodocs
Modules = [CfGRIB]
Pages   = ["indexing.jl"]
```
