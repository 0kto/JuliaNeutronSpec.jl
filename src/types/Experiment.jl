export Experiment

struct Experiment
	sample::AbstractString
	description::AbstractString
	facility::Symbol
	experimentID::AbstractString
	instrument::Symbol
	dataPath::AbstractString
end
