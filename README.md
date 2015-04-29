# Interfaces.jl
[![Build Status](https://travis-ci.org/Rory-Finnegan/Interfaces.jl.svg?branch=master)](https://travis-ci.org/Rory-Finnegan/Interfaces.jl)  [![Coverage Status](https://coveralls.io/repos/Rory-Finnegan/Interfaces.jl/badge.svg?branch=master)](https://coveralls.io/r/Rory-Finnegan/Interfaces.jl?branch=master)

## Summary
Interfaces.jl takes a functional approach to defining and using interfaces in julia. Rather than creating an interface which you need to subtype for all types that satisfy the required methods, simply wrap your instance in the interface wrapper. This reduces the need for complex type hierarchies found in typical object oriented interface mechanisms and provides an easy method of applying interfaces to third party software without needing to modify their existing type hierarchies.

## Usage
```
# Interface definition. 
#Takes the name of the interface followed by a list of method signatures.
@interface MyInterface begin
    func1(self::MyInterface, x::Int)
    func2(self::MyInterface, x::Float64, y::Float64)
end

# Some type Foo, which we may have defined ourselves 
# or could be exposed by some third party library
type Foo
    x::Int
end
func1(self::Foo, x::Int) = return self.x + x
func2(self::Foo, x::Float64, y::Float64) = return self.x * (x + y)

# Create an instance of our interface (which is just a wrapper)
# by passing instance of type Foo to the Interface constructor
myinterface = MyInterface(Foo(4))


# Wrapper works as we'd expect and we can now dispatch 
# on the MyInterface type rather than type Foo.
func1(myinterface, 4)
# returns 8

func2(myinterface, 1.0, 1.0)
# returns 8.0
```

## TODO
 * Improve tests to 100% coverage
 * Improve input validation of method signatures
