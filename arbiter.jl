cd("$(@__DIR__)/..") #Все файлы начинают с корневой директории

include("./source/BinanceAPI.jl")
include("./source/source.jl")
using JSON, Dates, DataFrames, HTTP

src.logging(1, "Библиотеки и модули загружены")

channel = Channel(1)

@async BN.wsDepth(channel, src.config()["symbols"]["symbol1"])
@async BN.wsDepth(channel, src.config()["symbols"]["symbol2"])
@async BN.wsDepth(channel, src.config()["symbols"]["symbol3"])

while !((@isdefined bookLTCBNB) && (@isdefined bookLTCBTC) && (@isdefined bookBNBBTC))
	buffer = take!(channel)
	if buffer["symbol"] == "LTCBNB"
		global bookLTCBNB = buffer
	end
	if buffer["symbol"] == "LTCBTC"
		global bookLTCBTC = buffer
	end
	if buffer["symbol"] == "BNBBTC"
		global bookBNBBTC = buffer
	end
end


sleep(2)

while true
	buffer = take!(channel)
	if buffer["symbol"] == "LTCBNB"
		global bookLTCBNB = buffer
		#src.logging(2, "$(src.config()["symbols"]["symbol2"]) - $(bookLTCBNB["lastUpdateId"])")
	end
	if buffer["symbol"] == "LTCBTC"
		global bookLTCBTC = buffer
		#src.logging(2, "$(src.config()["symbols"]["symbol3"]) - $(bookLTCBTC["lastUpdateId"])")
	end
	if buffer["symbol"] == "BNBBTC"
		global bookBNBBTC = buffer
		#src.logging(2, "$(src.config()["symbols"]["symbol1"]) - $(bookBNBBTC["lastUpdateId"])")
	end

	BNB = parse(Float64, bookLTCBNB["asks"][1][1]) # Я купил BNB
	BTC = parse(Float64, bookLTCBTC["bids"][1][1]) # Я продал BTC
	k = (BTC/BNB)/parse(Float64, bookBNBBTC["bids"][1][1])
	src.logging(1, "Туды - $k")
	if k > 1.0003
		@async BN.executeOrder(BN.createOrder("LTCBNB", "sell"; quantity = 0.05, orderType="MARKET"), BN.apiKey, BN.apiSecret)
		@async BN.executeOrder(BN.createOrder("LTCBTC", "buy"; quantity = 0.05, orderType="MARKET"), BN.apiKey, BN.apiSecret)
		@async BN.executeOrder(BN.createOrder("BNBBTC", "sell"; quantity = 0.12, orderType="MARKET"), BN.apiKey, BN.apiSecret)
	end
	BNB = parse(Float64, bookLTCBNB["bids"][1][1]) # Я продал BNB
	BTC = parse(Float64, bookLTCBTC["asks"][1][1]) # Я купил BTC
	k = (BTC/BNB)/parse(Float64, bookBNBBTC["asks"][1][1])
	src.logging(1, "Сюды - $k")
	if k > 1.0003
		@async BN.executeOrder(BN.createOrder("LTCBNB", "buy"; quantity = 0.05, orderType="MARKET"), BN.apiKey, BN.apiSecret)
		@async BN.executeOrder(BN.createOrder("LTCBTC", "sell"; quantity = 0.05, orderType="MARKET"), BN.apiKey, BN.apiSecret)
		@async BN.executeOrder(BN.createOrder("BNBBTC", "buy"; quantity = 0.12, orderType="MARKET"), BN.apiKey, BN.apiSecret)
	end
end
