export columnsTAS

"""
	columnsTAS()

returns an OrderedDict that lists columns and corresponding etypes for
DataFrames holding TAS Neutron Data.
"""
function columnsTAS()
	dict = OrderedDict{Symbol,Type}(
		# identifier
	    :scnID   => Union{Missings.Missing, Number , Array{Number,1}} ,
	    :detID   => Union{Missings.Missing, Number} ,
	    :scnIDX  => Union{Missings.Missing, Number} ,
	    :date    => Union{Missings.Missing, DateTime} ,
	    :cmd     => Union{Missings.Missing, AbstractString} ,
	    # movement in (Q,EN)-space / motors during scan
	    :scnType => Union{Missings.Missing, AbstractString} ,
	    :ScanVariable  => Union{Missings.Missing, Tuple} ,
	    :ScanMotor  => Union{Missings.Missing, Tuple} ,
	    # (Q,EN) space
	    :EN => Union{Missings.Missing, Number} ,
	    :QH => Union{Missings.Missing, Number} ,
	    :QK => Union{Missings.Missing, Number} ,
	    :QL => Union{Missings.Missing, Number} ,
	    # counters
	    :CNTS    => Union{Missings.Missing, Number} ,
	    :MON     => Union{Missings.Missing, Number} ,
	    :MONana  => Union{Missings.Missing, Number} ,
	    :time    => Union{Missings.Missing, Number} ,
	    # environment
	    :TEMP  => Union{Missings.Missing, Number} ,
	    :EI    => Union{Missings.Missing, Number} ,
	    :EV    => Union{Missings.Missing, Number} ,
	    :polSF => Union{Missings.Missing, Bool   } ,
	    :polCH => Union{Missings.Missing, Symbol} ,
	    :MF    => Union{Missings.Missing, Number} ,
	    :P     => Union{Missings.Missing, Number} ,
	    # scattering quantities
	    :ki   => Union{Missings.Missing, Number} ,
	    :Ki   => Union{Missings.Missing, SVector{3,Number}} ,
	    :mono => Union{Missings.Missing, Symbol} ,
	    :kf   => Union{Missings.Missing, Number} ,
	    :Kf   => Union{Missings.Missing, SVector{3,Number}} ,
	    :ana  => Union{Missings.Missing, Symbol} ,
	    :q    => Union{Missings.Missing, Number} ,
	    :qh   => Union{Missings.Missing, Number} ,
	    :qk   => Union{Missings.Missing, Number} ,
	    :ql   => Union{Missings.Missing, Number} ,
	    # normalized TAS angles
	    :θ  => Union{Missings.Missing, Number} ,
	    :ψ  => Union{Missings.Missing, Number} ,
	    :ϕ  => Union{Missings.Missing, Number} , 
	    :χ  => Union{Missings.Missing, Number} ,
	    :ω  => Union{Missings.Missing, Number} ,
	    :R  => Union{Missings.Missing, Rotations.RotZYX{Number}} ,
	    # Q vector in all coordinate systems
	    :Q   => Union{Missings.Missing, SVector{3,Number}} ,
	    :Q_L => Union{Missings.Missing, SVector{3,Number}} ,
	    :Q_θ => Union{Missings.Missing, SVector{3,Number}} ,
	    :Q_ν => Union{Missings.Missing, SVector{3,Number}} ,
	    # ILL motors
	    :A1  => Union{Missings.Missing, Number} ,
	    :A2  => Union{Missings.Missing, Number} ,
	    :A3  => Union{Missings.Missing, Number} ,
	    :A3B => Union{Missings.Missing, Number} ,
	    :A3P => Union{Missings.Missing, Number} ,
	    :A4  => Union{Missings.Missing, Number} ,
	    :A5  => Union{Missings.Missing, Number} ,
	    :A6  => Union{Missings.Missing, Number} ,
	    :GL  => Union{Missings.Missing, Number} ,
	    :GU  => Union{Missings.Missing, Number} ,
	    :GFC => Union{Missings.Missing, Number} ,
	    :PSI => Union{Missings.Missing, Number} ,
	    :DA  => Union{Missings.Missing, Number} ,
	    :DM  => Union{Missings.Missing, Number}
	)
	return dict
end