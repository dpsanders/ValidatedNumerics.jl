# This file is part of the ValidatedNumerics.jl package; MIT licensed

# Newton method

# What is this guarded_mid for? Shouldn't it be checking if f(m)==0?
doc"""Returns the midpoint of the interval x, slightly shifted in case
it is zero"""
function guarded_mid{T}(x::Interval{T})
    m = mid(x)
    if m == zero(T)                     # midpoint exactly 0
        α = convert(T, 0.46875)      # close to 0.5, but exactly representable as a floating point
        m = α*x.lo + (one(T)-α)*x.hi   # displace to another point in the interval
    end

    @assert m ∈ x

    m
end


function N{T}(f::Function, x::Interval{T}, deriv::Interval{T})
    m = guarded_mid(x)
    m = Interval(m)

    m - (f(m) / deriv)
end


doc"""If a root is known to be inside an interval,
`newton_refine` iterates the interval Newton method until that root is found."""
function newton_refine{T}(f::Function, f_prime::Function, x::Interval{T};
                          tolerance=eps(T), debug=false)

    debug && (print("Entering newton_refine:"); @show x)

    while diam(x) > tolerance  # avoid problem with tiny floating-point numbers if 0 is a root
        deriv = f_prime(x)
        Nx = N(f, x, deriv)

        debug && @show(x, Nx)

        Nx = Nx ∩ x
        Nx == x && break

        x = Nx
    end

    debug && @show "Refined root", x

    return [Root(x, :unique)]
end




doc"""`newton` performs the interval Newton method on the given function `f`
with its optional derivative `f_prime` and initial interval `x`.
Optional keyword arguments give the `tolerance`, `maxlevel` at which to stop
subdividing, and a `debug` boolean argument that prints out diagnostic information."""

function newton{T}(f::Function, f_prime::Function, x::Interval{T}, level::Int=0;
                   tolerance=eps(T), debug=false, maxlevel=30)

    debug && (print("Entering newton:"); @show(level); @show(x))

    isempty(x) && return Root{T}[]  #[(x, :none)]

    z = zero(x.lo)
    tolerance = abs(tolerance)

    # Tolerance reached or maximum level of bisection
    (diam(x) < tolerance || level >= maxlevel) && return [Root(x, :unknown)]

    deriv = f_prime(x)
    debug && @show(deriv)

    if !(z in deriv)
        Nx = N(f, x, deriv)
        debug && @show(Nx, Nx ⊆ x, Nx ∩ x)

        isempty(Nx ∩ x) && return Root{T}[]

        if Nx ⊆ x
            debug && (print("Refining "); @show(x))
            return newton_refine(f, f_prime, Nx, tolerance=tolerance, debug=debug)
        end

        m = guarded_mid(x)

        debug && @show(x,m)

        # bisect:
        roots = vcat(
            newton(f, f_prime, Interval(x.lo, m), level+1,
                   tolerance=tolerance, debug=debug, maxlevel=maxlevel),
            newton(f, f_prime, Interval(m, x.hi), level+1,
                   tolerance=tolerance, debug=debug, maxlevel=maxlevel)
            # note the nextfloat here to prevent repetition
            )

        debug && @show(roots)

    else  # 0 in deriv; this does extended interval division by hand

        y1 = Interval(deriv.lo, -z)
        y2 = Interval(z, deriv.hi)

        if debug
            @show (y1, y2)
            @show N(f, x, y1)
            @show N(f, x, y2)
        end

        y1 = N(f, x, y1) ∩ x
        y2 = N(f, x, y2) ∩ x

        debug && @show(y1, y2)

        roots = vcat(
            newton(f, f_prime, y1, level+1,
                   tolerance=tolerance, debug=debug, maxlevel=maxlevel),
            newton(f, f_prime, y2, level+1,
                   tolerance=tolerance, debug=debug, maxlevel=maxlevel)
            )

        debug && @show(roots)

    end

    # order, remove duplicates, and include intervals X only if f(X) contains 0
    sort!(roots, lt=lexless)
    roots = unique(roots)
    roots = filter(x -> 0 ∈ f(x.interval), roots)


    # merge neighbouring roots if they touch:

    if length(roots) < 2
        return roots
    end


    new_roots = eltype(roots)[]

    base_root = roots[1]

    for i in 2:length(roots)
        current_root = roots[i]

        if isempty(base_root.interval ∩ current_root.interval) ||
                (base_root.root_type != current_root.root_type)

            push!(new_roots, base_root)
            base_root = current_root
        else
            base_root = Root(hull(base_root.interval, current_root.interval), base_root.root_type)
        end
    end

    push!(new_roots, base_root)

    return new_roots
end


# use automatic differentiation if no derivative function given:
newton{T}(f::Function, x::Interval{T};  args...) =
    newton(f, x->D(f,x), x; args...)

# newton for vector of intervals:
newton{T}(f::Function, f_prime::Function, xx::Vector{Interval{T}}; args...) =
    vcat([newton(f, f_prime, @interval(x); args...) for x in xx]...)

newton{T}(f::Function,  xx::Vector{Interval{T}}, level; args...) =
    newton(f, x->D(f,x), xx, 0, args...)

newton{T}(f::Function,  xx::Vector{Root{T}}; args...) =
    newton(f, x->D(f,x), [x.interval for x in xx], args...)
