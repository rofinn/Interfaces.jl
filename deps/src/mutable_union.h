#ifndef MUTABLE_UNION_H
#define MUTABLE_UNION_H

#include <julia.h>

jl_value_t *jl_type_multable_union();
void jl_type_mutable_union_append(jl_value_t *u, jl_value_t *t);

#endif