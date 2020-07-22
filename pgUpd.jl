# Программа обновляет ордербуки в PG
# Индексальные номера: 0-3
cd("$(@__DIR__)/..") #Все файлы начинают с директории GitHub

include("./source/BinanceAPI.jl")
include("./source/source.jl")
using LibPQ, JSON, Dates
src.logging(0, "Start orderbook update")

sym = src.symbols()
config = src.config()

src.logging(0, "Include files")
channel1 = Channel(1) # Каналы единичины, чтобы не записивыть старые ордербуки.
channel2 = Channel(1)
channel3 = Channel(1)

@async BN.wsDepth(channel1, config["symbols"]["symbol1"])
@async BN.wsDepth(channel2, config["symbols"]["symbol2"])
@async BN.wsDepth(channel3, config["symbols"]["symbol3"])

src.logging(0, "Include websockets")
function ws2pg(channel::Channel, symbol::String)
       #	src.logging(5, symbol)
	book = take!(channel)
	for x in 1:3
		LibPQ.Connection(src.data()["connPG"]) do conn
			execute(conn, """	UPDATE	arb_trade
								SET		price = $(book["asks"][x][1]),
										quantity = $(book["asks"][x][2]),
										time = '$(now(UTC))'
								WHERE id = $x AND ihave = '$(sym[symbol]["quote"])' AND iwant = '$(sym[symbol]["base"])';""")
			execute(conn, """	UPDATE	arb_trade
								SET		price = $(1 / parse(Float64, book["bids"][x][1])),
										quantity = $(book["bids"][x][2]),
										time = '$(now(UTC))'
								WHERE id = $x AND ihave = '$(sym[symbol]["base"])' AND iwant = '$(sym[symbol]["quote"])';""")
		end
	end
end

while true
	#src.logging(2, "В бесконечном цикле.")
	@async ws2pg(channel1, config["symbols"]["symbol1"])
	sleep(src.config()["other"]["timeout"])
	@async ws2pg(channel2, config["symbols"]["symbol2"])
	sleep(src.config()["other"]["timeout"])
	@async ws2pg(channel3, config["symbols"]["symbol3"])
	sleep(src.config()["other"]["timeout"])
end

src.logging(0, "Exit")
