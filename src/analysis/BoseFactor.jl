export BoseFactor

BoseFactor(EN,T) = 1./(1-exp.(-EN./8.6173324e-2./T)) # divide by this
function BoseFactor(df_in::AbstractDataFrame)
  df = deepcopy(df_in)
  df[:CNTS] ./= BoseFactor(df[:EN],df[:TEMP])
  return df
end
