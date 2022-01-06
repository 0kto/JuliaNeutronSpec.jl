import StatsBase: fit
function StatsBase.fit(::Type{Histogram},
        df::AbstractDataFrame,
        axes::Array{Symbol,1},
        varargs...;
        weights::Symbol=:NA,
        kwargs... )
    
    if length(axes) == 1
        data = convert(Array{Float64,1},df[axes[1]])
    elseif length(axes) == 2
        data = (convert(Array{Float64,1},df[axes[1]]),convert(Array{Float64,1},df[axes[2]]))
    else
        @error "at most two axes are supported."
    end
            
    if weights != :NA
        weights = Weights(Array(df[weights]))
        hist = StatsBase.fit(Histogram,data,weights,varargs... ;kwargs... )
    else
        hist = StatsBase.fit(Histogram,data,varargs... ;kwargs... )
    end

    return hist
end
export fit