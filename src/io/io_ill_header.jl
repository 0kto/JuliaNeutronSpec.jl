export io_ill_header
"""
    io_ill_header(filename::AbstractString)

Reads the ILL header and returns the three dictionaries
  * `param` with all the instrument configs
  * `varia` with all the motors
  * `motor0` with all the zero values for the motors
  * `df_meta` with the line numbers important for reading the actual counts
"""
function io_ill_header(filename::AbstractString)
    # init variables
    param   = Dict{Symbol,Union{Missing,Number}}()
    varia   = Dict{Symbol,Union{Missing,Number}}()
    df_meta = Dict{Symbol,Any}()
    motor0  = Dict{Symbol,Union{Missing,Number}}()

    # read file
    fc = readlines(filename)

    # extract param, varia, zeros from file Header and store in above defined param and constants
    for line in 1:size(fc,1)
        if length(fc[line]) < 6; continue; end
        if fc[line][6] == ':'
            fragments = split(chomp(fc[line]),[':'])
            line_type = fragments[1]
            content = join(fragments[2:end],':')
            if line_type == "FILE_"
                df_meta[:scnID] = parse(Int64,content)
            elseif line_type == "TYPE_"
                if occursin("flatcone",content)
                    push!(df_meta,(:TYPE => :flatcone))
                else
                    push!(df_meta,(:TYPE => :tas))
                end
            elseif line_type == "DATE_"
                df_meta[:date] = Dates.DateTime(content,DateFormat(" dd-u-yy HH:MM:SS"))
            elseif line_type == "COMND"
                df_meta[:cmd] = content[2:end]
                df_meta[:cmd]
                if occursin("sc qh",df_meta[:cmd])
                    hkl_ar  = map(val -> parse(Float64,val), split(df_meta[:cmd],' ',keepempty=false)[3:5])
                    df_meta[:hkl] = Tuple(hkl_ar)
                end
            elseif line_type == "PARAM"
                pairs = split(content,[','])
                for pair in pairs
                    key,val = split(pair,['=',' '],keepempty=false)
                    val = val == "**********" ? missing : parse(Float64,val)
                    push!(param,(Symbol(key) => val ))
                end
            elseif line_type == "VARIA"
                pairs = split(content,[','])
                for pair in pairs
                    try
                        key,val = split(pair,['=',' '],keepempty=false)
                        val = val == "**********" ? missing : parse(Float64,val)
                        push!(varia,(Symbol(key) => val))
                    catch; nothing;
                    end
                end
            elseif line_type == "ZEROS"
                pairs = split(content,[','])
                for pair in pairs
                    try
                        key,val = split(pair,['=',' '],keepempty=false)
                        val = val == "**********" ? missing : parse(Float64,val)
                        push!(motor0,(Symbol(key) => val))
                    catch; nothing;
                    end
                end
            elseif line_type == "POSQE"
                content = split(content,['=',' ',','],keepempty=false)[[2,4,6,8]]
                df_meta[:hkle] = ntuple(i -> parse(Float64,content[i]),4)
            elseif line_type == "DATA_"
                df_meta[:ln_param_end] = line
            elseif line_type == "MULTI"
                df_meta[:lns_data]  = line - df_meta[:ln_param_end] -2
                df_meta[:lns_det_start] = line + 1
            end
        end # extract param, varia, zeros
    end
    if !haskey(df_meta,:lns_data)
         df_meta[:lns_data] = length(fc)  - df_meta[:ln_param_end] -1
    end

    # calculate U-matrix from par_lat and orientation vectors (h1 & h2)
    df_meta[:par_lat]     = SVector{6,Float64}(param[:AS],param[:BS],param[:CS],param[:AA],param[:BB],param[:CC])
    df_meta[:par_lat_rec] = SVector{6,Float64}( 2π / df_meta[:par_lat][1], 2π / df_meta[:par_lat][2], 2π / df_meta[:par_lat][3], 90, 90, 90)
    df_meta[:β1] = df_meta[:par_lat_rec][1] * SVector{3,Number}(1, 0, 0)
    df_meta[:β2] = df_meta[:par_lat_rec][2] * SVector{3,Number}(cosd(df_meta[:par_lat_rec][6]), sind(df_meta[:par_lat_rec][6]), 0)
    df_meta[:β3] = df_meta[:par_lat_rec][3] * SVector{3,Number}(cosd(df_meta[:par_lat_rec][5]),
            (cosd(df_meta[:par_lat_rec][4])-cosd(df_meta[:par_lat_rec][5])*cosd(df_meta[:par_lat_rec][6])) / sind(df_meta[:par_lat_rec][6]),
            df_meta[:par_lat_rec][1] * df_meta[:par_lat_rec][2] * df_meta[:par_lat_rec][3] / sind(df_meta[:par_lat_rec][6]) )
    df_meta[:h1] = SVector{3,Number}(param[:AX], param[:AY], param[:AZ])
    df_meta[:h2] = SVector{3,Number}(param[:BX], param[:BY], param[:BZ])
    df_meta[:t1] = df_meta[:h1][1]*df_meta[:β1] + df_meta[:h1][2]*df_meta[:β2] + df_meta[:h1][3]*df_meta[:β3]
    df_meta[:t1] /= sum(df_meta[:t1].^2).^0.5
    df_meta[:t2] = df_meta[:h2][1]*df_meta[:β1] + df_meta[:h2][2]*df_meta[:β2] + df_meta[:h2][3]*df_meta[:β3]
    df_meta[:t2] -= df_meta[:t1] * ( df_meta[:t1]' * df_meta[:t2] )
    df_meta[:t2] /= sum(df_meta[:t2].^2).^0.5
    df_meta[:t3] = LinearAlgebra.cross(df_meta[:t1], df_meta[:t2])

    df_meta[:U]  = SMatrix{3,3,Number,9}([df_meta[:t1]..., df_meta[:t2]..., df_meta[:t3]...])'

    # calculate B-matrix from par_lat and par_lat_rec
    df_meta[:B] = SMatrix{3,3,Number,9}([
            df_meta[:par_lat_rec][1],
            df_meta[:par_lat_rec][2]*cos(df_meta[:par_lat_rec][6]),
            df_meta[:par_lat_rec][3]*cos(df_meta[:par_lat_rec][5]),
            0.0,
            df_meta[:par_lat_rec][2]*sin(df_meta[:par_lat_rec][6]),
            -df_meta[:par_lat_rec][3]*sin(df_meta[:par_lat_rec][5])cos(df_meta[:par_lat][4]),
            0.0,
            0.0,
            1/df_meta[:par_lat][3]
        ])'

    return param, varia, df_meta, motor0
end