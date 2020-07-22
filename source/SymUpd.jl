# Эта программа парсит пары и разбивает их на base and quote

@info("Начало")
cd("$(@__DIR__)/../..") #Все файлы начинают с директории GitHub

include("BinanceAPI.jl")
@info("Подключили библиотеки")
sdict = BN.account()["balances"]
@info("Запросили валюты")
io = open("./arb/source/currency", "w") do io
    for x in sdict
        #push!(infile, get(x, "asset", Missing))
        write(io, string(get(x, "asset", Missing), "\n"))
    end
end
@info("Записали currency")
symbols = Vector()
io = open("./arb/source/currency", "r") do io
    global symbols
    for x in eachline(io)
        push!(symbols, x)
    end
end
@info("Считали currency")
ff = BN.getAllPrices()
@info("Запросили символы")
txt = ""
open("./arb/source/symbols.json", "w+") do io
    write(io, "{")
    for f in ff
        for x in symbols
            rnx = Regex("^($x)")
            if occursin(rnx, f["symbol"])
                newf = replace(f["symbol"], x => "")
                for y in symbols
                    rny = Regex("($y)\$")
                    if occursin(rny, newf)
                        if replace(newf, y => "") == ""
                            global txt
                            txt = string(txt, "\n\"$(f["symbol"])\": {\n\t\"base\" : \"$x\",\n \t\"quote\" : \"$y\"},")
                        end
                    end
                end
            end
        end
    end
    dicttxt = string(chop(txt, tail=1), "\n}")  # file information to string
    write(io, dicttxt)
end
@info("Записали symbols.json")
@info("Конец")
