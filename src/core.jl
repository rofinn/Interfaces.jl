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

        which generates a wrapper
        ```
        type MyInterfaceType
            obj

            function MyInterface(other)
                methods_exist(MyInterface, typeof(other))
                new(other)
            end
        end
        func1(self::MyInterfaceType, x::Int) = func1(self.obj, x)
        func2(self::MyInterfaceType, y) = func2(self.obj, y)
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
    At the lowest level we add a single Type to the interface typealias union.
""" ->
function implements(name::Type, interfaces::Union{Type,Tuple})
    interface_names = None
    if isa(interfaces, Type)
        interface_names = (interfaces,)
    elseif isa(interfaces, Tuple)
        interface_names = interfaces
    end

    for i in interface_names
        println(i)
        println(typeof(i))
        methods_exist(name, i, current_module())

        ccall(Libdl.dlsym(MUTABLE_UNION_LIB, :jl_type_mutable_union_append),
            Void, (Any, Any), i, name
        )
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
                # println("$(func)($(params))")
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

macro dlsym(func, lib)
    z, zlocal = gensym(string(func)), gensym()
    eval(current_module(),:(global $z = C_NULL))
    z = esc(z)
    quote
        let $zlocal::Ptr{Void} = $z::Ptr{Void}
            if $zlocal == C_NULL
               $zlocal = dlsym($(esc(lib))::Ptr{Void}, $(esc(func)))
               global $z = $zlocal
            end
            $zlocal
        end
    end
end
