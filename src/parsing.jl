
function parse{T}(::Type{DecoratedInterval{T}}, s::AbstractString)
    m = match(r"(\[.*\])(\_.*)?", s)

    if m == nothing  # matched
        throw(ArgumentError("Unable to process string $x as decorated interval"))

    end

    interval_string, decoration_string = m.captures
    interval = parse(Interval{T}, interval_string)

    # type unstable:
    if decoration_string == nothing
        decoration_string = "_com"
    end

    decoration_symbol = Symbol(decoration_string[2:end])
    decoration = getfield(ValidatedNumerics, decoration_symbol)

    return DecoratedInterval(interval, decoration)

end

doc"""
    parse{T}(Interval{T}, s::AbstractString)

Parse a string as an interval. Formats allowed include:
- "1"
- "[1]"
- "[3.5, 7.2]"
"""
function parse{T}(::Type{Interval{T}}, s::AbstractString)
    if !(contains(s, "["))  # string like "3.1"

        expr = parse(s)

        # after removing support for Julia 0.4, can simplify
        # make_interval to just accept two expressions

        val = make_interval(T, expr, [expr])   # use tryparse?
        return eval(val)
    end

    # match string of form [a, b]_dec:
    m = match(r"\[(.*),(.*)\]", s)

    if m != nothing  # matched
        lo, hi = m.captures

    else

        m = match(r"\[(.*)\]", s)  # string like "[1]"

        if m == nothing
            throw(ArgumentError("Unable to process string $s as interval"))
        end

        lo = m.captures[1]
        hi = lo

    end

    expr1 = parse(lo)
    expr2 = parse(hi)

    interval = eval(make_interval(T, expr1, [expr2]))

    return interval

end
