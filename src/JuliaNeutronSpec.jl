module JuliaNeutronSpec

# import packages -----------------------------------------------------
using Reexport

# load core Packages and the respective extensions --------------------
@reexport using DataFrames
	include("core-extensions/DataFrames.jl")
using Glob
@reexport using Query
@reexport using Measurements
	include("core-extensions/Measurements.jl")
@reexport using Missings
@reexport using Interpolations
	include("core-extensions/Interpolations.jl")
@reexport using Dates
@reexport using StaticArrays
@reexport using DataStructures
@reexport using Rotations
@reexport using CoordinateTransformations

# load extensions for optional packages -------------------------------
# these extensions are only loaded if a the respective package is 
# loaded before the JuliaNeutronSpec.jl package is included.
using Requires # provides the functionality
function __init__()
  @require Dierckx="39dd38d3-220a-591b-8e3c-4c3a8c710a94" include("optional-extensions/Dierckx.jl")
  @require DataFitting="2e2c70e5-d463-5cb0-9776-5d0c86956fe9" include("optional-extensions/DataFitting.jl")
  @require StatsBase="2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91" include("optional-extensions/StatsBase.jl")
  @require Plots="91a5bcdd-55d7-5caf-9e0b-520d859cae80" include("optional-extensions/Plots.jl")
end

# definition of types -------------------------------------------------

# actual package code -------------------------------------------------
# Load and normalize Data
include("io/load_data.jl")
include("io/io_ill.jl")
include("io/io_ill_header.jl")

end
