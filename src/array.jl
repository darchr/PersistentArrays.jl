# Array Wrapper around a persistent memory region.
"""
    PersistentArray{T,N} <: AbstractArray{T,N}

`N`-dimensional dense array with element of type `T` - backed by persistent memory NVDIMMs
instead of DRAM.

```julia
PersistentArray(A::AbstractArray{T,N}) -> PersistentArray{T,N}
```

Construct a `PersistentArray` copy of `A`.

```julia
PersistentArray{T}(undef, dims)
PersistentArray{T,N}(undef, dims)
```

Construct an unitialized `N`-dimensional `PersistentArray` containing elements of type `T`.
"""
mutable struct PersistentArray{T,N} <: DenseArray{T,N}
    ptr::Ptr{T}
    size::NTuple{N, Int}
    file::String

    function PersistentArray{T,N}(::UndefInitializer, d::NTuple{N,Int}) where {T,N}
        # Make sure `T` is an `isbitstype` so that the backing data is actually stored in
        # the persistent memory region.
        if !isbitstype(T)
            err = ArgumentError("""
                Expected elements of PersistentArrays to be `isbitstype`.
                Got an eltype of: $(T)
                """
            )
            throw(err)
        end

        # Determine the number of bytes needed for this array
        bytes = prod(d) * sizeof(T)
        (ptr_nothing, file) = alloc(bytes)
        ptr = Base.unsafe_convert(Ptr{T}, ptr_nothing)

        array = new{T,N}(ptr, d, file)
        finalizer(destroy, array)
        return array
    end
end

PersistentArray{T}(::UndefInitializer, d::NTuple{N,Int}) where {T,N} =
    PersistentArray{T,N}(undef, d)

PersistentArray{T}(::UndefInitializer, a::Integer, b...) where {T} =
    PersistentArray{T}(undef, convert.(Int, (a, b...)))

PersistentArray{T}(::UndefInitializer, d::Integer) where {T} =
    PersistentArray{T,1}(undef, (Int(d),))

function PersistentArray(A::AbstractArray{T,N}) where {T,N}
    P = PersistentArray{T,N}(undef, size(A))
    P .= A
    return P
end

# Baseic accessor.
Base.pointer(P::PersistentArray) = P.ptr

# Clean up the backing file as well.
destroy(P::PersistentArray) = free(Base.unsafe_convert(Ptr{Nothing}, P.ptr), true)

# Implement array interface.
Base.size(P::PersistentArray) = P.size
Base.sizeof(P::PersistentArray{T}) where {T} = length(P) * sizeof(T)
Base.@propagate_inbounds function Base.getindex(P::PersistentArray, i::Integer)
    @boundscheck checkbounds(P, i)
    return unsafe_load(pointer(P), i)
end
Base.@propagate_inbounds function Base.setindex!(P::PersistentArray, v, i::Integer)
    @boundscheck checkbounds(P, i)
    return unsafe_store!(pointer(P), v, i)
end

Base.IndexStyle(::Type{<:PersistentArray}) = IndexLinear()

# Allow conversion to pointer to dispatch to GEMM.
Base.unsafe_convert(::Type{Ptr{T}}, P::PersistentArray{T}) where {T} = pointer(P)
