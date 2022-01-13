"""
    round(df, precision_dict::Dict{Symbol,Int})

round dataframe columns defined in a precision_dict.
"""
# import Base: round
function Base.round(
    df_in::AbstractDataFrame,
    precision_dict::Dict{Symbol,Int}
)
    df = deepcopy(df_in)
    for (col,precision) in precision_dict
        if hasproperty(df,col)
            mask = @. ismissing(df[:,col]) == false
            df[mask,col] = @. round(df[mask,col], RoundingNearstTiesUp; digits=precision, base = 10)
        end
    end
    return df
end
export round

# import Base: -
function Base.:-(
    subtrahend::AbstractDataFrame,
    minuend::AbstractDataFrame,
    edges;
    bin_col::Symbol=:EN,
    monitor_count::Number=1e4
)

    # 1. combine input.
    sub = combine(
            subtrahend,
            edges,
            bin_cols=[bin_col],
            monitor_count=monitor_count
        )
    min = combine(
        minuend,
        edges,
        bin_cols=[bin_col],
        monitor_count=monitor_count
    )

    # 2. subtraction.
    min = rename(min, [ Symbol("min_$(col)") for col in names(min)])

    res = innerjoin(sub, min; on = bin_col => Symbol("min_$(bin_col)") )
    for col in  [ :CNTS, :SFx, :SFy, :SFz, :NSFx, :NSFy, :NSFz, :m_perp, :myy, :mzz ]
        if hasproperty(res, col)
            res[!,col] .-= res[:,Symbol("min_$(col)")]
        end
    end
    # 3. time / MON reflect the actual counting time / mon_ct that went into the 
    #    measurment.
    res[!,:time] .+= res[:,:min_time]
    res[!,:MON] .+= res[:,:min_MON]

    return res
end
export -

# import Base: +
function Base.:+(
    summand1::AbstractDataFrame,
    summand2::AbstractDataFrame,
    edges;
    bin_col::Symbol=:EN,
    monitor_count::Number=1e4
)

   for col in  [ :CNTS, :SFx, :SFy, :SFz, :NSFx, :NSFy, :NSFz, :m_perp, :myy, :mzz ]
        if hasproperty(summand2, col)
            summand2[!,col] .*= -1
        end
    end

    return -(summand1, summand2, edges; bin_col=bin_col, monitor_count=monitor_count)
end
export +


# import Base: *
function Base.:*(
    df_in::AbstractDataFrame,
    factor
)
    df = deepcopy(df_in)
    for col in  [ :MON, :CNTS, :SFx, :SFy, :SFz, :NSFx, :NSFy, :NSFz, :m_perp, :myy, :mzz ]
        if hasproperty(df, col)
            df[!,col] .*= factor
        end
    end

    return df
end
export *