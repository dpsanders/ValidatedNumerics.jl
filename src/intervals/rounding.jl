## Optimally tight rounding by changing rounding mode:

import Base.round

round(ex, rounding_mode) = ex  # generic fallback

function round(ex::Expr, rounding_mode)

    if ex.head == :call

        op = ex.args[1]

        if op ∈ (:min, :max)
            mapped_args = round.(ex.args[2:end], [rounding_mode]) # only in 0.5 and 0.6; in 0.6, can remove [...] around rounding_mode
            return :($op($(mapped_args...)))
        end


        if length(ex.args) == 3  # binary operator
            return :( $op( $(esc(ex.args[2])), $(esc(ex.args[3])), $rounding_mode) )

        else  # unary operator
            return :( $op($(esc(ex.args[2])), $rounding_mode ) )
        end
    else
        return ex
    end
end

macro ↑(ex)
    round(ex, RoundUp)
end

macro ↓(ex)
    round(ex, RoundDown)
end

↑(ex) = round(ex, RoundUp)
↓(ex) = round(ex, RoundDown)


macro round(ex1, ex2)
     :(Interval($(round(ex1, RoundDown)), $(round(ex2, RoundUp))))
    # :(Interval($(↓(ex1)), $(↑(ex2))))
    #:(Interval(↓($ex1), ↑($ex2)))

end



import Base: +, -, *, /, sin, sqrt, inv, ^, zero, convert, parse

# unary minus:
-{T<:AbstractFloat}(a::T, ::RoundingMode) = -a  # ignore rounding

# zero:
zero{T<:AbstractFloat}(a::Interval{T}, ::RoundingMode) = zero(T)
zero{T<:AbstractFloat}(::Type{T}, ::RoundingMode) = zero(T)

convert(::Type{BigFloat}, x, rounding_mode) = setrounding(BigFloat, rounding_mode) do
    convert(BigFloat, x)
end

parse{T}(::Type{T}, x, rounding_mode::RoundingMode) = setrounding(T, rounding_mode) do
    parse(T, x)
end


# no-ops for rational rounding:
for f in (:+, :-, :*, :/)
    @eval $f{T<:Rational}(a::T, b::T, ::RoundingMode) = $f(a, b)
end

sqrt{T<:Rational}(a::T, rounding_mode::RoundingMode) = setrounding(float(T), rounding_mode) do
    sqrt(float(a))
end



for mode in (:Down, :Up)

    mode1 = Expr(:quote, mode)
    mode1 = :(::RoundingMode{$mode1})

    mode2 = Symbol("Round", mode)


    for f in (:+, :-, :*, :/)

        @eval begin
            function $f{T<:AbstractFloat}(a::T, b::T, $mode1)
                setrounding(T, $mode2) do
                    $f(a, b)
                end
            end
        end
    end

    @eval begin
        function ^{T<:AbstractFloat,S}(a::T, b::S, $mode1)
            setrounding(T, $mode2) do
                ^(a, b)
            end
        end
    end


    for f in (:sqrt, :inv)
        @eval begin
            function $f{T<:AbstractFloat}(a::T, $mode1)
                setrounding(T, $mode2) do
                    $f(a)
                end
            end
        end
    end

end


## Fast, but *not* maximally tight rounding: just use prevfloat and nextfloat:

#=
function +{T}(a::T, b::T, ::RoundingMode{:Down})
    prevfloat(a + b)
end

function +{T}(a::T, b::T, ::RoundingMode{:Up})
    nextfloat(a + b)
end
=#


# function sin(a, ::RoundingMode{:Down})
#     prevfloat(sin(a))
# end

## Alternative: Fix rounding, e.g. down
