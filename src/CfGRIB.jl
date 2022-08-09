"""
$(README)
"""
module CfGRIB

const cfgrib_jl_version = "0.0.0"

using DocStringExtensions
import DiskArrays

const DA = DiskArrays

# Docstring template for types using DocStringExtensions
@template TYPES =
    """
    # Summary
    $(TYPEDEF)

    $(DOCSTRING)

    # Fields

    $(TYPEDFIELDS)

    # Constructors

    $(METHODLIST)
    """

@template (FUNCTIONS, METHODS) =
    """
    $(TYPEDSIGNATURES)
    $(DOCSTRING)
    """

@template (CONSTANT) =
    """
    $(TYPEDSIGNATURES)
    $(DOCSTRING)
    """

include("constants.jl")
include("cfmessage.jl")
include("indexing.jl")
include("dataset.jl")
include("backends.jl")

end
