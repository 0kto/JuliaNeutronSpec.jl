"""
    PolarizationAnalysis(df, MMON = 1e4, precision_dict)

converts NeutronDataFrames to polarizedNeutronDataFrames.
sorts into SF / NSF, and x,y,z channels, and calculates
polarization of excitations (relative to Q)
"""
function PolarizationAnalysis(
    ndf_in::AbstractDataFrame;
    MMON = 1e4,
    precision_dict::Dict{Symbol,Int} = Dict{Symbol,Int}(
      :EN=>1, :QH=>3, :QK=>0, :QL=>1, :TEMP=>0, :EI=>1, :EV=>1, :MF=>1, :P=>1, :q => 2, :qh => 2, :qk => 2, :ql => 2
      )
  )
  # prepare input NeutronDataFrame ------------------------------------
  ndf = deepcopy(ndf_in)
  for col in [:CNTS, :MON]     # :MON MUST BE LAST!
    ndf[!,col] .*= MMON ./ ndf[:,:MON]
  end
  # return ndf
  # initialyze tmp and output PolarizedNeutronDataFrame ---------------
  pndf = DataFrame(dict_pndf)
  pndf_out = DataFrame(dict_pndf)
  # convert to pndf ====================================================
  for gndf in groupby(ndf, [:polSF, :polCH], sort = true, skipmissing = true)
    # create a row in pndf for each row in ndf
    gpndf = DataFrame(dict_pndf,items = size(gndf,1))
    # sort whatever in ndf into pndf ------------------------------------
    for column in names(gpndf)
      hasproperty(gndf,column) ? gpndf[:,column] = convert(typeof(gpndf[:,column]), gndf[:,column]) : nothing
    end
    # sort into channels ------------------------------------------------
    col = gndf[1,:polSF] ? "SF$(gndf[1,:polCH])" : "NSF$(gndf[1,:polCH])"
    gpndf[:,Symbol(col)]       = gndf[:,:CNTS]
    # append to pndf ----------------------------------------------------
    pndf = vcat(pndf, gpndf)
  end
  # combine on variables ================================================
  pndf = round(pndf,precision_dict)
  for gpndf in groupby(pndf, [:EN, :QH, :QK, :QL, :TEMP, :EI, :EV, :MF, :P])
    if size(gpndf,1) > 1
      tmp = gpndf[1,:]
      for col in [:SFx, :SFy, :SFz, :NSFx, :NSFy, :NSFz]
        mask = .!ismissing.(gpndf[:,col])
        sum(mask) < 1 ? continue : nothing
        tmp[col] = sum(gpndf[mask,col]) / sum(mask)
      end
      pndf_out = vcat(pndf_out,DataFrame(tmp))
    else
      pndf_out = vcat(pndf_out,DataFrame(gpndf))
    end
  end
  # convert channels to polarization (Q-frame) ============================
  pndf_out = pndf_out |> @mutate(
      m_perp = 2 * _.SFx - _.SFy - _.SFz,
      bg = _.SFy + _.SFz - _.SFx,
      myy = _.SFx - _.SFy,
      mzz = _.SFx - _.SFz,
    ) |> DataFrame
  return pndf_out
end
export PolarizationAnalysis
