# This file is part of the ValidatedNumerics.jl package; MIT licensed

__precompile__(true)

module ValidatedNumerics

using CRlibm
using Compat
using FixedSizeArrays
using ForwardDiff

import Base:
    +, -, *, /, //, fma,
    <, >, ==, !=, ⊆, ^, <=,
    in, zero, one, abs, real, min, max,
    sqrt, exp, log, sin, cos, tan, inv,
    exp2, exp10, log2, log10,
    asin, acos, atan, atan2,
    sinh, cosh, tanh, asinh, acosh, atanh,
    union, intersect, isempty,
    convert, promote_rule, eltype,
    BigFloat, float, widen, big,
    ∩, ∪, ⊆, eps,
    floor, ceil, trunc, sign, round,
    expm1, log1p,
    precision,
    isfinite, isnan,
    show, showall,
    isinteger, setdiff,
    parse

export
    Interval, AbstractInterval,
    @interval, @biginterval, @floatinterval, @make_interval,
    diam, radius, mid, mag, mig, hull,
    emptyinterval, ∅, ∞, isempty, interior, isdisjoint, ⪽,
    precedes, strictprecedes, ≺,
    entireinterval, isentire, nai, isnai, isthin, iscommon,
    widen, infimum, supremum,
    parameters, eps, dist, roughly,
    pi_interval,
    midpoint_radius, interval_from_midpoint_radius,
    RoundTiesToEven, RoundTiesToAway,
    cancelminus, cancelplus, isunbounded,
    .., @I_str, ±

export
    displaymode

export RootFinding


if VERSION >= v"0.5.0-dev+1182"
    import Base: rounding, setrounding, setprecision
else
    import Compat:
        rounding, setrounding, setprecision

    export rounding, setrounding, setprecision  # reexport
end


## Multidimensional
export
    IntervalBox, @intervalbox

## Decorations
export
    @decorated,
    interval_part, decoration, DecoratedInterval,
    com, dac, def, trv, ill


function get_rounding_mode()
    if !haskey(ENV, "VN_ROUNDING")
        return :correct
    else
        mode_string = ENV["VN_ROUNDING"]

        if mode_string == "CORRECT"
            return :correct

        elseif mode_string == "FAST"
            return :fast

        elseif mode_string == "NONE"
            return :none

        else
            warn("Rounding mode $mode_string node defined. Falling back to `:correct`")
        end
    end
end


function __init__()
    setrounding(BigFloat, RoundNearest)
    setrounding(Float64, RoundNearest)

    setprecision(Interval, 256)  # set up pi
    setprecision(Interval, Float64)

    # CRlibm.setup()

end


## Includes

include("intervals/intervals.jl")
include("multidim/multidim.jl")
include("decorations/decorations.jl")

include("display.jl")

include("root_finding/root_finding.jl")

#if VERSION >= v"0.5"
include("plot_recipes/plot_recipes.jl")
#end


end # module ValidatedNumerics
