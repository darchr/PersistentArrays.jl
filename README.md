# PersistentArrays

Minimal package providing an AbstractArray type `PersistentArray{T,N}` where `T` is an 
`isbitstype` type.

## Setup

This package is expected to be run on a system with DAX NVDIMM persistent memory in a form that is compatible with `libpmem`: <https://pmem.io/pmdk/>.
Each `PersistentArray` will be backed by a file in the DAX persistent memory.
By default, these files will be given in random names in the directory `/mnt/public`.
The location of the DAX folder may be changed by setting the `JULIA_PA_DIR` environment variable prior to launching Julia.

## Usage

The simplest constructor is to construct a PersistentArray from a standard array:

```julia
julia> using PersistentArrays
julia> A = rand(Float32, 2, 2)
2×2 Array{Float32,2}:
 0.845112  0.568961
 0.232627  0.863465

julia> P = PersistentArray(A)
2×2 PersistentArray{Float32,2}:
 0.845112  0.568961
 0.232627  0.863465
```
