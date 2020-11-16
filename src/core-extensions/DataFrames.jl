"""
    DataFrames.DataFrame(dict::Dict{Symbol,Type}; items = 0)
	              
initializes a DataFrame with the names and types specdified in a dictionary
"""

function DataFrames.DataFrame(dict::AbstractDict{Symbol,Type}; items::Integer=0 )
	if items == 0
	    df_out = DataFrames.DataFrame([ n => T[] for (n,T) in dict ])
	elseif items == 1
		df_out = DataFrames.DataFrame([ n => T[missing] for (n,T) in dict ])
	elseif items > 1
		df_out = DataFrames.DataFrame(dict)
		for ii in 1:items
			append!(df_out, DataFrames.DataFrame(dict; items = 1))
		end
	else
		@error "items should be a positive Integer"
	end
	return df_out
end
export DataFrame
