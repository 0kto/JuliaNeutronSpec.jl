export isValid
function isValid(value)
	if [typeof(value)]  ⊆ [Missing, Nothing] || isnan(value)
		return false
	else
		return true
	end
end