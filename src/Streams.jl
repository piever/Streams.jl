module Streams

using Dates
using Base: RefValue

unixnow() = datetime2unix(now())

struct Event{T}
    time::Float64
    value::T
end

Event(v) = Event(unixnow(), v)

nullfunction() = nothing

# interace: current, current!, update!
abstract type AbstractStream{T} end

struct Stream{T, F, I} <: AbstractStream{T}
    f::F
    current::RefValue{Event{T}}
    inputs::I
end

Stream(f, e::Event, inputs=()) = Stream(f, Ref(e), inputs)
Stream(e::Event) = Stream(nullfunction, e)
Stream(val) = Stream(Event(val))

current(s::Stream) = s.current[]
current!(s::Stream, val) = s.current[] = val

Base.show(io::IO, s::Stream) = print(io, "Stream with value $(s[])")

function update!(s::Stream)
    current_time = current(s).time
    inputs = map(update!, s.inputs)
    inputs_time = mapreduce(max, inputs, init=-Inf) do str
        current(str).time
    end
    if inputs_time > current_time
        res = apply(s.f, inputs...)
        current!(s, Event(inputs_time, res))
    end
    return s
end

function Base.getindex(s::AbstractStream)
    update!(s)
    return current(s).value
end

Base.setindex!(s::AbstractStream, val) = current!(s, Event(val))

function apply(f, streams::AbstractStream...)
    args = map(getindex, streams)
    return f(args...)
end

function lift(f, streams::AbstractStream...)
    res = apply(f, streams...)
    return Stream(f, Event(res), streams)
end

struct TimeStream{T, F} <: AbstractStream{T}
    f::F
    TimeStream{T}(f::F) where {T, F} = new{T, F}(f)
end

function current(t::TimeStream)
    time = unixnow()
    return Event(time, t.f(time))
end
update!(t::TimeStream) = t

s1 = Stream(1)
s2 = Stream(2)
s3 = TimeStream{Float64}(sin)
s4 = lift(+, s1, s2, s3)
@info "initial value"
@show s4

@info "changing one addend"
s2[] = 100
@show s4


end
