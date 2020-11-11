using JuliaNeutronSpec
using Test

# variables -----------------------------------------------------------
dataPath = "$(pwd())/test_data"

@testset "Experiment type" begin
    myExperiment = Experiment("MySample","This is a sample experiment", :ILL, "Test01", :IN20, "~/")
    @test myExperiment.sample == "MySample"
end
@testset "Load Data for ILL / IN20" begin
	myExperiment = Experiment("Ca2RuO4","This is a sample polarized TAS experiment", :ILL, "4-01-1431", :IN20, dataPath)

	data_ill_in20 = load_data(myExperiment, "092575")
	# the test file  has five data points
	@test size(data_ill_in20,1) == 5
	# test if number of DataFrame columns is the same as the number
	# of columns defined in the OrderedDict from columnsTAS().
	@test size(data_ill_in20,2) == length(columnsTAS)
end
