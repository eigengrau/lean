import("util.lua")
e = environment()
assert(is_environment(e))
e:add_uvar_cnstr("M1")
print(e:get_uvar("M1"))
e:add_var("N", Type())
N, M = Consts("N M")
e:add_var("a", N)
x, a = Consts("x, a")
check_error(function() e:type_check(fun(x, M, a)) end)
print(e:type_check(fun(x, N, a)))
