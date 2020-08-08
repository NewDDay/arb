cd("$(@__DIR__)/..") #Все файлы начинают с директории GitHub

include("../../source/BinanceAPI.jl")
include("../../source/source.jl")
using LibPQ, JSON, CSV, Dates
src.logging(0, "Start orderbook update")

@time (LibPQ.Connection(src.data()["connPG"]) do conn
    execute(conn, """	select * from	arb_trade""")
end |> DataFrame)

@time DataFrame(CSV.file("./arb/analysis/orderbooks/test.csv"))
