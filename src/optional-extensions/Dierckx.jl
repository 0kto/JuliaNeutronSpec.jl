import Dierckx: Spline1D

function Dierckx.Spline1D(
    x::Vector{Float64},
    y::Vector{Measurement{Float64}};
    kwargs...
)
    kwargs = Dict{Symbol,Any}(kwargs)

    if ~haskey(kwargs, :w)
        kwargs[:w] = Measurements.uncertainty.(y)
    end
    y = Measurements.value.(y)

    return Dierckx.Spline1D(x, y; kwargs...)
end

function Dierckx.Spline1D(
    df::AbstractDataFrame,
    x::Symbol,
    y::Symbol;
    kwargs...
)
    kwargs = Dict{Symbol,Any}(kwargs)
    # handle weights differently (could be supplied as DataFrame col).
    if haskey(kwargs, :w)
        if typeof(kwargs[:w]) === Symbol
            kwargs[:w] = df[:,:w].^-1
        end
    end
    return Dierckx.Spline1D(df[:,x], df[:,y]; kwargs...)
end

export Spline1D
