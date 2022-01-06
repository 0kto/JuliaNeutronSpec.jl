function normalize!(
    df::AbstractDataFrame;
    monitor_col::Symbol=:MON,
    monitor_count::Float64=1e4,
    data_cols::Array{Symbol,1}=[:CNTS],
)
    ratio = df[monitor_col] ./ monitor_count

    df[monitor_col] ./= ratio
    for col = data_cols
        haskey(df,col) ? df[col] ./= ratio : nothing
    end

    nothing
end

function normalize(df_in::AbstractDataFrame; kwargs...)
    df = deepcopy(df_in)
    normalize!(df; kwargs...)
    return df
end
