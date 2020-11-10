using JuliaNeutronSpec
using Test

@testset "Load Data" begin
	dataPath = "test/fake_data"
	for facility,instrument,pattern in [(:ILL, :IN8, "010101")]
		myExperiment = Experiment("MySample","This is a sample experiment object", facility, "Test01", instrument, dataPath)
		data_ill_in8 = load_data(myExperiment, pattern)

		@test size(data_ill_in8) = (1,1)
	end
end
