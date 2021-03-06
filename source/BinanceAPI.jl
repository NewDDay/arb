module BN
    cd(@__DIR__)
    using HTTP, CSV, SHA, JSON, Dates, Printf
    # base URL of the Binance API
    BINANCE_API_REST = "https://api.binance.com/"
    BINANCE_API_TICKER = string(BINANCE_API_REST, "api/v3/ticker/")
    BINANCE_API_DEPTH = string(BINANCE_API_REST, "api/v3/depth")
    BINANCE_API_KLINES = string(BINANCE_API_REST, "/api/v3/klines")
    BINANCE_API_USER_DATA_STREAM = string(BINANCE_API_REST, "api/v3/userDataStream")
    BINANCE_API_WS = "wss://stream.binance.com:9443/ws/"
    #BINANCE_API_STREAM = "wss://stream.binance.com:9443"
    cd("$(@__DIR__)/../..")
    include("./source.jl")
    file = JSON.parsefile("./local/data.json")
    global apiKey = file["public"]
    global apiSecret = file["private"]

    function dict2Params(dict::Dict)
        params = ""
        for kv in dict
            params = string(params, "&$(kv[1])=$(kv[2])")
        end
        params[2:end]
    end
    function timestamp()
        Int64(floor(Dates.datetime2unix(Dates.now(Dates.UTC)) * 1000))
    end
    function doSign(queryString, apiSecret )
        bytes2hex(hmac_sha256(Vector{UInt8}(apiSecret), Vector{UInt8}(queryString)))
    end
    function r2j(response)
        JSON.parse(String(response))
    end
    function ping()
        r = HTTP.request("GET", string(BINANCE_API_REST, "api/v1/ping"))
        r.status
    end
    function serverTime()
        r = HTTP.request("GET", string(BINANCE_API_REST, "api/v1/time"))
        r.status
        result = r2j(r.body)
        Dates.unix2datetime(result["serverTime"] / 1000), result["serverTime"]
    end
    function get24HR()
        r = HTTP.request("GET", string(BINANCE_API_TICKER, "24hr"))
        r2j(r.body) #Статистика изменения цен за 24 часа
    end
    function getDepth(symbol::String; limit=100) # 500(5), 1000(10)
        r = HTTP.request("GET", string(BINANCE_API_DEPTH, "?symbol=", symbol,"&limit=",limit))
        r2j(r.body)
    end
    function coinList()
        headers = Dict("X-MBX-APIKEY" => apiKey)
        r = HTTP.request("GET", string(BINANCE_API_REST, "/sapi/v1/mining/pub/coinList"), headers)
        r2j(r.body)
    end
    function get24HR(symbol::String)
        r = HTTP.request("GET", string(BINANCE_API_TICKER, "24hr?symbol=", symbol))
        r2j(r.body) #Статистика изменения цен за 24 часа
    end
    function getAllPrices()
        r = HTTP.request("GET", string(BINANCE_API_TICKER, "price"))
        r2j(r.body)
    end
    function getAllBookTickers()
        r = HTTP.request("GET", string(BINANCE_API_TICKER, "allBookTickers"))
        r2j(r.body)
    end
    function getExchangeInfo()
        r = HTTP.request("GET", "https://www.binance.com/api/v1/exchangeInfo")
        r2j(r.body)
    end
    function getMarket()
        r = HTTP.request("GET", "https://www.binance.com/exchange/public/product")
        r2j(r.body)["data"]
    end
    function getMarket(symbol::String)
        r = HTTP.request("GET", string("https://www.binance.com/exchange/public/product?symbol=", symbol))
        r2j(r.body)["data"]
    end
    function getKlines(symbol; startDateTime=nothing, endDateTime=nothing, interval="1m")
        query = string("?symbol=", symbol, "&interval=", interval)
        if startDateTime != nothing && endDateTime != nothing
            startTime = Printf.@sprintf("%.0d",Dates.datetime2unix(startDateTime) * 1000)
            endTime = Printf.@sprintf("%.0d",Dates.datetime2unix(endDateTime) * 1000)
            query = string(query, "&startTime=", startTime, "&endTime=", endTime)
        end
        r = HTTP.request("GET", string(BINANCE_API_KLINES, query))
        r2j(r.body)
    end
    function wsFunction(channel::Channel, ws::String, symbol::String)
        HTTP.WebSockets.open(string(BINANCE_API_WS, lowercase(symbol), ws); verbose=false) do io
            while !eof(io)
                json = r2j(readavailable(io))
                get!(json, "symbol", symbol)
                put!(channel, json)
            end
        end
    end
    function wsTradeAgg(channel::Channel, symbol::String)
        wsFunction(channel, "@aggTrade", symbol)
    end
    function wsTradeRaw(channel::Channel, symbol::String)
        wsFunction(channel, "@trade", symbol)
    end
    function wsDepth(channel::Channel, symbol::String; level=5)
        wsFunction(channel, string("@depth", level, "@100ms"), symbol)
    end
    function wsDepthDiff(channel::Channel, symbol::String)
        wsFunction(channel, "@depth", symbol)
    end
    function wsTicker(channel::Channel, symbol::String)
        wsFunction(channel, "@ticker", symbol)
    end
    function wsTicker24Hr(channel::Channel)
        HTTP.WebSockets.open(string(BINANCE_API_WS, "!ticker@arr"); verbose=false) do io
          while !eof(io);
            put!(channel, r2j(readavailable(io)))
        end
      end
    end
    function wsKline(channel::Channel, symbol::String; interval="1m")
      #interval => 1m 3m 5m 15m 30m 1h 2h 4h 6h 8h 12h 1d 3d 1w 1M
        wsFunction(channel, string("@kline_", interval), symbol)
    end
    function executeOrder(order::Dict, apiKey, apiSecret; execute=true)
        headers = Dict("X-MBX-APIKEY" => apiKey)
        query = string(BN.dict2Params(order), "&timestamp=", BN.timestamp())
        body = string(query, "&signature=", BN.doSign(query, apiSecret))
        #println(body)

        uri = "api/v3/order/test"
        if execute
            uri = "api/v3/order"
        end

        r = HTTP.request("POST", string(BN.BINANCE_API_REST, uri), headers, body)
        ord = BN.r2j(r.body)
        @async src.balanceupd(BN.account()["balances"])
        @async src.tradelog(ord)
        return ord
    end
    function cancelOrder(symbol, origClientOrderId)
        headers = Dict("X-MBX-APIKEY" => apiKey)
        query = string("recvWindow=5000&timestamp=", timestamp(),"&symbol=", symbol,"&origClientOrderId=", origClientOrderId)
        r = HTTP.request("DELETE", string(BINANCE_API_REST, "api/v3/order?", query, "&signature=", doSign(query, apiSecret)), headers)
        r2j(r.body)
    end
    function createOrder(symbol::String, orderSide::String;
        quantity::Float64=0.0, orderType::String = "LIMIT",
        price::Float64=0.0, stopPrice::Float64=0.0,
        icebergQty::Float64=0.0, newClientOrderId::String="")

          if quantity <= 0.0
              error("Quantity cannot be <=0 for order type.")
          end

          #println(now(UTC)," $orderSide => $symbol q: $quantity, p: $price ")

          order = Dict("symbol"           => symbol,
                          "side"             => orderSide,
                          "type"             => orderType,
                          "quantity"         => Printf.@sprintf("%.8f", quantity),
                          "newOrderRespType" => "FULL",
                          "recvWindow"       => 10000)

          if newClientOrderId != ""
              order["newClientOrderId"] = newClientOrderId;
          end

          if orderType == "LIMIT" || orderType == "LIMIT_MAKER"
              if price <= 0.0
                  error("Price cannot be <= 0 for order type.")
              end
              order["price"] =  Printf.@sprintf("%.8f", price)
          end

          if orderType == "STOP_LOSS" || orderType == "TAKE_PROFIT"
              if stopPrice <= 0.0
                  error("StopPrice cannot be <= 0 for order type.")
              end
              order["stopPrice"] = Printf.@sprintf("%.8f", stopPrice)
          end

          if orderType == "STOP_LOSS_LIMIT" || orderType == "TAKE_PROFIT_LIMIT"
              if price <= 0.0 || stopPrice <= 0.0
                  error("Price / StopPrice cannot be <= 0 for order type.")
              end
              order["price"] =  Printf.@sprintf("%.8f", price)
              order["stopPrice"] =  Printf.@sprintf("%.8f", stopPrice)
          end

          if orderType == "TAKE_PROFIT"
              if price <= 0.0 || stopPrice <= 0.0
                  error("Price / StopPrice cannot be <= 0 for STOP_LOSS_LIMIT order type.")
              end
              order["price"] =  Printf.@sprintf("%.8f", price)
              order["stopPrice"] =  Printf.@sprintf("%.8f", stopPrice)
          end

          if orderType == "LIMIT"  || orderType == "STOP_LOSS_LIMIT" || orderType == "TAKE_PROFIT_LIMIT"
              order["timeInForce"] = "GTC"
          end

          return order
      end

    function account()
        headers = Dict("X-MBX-APIKEY" => apiKey)

        query = string("recvWindow=10000&timestamp=", timestamp())

        r = HTTP.request("GET", string(BINANCE_API_REST, "api/v3/account?", query, "&signature=", doSign(query, apiSecret)), headers)

        if r.status != 200
            println(r)
            return status
        end

        return r2j(r.body)
    end
end
