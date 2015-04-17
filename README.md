# Interfaces.jl
An implementation of interfaces for Julia

## Usage
```
# Create interface
@interface MyInterfaceType begin
    func1(self::MyInterfaceType, x::Int)
    func2(self::MyInterfaceType, y...)
end

# Object with the required methods
type MyObj
    x
end
func1(self::MyObj, x::Int) = println(self.x * x)
func2(self::MyObj, y...) = println(y)

obj_imp = MyObj(4)
interface_imp = MyInterfaceType(obj_imp)

func1(interface_imp, 4)
# returns 4
```
