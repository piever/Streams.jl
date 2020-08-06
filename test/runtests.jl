using Streams
using Test

s1 = Stream(1)
s2 = Stream(2)
s3 = TimeStream{Float64}(sin)
s4 = lift(+, s1, s2, s3)
@info "initial value"
@show s4

@info "changing one addend"
s2[] = 100
@show s4
