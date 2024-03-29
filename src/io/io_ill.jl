export io_ill
"""
    io_ill(filename::AbstractString,
           precision_dict::AbstractDict{Symbol,Int};
           kwargs...)

Read a single experimental measurement scan from file.
Handles the ILL format for inelastic neutron spectrometers (tested with IN20,
IN8) in single detector and multidetector (flatcone) configuration.
The output DataFrame has columns determined in [`columnsTAS`](@ref).  
Motor angles can be overwritten by supplying a dictionary to the kwarg
`override`.

# Arguments
- `filename::AbstractString`: relative file path
- `precision_dict::AbstractDict{Symbol,Int}`: rounding to precision for defined
  column (`precision_dict=Dict(:EN=>2)`).
- `kwargs...`:
    - `rename_cols::Dict()`: `Dict(:old_name => :new_name)`
    - `ki::Number`: only supply in ki=fixed measurements (time-of-flight)
    - `kf::Number`: manually supply kf
    - `override::Dict()`: `Dict(:A1 = 15.0)`
    - `detector_efficiency::Array{Union{Float,Measurments}}`
    - `par_lat::Array{Float,1}`: `[a b c α β γ]`

See also: [`columnsTAS`](@ref), [`calc_detector_efficiency`](@ref)
"""
function io_ill(filename::AbstractString; 
                precision_dict::AbstractDict{Symbol,Int} = Dict{Symbol,Int}(),
                kwargs...)
    kwargs = Dict{Symbol,Any}(kwargs)
    # get metadata and attach to initialized df ---------------------------------
    param, varia, df_meta, motor0  = io_ill_header(filename)
    # read file -----------------------------------------------------------------
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
    fc = readlines(filename)
    multidetectorCNTS_start = findfirst(occursin.("MULTI:", fc))
    if !(multidetectorCNTS_start === nothing)
        # add columns to df_raw
        df_raw[!,:detID] .= 0
        df_multi = CSV.read(
            filename, DataFrame;
            header = false,
            skipto = multidetectorCNTS_start+1,
            delim = ' ', 
            ignorerepeated = true,
            silencewarnings = true
        )
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
    # create the final DataFrame ------------------------------------------------
    good_cols = intersect(
        Set(propertynames(df_raw)),
        Set(keys(JuliaNeutronSpec.columnsTAS))
    )
    df_out = df_raw[:,[ii for ii in good_cols]]
    # investigate metadata ------------------------------------------------------
    for dict_meta in [param, varia, df_meta]
        # add columns that should be there (`columnsTAS`) but do not override.
        for col in setdiff(
            intersect(
                keys(dict_meta),
                keys(JuliaNeutronSpec.columnsTAS) ),
            propertynames(df_out) )

            df_out[!, col] .= dict_meta[col]
        end
    end

    # put ki --------------------------------------------------------------------
    haskey(param, :DM) ? df_out[!,:DM] .= param[:DM] : df_out[!,:DM] .= missing
    if haskey(kwargs, :ki)
        df_out[!,:ki] .= kwargs[:ki]
    elseif hasproperty(df_out, :ki)
        nothing
    elseif hasproperty(df_out, :A1)
        df_out = df_out |>
            @mutate( ki = π / ( sind(_.A1) * _.DM ) ) |>
            DataFrame
    elseif haskey(varia, :A1)
        df_out = df_out |>
            @mutate( ki = π / ( varia[:A1] * df_out[:,:DM] ) ) |>
            DataFrame
    else
        df_out[!,:ki] .= missing
    end
    df_out[!,:Ki]   = map( pt -> ismissing(df_out[pt,:ki]) ? missing : SVector{3,Number}(0, df_out[pt,:ki], 0), 1:length(df_out[:,:ki]) ) 
    # put kf --------------------------------------------------------------------
    haskey(param, :DA) ? df_out[!,:DA] .= param[:DA] : df_out[!,:DA] .= missing
    if haskey(kwargs, :kf)
        df_out[!,:kf] .= kwargs[:kf]
    elseif hasproperty(df_out, :kf)
        nothing
    elseif hasproperty(df_out, :A5) && hasproperty(df_out, :DA)
        df_out[!,:kf] = @. π / ( sind(df_out[:,:A5]) * df_out[:,:DA] )
    elseif haskey(param, :KFIX)
        df_out[!,:kf] .= param[:KFIX]
    else
        df_out[!,:kf] .= missing
    end
    # put Energy ----------------------------------------------------------------
    if hasproperty(df_out, :EN)
        nothing
    else
        df_out[!,:EN] = map(pt -> EN(;ki = df_out[pt,:ki], kf = df_out[pt,:kf]), 1:size(df_out,1) )
    end
    # # populate df_out with overrides ------------------------------------------
    if haskey(kwargs,:override)
      for (key,val) in kwargs[:override]
        df_out[!,key] = typeof(val) <: AbstractString ? Base.eval(val) : val
      end
    end
    # set proper types for columns ----------------------------------------------
    for key in propertynames(df_out)
        isa(eltype(df_out[:,key]), Union) ? nothing : df_out[!,key] .= Array{Union{Missing,eltype(df_out[:,key])}}(df_out[:,key])
    end
    # detect spin-flip in IN20 polarization measurements ------------------------
    if hasproperty(df_raw, :F2)
        df_out[!,:polSF]  = df_raw[:,:F2] .== 1
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
    for key in propertynames(df_out)
        haskey(varia,key)   ? df_out[:,key] .= convert(describe(df_out, cols=[key]).eltype[1], varia[key] )   : nothing
        haskey(param,key)   ? df_out[:,key] .= convert(describe(df_out, cols=[key]).eltype[1], param[key] )   : nothing
        haskey(df_meta,key) ? df_out[:,key] .= convert(describe(df_out, cols=[key]).eltype[1], df_meta[key] ) : nothing
    end
    # add missing columns
    missing_cols = setdiff(
        keys(JuliaNeutronSpec.columnsTAS), 
        propertynames(df_out)
    )
    for col = missing_cols
        df_out[!,col] .= missing
    end
    # flatcone specific ---------------------------------------------------------
    if !(multidetectorCNTS_start === nothing)
        UB_inv = inv(df_meta[:U] * df_meta[:B])
        df_out = df_out |>
            @mutate(δ      = _.A4 .- 52.5 ) |>
            @mutate(γ      = _.GFC ) |>
            @mutate(ν      = ( _.detID - 1 ) * 2.5 + 15 ) |>
            @mutate(Q_FC   = SVector{3,Number}(0.0, _.ki, 0.0) - RotZXZ( _.δ /180*pi, _.γ /180*pi, _.ν /180*pi) * SVector{3,Number}(0.0, _.kf, 0.0)) |>
            @mutate(Qsq    = _.Q_FC[1]^2 + _.Q_FC[2]^2 + _.Q_FC[3]^2 ) |>
            @mutate(q      = sqrt(_.Qsq) ) |>
            @mutate(Q_perp = _.ki * cosd(_.δ) * sind(_.γ) ) |>
            @mutate(Q_para = ( _.Qsq - _.Q_perp^2 )^0.5 ) |>
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
            @mutate(Q      = UB_inv * _.Q_ν ) |>
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
            gdf = groupby(df_out, :detID)
            for ii in 1:length(gdf)
                gdf[ii][!,:MON] ./= kwargs[:detector_efficiency][ii]
            end
            df_out = DataFrame(gdf)
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
