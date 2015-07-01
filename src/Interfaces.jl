module Interfaces

VERSION < v"0.4-" && using Docile

#MUTABLE_UNION_LIB_PATH = "deps/usr/lib/lib_mutable_union.so"
FILE_PATH = @__FILE__
PKG_PATH = dirname(FILE_PATH)
MUTABLE_UNION_LIB = Libdl.dlopen("$PKG_PATH/../deps/usr/lib/lib_mutable_union.so")

export @interface, implements, methods_exist, MUTABLE_UNION_LIB

include("core.jl")

end
