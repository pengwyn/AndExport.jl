module AndExport

##############################
# * Exporting
#----------------------------

export @xport

using MacroTools

# Convenient iteration flatten
# My version of flatten1, which doesn't remove blocks at the top level (this ruins structs)
function my_flatten1(ex)
  isexpr(ex, :block) || return ex
  #ex′ = :(;)
  ex′ = Expr(:block)
  for x in ex.args
    isexpr(x, :block) ? append!(ex′.args, x.args) : push!(ex′.args, x)
  end
  return ex′
end
iterflatten(ex) = MacroTools.postwalk(my_flatten1, block(ex)).args

macro xport(expr::Expr)
    expr = macroexpand(__module__, expr)

    exports = Expr[]

    for item in iterflatten(expr)
        if @capture (item) ( (function name_(args__) where {T__} content__ end) |
                                   (function name_(args__) content__ end) |
                                   (name_(args__) where {T__} = content__) |
                                   (name_(args__) = content__) |
                                   (mutable struct name_ content__ end) |
                                   (struct name_ content__ end) |
                                   (abstract type name_ end) |
                                   (const name_ = val__) |
                                   (name_ = val__) )
            if @capture (name) ( (name2_{T__} <: Z_ where T2_) |
                                 (name2_ <: Z_ where T2_) |
                                 (name2_{T__} where T2_) |
                                 (name2_ where T2_) |
                                 (name2_{T__} <: Z_) |
                                 (name2_ <: Z_) |
                                 (name2_{T__}) |
                                 name2_ )
                # Ignore (::Type{T}) functions for exports
                # if @capture (name2) (::Type{T__})
                #     @info "Ignoring" name
                if name2 isa Expr# && name2.head == Symbol("::")
                    # @info "Ignoring" name
                else
                    push!(exports, :(export $(esc(name2))))
                end
            end
        elseif @capture (item) (macro name_(args__) content__ end)
            name = Symbol("@" * string(name))
            push!(exports, :(export $(esc(name))))
        end
        item
    end
            
    if isempty(exports)
        buf = IOBuffer()
        dump(buf, expr, maxdepth=1)
        repr = String(take!(buf))
        error("Unknown object to export: $repr.")
    end

    fullcode = Expr(:block, exports..., esc(expr))
end

end # module
