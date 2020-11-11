using JuliaNeutronSpec
using Test

# variables -----------------------------------------------------------
dataPath = "$(pwd())/test_data"

@testset "Experiment type             " begin
    myExperiment = Experiment("MySample","This is a sample experiment", :ILL, "Test01", :IN20, "~/")
    @test myExperiment.sample == "MySample"
    @test myExperiment.description == "This is a sample experiment"
    @test myExperiment.facility == :ILL
    @test myExperiment.experimentID == "Test01"
    @test myExperiment.instrument == :IN20
    @test myExperiment.dataPath == "~/"
end

@testset "Extending DataFrames package" begin
    @test size(DataFrame(columnsTAS; items = 3)) == (3, length(columnsTAS))
end

@testset "Read header of IN20 datafiles" begin
	param, varia, df_meta, motor0 = io_ill_header("$dataPath/092575")
	@test df_meta[:scnID] == 92575
end

@testset "Load Data for ILL / IN20    " begin
	myExperiment = Experiment("Ca2RuO4","This is a sample polarized TAS experiment", :ILL, "4-01-1431", :IN20, dataPath)
	data_ill_in20 = load_data(myExperiment, "092575")
	# the test file  has five data points
	@test size(data_ill_in20,1) == 5
	# test if number of DataFrame columns is the same as the number
	# of columns defined in the OrderedDict from columnsTAS().
	@test size(data_ill_in20,2) == length(columnsTAS)
	# check identifiers
	@test data_ill_in20[1,:scnID] .== 92575
	@test data_ill_in20[1,:detID] .== 1
	@test data_ill_in20[3,:scnIDX] == 3
	# check important columns for missing info
	for (col,coltype) in columnsTAS
		if [col] ⊆ [:EN, :QH, :QK, :QL, :CNTS, :MON, :MONana, :time, :TEMP, :ki, :kf, :q, :qh, :qk, :ql]
			@test begin
				if ismissing(data_ill_in20[1,col]) == false
					true
				else
					@show "offending column: $col"
				end
			end
		end
	end
end
