import Interpolations: interpolate

"""
    interpolate(
        df::AbstractDataFrame,
        axes::Vector{Symbol},
        varargs...;
        weights::Symbol=:CNTS,
        kwargs...
    )

Make `Interpolations.interpolate` easier to use with DataFrames.
Supports 1D and 2D interpolations.
"""
function Interpolations.interpolate(
    df::AbstractDataFrame,
    axes::Vector{Symbol},
    varargs...;
    weights::Symbol=:CNTS,
    kwargs...
)

    weights = Vector{Float64}(df[weights])

    if length(axes) == 1
        knots = (sort(convert(Vector{Float64},df[axes[1]])),)
    elseif length(axes) == 2
        knots = (
            sort(convert(Vector{Float64},df[axes[1]])),
            sort(convert(Vector{Float64},df[axes[2]]))
        )
    else
        @error "at most two axes are supported."
    end

    itp = interpolate(knots, weights, varargs...; kwargs...)
    return itp
end
export interpolate
