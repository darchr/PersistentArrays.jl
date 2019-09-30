# Allocator for persistent memory regions.
#
# Each allocation initializes a new file for reading and writing.

# Global constant mapping pointers to the allocated size and backing file.
const PtrMap = Dict{Ptr{Nothing}, Tuple{Int, String}}()

# The directory where pmem backed files are created.
const FILE_DIR = Ref(get(ENV, "JULIA_PA_DIR", "/mnt/public"))

# Constants copied from libpmem.h
const PMEM_FILE_CREATE = (1 << 0)

"""
    alloc(bytes::Integer, [file]) -> (Ptr{Nothing}, String)

Allocate a persistent memory region of size `bytes`.
Returns a tuple of the pointer to the newly allocated region and the backing file name.

If `file` is not provided, a temporary filename will be used.
"""
function alloc(bytes::Integer, file = basename(tempname()))
    # Create the whole file path.
    filepath = joinpath(FILE_DIR[], file)

    # Call into libpmem
    ptr = ccall(
        (:pmem_map_file, libpmem),
        Ptr{Nothing},
        (Cstring, Csize_t, Cint, Base.Cmode_t, Csize_t, Cint),
        filepath,
        bytes,
        PMEM_FILE_CREATE,
        0o666,
        Ptr{Cvoid}(),
        Ptr{Cvoid}(),
    )

    # Save the pointer mapping and return.
    PtrMap[ptr] = (bytes, filepath)
    return (ptr, filepath)
end

"""
    free(ptr::Ptr{Nothing}, delete_file=false)

Free the persistent memory backing `ptr`.
If `delete_file = true`, also delete the backing file form the file system.
"""
function free(ptr::Ptr{Nothing}, delete_file = false)
    # Get the mapped size and file
    bytes, filepath = PtrMap[ptr]

    ccall(
        (:pmem_unmap, libpmem),
        Cvoid,
        (Ptr{Cvoid}, Csize_t),
        ptr,
        bytes,
    )

    # Clean up this pointer mapping.
    delete!(PtrMap, ptr)

    # If requested, clean up the backing file
    delete_file && rm(filepath)
    return nothing
end
