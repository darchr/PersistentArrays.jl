module PersistentArrays

export PersistentArray

using Libdl

const SRCDIR = @__DIR__
const PKGDIR = dirname(SRCDIR)
const DEPSDIR = joinpath(PKGDIR, "deps")
const LIBDIR = joinpath(DEPSDIR, "usr", "lib")

# Path to `libpmem`
const libpmem = joinpath(LIBDIR, "libpmem.so")

function __init__()
    # dlopen libpmem so we can `ccall` into it.
    global libpmem 
    Libdl.dlopen(libpmem, Libdl.RTLD_GLOBAL)
end

include("lib.jl")
include("array.jl")

end # module
