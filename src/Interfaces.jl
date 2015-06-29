module Interfaces

VERSION < v"0.4-" && using Docile

export @interface, methods_exist

dlopen("../deps/usr/lib/lib_mutable_union.so")
include("core.jl")

end
