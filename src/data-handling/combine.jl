"""
    normalize!(
        df::AbstractDataFrame;
        monitor_col::Symbol=:MON,
        monitor_count::Float64=1e4,
        data_cols::Array{Symbol,1}=[:CNTS]
    )

normalize a DataFrame *in place* by scaling the column `monitor_col` to
`monitor_count`, and applying the same scaling factor to the all `data_cols`
as well.

See also: [`normalize`](@ref)
"""
function normalize!(
    df::AbstractDataFrame;
    monitor_col::Symbol=:MON,
    monitor_count::Float64=1e4,
    data_cols::Array{Symbol,1}=[:CNTS],
)
    ratio = df[!,monitor_col] ./ monitor_count

    for col = intersect( data_cols, propertynames(df))
        df[!,col] ./= ratio
    end
    df[!,monitor_col] ./= ratio
    nothing
end

"""
    normalize!(
        df::AbstractDataFrame;
        monitor_col::Symbol=:MON,
        monitor_count::Float64=1e4,
        data_cols::Array{Symbol,1}=[:CNTS]
    )

return a normalized DataFrame by scaling the column `monitor_col` to
`monitor_count`, and applying the same scaling factor to the all `data_cols`
as well.

See also: [`normalize`](@ref)
"""
function normalize(df_in::AbstractDataFrame; kwargs...)
    df = deepcopy(df_in)
    normalize!(df; kwargs...)
    return df
end

"""
    combine(
        df_in::AbstractDataFrame,
        edges;
        bin_cols::Array{Symbol,1}=[:EN],
        monitor_count::Number=1e4
    )

Combine multiple measurements to a single measurement.
This function should only be applied to raw data!

All data in a DataFrame is binned according to `edges` along the columns defined
in `bin_cols` and normalized to `monitor_count`.


"""
function combine(
    df_in::AbstractDataFrame,
    edges;
    bin_cols::Array{Symbol,1}=[:EN],
    monitor_count::Number=1e4
)
    df = deepcopy(df_in)
    # variables that do not scale with counting time
    cols_intensive = [
        :QH, :QK, :QL, :EN, :q, :qh, :qk, :ql, :kf, :ki,
        :A1, :A2, :A3, :A3B, :A3P, :A4, :A5, :A6,
        :GL, :GU, :GFC, :PSI, :DA, :DM, :MF,
        :θ, :ω, :χ, :ψ, :ϕ,
        :TEMP, :EI, :P, :EV,
    ]
    # variables that scale with counting time
    ## mind that :MON is handled seperately
    cols_extensive = [
        :CNTS, :time,
        :SFx, :SFy, :SFz, :NSFx, :NSFy, :NSFz, :m_perp, :myy, :mzz
    ]
    cols_static = setdiff(
        Set(propertynames(df)),
        cols_intensive,
        cols_extensive
    )
    # prepare input NeutronDataFrame ------------------------------------
    df = deepcopy(dropmissing(df_in, bin_cols))
    df = normalize(df,
        data_cols = cols_extensive[cols_extensive .!= :time],
        monitor_count = monitor_count,
        monitor_col = :MON
    )
    # prepare df_out with uniform stat ----------------------------------------
    # check if we deal with polarized NeutronDataFrame and create new df_out
    df_out = DataFrame(cmd=repeat(["combined"], length(edges)-1))
    # do histograms of variable data ------------------------------------------
    # here we use means
    for key in cols_intensive
        if key in propertynames(df) && sum(ismissing.(df[:,key])) == 0
            hst_int = fit(Histogram, df, bin_cols, edges)
            hst_tmp = fit(Histogram, df, bin_cols, edges; weights=key)
            df_out[!,key] = hst_tmp.weights ./ hst_int.weights
            replace!(df_out[:,key], NaN => 0)
        end
    end
    # do histograms on counted columns ----------------------------------------
    for key in union(cols_extensive, [:MON])
        if key in propertynames(df)
            hst_tmp     = fit(Histogram, df, bin_cols, edges; weights=key)
            # normalization happens outside the loop
            df_out[!,key] = hst_tmp.weights
            replace!(df_out[:,key], NaN => 0)
        end
    end
    df_out = normalize(df_out,
        data_cols = cols_extensive[cols_extensive .!= :time],
        monitor_count = monitor_count,
        monitor_col = :MON
    )
    # df_out[:scnVariable]   = Tuple(bin_cols)
    if length(bin_cols) === 1
        if typeof(edges) <: StepRangeLen
            df_out[!,bin_cols[1]] = midpoints(edges)
        end
    end
    # remove misssing or NaN in EN --------------------------------------------
    mask = iszero.(sum.(
        ismissing.(df_out[:,:EN])
        + isnan.(df_out[:,:EN])
        + isnan.(values.(df_out[:,:CNTS]))
    ))
    return df_out[mask,:]
end