import REPL

# Very hacky way to get the pretty show output as a sting so that it can be
# included in the docstrings automatically. This can definitely be done better
# but I haven't looked it up much.
function _pretty_show_str_(var)
    capturedout=IOBuffer()
    term = REPL.Terminals.TTYTerminal("dumb", stdin, capturedout, capturedout)
    mime = MIME{Symbol("text/plain")}()
    show(term, mime, var)
    out = String(take!(capturedout))
    out = replace(out, "_"=>"\\_")
    out = split(out)
    return out
end

const GLOBAL_ATTRIBUTES_KEYS = [
    "edition", "centre",
    "centreDescription", "subCentre"
]
@doc """
$(_pretty_show_str_(GLOBAL_ATTRIBUTES_KEYS))
""" GLOBAL_ATTRIBUTES_KEYS

const DATA_ATTRIBUTES_KEYS = [
    "paramId",
    "shortName",
    "units",
    "name",
    "cfName",
    "cfVarName",
    "dataType",
    "missingValue",
    "numberOfPoints",
    "totalNumber",
    "numberOfDirections",
    "numberOfFrequencies",
    "typeOfLevel",
    "NV",
    "stepUnits",
    "stepType",
    "gridType",
    "gridDefinitionDescription",
]
@doc """
$(_pretty_show_str_(DATA_ATTRIBUTES_KEYS))
""" DATA_ATTRIBUTES_KEYS

const GRID_TYPE_MAP = Dict(
    "regular_ll" => [
        "Nx",
        "iDirectionIncrementInDegrees",
        "iScansNegatively",
        "longitudeOfFirstGridPointInDegrees",
        "longitudeOfLastGridPointInDegrees",
        "Ny",
        "jDirectionIncrementInDegrees",
        "jPointsAreConsecutive",
        "jScansPositively",
        "latitudeOfFirstGridPointInDegrees",
        "latitudeOfLastGridPointInDegrees",
    ],
    "rotated_ll" => [
        "Nx",
        "Ny",
        "angleOfRotationInDegrees",
        "iDirectionIncrementInDegrees",
        "iScansNegatively",
        "jDirectionIncrementInDegrees",
        "jPointsAreConsecutive",
        "jScansPositively",
        "latitudeOfFirstGridPointInDegrees",
        "latitudeOfLastGridPointInDegrees",
        "latitudeOfSouthernPoleInDegrees",
        "longitudeOfFirstGridPointInDegrees",
        "longitudeOfLastGridPointInDegrees",
        "longitudeOfSouthernPoleInDegrees",
    ],
    "reduced_ll" => [
        "Ny",
        "jDirectionIncrementInDegrees",
        "jPointsAreConsecutive",
        "jScansPositively",
        "latitudeOfFirstGridPointInDegrees",
        "latitudeOfLastGridPointInDegrees",
    ],
    "regular_gg" => [
        "Nx",
        "iDirectionIncrementInDegrees",
        "iScansNegatively",
        "longitudeOfFirstGridPointInDegrees",
        "longitudeOfLastGridPointInDegrees",
        "N",
        "Ny",
    ],
    "rotated_gg" => [
        "Nx",
        "Ny",
        "angleOfRotationInDegrees",
        "iDirectionIncrementInDegrees",
        "iScansNegatively",
        "jPointsAreConsecutive",
        "jScansPositively",
        "latitudeOfFirstGridPointInDegrees",
        "latitudeOfLastGridPointInDegrees",
        "latitudeOfSouthernPoleInDegrees",
        "longitudeOfFirstGridPointInDegrees",
        "longitudeOfLastGridPointInDegrees",
        "longitudeOfSouthernPoleInDegrees",
        "N",
    ],
    "lambert" => [
        "LaDInDegrees",
        "LoVInDegrees",
        "iScansNegatively",
        "jPointsAreConsecutive",
        "jScansPositively",
        "latitudeOfFirstGridPointInDegrees",
        "latitudeOfSouthernPoleInDegrees",
        "longitudeOfFirstGridPointInDegrees",
        "longitudeOfSouthernPoleInDegrees",
        "DyInMetres",
        "DxInMetres",
        "Latin2InDegrees",
        "Latin1InDegrees",
        "Ny",
        "Nx",
    ],
    "reduced_gg" => ["N", "pl"],
    "sh" => ["M", "K", "J"],
)
@doc """
$(_pretty_show_str_(GRID_TYPE_MAP))
""" GRID_TYPE_MAP

const GRID_TYPE_KEYS = unique(vcat(values(GRID_TYPE_MAP)...))
@doc """
$(_pretty_show_str_(GRID_TYPE_KEYS))
""" GRID_TYPE_KEYS

const ENSEMBLE_KEYS = ["number"]
@doc """
$(_pretty_show_str_(ENSEMBLE_KEYS))
""" ENSEMBLE_KEYS

const VERTICAL_KEYS = ["level"]
@doc """
$(_pretty_show_str_(VERTICAL_KEYS))
""" VERTICAL_KEYS

const DATA_TIME_KEYS = ["dataDate", "dataTime", "endStep"]
@doc """
$(_pretty_show_str_(DATA_TIME_KEYS))
""" DATA_TIME_KEYS

const ALL_REF_TIME_KEYS = [
    "time", "step",
    "valid_time", "verifying_time", "indexing_time",
    "forecastMonth"
]
@doc """
$(_pretty_show_str_(ALL_REF_TIME_KEYS))
""" ALL_REF_TIME_KEYS

const SPECTRA_KEYS = ["directionNumber", "frequencyNumber"]
@doc """
$(_pretty_show_str_(SPECTRA_KEYS))
""" SPECTRA_KEYS


const ALL_HEADER_DIMS = vcat(
    ENSEMBLE_KEYS,
    VERTICAL_KEYS,
    DATA_TIME_KEYS,
    ALL_REF_TIME_KEYS,
    SPECTRA_KEYS
)
@doc """
$(_pretty_show_str_(ALL_HEADER_DIMS))
""" ALL_HEADER_DIMS

#  TODO: Include the list of included keys in docs automatically
const ALL_KEYS = sort(unique(vcat(
    GLOBAL_ATTRIBUTES_KEYS, DATA_ATTRIBUTES_KEYS,
    GRID_TYPE_KEYS, ALL_HEADER_DIMS
)))
@doc """
$(_pretty_show_str_(ALL_KEYS))
""" ALL_KEYS


#  TODO: Include the list of coordinate attributes in docs automatically
const COORD_ATTRS = Dict(
    # geography
    "latitude"             => Dict(
        "units"            => "degrees_north",
        "standard_name"    => "latitude",
        "long_name"        => "latitude"
    ),
    "longitude"            => Dict(
        "units"            => "degrees_east",
        "standard_name"    => "longitude",
        "long_name"        => "longitude"
    ),
    # vertical
    "depthBelowLand"       => Dict(
        "units"            => "m",
        "positive"         => "down",
        "long_name"        => "soil depth",
        "standard_name"    => "depth",
    ),
    "depthBelowLandLayer"  => Dict(
        "units"            => "m",
        "positive"         => "down",
        "long_name"        => "soil depth",
        "standard_name"    => "depth",
    ),
    "hybrid"               => Dict(
        "units"            => "1",
        "positive"         => "down",
        "long_name"        => "hybrid level",
        "standard_name"    => "atmosphere_hybrid_sigma_pressure_coordinate",
    ),
    "heightAboveGround"    => Dict(
        "units"            => "m",
        "positive"         => "up",
        "long_name"        => "height above the surface",
        "standard_name"    => "height",
    ),
    "isobaricInhPa"        => Dict(
        "units"            => "hPa",
        "positive"         => "down",
        "stored_direction" => "decreasing",
        "standard_name"    => "air_pressure",
        "long_name"        => "pressure",
    ),
    "isobaricInPa"         => Dict(
        "units"            => "Pa",
        "positive"         => "down",
        "stored_direction" => "decreasing",
        "standard_name"    => "air_pressure",
        "long_name"        => "pressure",
    ),
    "isobaricLayer"        => Dict(
        "units"            => "Pa",
        "positive"         => "down",
        "standard_name"    => "air_pressure",
        "long_name"        => "pressure",
    ),
    # ensemble
    "number"               => Dict(
        "units"            => "1",
        "standard_name"    => "realization",
        "long_name"        => "ensemble member numerical id",
    ),
    # time
    "step"                 => Dict(
        "units"            => "hours",
        "standard_name"    => "forecast_period",
        "long_name"        => "time since forecast_reference_time",
    ),
    "time"                 => Dict(
        "units"            => "seconds since 1970-01-01T00:00:00",
        "calendar"         => "proleptic_gregorian",
        "standard_name"    => "forecast_reference_time",
        "long_name"        => "initial time of forecast",
    ),
    "indexing_time"        => Dict(
        "units"            => "seconds since 1970-01-01T00:00:00",
        "calendar"         => "proleptic_gregorian",
        "standard_name"    => "forecast_reference_time",
        "long_name"        => "nominal initial time of forecast",
    ),
    "valid_time"           => Dict(
        "units"            => "seconds since 1970-01-01T00:00:00",
        "calendar"         => "proleptic_gregorian",
        "standard_name"    => "time",
        "long_name"        => "time",
    ),
    "verifying_time"       => Dict(
        "units"            => "seconds since 1970-01-01T00:00:00",
        "calendar"         => "proleptic_gregorian",
        "standard_name"    => "time",
        "long_name"        => "time",
    ),
)
@doc """
$(_pretty_show_str_(COORD_ATTRS))
""" COORD_ATTRS

const GRID_TYPES_DIMENSION_COORDS = ["regular_ll", "regular_gg"]
@doc """
$(_pretty_show_str_(GRID_TYPES_DIMENSION_COORDS))
""" GRID_TYPES_DIMENSION_COORDS

const GRID_TYPES_2D_NON_DIMENSION_COORDS = [
    "rotated_ll",
    "rotated_gg",
    "lambert",
    "albers",
    "polar_stereographic",
]
@doc """
$(_pretty_show_str_(GRID_TYPES_2D_NON_DIMENSION_COORDS))
""" GRID_TYPES_2D_NON_DIMENSION_COORDS

