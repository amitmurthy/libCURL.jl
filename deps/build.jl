using BinaryProvider # requires BinaryProvider 0.3.0 or later

# Parse some basic command-line arguments
const verbose = "--verbose" in ARGS
const prefix = Prefix(get([a for a in ARGS if a != "--verbose"], 1, joinpath(@__DIR__, "usr")))
products = [
    LibraryProduct(prefix, ["libcurl"], :libcurl),
]

# Install BinaryBuilder dependencies
dependencies = [
    "https://github.com/bicycle1885/ZlibBuilder/releases/download/v1.0.2/build_Zlib.v1.2.11.jl",
    "https://github.com/JuliaWeb/MbedTLSBuilder/releases/download/v0.11/build_MbedTLS.v1.0.0.jl"
]

for url in dependencies
    build_file = joinpath(@__DIR__, basename(url))
    if !isfile(build_file)
        download(url, build_file)
    end
end

# Execute the build scripts for the dependencies in an isolated module to avoid overwriting
# any variables/constants here
for url in dependencies
    build_file = joinpath(@__DIR__, basename(url))
    m = @eval module $(gensym()); include($build_file); end
    append!(products, m.products)
end

# Download binaries from hosted location
bin_prefix = "https://github.com/JuliaWeb/LibCURLBuilder/releases/download/v0.3.0"

# Listing of files generated by BinaryBuilder:
download_info = Dict(
    Linux(:aarch64, :glibc) => ("$bin_prefix/LibCURL.v7.61.0.aarch64-linux-gnu.tar.gz", "9cb9a9584074a85fbef1f3dfe4201457eb6e2b295adb2e30e8c78ba869be841c"),
    Linux(:aarch64, :musl) => ("$bin_prefix/LibCURL.v7.61.0.aarch64-linux-musl.tar.gz", "a934c5d146a4340a87682a71a5edec1f9e76af26be720ae0f31f9d1c870ac8b0"),
    Linux(:armv7l, :glibc, :eabihf) => ("$bin_prefix/LibCURL.v7.61.0.arm-linux-gnueabihf.tar.gz", "1cefd898b4d3b391811998f179323d7c765c02c50a1fb32745f88c8bc8ab00a3"),
    Linux(:armv7l, :musl, :eabihf) => ("$bin_prefix/LibCURL.v7.61.0.arm-linux-musleabihf.tar.gz", "f38eefaa8f46ea4c37d6bfd2a055b5e2d1c4d940771fdd188f2e452fc6be2095"),
    Linux(:i686, :glibc) => ("$bin_prefix/LibCURL.v7.61.0.i686-linux-gnu.tar.gz", "8d2acf9f792d528f2288695063b9f0f0185d662e929b6eb2fc7e8284e9b669ce"),
    Linux(:i686, :musl) => ("$bin_prefix/LibCURL.v7.61.0.i686-linux-musl.tar.gz", "2177fd88f1cfb5022e9342709bedd797a8ed33f0920c5745aa8258af1d2d5492"),
    Linux(:powerpc64le, :glibc) => ("$bin_prefix/LibCURL.v7.61.0.powerpc64le-linux-gnu.tar.gz", "105df265bd3579afd6aa41f41675b49479e2b2598c97500f69252caef6f35c17"),
    MacOS(:x86_64) => ("$bin_prefix/LibCURL.v7.61.0.x86_64-apple-darwin14.tar.gz", "799f7d746b689f83c2a9cc96c2593340d2d93db50d8374a78a0386fbcd5cff96"),
    Linux(:x86_64, :glibc) => ("$bin_prefix/LibCURL.v7.61.0.x86_64-linux-gnu.tar.gz", "a84fc99d076b99ae22ceb18ef9bb99678d6d55e3c6dd8995b8678012e33f3b75"),
    Linux(:x86_64, :musl) => ("$bin_prefix/LibCURL.v7.61.0.x86_64-linux-musl.tar.gz", "a47a41693230bcdd2eb1952b7e5b1d2cd592770e29f6df7b02034a5dfd01ff71"),
    FreeBSD(:x86_64) => ("$bin_prefix/LibCURL.v7.61.0.x86_64-unknown-freebsd11.1.tar.gz", "12d81a4ea93aa14cb204f424e6180cf2a5c60c2c65bb250ae04733d81a333f04"),
    Windows(:x86_64) => ("$bin_prefix/LibCURL.v7.61.0.x86_64-w64-mingw32.tar.gz", "26143b5f208e5f4c4cf483d6a30b9ba0e96805155f87c4970b3d37a7f62f3759"),
)

# Install unsatisfied or updated dependencies:
unsatisfied = any(!satisfied(p; verbose=verbose) for p in products)
if haskey(download_info, platform_key())
    url, tarball_hash = download_info[platform_key()]
    if unsatisfied || !isinstalled(url, tarball_hash; prefix=prefix)
        # Download and install binaries
        install(url, tarball_hash; prefix=prefix, force=true, verbose=verbose)
    end
elseif unsatisfied
    # If we don't have a BinaryProvider-compatible .tar.gz to download, complain.
    # Alternatively, you could attempt to install from a separate provider,
    # build from source or something even more ambitious here.
    error("Your platform $(triplet(platform_key())) is not supported by this package!")
end

# Write out a deps.jl file that will contain mappings for our products
write_deps_file(joinpath(@__DIR__, "deps.jl"), products)
