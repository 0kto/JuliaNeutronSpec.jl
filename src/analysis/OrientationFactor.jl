export OrientationFactor
"""
    orientationfactor_sq(x,y,z)

calcualte orientation factor for a,b,c direction from
q_x q_y q_z in units of Å^-1
"""
function OrientationFactor(x,y,z)
    qq = x^2+y^2+z^2
    return [(y^2+z^2)/qq, (z^2+x^2)/qq, (x^2+y^2)/qq]
end

function OrientationFactor(df::AbstractDataFrame)
  map(i -> OrientationFactor(df[i,:qh],df[i,:qk],df[i,:ql]), 1:size(df,1))
end
