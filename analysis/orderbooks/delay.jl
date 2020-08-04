include("../../source/BinanceAPI.jl")
include("../../source/source.jl")

using Dates, CSV, DataFrames

while true
    df = DataFrame(CSV.file("./LTCBTC.csv"))
    delay = now(UTC) - df.time[1]
    src.logging("LTCBTC.log", 1, "$delay")
    sleep(0.5)
end
