export loadData

function loadData(experiment::JuliaNeutronSpec.Experiment,
		pattern::AbstractString;
		kwargs...
	)
	if isfile("$(experiment.dataPath)/$pattern")
		filename = "$(experiment.dataPath)/$pattern"
		# dealing with a single file, load file directly
		if experiment.facility == :ILL
			if experiment.instrument == :IN8
				df_out = io_ill(filename; kwargs...)
			else
				@error "Instrument is not implemented"
			end
		else
			@error "No Instrument of Facility implemented"
		end
	else
		# create output object
		df_out = DataFrames(columnsTAS(); items = 0)
		# iterate over files and append
		for file in glob(pattern, experiment.dataPath)
			df_file = loadData(experiment, file; kwargs...),
	    	append!(df_out, df_file)
	    end
	end
	return df_out
end