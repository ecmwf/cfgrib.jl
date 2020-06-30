# Tasks

List of tasks, roughly in order of completion and priority:

## Done

- [x] updating with additional tests/features from cfgrib.py
  - new test file: `forecast_monthly_ukmo`
  - addition of `date_key="indexingDate"` and `time_key="indexingTime"`

- [x] added `CompatHelper` for automated dependency updates (similar to Dependabot)

- [x] segfaults in GRIB.jl
  - @Robert to open an issue on GRIB.jl on GitHub and mention Stephan, so that
    he is in the loop.
  - Problem ended up being with Julia, not GRIB.jl!
  - https://github.com/JuliaLang/julia/issues/36422
  - Tuples over 64 items caused a segfault with the `unique` function

- [x] adding in xarray-like backends
  - made flexible backend system that allows for multiple/no backends to be
    loaded dynamically
  - two backends present: `AxisArrays` and `DimensionalData`
  - both are relatively basic wrappers around my `DataSet` types
  - features like pretty printing, conversion, clever-ish getindex/getproperty
  - [x] tests


## In Progress

- [~] FileIO integration
  - 90% done, integration is set up in the code, but for full integration a PR
    to FileIO is required
  - will wait until package is on the Julia Package Registry to do that

- [~] started work on documentation
  - [ ] fill in all user-facing docstrings
  - [ ] setting up documentation deployment
  - [ ] integrate doctests with rest of CI
  - [ ] examples
  - [ ] add in badges

- [~] working on GitHub Workflow CI instead of travis
  - in theory more flexible, if it works properly...

- [~] logging
  - Iain reports that logging is only used to report problems.
  - In Julia, there are built-in logging functionalities. Stephan would be
    interested in seeing warnings/errors in Julia
  - @Robert to look into that
  - some logging already present, need to flesh out the rest

## Todo

- [ ] filter by keys examples
  - Iain suggested that to look at the top level README for examples of
    filter_by_keys, missing in tests
  - @Robert to look into that

- [ ] intensive real-life examples
  - Robert cannot implement any Julia specific optimisations because he does not
    have a non-trivial example.
  - @Shahram can provide stress tests for eccodes
  - @Iain can provide an example using very high horizontal resolution and
    numerous vertical levels

## Backlog

- [ ]cfmessage conversion methods
    - I ain checked and found a test for the first three, but last one is not
      used/tested.

- [ ] tiny questions
  - The version is in GitHub.
  - @Robert to file a feature request to add a function to expose the version.

- [ ] Additional questions:
  - Sharam suggested to use code coverage on the GitHub repo. Robert mentioned
    there is already code coverage for cfgrib.jl but not for GRIB.jl
  - @Robert to mention this to the developer of GRIB.jl

- [ ] use of history
  - In Julia it's not easy to convert dictionary to string. Is this
    functionality needed? Should Robert implement it?
  - Iain mentioned this is optional to have.
