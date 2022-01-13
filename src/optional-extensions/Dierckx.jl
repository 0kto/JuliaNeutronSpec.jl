import Dierckx: Spline1D
"""
    Spline1D(x::Vector{Number}, y::Vector{Measurement{Number}}; kwargs...)

Allow Measurements.Measurement type for `y`  values, using the
inverse uncertainty as weights.
"""
function Dierckx.Spline1D(x::Vector{Number}, y::Vector{Measurement{Number}}; kwargs...)

    kwargs = Dict{Symbol,Any}(kwargs)

    if ~haskey(kwargs, :w)
        kwargs[:w] = Measurements.uncertainty.(y).^-1
    end
    y = Measurements.value.(y)

    return Dierckx.Spline1D(x, y; kwargs...)
end

"""
    Spline1D( df::AbstractDataFrame, x::Symbol, y::Symbol; kwargs... )

Make the use of DataFrames easier.
"""
function Dierckx.Spline1D( df::AbstractDataFrame, x::Symbol, y::Symbol; kwargs... )
    kwargs = Dict{Symbol,Any}(kwargs)
    # handle weights differently (could be supplied as DataFrame col).
    if haskey(kwargs, :w)
        if typeof(kwargs[:w]) === Symbol
            kwargs[:w] = df[:,:w]
        end
    end
    return Dierckx.Spline1D(df[:,x], df[:,y]; kwargs...)
end

export Spline1D
