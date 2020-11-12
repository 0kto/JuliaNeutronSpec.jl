elements = Dict{Symbol,AbstractDict}(
  :Ru => Dict{Symbol,AbstractDict}(
    :j0 => Dict{Symbol,Number}(
      :A =>  0.1069, :a => 49.424,
      :B =>  1.1912, :b => 12.742,
      :C => -0.3176, :c =>  4.912,
      :D =>  0.0213, :e =>  0.3597,
    ),
    :j2 => Dict{Symbol,Number}(
      :A =>  3.7445, :a => 18.613,
      :B =>  3.4749, :b => 7.420,
      :C => -0.0363, :c => 1.007,
      :D =>  0.0073, :e => 0.0533,
    )
  ),
  :Ru¹⁺ => Dict{Symbol,AbstractDict}(
    :j0 => Dict{Symbol,Number}(
      :A =>  0.4410, :a => 33.309,
      :B =>  1.4775, :b =>  9.553,
      :C => -0.9361, :c =>  6.722,
      :D =>  0.0176, :e =>  0.2608
    ),
    :j2 => Dict{Symbol,Number}(
      :A =>  5.2826, :a => 23.683,
      :B =>  3.5813, :b =>  8.152,
      :C => -0.0257, :c =>  0.426,
      :D =>  0.0131, :e =>  0.083
    )
  ),
)

function j0(element,q)
  s = q / ( 4 * pi)
  elements[element][:j0][:A] * exp.(-elements[element][:j0][:a] * s^2) + elements[element][:j0][:B] * exp(-elements[element][:j0][:b] * s^2) + elements[element][:j0][:C] * exp(-elements[element][:j0][:c] * s^2) + elements[element][:j0][:D]
end
function j2(element,q)
  s = q / ( 4 * pi)
  elements[element][:j2][:A] * exp.(-elements[element][:j2][:a] * s^2) + elements[element][:j2][:B] * exp(-elements[element][:j2][:b] * s^2) + elements[element][:j2][:C] * exp(-elements[element][:j2][:c] * s^2) + elements[element][:j2][:D]
end

function MagneticFormFactor(q::Number,element::Symbol;S=1,L=1)
  return j0.(element,q)  + j2.(element,q) * (L / (L + 2*S))
end

function MagneticFormFactor(q::Missing,element::Symbol;S=1,L=1)
  return missing
end
