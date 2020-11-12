"""
    round(df, precision_dict::Dict{Symbol,Int})

round dataframe columns defined in a precision_dict.
"""
function Base.round(df_in::AbstractDataFrame,
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