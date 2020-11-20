# AndExport.jl
A convenience macro to easily export things.

## Usage

Just put `@xport` in front of the object you want to export. For example,

```julia
@xport short_func(x) = ...

@xport function long_name(x)
    ...
end

@xport const a = 3

@xport macro special(ex)
    ...
end
```
