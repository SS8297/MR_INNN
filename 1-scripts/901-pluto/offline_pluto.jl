# Edit Pluto (in place!) to run in an air-gapped environment

# Editing a package after it's installed is bad. But hey, this works.
# Before running this script, you can instantiate a new depot to avoid 
# contaminating your main depot.  Something like:
#
# push!(empty!(DEPOT_PATH), "my/new/depot/path")
# using Pkg
# Pkg.activate("my/project/path")
# Pkg.instantiate()

using Pluto, DelimitedFiles

pluto_root(args...) = abspath(joinpath(pathof(Pluto), "..", "..", args...))


function _replace(file, old_new::Pair)
    old, new = old_new
    sed = Sys.isapple() ?  ["sed", "-i", ""] : ["sed", "-i"]
    run(`$sed $("s|$old|$new|g") $file`)
end
frontend = pluto_root("frontend")
assets = pluto_root("frontend", "offline_assets")
mkpath(assets)

# find all lines that contain `jsdelivr`, the CDN that delivers assets to Pluto
lines = split(read(`grep -r "jsdelivr" $frontend`, String), '\n')

# place all CDN urls into `replaced_assets`
replaced_assets = []
for line in lines 
    match = findfirst(r"((?<=\")https:\/\/[^\"]*)|((?<=\()https:\/\/[^\)]*)", line)
    if isnothing(match)
        @warn "No match found for line: $line"
    else
        url = line[match]
        push!(replaced_assets, url)
        pluto_file = line[1:findfirst(':', line) - 1]
        _replace(pluto_file, url => "/offline_assets/$(basename(url))")
    end
end
writedlm(joinpath(@__DIR__, "assets.csv"), replaced_assets)

dir = pluto_root("frontend", "offline_assets")
for url in readlines(joinpath(@__DIR__, "assets.csv") )
    @info "Downloading: $url"
    file = touch(joinpath(dir, basename(url)))
    download(url, file)
end