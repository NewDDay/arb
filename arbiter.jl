
cd("$(@__DIR__)/..") #Все файлы начинают с корневой директории

include("./source/BinanceAPI.jl")
include("./source/source.jl")
using JSON, Dates, LibPQ, DataFrames

src.logging(1, "Start arbiter")

balance = BN.account()["balances"]
global BalanceLTC = balance[2]["free"]
global BalanceBTC = balance[1]["free"]
global BalanceBNB = balance[5]["free"]

while true
	pBNBBTC = 0.12
	pLTCBTC = 0.05
	pLTCBNB = 0.05
	LibPQ.Connection(src.data()["connPG"]) do conn
		global LTC =  (execute(conn, """	select * from arb(0.1, 'LTC')""") |> DataFrame).arb[1]
	end
	src.logging(4, string(LTC))
	if (LTC > 0.100023) && (LTC < 10)
		
		@async BN.executeOrder(BN.createOrder("LTCBTC", "sell"; quantity = pLTCBTC, orderType="MARKET"), BN.apiKey, BN.apiSecret)
		sleep(0.05)
		@async BN.executeOrder(BN.createOrder("BNBBTC", "buy"; quantity = pBNBBTC, orderType="MARKET"), BN.apiKey, BN.apiSecret)
		sleep(0.05)
		@async BN.executeOrder(BN.createOrder("LTCBNB", "buy"; quantity = pLTCBNB, orderType="MARKET"), BN.apiKey, BN.apiSecret)
		sleep(0.2)
		#balance = BN.account()["balances"]
		#src.logging(7, """LTC, BTC, BNB\t$(balance[2]["free"])\t$(balance[1]["free"])\t$(balance[5]["free"])""")
		#src.logging(6, """LTC, BTC, BNB\t$(balance[2]["free"]-BalanceLTC)\t$(balance[1]["free"]-BalanceBTC)\t$(balance[5]["free"]-BalanceBNB)""")
		#global BalanceLTC = balance[2]["free"]
		#global BalanceBTC = balance[1]["free"]
		#global BalanceBNB = balance[5]["free"]
	end
	if (LTC > 10.100023)
		@async BN.executeOrder(BN.createOrder("LTCBNB", "sell"; quantity = pLTCBNB, orderType="MARKET"), BN.apiKey, BN.apiSecret)
		sleep(0.05)
		@async BN.executeOrder(BN.createOrder("BNBBTC", "sell"; quantity = pBNBBTC, orderType="MARKET"), BN.apiKey, BN.apiSecret)
		sleep(0.05)
		@async BN.executeOrder(BN.createOrder("LTCBTC", "buy"; quantity = pLTCBTC, orderType="MARKET"), BN.apiKey, BN.apiSecret)
		sleep(0.2)
		#balance = BN.account()["balances"]
		#src.logging(7, """LTC, BTC, BNB\t$(balance[2]["free"])\t$(balance[1]["free"])\t$(balance[5]["free"])""")
		#src.logging(6, """LTC, BTC, BNB\t$(balance[2]["free"]-BalanceLTC)\t$(balance[1]["free"]-BalanceBTC)\t$(balance[5]["free"]-BalanceBNB)""")
		#global BalanceLTC = balance[2]["free"]
		#global BalanceBTC = balance[1]["free"]
		#global BalanceBNB = balance[5]["free"]
	end
end

src.logging(9, "Арбитр вышел из цикла")
