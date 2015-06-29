#include "mutable_union.h"

// Creates a Union type containing any number of types.
jl_uniontype_t *force_union_type(jl_svec_t *types)
{
    // Note: This code could be much simpler if I could access "newobj" which is exported in
    // "julia_internal.h". This would allow us to re-implement the "jl_type_union_v" function 
    // (found in Julia source "src/jltypes.c") without the conditionals for 0 or 1 internal types.

    // Use exported jl_type_union to flatten the Union.
    jl_value_t *u = jl_type_union(types);

    if(!jl_is_uniontype(u) || u == jl_bottom_type)
    {
        // Ensure that jl_type_union returns a jt_union_type by supplying
        // at least two distinct types.
        jl_svec_t *v = jl_alloc_svec_uninit(2);
        jl_svecset(v, 0, jl_int64_type);
        jl_svecset(v, 1, jl_float64_type);

        jl_uniontype_t *uf = (jl_uniontype_t*) jl_type_union(v);

        // Override the types internal to the union.
        if(!jl_is_uniontype(u))
            uf->types = jl_svec_fill(1, u);
        else
            uf->types = jl_alloc_svec_uninit(0);

        u = (jl_value_t*) uf;
    }

    return (jl_uniontype_t*) u;
}

// Generates an empty Union type that can be modified.
jl_value_t *jl_type_multable_union()
{
    return (jl_value_t*) force_union_type(jl_emptysvec);
}

// Appends Julia Type "t" to the union "u".
void jl_type_mutable_union_append(jl_value_t *u, jl_value_t *t)
{
    if (jl_is_uniontype(u) && u != jl_bottom_type) {
        jl_uniontype_t *_union = (jl_uniontype_t*) u; 
        jl_svec_t *new_types = jl_svec_append(_union->types, jl_svec_fill(1, t));

        jl_uniontype_t *new_union = force_union_type(new_types);

        _union->types = new_union->types;
    }
}