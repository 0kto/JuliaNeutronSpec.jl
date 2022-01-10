export calc_detector_efficiency
"""
    calc_detector_efficiency(df)

calculate the detector efficiency for each detector distinguised by `:detID`
using a single measurement.
The output can be handed over to `io_ill( ...; detector_efficiency=output`),
or the correction can be manually applied by dividing the Monitor count by
the output.

# Arguments
- `df::AbstractDataFrame`: cols `:CNTS` and `:detID` are mandatory.

See also [`io_ill`](@ref)
"""
function calc_detector_efficiency(df::AbstractDataFrame)
    df = df_eff |>
        @groupby(_.detID) |>
        @map({eff = mean(_.CNTS)}) |>
        DataFrame
    efficiency = df_efficiency.eff ./ mean(df_efficiency.eff)
    return efficiency
end
