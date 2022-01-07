export io_ill
function io_ill(filename::AbstractString; 
                precision_dict::AbstractDict{Symbol,Int} = Dict{Symbol,Int}(),
                kwargs...)
    kwargs = Dict{Symbol,Any}(kwargs)
    # get metadata and attach to initialized df ---------------------------------
    param, varia, df_meta, motor0  = io_ill_header(filename)
    # read file -----------------------------------------------------------------
    fc = readlines(filename)
    df_raw = CSV.read(
        filename, DataFrame;
        header=df_meta[:ln_param_end]+1,
        limit=df_meta[:lns_data],
        delim=' ',
        ignorerepeated=true,
        silencewarnings=true,
        normalizenames=true
    ) 
    df_raw[!,:scnID] .= df_meta[:scnID]
    df_raw[!,:scnIDX] = collect(1:size(df_raw,1))
    # test for multidetector like Flatcone --------------------------------------
    multidetectorCNTS_start = findfirst(occursin.("MULTI:", fc))
    if !(multidetectorCNTS_start === nothing)
        # add columns to df_raw
        df_raw[!,:detID] .= 0
        df_multi = CSV.read(filename, DataFrame;
                            header = false,
                            datarow = multidetectorCNTS_start+1,
                            delim = ' ', 
                            ignorerepeated = true,
                            silencewarnings = true)
        multidetectorChannelNumber = size(df_multi,2)
        df_multi[!,:PNT] = 1:size(df_multi,1)
        df_join = innerjoin(df_raw, df_multi, on = :PNT, makeunique = false, validate=(false,false))
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
    # df_out_dummy = DataFrame(columnsTAS,items = size(df_raw,1))
    # investigate metadata ------------------------------------------------------
    # put ki --------------------------------------------------------------------
    haskey(param, :DM) ? df_raw[!,:DM] .= param[:DM] : df_raw[!,:DM] .= missing
    if haskey(kwargs, :ki)
        df_raw[!,:ki] .= kwargs[:ki]
    elseif hasproperty(df_raw, :ki)
        nothing
    elseif hasproperty(df_raw, :A1)
        mask_A1 = .!ismissing.(df_raw[:,:A1])
        df_raw[mask_A1,:ki_dummy] = @. π / ( sind(df_raw[mask_A1,:A1]) * df_raw[:,:DM] )
        df_raw[!,:ki] = df_raw[:,:ki_dummy]
        df_raw = drop(df_raw, cols=:ki_dummy)
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
        df_raw[!,:EN] = map(pt -> EN(;ki = df_raw[pt,:ki], kf = df_raw[pt,:kf]), 1:size(df_raw,1) )
    end
    # # populate df_out with overrides ------------------------------------------
    # if haskey(kwargs,:override)
    #   for (key,val) in kwargs[:override]
    #     df_out[!,key] = typeof(val) <: AbstractString ? Base.eval(val) : val
    #   end
    # end
    # set proper types for columns ----------------------------------------------
    for key in propertynames(df_raw)
        isa(eltype(df_raw[:,key]), Union) ? nothing : df_raw[!,key] .= Array{Union{Missing,eltype(df_raw[:,key])}}(df_raw[:,key])
    end
    # create the final DataFrame ------------------------------------------------
    good_cols = intersect(
        Set(propertynames(df_raw)),
        Set(keys(JuliaNeutronSpec.columnsTAS))
    )
    df_out = df_raw[:,[ii for ii in good_cols]]
    # detect spin-flip in IN20 polarization measurements ------------------------
    if hasproperty(df_raw, :F2)
        df_out[!,:polSF]  = df_raw[:,:F2] .== 1
    else
        df_out[!,:polSF] .= missing
    end
    function get_pol(HX,HY,HZ)
        if      (HX > 9) | (HX < -9) ; return :x ;
        elseif  (HY > 9) | (HY < -9) ; return :y ;
        elseif  (HZ > 5) | (HZ < -5) ; return :z ;
        else; return missing ;
        end
    end
    if hasproperty(df_raw, :HX)
        df_out[!, :HX] = df_raw.HX
        df_out[!, :HY] = df_raw.HY
        df_out[!, :HZ] = df_raw.HZ
        df_out = df_out |>
            @mutate( polCH = get_pol(_.HX, _.HY, _.HZ) ) |>
            @select( -:HX, -:HY, -:HZ ) |>
            DataFrame
    end

    # populate df_out with header stuff -----------------------------------------
    for key in collect(propertynames(df_out))
        key = Symbol(key)
        haskey(varia,key)   ? df_out[:,key] .= convert(describe(df_out, cols=[key]).eltype[1], varia[key] )   : nothing
        haskey(param,key)   ? df_out[:,key] .= convert(describe(df_out, cols=[key]).eltype[1], param[key] )   : nothing
        haskey(df_meta,key) ? df_out[:,key] .= convert(describe(df_out, cols=[key]).eltype[1], df_meta[key] ) : nothing
    end
    # add missing columns
    missing_cols = setdiff(
        keys(JuliaNeutronSpec.columnsTAS), 
        Set(propertynames(df_out))
    )
    for col = missing_cols
        df_out[!,col] .= missing
    end
    # populate df_out with data read from the file ------------------------------
    # for key in names(df_out)
    #     if hasproperty(df_raw, key) 
    #         df_out[!,key] .= convert(typeof(df_out[:,key]), df_raw[:,key])
    #     end
    # end
    # # why is this needed??
    # if sum(ismissing(df_out[:,:EN])) > 0
    #   mask_EN = ismissing.(df_out[:,:EN])
    #   df_out[mask_EN,:EN]  = df_raw[mask_EN, :EN]
    # end
    # flatcone specific ---------------------------------------------------------
    if !(multidetectorCNTS_start === nothing)
        df_out = df_out |>
            @mutate(δ      = _.A4 .- 52.5 ) |>
            @mutate(γ      = _.GFC ) |>
            @mutate(ν      = ( _.detID - 1 ) * 2.5 + 15 ) |>
            @mutate(Q_FC   = SVector{3,Number}(0.0, _.ki, 0.0) - RotZXZ( _.δ /180*pi, _.γ /180*pi, _.ν /180*pi) * SVector{3,Number}(0.0, _.kf, 0.0)) |>
            @mutate(Qsq    = _.Q_FC[1]^2 + _.Q_FC[2]^2 + _.Q_FC[3]^2 ) |>
            @mutate(q      = sqrt(_.Qsq) ) |>
            @mutate(Q_perp = _.ki * cosd(_.δ) * sind(_.γ) ) |>
            @mutate(Q_para = ( _.Qsq - Q_perp^2 )^0.5 ) |>
            @mutate() |>
            @mutate(Q_θ    = SVector{3,Number}(_.Q_para, 0.0, _.Q_perp) ) |>
            @mutate(ψ      = asind( _.Q_perp / _.kf ) ) |>
            @mutate(χ      = atand( _.kf * sind(_.ψ) / _.Q_para ) ) |>
            @mutate(ϕ      = (_.ki^2 + _.kf^2 * (cosd(_.ψ))^2 - _.Q_para^2) / (2 * _.ki * _.kf * cosd(_.ψ)) ) |>
            @mutate(ϕ      = try acosd(_.ϕ); catch missing; end ) |>
            @mutate(A4     = _.ϕ  ) |># this overwrites the prev. (incorrect if :GFC!=0 ) values!
            @mutate(θ      = atand( (_.ki - _.kf * cosd(_.ψ) * cosd(_.ϕ)) / (_.kf * cosd(_.ψ) * sind(_.ϕ)) ) ) |>
            @mutate(Kf     = SVector{3,Number}(
                                - _.kf * cosd(_.ψ) * sind(_.ϕ),
                                + _.kf * cosd(_.ψ) * cosd(_.ϕ),
                                - _.kf * sind(_.ψ)
                            ) ) |>
            @mutate(Q_L    = _.Ki - _.Kf ) |>
            @mutate(ω      = _.A3 - _.θ ) |>
            @mutate(R      = RotZYX(_.ω/180*pi, _.GL/180*pi, _.GU/180*pi) ) |>
            @mutate(Q_ν    = inv(_.R) * _.Q_θ ) |>
            @mutate(Q      = inv(df_meta[:U] .* df_meta[:B]) * _.Q_ν ) |>
            # sometimes inverting UB is not possible, resulting in an error
            @mutate(QH     = _.Q[1]  ) |>
            @mutate(QK     = _.Q[2]  ) |>
            @mutate(QL     = _.Q[3]  ) |>
            # calculate q, qh, qk, ql ---------------------------------------------------
            @mutate(qh     = _.Q_ν[1] ) |>
            @mutate(qk     = _.Q_ν[2] ) |>
            @mutate(ql     = _.Q_ν[3] ) |>
            DataFrame

        # apply detector correction -------------------------------------------------
        # if keyword 'detector_efficiency' is supplied and it has the same length as
        # detectors available, the efficency is applied to the monitor.
        if haskey(kwargs, :detector_efficiency) && length(unique(df_out[:,:detID])) == length(kwargs[:detector_efficiency])
            df_out |> @mutate(MON = _.MON * kwargs[:detector_efficiency][_.detID]) |> DataFrame
        else
            @warn "no detector efficiency given"
        end
    else  # if multidetectorCNTS_start === nothing
        df_out = df_out |>
            @mutate(qh = _.QH * df_meta[:par_lat_rec][1]) |>
            @mutate(qk = _.QK * df_meta[:par_lat_rec][2]) |>
            @mutate(ql = _.QL * df_meta[:par_lat_rec][3]) |>
            @mutate(q  = (_.qh^2 + _.qk^2 + _.ql^2)^0.5) |>
            DataFrame
    end
    # # evaluate fields -----------------------------------------------------------
    # df_out[!,:ScanVariable] = DataFramesNeutronTools.find_ScanVariable(df_out, col=[:QH, :QK, :QL, :EN, :TEMP])
    # df_out[!,:ScanMotor] = DataFramesNeutronTools.find_ScanVariable(df_out, col=[:A1, :A2, :A3, :A3P, :A4, :A5, :A6]) 
    df_out[!,:CNTS] = @. Measurements.measurement(df_out[:,:CNTS] ± df_out[:,:CNTS]^0.5)


        
    return round(df_out, precision_dict)
end
