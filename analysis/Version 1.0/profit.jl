cd("$(@__DIR__)")

using Plots, Dates, CSV, DataFrames

file = DataFrame(CSV.file("../../logs/orders.csv"))

global BTC = 0
global BNB = 0
global LTC = 0
global graphBTC = Float64[]
global graphBNB = Float64[]
global graphLTC = Float64[]
global time = DateTime[]

for x in eachrow(file)
    if (x.symbol == "LTCBTC") && (x.side == "SELL")
        global LTC = LTC - x.q
        global BTC = BTC + x.q
        push!(graphBNB, BNB)
        push!(graphBTC, BTC)
        push!(graphLTC, LTC)
        push!(time, x.time)
    end
    if (x.symbol == "LTCBTC") && (x.side == "BUY")
        global LTC = LTC + x.q
        global BTC = BTC - x.q
        push!(graphBNB, BNB)
        push!(graphBTC, BTC)
        push!(graphLTC, LTC)
        push!(time, x.time)
    end
    if (x.symbol == "LTCBNB") && (x.side == "SELL")
        global LTC = LTC - x.q
        global BNB = BNB + x.q
        push!(graphBNB, BNB)
        push!(graphBTC, BTC)
        push!(graphLTC, LTC)
        push!(time, x.time)
    end
    if (x.symbol == "LTCBNB") && (x.side == "BUY")
        global LTC = LTC + x.q
        global BNB = BNB - x.q
        push!(graphBNB, BNB)
        push!(graphBTC, BTC)
        push!(graphLTC, LTC)
        push!(time, x.time)
    end
    if (x.symbol == "BNBBTC") && (x.side == "SELL")
        global BNB = BNB - x.q
        global BTC = BTC + x.q
        push!(graphBNB, BNB)
        push!(graphBTC, BTC)
        push!(graphLTC, LTC)
        push!(time, x.time)
    end
    if (x.symbol == "BNBBTC") && (x.side == "BUY")
        global BNB = BNB + x.q
        global BTC = BTC - x.q
        push!(graphBNB, BNB)
        push!(graphBTC, BTC)
        push!(graphLTC, LTC)
        push!(time, x.time)
    end
end


pl = plot(time, [graphBNB, graphBTC, graphLTC])

pl = plot(times, [number, limit], fmt = :png)

savefig( "131233.pdf")

file
