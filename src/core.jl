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
        type $(typename)
            obj

            function $(typename)(other)
                methods_exist($(typename), typeof(other), current_module())
                new(other)
            end
        end
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
            linebody = copy(line)

            for i in 2:length(linebody.args)
                if isa(linebody.args[i], Expr)
                    if linebody.args[i].args[2] == name
                        linebody.args[i] = parse(
                            string(linebody.args[i].args[1], ".obj")
                        )
                    else
                        linebody.args[i] = linebody.args[i].args[1]
                    end
                end
            end
            funcbody = esc(linebody)
            code = quote
                $code
                $(func) = $(funcbody)
            end
        else
            error("Invalid type for line")
        end
    end

    #println(code)

    return code
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
                params = map(x -> x == self ? obj : x, self_method.sig)
                func = eval(mod, obj_fname)
                # println("$(func)($(params))")
                if method_exists(func, params)
                    method_found = true
                    break
                end
           end
        end
        if !method_found
            error("Required method $(self_fname)($(self_method.sig)) not implemented for $(typeof(obj))")
        end
    end
end
