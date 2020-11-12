function λ(;ϕ::Number = nothing, d::Number = nothing, n::Integer=1)
	if ϕ == nothing || d == nothing
		@warn "usage: λ(ϕ = <detector angle>, d = <spacing>, n = <order>"
	end
	if isValid(ϕ) && isValid(d)
		λ = (ϕ) *d * 2 / n
	else
		λ = missing
	end
	return λ
end

function ϕ(;λ::Number = nothing, d::Number = nothing, n::Integer = 1)
	if λ == nothing || d == nothing
		@warn "usage: λ(ϕ = <detector angle>, d = <spacing>, n = <order>"
	end
	if isValid(λ) && isValid(d)
		ϕ = asind(λ*n/2/d)
	else
		ϕ = missing
	end
	return ϕ
end

function k(;ϕ::Number = nothing, d::Number = nothing, n::Integer = 1)
	if ϕ == nothing || d == nothing
		@warn "usage: k(ϕ = <detector angle>, d = <spacing>, n = <order>"
	end
	return 2π / λ(ϕ = ϕ, d = d, n = n)
end

function EN(;ki::Number = nothing, kf::Number = nothing)
	if ki == nothing || kf == nothing
		@warn "usage: EN(ki = ki, kf = kf"
	end
	if isValid(ki) && isValid(kf)
		EN = ( (ki*1e10 )^2 - (kf*1e10 ).^2 )  * ħ^2 / 2 / mass[:neutron] / 1e-3 / abs(charge[:electron])
	else
		EN = missing
	end
	return EN
end
