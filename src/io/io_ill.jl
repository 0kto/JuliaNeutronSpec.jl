export io_ill
function io_ill(filename::AbstractString; 
                precision_dict::AbstractDict{Symbol,Int} = Dict{Symbol,Int}(),
                kwargs...)
    kwargs = Dict{Symbol,Any}(kwargs)
    # get metadata and attach to initialized df ---------------------------------
    param, varia, df_meta, motor0  = io_ill_header(filename)
    # read file -----------------------------------------------------------------
    fc = readlines(filename)
    df_raw = CSV.read(filename, header = df_meta[:ln_param_end]+1,
                      limit = df_meta[:lns_data],
                      delim=' ',
                      ignorerepeated = true,
                      silencewarnings = true) |> DataFrame
    df_raw[!,:scnID] .= df_meta[:scnID]
    df_raw[!,:scnIDX] = collect(1:size(df_raw,1))
    # test for multidetector like Flatcone --------------------------------------
    multidetectorCNTS_start = findfirst(occursin.("MULTI:", fc))
    if multidetectorCNTS_start != nothing
        # add columns to df_raw
        df_raw[!,:detID] .= 0
        df_multi = CSV.read(filename, header = false,
                            datarow = multidetectorCNTS_start+1,
                            delim=' ', 
                            ignorerepeated=true,
                            silencewarnings = true
                            ) |> DataFrame
        multidetectorChannelNumber = size(df_multi,2)
        df_multi[!,:PNT] = 1:size(df_multi,1)
        df_join = join(df_raw, df_multi, on = :PNT)
        df_current  = similar(df_raw[[],vcat(filter!(i -> i ≠ "CNTS", names(df_raw)), "CNTS")])
        for pnt in 1:df_meta[:lns_data]
            for det_idx in 1:multidetectorChannelNumber
                cols = vcat(filter!(i -> i ≠ "CNTS", names(df_raw)), "Column$(det_idx)")
                df_tmp = DataFrame(df_join[pnt,cols])
                df_tmp = rename(df_tmp, Symbol("Column$(det_idx)") => :CNTS)
                df_tmp[!,:detID] .= det_idx
                append!(df_current, df_tmp)
            end
        end
        df_raw = df_current
    else
        df_raw[!,:detID]  .= 1
    end
    # prepping df_raw (column names) --------------------------------------------
    rename_cols = Dict{Symbol,Symbol}(:M1 => :MON,
                                      :TT => :TEMP,
                                      :M2 => :MONana,
                                      :TIME => :time)
    if haskey(kwargs,:rename_cols)
        for (key,val) in kwargs[:rename_cols]
            rename_cols[key] = val
        end
    end
    for (key,val) in rename_cols
        if hasproperty(df_raw,key)
            rename!(df_raw,key => val)
        end
    end
    # create dummy output -------------------------------------------------------
    df_out_dummy = DataFrame(columnsTAS(),items = size(df_raw,1))
    # investigate metadata ------------------------------------------------------
    # put ki --------------------------------------------------------------------
    haskey(param, :DM) ? df_raw[!,:DM] .= param[:DM] : df_raw[!,:DM] .= missing
    if haskey(kwargs, :ki)
        df_raw[!,:ki] .= kwargs[:ki]
    elseif hasproperty(df_raw, :ki)
        nothing
    elseif hasproperty(df_raw, :A1)
        mask_A1 = .!ismissing.(df_raw[:,:A1])
        df_out_dummy[mask_A1,:ki] = @. π / ( sind(df_raw[mask_A1,:A1]) * df_raw[:,:DM] )
        df_raw[!,:ki] = df_out_dummy[:,:ki]
    elseif haskey(varia, :A1)
        df_raw[!,:ki] = @. π / ( sind(varia[:A1]) * df_raw[:,:DM] )
    else
        df_raw[!,:ki] .= missing
    end
    df_raw[!,:Ki]   = map( pt -> ismissing(df_raw[pt,:ki]) ? missing : SVector{3,Number}(0, df_raw[pt,:ki], 0), 1:length(df_raw[:,:ki]) ) 
    # put kf --------------------------------------------------------------------
    haskey(param, :DA) ? df_raw[!,:DA] .= param[:DA] : nothing
    if haskey(kwargs, :kf)
        df_raw[!,:kf] .= kwargs[:kf]
    elseif hasproperty(df_raw, :kf)
        nothing
    elseif hasproperty(df_raw, :A5) && hasproperty(df_raw, :DA)
        df_raw[!,:kf] = @. π / ( sind(df_raw[:,:A5]) * df_raw[:,:DA] )
    elseif haskey(param, :KFIX)
        df_raw[!,:kf] .= param[:KFIX]
    else
        df_raw[!,:kf] .= missing
    end
    # put Energy ----------------------------------------------------------------
    if hasproperty(df_raw, :EN)
        nothing
    else
        df_raw[!,:EN]    = @. ħ^2 * ( (df_raw[:,:ki]*1e10 )^2 - (df_raw[:,:kf]*1e10 )^2 )  / 2 / mass[:neutron] / 1e-3 / abs(charge[:electron])
    end
    # # populate df_out with overrides ------------------------------------------
    # if haskey(kwargs,:override)
    #   for (key,val) in kwargs[:override]
    #     df_out[!,key] = typeof(val) <: AbstractString ? Base.eval(val) : val
    #   end
    # end
    # set proper types for columns ----------------------------------------------
    for key in names(df_raw)
            isa(eltype(df_raw[:,key]), Union) ? nothing : df_raw[!,key] .= Array{Union{Missing,eltype(df_raw[:,key])}}(df_raw[:,key])
    end
    # create the final DataFrame ------------------------------------------------
    df_out = DataFrame(columnsTAS,items = size(df_raw,1))
    # detect spin-flip in IN20 polarization measurements ------------------------
    if hasproperty(df_raw, :F2)
        df_out[!,:polSF]  = df_raw[:,:F2] .== 1
    else
        df_out[!,:polSF] .= missing
    end
    hasproperty(df_raw, :HX) ? df_out[df_raw[:,:HX] .>  9, :polCH] .= :x : nothing
    hasproperty(df_raw, :HX) ? df_out[df_raw[:,:HX] .< -9, :polCH] .= :x : nothing
    hasproperty(df_raw, :HY) ? df_out[df_raw[:,:HY] .>  9, :polCH] .= :y : nothing
    hasproperty(df_raw, :HY) ? df_out[df_raw[:,:HY] .< -9, :polCH] .= :y : nothing
    hasproperty(df_raw, :HZ) ? df_out[df_raw[:,:HZ] .>  5, :polCH] .= :z : nothing
    hasproperty(df_raw, :HZ) ? df_out[df_raw[:,:HZ] .< -5, :polCH] .= :z : nothing
    # populate df_out with header stuff -----------------------------------------
    for key in collect(names(df_out))
        key = Symbol(key)
        haskey(varia,key)   ? df_out[:,key] .= convert(describe(df_out, cols=[key]).eltype[1], varia[key] )   : nothing
        haskey(param,key)   ? df_out[:,key] .= convert(describe(df_out, cols=[key]).eltype[1], param[key] )   : nothing
        haskey(df_meta,key) ? df_out[:,key] .= convert(describe(df_out, cols=[key]).eltype[1], df_meta[key] ) : nothing
    end
    # populate df_out with data read from the file ------------------------------
    for key in names(df_out)
        if hasproperty(df_raw, key) 
            df_out[!,key] .= convert(typeof(df_out[:,key]), df_raw[:,key])
        end
    end
    # # why is this needed??
    # if sum(ismissing(df_out[:,:EN])) > 0
    #   mask_EN = ismissing.(df_out[:,:EN])
    #   df_out[mask_EN,:EN]  = df_raw[mask_EN, :EN]
    # end
    # flatcone specific ---------------------------------------------------------
    if multidetectorCNTS_start != nothing
        δ              = df_out[:,:A4] .- 52.5
        γ              = df_out[:,:GFC]
        ν              = @. (df_out[:,:detID] -1) * 2.5 + 15
        Q_FC           = @. SVector{3,Number}(0.0, df_out[:,:ki], 0.0) - RotZXZ(δ/180*pi, γ/180*pi, ν/180*pi) * SVector{3,Number}(0.0, df_out[:,:kf], 0.0)
        Qsq            = map( Q -> Q[1]^2 + Q[2]^2 + Q[3]^2, Q_FC )
        df_out[!,:q]   = @. sqrt(Qsq)
        Q_perp         = @. df_out[:,:ki] * cosd(δ) * sind(γ)
        Q_para         = @. (Qsq - Q_perp^2)^0.5
        df_out[!,:Q_θ] = @. SVector{3,Number}(Q_para, 0.0, Q_perp)
        df_out[!,:ψ]   = @. asind( Q_perp / df_out[:,:kf] )
        df_out[!,:χ]   = @. atand( df_out[:,:kf] * sind(df_out[:,:ψ]) / Q_para )
        df_out[!,:ϕ]   = @. (df_out[:,:ki]^2 + df_out[:,:kf]^2 * (cosd(df_out[:,:ψ]))^2 - Q_para^2) / (2 * df_out[:,:ki] * df_out[:,:kf] * cosd(df_out[:,:ψ]))
        df_out[!,:ϕ]   = @. try acosd(df_out[:,:ϕ]); catch missing; end
        df_out[!,:A4]  = df_out[!,:ϕ] # this overwrites the prev. (incorrect if :GFC!=0 ) values!
        df_out[!,:θ]   = @. atand( (df_out[:,:ki] - df_out[:,:kf] * cosd(df_out[:,:ψ]) * cosd(df_out[:,:ϕ])) / (df_out[:,:kf] * cosd(df_out[:,:ψ]) * sind(df_out[:,:ϕ])) )
        df_out[!,:Kf]  = @. SVector{3,Number}(- df_out[:,:kf] * cosd(df_out[:,:ψ]) * sind(df_out[:,:ϕ]),
                                                                                    + df_out[:,:kf] * cosd(df_out[:,:ψ]) * cosd(df_out[:,:ϕ]),
                                                                                    - df_out[:,:kf] * sind(df_out[:,:ψ]) )
        df_out[!,:Q_L] = df_out[:,:Ki] - df_out[:,:Kf]
        df_out[!,:ω]   = df_out[:,:A3] - df_out[:,:θ]
        df_out[!,:R]   = @. RotZYX(df_out[:,:ω]/180*pi, df_out[:,:GL]/180*pi, df_out[:,:GU]/180*pi)
        df_out[!,:Q_ν] = @. inv(df_out[:,:R]) * df_out[:,:Q_θ]
        # sometimes inverting UB is not possible, resulting in an error
        df_out[!,:Q]   = map(pt -> inv(df_meta[:U] .* df_meta[:B]) * df_out[pt,:Q_ν], 1:length(Q_perp))

        df_out[!,:QH]  = map( pt -> df_out[pt,:Q][1] ,1:length(Q_perp) )
        df_out[!,:QK]  = map( pt -> df_out[pt,:Q][2] ,1:length(Q_perp) )
        df_out[!,:QL]  = map( pt -> df_out[pt,:Q][3] ,1:length(Q_perp) )
        # calculate q, qh, qk, ql ---------------------------------------------------
        df_out[!,:qh] = map(pt -> df_out[pt,:Q_ν][1], 1:length(Q_perp));
        df_out[!,:qk] = map(pt -> df_out[pt,:Q_ν][2], 1:length(Q_perp));
        df_out[!,:ql] = map(pt -> df_out[pt,:Q_ν][3], 1:length(Q_perp));
        # apply detector correction -------------------------------------------------
        # if keyword 'detector_efficiency' is supplied and it has the same length as
        # detectors available, the efficency is applied to the monitor.
        if haskey(kwargs, :detector_efficiency) && length(unique(df_out[:,:detID])) == length(kwargs[:detector_efficiency])
            df_out |> @mutate(MON = _.MON * kwargs[:detector_efficiency][_.detID]) |> DataFrame
        else
            @warn "no detector efficiency given"
        end
    else
        # stuff to do for single detector measurements
        df_out[!,:qh] = @. df_out[:,:QH] * df_meta[:par_lat_rec][1]
        df_out[!,:qk] = @. df_out[:,:QK] * df_meta[:par_lat_rec][2]
        df_out[!,:ql] = @. df_out[:,:QL] * df_meta[:par_lat_rec][3]
        df_out[!,:q]  = @. (df_out[:,:qh]^2 + df_out[:,:qk]^2 + df_out[:,:ql]^2)^0.5
    end
    # # evaluate fields -----------------------------------------------------------
    # df_out[!,:ScanVariable] = DataFramesNeutronTools.find_ScanVariable(df_out, col=[:QH, :QK, :QL, :EN, :TEMP])
    # df_out[!,:ScanMotor] = DataFramesNeutronTools.find_ScanVariable(df_out, col=[:A1, :A2, :A3, :A3P, :A4, :A5, :A6]) 
    df_out[!,:CNTS] = @. Measurements.measurement(df_out[:,:CNTS] ± df_out[:,:CNTS]^0.5)
    return round(df_out, precision_dict)
end
