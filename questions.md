## cfgrib questions

Some questions I need input on, in no particular order:


### logging

How is the logging functionality usually used? So far I just haven't implemented
it, for when I do it would be useful to know if it's only (or primarily) used
for developing and debugging the package, or if it is actually used to log info
for data analysis by users (not developers) of the package.


### offsets

There is a discrepancy between how offsets are defined and used in cfgrib with
the GRIB file seek method and in the Julia GRIB package, in Julia seek seeks
through the messages themselves not the actual offset values.

This is probably due to me making a mistake, don't know enough about GRIB spec
to figure out how this should be done.


### filter by keys examples

Would be nice to see some examples of how and when `filter_by_keys` is used so
that I can add in some tests for it.


### use of history

How is the `history` field used? There are some problems with correctly escaping
quotes and making the string look like a dictionary in Julia, so right now it's
not really equivalent to the python version.


### OnDiskArray dtype

The `OnDiskArray` class in Python has a `dtype` filed which is always set to
`Float32`, is the multidimensional message data in GRIB always that type, or
should I try to infer what type it is from the file and then set the type of the
`OnDiskArray` to match that?


### cfmessage conversion methods

There are a few methods in `cfmessage` which aren't called by the tests, so I
haven't added their equivalents in yet for Julia. Could I have some examples for
these being called:

- `to_grib_date_time`
- `from_grib_step`
- `to_grib_step`
- `from_grib_month`


### intensive real-life examples

There's quit a bit of optimisation that I could apply to make the package both
faster to use on its own, or to make it easier to use it with other tools (e.g.
outputting shared or distributed arrays for parallelised tasks; CuArrays for
GPU tasks), but I need an example of real analysis code that calls cfgrib for
this. It's hard to optimise the code without seeing real usecases.

Also I'm at the stage where I need to make some decisions on how users interface
with the functions, it's hard to figure out the right design without seeing how
people currently use cfgrib.

A non-trivial example going through a decent amount of data would also let me
create a performance benchmark, which is important for the development of the
package but also lets me show a concrete python vs. julia example of how julia
code should be written.


### wrong increment loading behaviour

My automated parity tests between julia and python showed python returns data
for the `u10` variable in `regular_gg_wrong_increment.grib`, whereas Julia
throws an error `DimensionMismatch("new dimensions (192, 64) must be consistent with array size 18432")`.

This happens because the `u10` variable contains an array of 18 432 values, but
it gives dimensions of `(192, 64)`, which is only 12 288 values, so there are
6 144 more values in than would fit in the array.

In python, the assignment to the array is done with:

```
array_field.__getitem__(tuple(array_field_indexes)).flat[:] = values
```

Which means that the last values are discarded.

I can easily implement the same behaviour in Julia, but is this really intended?
Those values aren't missing, they contain actual data which is just thrown away,
in my mind this should throw an error by default, but there could be a `discard`
or `force_fit` flag which allows data to be thrown away.

The flag could have values of `false` (default), `end` (discard data at the end
of the array, current behaviour in python) or `start` (discard data at the start
instead).


### segfaults in GRIB.jl

This is completely beyond my skills, I use `GRIB.jl` to open and read the GRIB
files. GRIB.jl provides an interface to eccodes. For some reason I don't
understand, GRIB.jl throws a segfault error when trying to read the sample file
`reduced_gg.grib`.

Julia calls to c are native, so (I assume) debugging this should be relatively
straightforward for somebody who knows the interface to eccodes well, but that's
not me :P could I get some help with tracking down this issue?


### tiny questions

- How can I pull out the version of eccodes? It's stored in the `history` but I
  don't know hot to get it.


# Meeting Notes

- make grib.jl issue about segfaults and @ steffen

- wrong increment loading behaviour
  - calculate increment and dimensions from the first bits of information
  - grib devided into sections, section describes grid geometry information
  - other section contains the data
  - array of values can be out of sync with the grid geometry

- logging only for debugging
  - warn, error, critical, level logging in julia

- offsets
  - each message is self contained
  - message number (count key) starts from 1
  - offset is a long integer which is the BYTE OFFSET OF THE MESSAGE IN THE FILE
  - seeking to the byte offset puts you at the beginning of the message

- use readme file as tests for filter by keys

- history shouldn't matter much, just leave it as a list of processing steps

- OnDiskArray leave as float32

- cfmessage conversion methods
  - these methods to have some tests:
  - to_grib_date_time, from_grib_step, to_grib_step

- look for the eccodes c-engine on github to see the version
  - eccodes-python python bindings have the way to get the versions
  - request GRIB.jl to add a versions method in

- ask GRIB.jl author about adding in tests
