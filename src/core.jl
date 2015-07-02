@doc doc"""
    A simple macro to automate creating interface code.

    Usage:
        create an interface with
        ```
        @interface MyInterfaceType begin
            func1(self::MyInterfaceType, x::Int)
            func2(self::MyInterfaceType, y)
        end
        ```
""" ->
macro interface(name, prototypes)
    @assert isa(name, Symbol)
    @assert prototypes.head == :block

    typename = esc(name)
    code = quote
        typealias $(typename) ccall(Libdl.dlsym(MUTABLE_UNION_LIB, :jl_type_mutable_union), Any, ())
    end

    for line in prototypes.args
        if isa(line, Symbol)
            println("Providing only function names isn't supported yet.")
            continue
        elseif line.head == :line
            continue
        elseif isa(line, Expr)
            func = esc(line)
            fname = esc(line.args[1])

            code = quote
                $code
                $(func) = error("$(fname) not implemented")
            end
        else
            error("Invalid type for line")
        end
    end

    return code
end


@doc doc"""
    A second macro for making a type implement a declared interface. This is really
    just syntactic sugar for the implements function. The macro takes an
    expression of the forms provided below and calls the implements function

    Usage:
        *Assuming MyType and MyInterface exist and MyType has
        all the required methods defined
        ```
        @implements MyType <: MyInterface
        ```

    or to implement multiple interfaces at once
        ```
        @implements MyType <: (MyInterface, OtherInterface, ...)
        ```
""" ->
macro implements(expr)
   @assert isa(expr, Expr)
   @assert length(expr.args) == 3
   @assert expr.args[2] == :<:

   typename = esc(expr.args[1])
   interfaces = esc(expr.args[3])
   code = quote
       Interfaces.implements($(typename), $(interfaces))
   end
   return code
end


@doc doc"""
    The implements function called from the @implements macro
    takes a single type and either a single Interface or a Tuple of Interfaces.
    The implements function uses methods with to ensure that Type provided implements
    each of the required methods for each Interfaces and then updates the typealias
    union for that Interface with the Type.

    Usage:
        *Assuming MyType and MyInterface exist and MyType has
        all the required methods defined
        ```
        implements(MyType, MyInterface)
        ```

        or for a batch implements
        ```
        implements(MyType, (MyInterface, MyOtherInterface))
        ```
""" ->
function implements(name::Type, interfaces::Union{Type,Tuple})
    interface_names = None
    if isa(interfaces, Type)
        interface_names = (interfaces,)
    elseif isa(interfaces, Tuple)
        interface_names = interfaces
    end

    for i in interface_names
        # Only bother checking the methods and updating the typealias
        # If the interface != type, since methodswith is slow
        # (Note: Foo == Union{Foo})
        if i != name
            methods_exist(i, name, current_module())

            ccall(Libdl.dlsym(MUTABLE_UNION_LIB, :jl_type_mutable_union_append),
                Void, (Any, Any), i, name
            )
        end
    end
end


@doc doc"""
    Determines whether type obj supports all the same methods
    as type self.
""" ->
function methods_exist(self, obj, mod)
    method_found = false
    for self_method in methodswith(self)
        method_found = false
        self_fname = self_method.func.code.name    # Dumb! and it doesn't even tab complete

        for obj_method in methodswith(obj)
            obj_fname = obj_method.func.code.name
            if obj_fname == self_fname
                params = ()
                if VERSION < v"0.4-"
                    params = map(x -> x == self ? obj : x, self_method.sig)
                else
                    params = tuple(map(x -> x == self ? obj : x, self_method.sig.parameters)...)
                end
                func = eval(mod, obj_fname)
                if method_exists(func, params)
                    method_found = true
                    break
                end
           end
        end
        if !method_found
            error("Required method $(self_fname)($(self_method.sig)) not implemented for $(obj)")
        end
    end
end
