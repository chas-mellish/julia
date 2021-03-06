# This file is a part of Julia. License is MIT: https://julialang.org/license

struct BitPerm_19352
    p::NTuple{8,UInt8}
    function BitPerm(p::NTuple{8,UInt8})
        sort(collect(p)) != collect(0:7) && error("$p is not a permutation of 0:7")
        new(p)
    end
    BitPerm_19352(xs::Vararg{Any,8}) = BitPerm(map(UInt8, xs))
end

# #17198
@test_throws BoundsError convert(Tuple{Int}, (1.0, 2.0, 3.0))
# #21238
@test_throws MethodError convert(Tuple{Int, Int, Int}, (1, 2))

@testset "conversion and construction" begin
    @test convert(Tuple, ()) === ()
    @test convert(Tuple, (1, 2)) === (1, 2)
    @test convert(Tuple, (1.0, 2)) === (1.0, 2)

    @test convert(NTuple, ()) === ()
    @test convert(Tuple{}, ()) === ()
    @test convert(Tuple{Vararg{Int}}, ()) === ()
    @test convert(Tuple{Vararg{T}} where T<:Integer, ()) === ()

    @test convert(NTuple{3, Int}, (1, 2, 3)) === (1, 2, 3)
    @test convert(NTuple, (1, 2, 3)) === (1, 2, 3)
    @test convert(Tuple{Vararg{Int}}, (1, 2, 3)) === (1, 2, 3)
    @test convert(Tuple{Int, Vararg{Int}}, (1, 2, 3)) === (1, 2, 3)
    @test convert(Tuple{Vararg{T}} where T<:Integer, (1, 2, 3)) === (1, 2, 3)
    @test convert(Tuple{T, Vararg{T}} where T<:Integer, (1, 2, 3)) === (1, 2, 3)
    @test convert(Tuple{Int, Int, Float64}, (1, 2, 3)) === (1, 2, 3.0)

    @test convert(Tuple{Float64, Int, UInt8}, (1.0, 2, 0x3)) === (1.0, 2, 0x3)
    @test convert(NTuple, (1.0, 2, 0x3)) === (1.0, 2, 0x3)
    @test convert(Tuple{Vararg{Int}}, (1.0, 2, 0x3)) === (1, 2, 3)
    @test convert(Tuple{Int, Vararg{Int}}, (1.0, 2, 0x3)) === (1, 2, 3)
    @test convert(Tuple{Vararg{T}} where T<:Integer, (1.0, 2, 0x3)) === (1, 2, 0x3)
    @test convert(Tuple{T, Vararg{T}} where T<:Integer, (1.0, 2, 0x3)) === (1, 2, 0x3)
    @test convert(NTuple{3, Int}, (1.0, 2, 0x3)) === (1, 2, 3)
    @test convert(Tuple{Int, Int, Float64}, (1.0, 2, 0x3)) === (1, 2, 3.0)

    # TODO: seems like these all should throw BoundsError?
    @test_throws MethodError convert(Tuple{Int}, ())
    @test_throws MethodError convert(Tuple{Int, Vararg{Int}}, ())
    @test_throws BoundsError convert(Tuple{}, (1, 2, 3))
    @test_throws BoundsError convert(Tuple{}, (1.0, 2, 3))
    @test_throws MethodError convert(NTuple{3, Int}, ())
    @test_throws MethodError convert(NTuple{3, Int}, (1, 2))
    @test_throws BoundsError convert(NTuple{3, Int}, (1, 2, 3, 4))
    @test_throws MethodError convert(Tuple{Int, Int, Float64}, ())
    @test_throws MethodError convert(Tuple{Int, Int, Float64}, (1, 2))
    @test_throws BoundsError convert(Tuple{Int, Int, Float64}, (1, 2, 3, 4))

    # PR #15516
    @test Tuple{Char,Char}("za") === ('z','a')
    @test_throws ArgumentError Tuple{Char,Char}("z")

    @test NTuple{20,Int}(Iterators.countfrom(2)) === (2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21)
    @test NTuple{20,Float64}(Iterators.countfrom(2)) === (2.,3.,4.,5.,6.,7.,8.,9.,10.,11.,12.,13.,14.,15.,16.,17.,18.,19.,20.,21.)
    @test_throws ArgumentError NTuple{20,Int}([1,2])

    @test Tuple{Vararg{Float32}}(Float64[1,2,3]) === (1.0f0, 2.0f0, 3.0f0)
    @test Tuple{Int,Vararg{Float32}}(Float64[1,2,3]) === (1, 2.0f0, 3.0f0)
    @test Tuple{Int,Vararg{Any}}(Float64[1,2,3]) === (1, 2.0, 3.0)
    @test Tuple(ones(5)) === (1.0,1.0,1.0,1.0,1.0)
    @test_throws MethodError convert(Tuple, ones(5))

    @testset "ambiguity between tuple constructors #20990" begin
        Tuple16Int = Tuple{Int,Int,Int,Int,Int,Int,Int,Int,Int,Int,Int,Int,Int,Int,Int,Int}
        tuple16int = (1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1)
        @test Tuple16Int(tuple16int) isa Tuple16Int
    end

    @testset "side effect in tuple constructor #19352" begin
        @test BitPerm_19352(0,2,4,6,1,3,5,7).p[2] == 0x02
    end

    @testset "ninitialized" begin
        @test Tuple{Int,Any}.ninitialized == 2
        @test Tuple.ninitialized == 0
        @test Tuple{Int,Vararg{Any}}.ninitialized == 1
        @test Tuple{Any,Any,Vararg{Any}}.ninitialized == 2
    end

    @test empty((1, 2.0, "c")) === ()
end

@testset "size" begin
    @test length(()) == 0
    @test length((1,)) === 1
    @test length((1,2)) === 2

    @test_throws ArgumentError Base.front(())
    @test_throws ArgumentError first(())

    @test endof(()) === 0
    @test endof((1,)) === 1
    @test endof((1,2)) === 2

    @test size((), 1) === 0
    @test size((1,), 1) === 1
    @test size((1,2), 1) === 2

    # @test_throws ArgumentError size((), 2)
    # @test_throws ArgumentError size((1,), 2)
    # @test_throws ArgumentError size((1,2), 2)
end

@testset "indexing" begin
    @test getindex((1,), 1) === 1
    @test getindex((1,2), 2) === 2
    @test_throws BoundsError getindex((), 1)
    @test_throws BoundsError getindex((1,2), 0)
    @test_throws BoundsError getindex((1,2), -1)

    @test getindex((1,), 1.0) === 1
    @test getindex((1,2), 2.0) === 2
    @test_throws BoundsError getindex((), 1.0)
    @test_throws BoundsError getindex((1,2), 0.0)
    @test_throws BoundsError getindex((1,2), -1.0)

    @test getindex((5,6,7,8), [1,2,3]) === (5,6,7)
    @test_throws BoundsError getindex((1,2), [3,4])

    @test getindex((5,6,7,8), [true, false, false, true]) === (5,8)
    @test_throws BoundsError getindex((5,6,7,8), [true, false, false, true, true])

    @test getindex((5,6,7,8), []) === ()

    @testset "boolean arrays" begin
        # issue #19719
        @test_throws BoundsError (1,2,3)[falses(4)]
        @test_throws BoundsError (1,2,3)[[false,false,true,true]]
        @test_throws BoundsError (1,2,3)[trues(2)]
        @test_throws BoundsError (1,2,3)[falses(2)]
        @test_throws BoundsError ()[[false]]
        @test_throws BoundsError ()[[true]]
    end

    @testset "Multidimensional indexing (issue #20453)" begin
        @test_throws MethodError (1,)[]
        @test_throws MethodError (1,1,1)[1,1]
    end
end

@testset "fill to length" begin
    ## filling to specified length
    @test @inferred(Base.fill_to_length((1,2,3), -1, Val(5))) == (1,2,3,-1,-1)
    @test_throws ArgumentError Base.fill_to_length((1,2,3), -1, Val(2))
end

@testset "iterating" begin
    @test start((1,2,3)) === 1

    @test done((), 1)
    @test !done((1,2,3), 3)
    @test done((1,2,3), 4)

    @test next((5,6,7), 1) === (5, 2)
    @test next((5,6,7), 3) === (7, 4)
    @test_throws BoundsError next((5,6,7), 0)
    @test_throws BoundsError next((), 1)

    @test collect(eachindex((2,5,"foo"))) == collect(1:3)
    @test collect(eachindex((2,5,"foo"), (1,2,5,7))) == collect(1:4)
end


@testset "element type" begin
    @test eltype((1,2,3)) === Int
    @test eltype((1.0,2.0,3.0)) <: AbstractFloat
    @test eltype((true, false)) === Bool
    @test eltype((1, 2.0, false)) === typejoin(Int, Float64, Bool)
    @test eltype(()) === Union{}
    @test eltype(Tuple{Int, Float64, Vararg{Bool}}) === typejoin(Int, Float64, Bool)
    @test eltype(Tuple{Int, T, Vararg{Bool}} where T <: AbstractFloat) ===
        typejoin(Int, AbstractFloat, Bool)
    @test eltype(Tuple{Int, Bool, Vararg{T}} where T <: AbstractFloat) ===
        typejoin(Int, AbstractFloat, Bool)
    @test eltype(Union{Tuple{Int, Float64}, Tuple{Vararg{Bool}}}) ===
        typejoin(Int, Float64, Bool)
end

@testset "mapping" begin
    foo() = 2
    foo(x) = 2x
    foo(x, y) = x + y
    foo(x, y, z) = x + y + z
    longtuple = ntuple(identity, 20)

    @testset "1 argument" begin
        @test map(foo, ()) === ()
        @test map(foo, (1,)) === (2,)
        @test map(foo, (1,2)) === (2,4)
        @test map(foo, (1,2,3,4)) === (2,4,6,8)
        @test map(foo, longtuple) === ntuple(i->2i,20)
    end

    @testset "2 arguments" begin
        @test map(foo, (), ()) === ()
        @test map(foo, (1,), (1,)) === (2,)
        @test map(foo, (1,2), (1,2)) === (2,4)
        @test map(foo, (1,2,3,4), (1,2,3,4)) === (2,4,6,8)
        @test map(foo, longtuple, longtuple) === ntuple(i->2i,20)
        @test_throws BoundsError map(foo, (), (1,))
        @test_throws BoundsError map(foo, (1,), ())
    end

    @testset "n arguments" begin
        @test map(foo, (), (), ()) === ()
        @test map(foo, (1,), (1,), (1,)) === (3,)
        @test map(foo, (1,2), (1,2), (1,2)) === (3,6)
        @test map(foo, (1,2,3,4), (1,2,3,4), (1,2,3,4)) === (3,6,9,12)
        @test map(foo, longtuple, longtuple, longtuple) === ntuple(i->3i,20)
        @test_throws BoundsError map(foo, (), (1,), (1,))
        @test_throws BoundsError map(foo, (1,), (1,), ())
    end
end

@testset "comparison" begin
    @test isequal((), ())
    @test isequal((1,2,3), (1,2,3))
    @test !isequal((1,2,3), (1,2,4))
    @test !isequal((1,2,3), (1,2))

    @test ==((), ())
    @test ==((1,2,3), (1,2,3))
    @test !==((1,2,3), (1,2,4))
    @test !==((1,2,3), (1,2))

    @test isless((1,2), (1,3))
    @test isless((1,), (1,2))
    @test !isless((1,2), (1,2))
    @test !isless((2,1), (1,2))
end


@testset "functions" begin
    @test isempty(())
    @test !isempty((1,))

    @test reverse(()) === ()
    @test reverse((1,2,3)) === (3,2,1)
end
# issue #21697
@test_throws ArgumentError ntuple(identity, -1)


@testset "specialized reduction" begin
    @test sum((1,2,3)) === 6

    @test prod(()) === 1
    @test prod((1,2,3)) === 6

    @testset "all" begin
        @test all(()) === true
        @test all((false,)) === false
        @test all((true,)) === true
        @test all((true, true)) === true
        @test all((true, false)) === false
        @test all((false, false)) === false
    end

    @testset "any" begin
        @test any(()) === false
        @test any((true,)) === true
        @test any((false,)) === false
        @test any((true, true)) === true
        @test any((true, false)) === true
        @test any((false, false)) === false
        @test any((false,false,false)) === false
        @test any((true,false,false)) === true
        @test any((false,true,false)) === true
        @test any((false,false,true)) === true
        @test any((true,true,false)) === true
        @test any((true,false,true)) === true
        @test any((true,true,false)) === true
        @test any((true,true,true)) === true
    end
end

@testset "ntuple" begin
    nttest1(x::NTuple{n, Int}) where {n} = n
    @test nttest1(()) == 0
    @test nttest1((1, 2)) == 2
    @test NTuple <: Tuple
    @test (NTuple{T, Int32} where T) <: Tuple{Vararg{Int32}}
    @test !((NTuple{T, Int32} where T) <: Tuple{Int32, Vararg{Int32}})
    @test Tuple{Vararg{Int32}} <: (NTuple{T, Int32} where T)
    @test Tuple{Int32, Vararg{Int32}} <: (NTuple{T, Int32} where T)
    @test @inferred(ntuple(abs2, Val(0))) == ()
    @test @inferred(ntuple(abs2, Val(2))) == (1, 4)
    @test @inferred(ntuple(abs2, Val(3))) == (1, 4, 9)
    @test @inferred(ntuple(abs2, Val(4))) == (1, 4, 9, 16)
    @test @inferred(ntuple(abs2, Val(5))) == (1, 4, 9, 16, 25)
    @test @inferred(ntuple(abs2, Val(6))) == (1, 4, 9, 16, 25, 36)
    # issue #21697
    @test_throws ArgumentError ntuple(abs2, Val(-1))

    # issue #12854
    @test_throws TypeError ntuple(identity, Val(1:2))

    for n = 0:20
        t = ntuple(identity, n)
        @test length(t) == n
        for i = 1:n
            @test t[i] == i
        end
    end
    # issue #21697
    @test_throws ArgumentError ntuple(identity, -1)

    # PR #21446
    for n = 0:15
        @test ntuple(identity, Val(n)) == ntuple(identity, n)
    end
end

struct A_15703{N}
    keys::NTuple{N, Int}
end

struct B_15703
    x::A_15703
end
@testset "issue #15703" begin
    function bug_15703(xs...)
        [x for x in xs]
    end

    function test_15703()
        s = (1,)
        a = A_15703(s)
        ss = B_15703(a).x.keys
        @test ss === s
        bug_15703(ss...)
    end

    test_15703()
end

@testset "#21026" begin
    # https://github.com/JuliaLang/julia/issues/21026#issuecomment-317113307
    VecTuple21026{T} = Tuple{VecElement{T}}
    @test convert(VecTuple21026, (1,)) === (VecElement(1),)

    @test convert(Tuple{Complex{T}, Complex{T}} where T<:Real, (1, 2)) ===
        (Complex(1), Complex(2))
    @test convert(Tuple{Complex{T}, Complex{T}} where T<:Real, (1, 2.0)) ===
        (Complex(1), Complex(2.0))
    @test convert(Tuple{Complex, Complex}, (1, 2)) ===
        (Complex(1), Complex(2))
    @test convert(Tuple{Complex, Complex}, (1, 2.0)) ===
        (Complex(1), Complex(2.0))
end
