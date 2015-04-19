# Interfaces.jl
[![Build Status](https://travis-ci.org/Rory-Finnegan/Interfaces.jl.svg?branch=master)](https://travis-ci.org/Rory-Finnegan/Interfaces.jl)  [![Coverage Status](https://coveralls.io/repos/Rory-Finnegan/Interfaces.jl/badge.svg?branch=master)](https://coveralls.io/r/Rory-Finnegan/Interfaces.jl?branch=master)

## Summary
Interfaces.jl takes a functional approach to defining and using interfaces in julia. Rather than creating an interface which you need to subtype for all types that satisfy the required methods, you simply wrap your type in the interface wrapper. This avoids deep and complex type hierarchies found in typical object oriented interface mechanisms. Another advantage is that interfaces can be used on existing types in third party packages without needing to modify the existing code (ie: making an existing type subtype some new interface).

## Usage
```
# Create interface
@interface MyInterface begin
    func1(self::MyInterface, x::Int)
    func2(self::MyInterface, y...)
end

# Object with the required methods
type MyObj
    x
end
func1(self::MyObj, x::Int) = return self.x * x
func2(self::MyObj, y...) = return y

obj_imp = MyObj(4)
interface_imp = MyInterfaceType(obj_imp)

func1(interface_imp, 4)
# returns 4
```
