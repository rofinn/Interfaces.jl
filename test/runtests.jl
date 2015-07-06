include("../src/Interfaces.jl")
using Interfaces
using Base.Test


type Foo
    x::Int
end

type Bar
    x::ASCIIString
end

@interface MyInterface begin
    func(self::MyInterface, x::Int)
end
common_func(obj::MyInterface) = func(obj, 2)

@interface OtherInterface begin
    run(self::OtherInterface, x::Int)
end


@test_throws(UndefVarError, methods_exist(MyInterface, Foo, current_module()))
func(self::Foo) = self.x
@test_throws(ErrorException, methods_exist(MyInterface, Foo, current_module()))
func(self::Foo, x::Int) = self.x + x

implements(Foo, MyInterface)
@test(common_func(Foo(4)) == 6)

func(self::Bar, x::Int) = string(self.x, ",", x)
run(self::Bar, x::Int) = println("Running...")
@implements Bar <: (MyInterface, OtherInterface)
