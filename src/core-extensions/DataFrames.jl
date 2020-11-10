"""
    DataFrames.DataFrame(dict::Dict{Symbol,DataType};
          	             items::Int = 0)
	              
initializes a DataFrame with the names and types specdified in a dictionary
"""

function DataFrames.DataFrame(dict::AbstractDict{Symbol,Type}; items::Int=0 )
    return DataFrames.DataFrame(collect(values(dict)), collect(keys(dict)), items)
end
export DataFrame
