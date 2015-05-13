@which isinteger(3.1)
@which trunc(3.1)

@which iseven(3)
## Powers
# Integer power:
function ^{T}(a::Interval{T}, n::Integer)
    n < 0  && return inv( a^(-n) )
    n == 0 && return one(a)
    n == 1 && return a

    iseven(n) && return @round(T, mig(a)^n, mag(a)^n)  # even power

    @round(T, a.lo^n, a.hi^n)  # odd power
end

^{T}(a::Interval{T}, r::Rational) = (a^(r.num)) ^ (1/r.den)

# Real power of an interval:
function ^{T}(a::Interval{T}, x::Real)
    isinteger(x)  && return a^round(Int,x)
    x < 0  && return inv( a^(-x) )
    x == 0.5  && return sqrt(a)

    0 > a.hi && error("Undefined: interval is strictly negative and power is non-integer")

    x = make_interval(T, x) # convert(Interval{T}, x)  # @interval(x) ?
    a^x

end

# Interval power of an interval:
function ^{T}(a::Interval{T}, x::Interval)
    0 > a.hi && error("Undefined: interval is strictly negative and power is non-integer")

    domain = Interval{T}(0, Inf)
    a_restricted = intersect(a, domain)

    @round(T,
           begin
               lolo = a_restricted.lo^(x.lo)
               lohi = a_restricted.lo^(x.hi)
               min( lolo, lohi )
           end,
           begin
               hilo = a_restricted.hi^(x.lo)
               hihi = a_restricted.hi^(x.hi)
               max( hilo, hihi)
           end
           )
end

## sqrt

inf(x::Rational) = 1//0  # to allow sqrt()

function sqrt{T}(a::Interval{T})

    0 > a.hi && error("Undefined: interval is strictly negative and power is non-integer")

    domain = Interval{T}(0, Inf)
    a_restricted = intersect(a, domain)

    @round(T, sqrt(a_restricted.lo), sqrt(a_restricted.hi))

end

## exp
exp{T}(a::Interval{T}) = @round(T, exp(a.lo), exp(a.hi))

## log
function log{T}(a::Interval{T})

    domain = Interval{T}(0, Inf)
    0 > a.hi && error("Undefined log; Interval is strictly negative")

    a_restricted = intersect(a, domain)

    @round(T, log(a_restricted.lo), log(a_restricted.hi))
end
