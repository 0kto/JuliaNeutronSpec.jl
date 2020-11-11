using JuliaNeutronSpec
using Test

@testset "Load Data" begin
	dataPath = "test/test_data"
	for (facility,instrument,pattern) in [(:ILL, :IN20, "092575"),]
		myExperiment = Experiment("MySample","This is a sample polarized TAS experiment", facility, "Test01", instrument, dataPath)
		data_ill_in8 = load_data(myExperiment, pattern)

		# test if number of DataFrame columns is the same as the number
		# of columns defined in the OrderedDict from columnsTAS().
		@test size(data_ill_in8,1) = length(columnsTAS())
	end
end
