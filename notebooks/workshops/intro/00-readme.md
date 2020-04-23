# Introductory Workshop Notes

Some notes on what to do before running the notebooks in this directory

## Install Process

### Installing Julia

Julia can be installed from
[the julialang website](https://julialang.org/downloads/).

### Installing cfgrib.jl

Packages in Julia are usually installed by entering package mode (press `]` in
the julia prompt on a newline) and simply running `] add
https://github.com/RobertRosca/cfgrib.jl`, however as the aim is to dive a bit
into the code it will be easier to install `cfgrib.jl` as a project instead.

To do this, you clone the project, `cd` into it, and then run instantiate, e.g:

```
> git clone https://github.com/RobertRosca/cfgrib.jl
> cd cfgrib.jl
> julia
julia > ]
(@v1.4) pkg> activate .
(@v1.4) pkg> instantiate
```

This would typically work, however there will likely be an error saying that
the `GRIB.jl` package cannot be found. This is because it has not been added to
the Julia package registry yet, you must first manually install it by running
`add https://github.com/weech/GRIB.jl` while in package mode. Once it has
finished, run instantiate again and `cfgrib.jl` will be installed.

### Installing a Julia Kernel

There are a few ways to set up IJulia as noted on the
[IJulia repository](https://github.com/JuliaLang/IJulia.jl), the simplest
install process is running:

```
> julia
julia > ]
(@v1.4) pkg> add IJulia
(@v1.4) pkg> (backspace to exit pkg mode)
julia > using IJulia
```

This will install the standard IJulia kernel which should automatically find
and load the project in the parent directory of the notebook, enabling the
correct environment for the notebooks to run in.

Now just start Jupyter as you normally would and open the notebooks in order.
