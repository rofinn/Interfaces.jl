type MethodSig
    name::Symbol
    params::Array{Any, 1}
end

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
    # hidden_typename is just used as a hack to make sure updateing
    # the mutable unions modifies what is excepted by functions that use it
    hidden_typename = esc("_$(name)")
    code = quote
        typealias $(typename) ccall(Libdl.dlsym(MUTABLE_UNION_LIB, :jl_type_mutable_union), Any, ())
        eval(parse(string("type ", $(hidden_typename), " end")))
        ccall(Libdl.dlsym(MUTABLE_UNION_LIB, :jl_type_mutable_union_append),
                Void, (Any, Any), $(typename), $(hidden_typename)
            )
    end

    methods = []
    for line in prototypes.args
        if isa(line, Symbol)
            println("Providing only function names isn't supported yet.")
            continue
        elseif line.head == :line
            continue
        elseif isa(line, Expr)
            fname = line.args[1]
            params = []
            for arg in line.args[2:end]
                push!(params, arg.args[2])
            end
            push!(methods, MethodSig(fname, params))
        end
    end

    func = esc(:(get_methods(interface::Type{$(name)}) = return $(methods)))

    code = quote
        $code
        $func
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
    Determines whether type atype supports all the same methods
    as the interface.
""" ->
function methods_exist(interface::Type, atype::Type, mod)
    get_methods_func = eval(mod, :get_methods)
    interface_type = eval(mod, interface)
    for interface_method in get_methods_func(interface_type)
        fname = interface_method.name
        params = []

        for p in interface_method.params
            param = eval(mod, p)
            if param == interface
                push!(params, atype)
            else
                push!(params, param)
            end
        end

        func = eval(mod, fname)
        if !method_exists(func, tuple(params...))
            error("Required method $(fname)($(params)) not implemented for $(atype)")
        end
    end
end

