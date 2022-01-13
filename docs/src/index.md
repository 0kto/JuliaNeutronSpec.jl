# Documentation    
```@meta
CurrentModule = JuliaNeutronSpec
```
```@contents
Depth = 3
```

The package handles data parsing and analysis for inelastic neutron scattering experiments.
It aims to be a flexible and reliable package for all needs for data ingestion and fast plotting, and holds routines for data analysis.

## Environment
The package relies on many other Julia packages, and makes using them a bit easier by providing wrappers for specific functions.

Some of the most important Packages are:
- DataFrames.jl and CSV.jl

## Features

### I/O
```@docs
io_ill_header
io_ill
calc_detector_efficiency(df::AbstractDataFrame)
```

### DataHandling
```@docs
combine
normalize
normalize!
```

### Analysis
```@docs
OrientationFactor
PolarizationAnalysis
```

### Extended Packages
```@docs
fit
Spline1D
```

### Scattering Functions
```@docs
Kf
```

### Other
```@docs
columnsTAS
```