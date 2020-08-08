include("../source/BinanceAPI.jl")
include("../source/source.jl")
using HTTP, Dates

function wsparse(json::Vector{UInt8})
    txt = String(json)
    rx = r"\d*\.\d*|\d+"
    m = eachmatch(rx, txt)
    collect(m)
end

function infile(book::Vector{RegexMatch})
    open("./arb/orderbooks/LTCBTC.csv", "w+") do io
        write(io, "askprice,askquantity,bidprice,bidquantity,time,id\n")
        write(io, "$(book[12].match),$(book[13].match),$(book[2].match),$(book[3].match),$(now(UTC)),$(book[1].match)\n")
        write(io, "$(book[14].match),$(book[15].match),$(book[4].match),$(book[5].match)\n")
        write(io, "$(book[16].match),$(book[17].match),$(book[6].match),$(book[7].match)\n")
        write(io, "$(book[18].match),$(book[19].match),$(book[8].match),$(book[9].match)\n")
        write(io, "$(book[20].match),$(book[21].match),$(book[10].match),$(book[11].match)\n")
    end
end

HTTP.WebSockets.open(string(BN.BINANCE_API_WS, lowercase("LTCBTC"), string("@depth", 5, "@100ms")); verbose=false) do io
    while !eof(io)
        book = wsparse(readavailable(io))
        try
            infile(book)
        catch
            @error("Не удалость записать ордербук LTCBTC") # "julia > book &". При это команде, эта строка выбьется в консоль
            println("Не удалость записать ордербук LTCBTC") # А эта в файл.
        end
    end
end
