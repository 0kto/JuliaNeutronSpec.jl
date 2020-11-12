export Ki
function Ki(ki::Union{Missing, Number})
	[typeof(ki)] ⊆ [Missing, Nothing] || isnan(ki) ?  missing : SVector{3,Number}(0,ki,0)
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
	kf_is_invalid = [typeof(kf)] ⊆ [Missing, Nothing] || isnan(kf)
	ϕ_is_invalid  = [typeof(ϕ)]  ⊆ [Missing, Nothing] || isnan(ϕ)
	ψ_is_invalid  = [typeof(ψ)]  ⊆ [Missing, Nothing] || isnan(ψ)
	if kf_is_invalid || ϕ_is_invalid || ψ_is_invalid
		Kf = missing
	else
		Kf = kf .* SVector(-sind(ϕ)*cosd(ψ),
							cosd(ϕ)*cosd(ψ),
							sind(ψ))
	end
	return Kf
end
Kf(kf, ϕ, ψ) = Kf(kf, ϕ; ψ = ψ)
