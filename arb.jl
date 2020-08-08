cd("$(@__DIR__)/..") #Все файлы начинают с корневой директории

include("./source/BinanceAPI.jl")
include("./source/source.jl")
using JSON, Dates, DataFrames, CSV

function price(symbol::String, ask::Bool)
    delay = Dict([("LTCBTC", Millisecond(150)), ("LTCBNB", Millisecond(500)), ("BNBBTC", Millisecond(90))])
    df = DataFrame(CSV.file("./arb/orderbooks/$symbol.csv"))
    if (now(UTC) - df.time[1]) > delay[symbol]
        "timeout"
    else
        if ask
            df.askprice[1]
        else
            df.bidprice[1]
        end
    end
end

while true
    try
        a = price("LTCBTC", false)
        src.logging(2, "$a")
        b = price("LTCBNB", false)
        src.logging(2, "$b")
        c = price("BNBBTC", false)
        src.logging(2, "$c")
        f = a * b * c
        src.logging(3, "$f")
    catch
        src.logging(1, "null")
    end
end
# a = 0.05*price("LTCBTC", false) # Я продал LTC. Столько я купил BTC
# b = 0.05*price("LTCBNB", true) # Я купил LTC. Столько я продал BNB
# (a/b)/price("BNBBTC", true)
