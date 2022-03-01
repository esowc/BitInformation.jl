"""In-place version of `signed_exponent(::Array)`."""
function signed_exponent!(A::AbstractArray{T}) where {T<:Base.IEEEFloat}

    # sign&fraction mask
    sfmask = Base.sign_mask(T) | Base.significand_mask(T)
    emask = Base.exponent_mask(T)         
    esignmask = Base.sign_mask(T) >> 1  # exponent sign mask (1st exp bit)

    sbits = Base.significand_bits(T)
    bias  = Base.exponent_bias(T)

    for i in eachindex(A)
        ui = reinterpret(Unsigned,A[i])
        sf = ui & sfmask                            # sign & fraction bits
        e = (((ui & emask) >> sbits) % Int) - bias  # de-biased exponent
        eabs = abs(e) % typeof(ui)                  # magnitude of exponent
        esign = e < 0 ? esignmask : zero(esignmask) # determine sign of exponent
        esigned = esign | (eabs << sbits)           # concatentate exponent

        A[i] = reinterpret(T,sf | esigned)  # concatenate everything back together
    end
end

"""In-place version of `biased_exponent(::Array)`. Inverse of `signed_exponent!"."""
function biased_exponent!(A::AbstractArray{T}) where {T<:Base.IEEEFloat}

    # sign&fraction mask
    sfmask = Base.sign_mask(T) | Base.significand_mask(T)
    esignmask = Base.sign_mask(T) >> 1
    eabsmask = Base.exponent_mask(T) & ~esignmask

    sbits = Base.significand_bits(T)
    bias  = Base.uinttype(T)(Base.exponent_bias(T))

    for i in eachindex(A)
        ui = reinterpret(Unsigned,A[i])
        sf = ui & sfmask                        # sign & fraction bits
        eabs = ((ui & eabsmask) >> sbits)       # isolate sign-magnitude exponent
        esign = (ui & esignmask) == esignmask ? true : false
        ebiased = bias + (esign ? -eabs : eabs) # concatenate mag&sign and add bias
        ebiased <<= sbits                       # shit exponent in position
        A[i] = reinterpret(T,sf | ebiased)      # concatenate everything back together
    end
end

"""
```julia
B = signed_exponent(A::AbstractArray{T}) where {T<:Base.IEEEFloat}
```
Converts the exponent bits of Float16,Float32 or Float64-arrays from its
conventional biased-form into a sign&magnitude representation.

# Example

```julia
julia> bitstring(10f0,:split)
"0 10000010 01000000000000000000000"

julia> bitstring.(signed_exponent([10f0]),:split)[1]
"0 00000011 01000000000000000000000"
```

In the former the exponent 3 is interpret from 0b10000010=130 via subtraction of
the exponent bias of Float32 = 127. In the latter the exponent is inferred from
sign bit (0) and a magnitude represetation 2^1 + 2^1 = 3."""
function signed_exponent(A::Array{T}) where {T<:Union{Float16,Float32,Float64}}
    B = copy(A)
    signed_exponent!(B)
    return B
end

"""
```julia
B = biased_exponent(A::AbstractArray{T}) where {T<:Base.IEEEFloat}
```
Convert the signed exponents from `signed_exponent` back into the 
standard biased exponents of IEEE floats."""
function biased_exponent(A::Array{T}) where {T<:Union{Float16,Float32,Float64}}
    B = copy(A)
    biased_exponent!(B)
    return B
end