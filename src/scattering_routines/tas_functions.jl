export Ki
function Ki(ki::Union{Missing, Number})
	isValid(ki) ?  SVector{3,Number}(0,ki,0) : missing
end

export Kf
"""
	Kf(kf, ϕ; ψ = 0)

calculate Kf from kf (Å^-1), ϕ (°), and ψ.
ϕ is the horizontal detector angle.
ψ is the vertical detector angle.
TODO: implement out-of-plane scattering depending on ψ.
"""
function Kf(kf::Union{Missing, Number}, ϕ::Union{Missing, Number}; ψ::Union{Missing,Number} = 0) 
	if isValid(kf) && isValid(ϕ) && isValid(ψ)
		Kf = kf .* SVector(-sind(ϕ)*cosd(ψ),
							cosd(ϕ)*cosd(ψ),
							sind(ψ))
	else
		Kf = missing
	end
	return Kf
end
Kf(kf, ϕ, ψ) = Kf(kf, ϕ; ψ = ψ)
