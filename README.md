# Interfaces.jl (not maintained)
[![Build Status](https://travis-ci.org/Rory-Finnegan/Interfaces.jl.svg?branch=master)](https://travis-ci.org/Rory-Finnegan/Interfaces.jl)  [![Coverage Status](https://coveralls.io/repos/Rory-Finnegan/Interfaces.jl/badge.svg?branch=master)](https://coveralls.io/r/Rory-Finnegan/Interfaces.jl?branch=master)

NOTE: This package was initially designed as a proof of concept for interfaces in julia. However, with changes to how unions work in base julia the approach taken here no longer works.

## Summary
Interfaces.jl takes a simplistic approach to defining and using interfaces in julia. Rather than creating an interface which you need to subtype for all types that satisfy the required methods, you can simply state that a type implements some interfaces without needing to modify your existing type heirarchy.

## Usage
The Interface definition takes the name of the interface followed by a list of method signatures. Here define an interface called `MyInterface` with 2 methods `func1` and `func2`.
```
@interface MyInterface begin
    func1(self::MyInterface, x::Int)
    func2(self::MyInterface, x::Float64, y::Float64)
end
```

Now given the following type `Foo`, which we may have defined ourselves or could be exposed by some third party library, but supports all of our desired methods.
```
type Foo
    x::Int
end
func1(self::Foo, x::Int) = return self.x + x
func2(self::Foo, x::Float64, y::Float64) = return self.x * (x + y)
```

We can say that `Foo` implements `MyInterface` like so.
```
@implements Foo <: MyInterface
```
or with
```
implements(Foo, MyInterface)
```

Similarly, if we want our type `Foo` to implement multiple Interfaces we can say.
```
@implements Foo <: (MyInterface, OtherInterface)
```

If we define a function that take `MyInterface` we can see that dispatching works fine if we pass in an instance of `Foo`
```
common_func(obj::MyInterface) = func1(obj, 4)

common_func(Foo(4))
# returns 8
```

## TODO
 * Improve tests to 100% coverage
 * Improve input validation of method signatures
