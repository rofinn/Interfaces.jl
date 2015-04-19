include("../src/Interfaces.jl")
using Interfaces
using Base.Test

# Test methods_exist first
abstract Foo
abstract Bar

func1(self::Foo, x::Int) = println("func1(self::Foo, x::Int)")
func2(self::Foo, x::Float64, y::Float64) = println("func2(self::Foo, x::Float64, y::Float64")
# Throws error cause we haven't defined those methods for Bar yet
@test_throws(ErrorException, methods_exist(Foo, Bar, current_module()))

func1(self::Bar, x::Int) = println("func1(self::Bar, x::Int)")
# Throws error cause we haven't defined func2 for Bar yet
@test_throws(ErrorException, methods_exist(Foo, Bar, current_module()))

func2(self::Bar, x::Int, y::Int) = println("func2(self::Bar, x::Int, y::Int")
# Throws error cause types don't match for func2
@test_throws(ErrorException, methods_exist(Foo, Bar, current_module()))

func2(self::Bar, x::Float64, y::Float64) = println("func2(self::Bar, x::Float64, y::Float64")
methods_exist(Foo, Bar, current_module())

# Test the interface macro in a similar way
@interface Baz begin
    func1(self::Baz, x::Int)
    func2(self::Baz, x::Float64, y::Float64)
end

type Alpha
    x::Int
end

@test_throws(ErrorException, Baz(Alpha(4)))

func1(self::Alpha, x::Int) = return self.x + x
@test_throws(ErrorException, Baz(Alpha(4)))

func2(self::Alpha, x::Float64, y::Float64) = return self.x * (x + y)

baz = Baz(Alpha(4))

@test(func1(baz, 4) == 8)
@test(func2(baz, 1.0, 1.0) == 8.0)
