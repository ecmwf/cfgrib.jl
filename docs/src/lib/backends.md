```@meta
Author = "Robert Rosca"
```

# [Backends](@id lib_backends)

CfGRIB.jl has a flexible backend system built in to allow for multiple ways to
represent multidimensional data with named dimensions.

Backends are loaded in dynamically based on what packages the user has
available, currently there are two built-in backends, one is based on
[DimensionalData.jl](https://github.com/rafaqz/DimensionalData.jl) and the other
uses [AxisArrays](https://github.com/JuliaArrays/AxisArrays.jl).

Additionally, [FileIO.jl](https://github.com/JuliaIO/FileIO.jl) integration is
prepared for each of the backends so that users utilising FileIO can use its
smart load functions which will load the file via CfGRIB.jl when the correct
file extension and magic numbers are present.

---

```@index
Modules = [CfGRIB]
Pages   = ["backends.jl"]
```

```@autodocs
Modules = [CfGRIB]
Pages   = ["backends.jl"]
```

---

```@index
Modules = [CfGRIB]
Pages   = ["backends/axisarrays.jl", "backends/dimensionaldata.jl"]
```

```@autodocs
Modules = [CfGRIB]
Pages   = ["backends/axisarrays.jl", "backends/dimensionaldata.jl"]
```
