include("../../source/BinanceAPI.jl")
include("../../source/source.jl")

using Dates, CSV, DataFrames

while true
    df = DataFrame(CSV.file("./arb/orderbooks/LTCBNB.csv"))
    try
    	delay = now(UTC) - df.time[1]
    	src.logging("LTCBNB.log", 1, "$delay")
    	sleep(0.05)
    catch
	df |> println
    end
end
