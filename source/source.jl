# В этом файле размещены вспомогательные функции.

module src
using Dates, JSON, CSV, DataFrames, LibPQ

    """
        logging(relevance::Integer, str::String)

    Записать событие в лог-файл.
    Фиксирует время событие.
    Можно присвоить цифру от 0 до 9 для убодного поиска.
    # Examples
    ```julia-repl
    julia> logging(2, "Start")
    [2020-07-02T15:42:13.14][2]     Start
    ```
    """
    function logging(relevance::Integer, str::String)
        if -1 < relevance < 10
            try
                open("./arb/logs/logs", "a") do io
                    write(io, "[$(now(UTC))][$relevance] \t$str \n")
                end
            catch
                @error("Не удаётся открыть лог файл") # "julia > book &". При это команде, эта строка выбьется в консоль
                println("Не удаётся открыть лог файл") # А эта в файл.
            end
        else
            @error("Не правильный приоритет! Логи не ведутся!")
            println("Не правильный приоритет! Логи не ведутся!")
        end
    end

    function logging(namefile::String, relevance::Integer, str::String)
        if -1 < relevance < 10
            try
                open("./arb/logs/$namefile", "a") do io
                    write(io, "[$(now(UTC))][$relevance] \t$str \n")
                end
            catch
                @error("Не удаётся открыть лог файл") # "julia > book &". При это команде, эта строка выбьется в консоль
                println("Не удаётся открыть лог файл") # А эта в файл.
            end
        else
            @error("Не правильный приоритет! Логи не ведутся!")
            println("Не правильный приоритет! Логи не ведутся!")
        end
    end


    """
        balanceupd(balance :: Vector)

    Обновляет в pg балансы LTC, BTC и BNB.
    # Examples
    ```julia-repl
    julia> balance(BN.account()["balances"])
    ```
    """
    function balanceupd(balance :: Vector)
        try
            LibPQ.Connection(data()["connPG"]) do conn
                execute(conn, """	UPDATE  arb_config
                                        SET		int = $(balance[2]["free"])
                				        WHERE parametr = 'LTC_Balance';""")

                execute(conn, """	UPDATE  arb_config
                                        SET		int = $(balance[1]["free"])
                                        WHERE parametr = 'BTC_Balance';""")

                execute(conn, """	UPDATE  arb_config
                                        SET		int = $(balance[5]["free"])
                				        WHERE parametr = 'BNB_Balance';""")
            end
        catch
            @error("Не обновляет балансы в pg") # "julia > book &". При это команде, эта строка выбьется в консоль
            println("Не обновляет балансы в pg") # А эта в файл.
        end
    end

    """
        tradelog(inf::Dict)

    Функция записывает ордер в csv-файл или pg. Настраивается конфигом.
    # Examples
    ```julia-repl
    julia> BN.executeOrder(BN.createOrder("BNBBTC", "sell"; quantity = 0.11, orderType="MARKET"), BN.apiKey, BN.apiSecret)
    *in file or pg
    │ Row │ Date                    │ Pair   │ Side   │ Type   │ Quontity   │ Price      │ Total       │ Fee        │ Status │
    │     │ DateTime                │ String │ String │ String │ String     │ String     │ Float64     │ String     │ String │
    ├─────┼─────────────────────────┼────────┼────────┼────────┼────────────┼────────────┼─────────────┼────────────┼────────┤
    │ 1   │ 2020-07-04T11:06:32.226 │ BNBBTC │ SELL   │ MARKET │ 0.11000000 │ 0.00169310 │ 0.000186241 │ 0.00008415 │ FILLED │

    ```
    """
    function tradelog(inf::Dict)
        if src.config()["logging"]["orders in pg"] == 1
            LibPQ.Connection(data()["connPG"]) do conn
                execute(conn, """	INSERT INTO arb_ordershistory
                                    VALUES ('$(unix2datetime(inf["transactTime"]/1000))', '$(inf["symbol"])', '$(inf["side"])', '$(inf["type"])',
                                    '$(inf["fills"][1]["qty"])', '$(inf["fills"][1]["price"])',
                                    '$(parse(Float64, inf["fills"][1]["qty"])*parse(Float64, inf["fills"][1]["price"]))',
                                    '$(inf["fills"][1]["commission"])', '$(inf["status"])')""")
            end
        end
        if src.config()["logging"]["orders in csv"] == 1
            ff = DataFrame(Date = unix2datetime(inf["transactTime"]/1000), Pair = inf["symbol"], Side = inf["side"], Type = inf["type"], Quontity = inf["fills"][1]["qty"], Price = inf["fills"][1]["price"], Total = parse(Float64, inf["fills"][1]["qty"])*parse(Float64, inf["fills"][1]["price"]), Fee = inf["fills"][1]["commission"], Status = inf["status"])
            try
                CSV.write("./arb/logs/orders.csv", ff; append=true)
            catch
                @error("Не удалось записать ордер в orders.csv")
                logging(8, "Не удалось записать ордер в orders.csv")
            end
        end
    end

    """
        symbols()

    Это все торгуемые пары Бинанса, разбитые на base и quote currency.
    # Examples
    ```julia-repl
    julia> symbols()["LTCBTC"]
    Dict{String, Any} with 2 entries
    "quote" => "BTC"
    "base" => "LTC"
    ```
    """
    function symbols()
        try
            open("./arb/source/symbols.json", "r+") do io
                global symbols
                json = String(read(io))
                symbol = JSON.parse(json)
            end
        catch
            @error("Не удаётся открыть файл symbols.json")
            logging(8, "Не удаётся открыть файл symbols.json")
        end
    end

    """
        config()

    Это конфиг проекта, сюда выводятся переменные управления проектом.
    # Examples
    ```julia-repl
    julia> config()["logging"]["orders in csv"]
    1
    ```
    """
    function config()
        try
            open("./arb/config/config.json", "r+") do io
                json = String(read(io))
                JSON.parse(json)
            end
        catch
            @error("Не удаётся открыть файл config.json")
            logging(8, "Не удаётся открыть файл config.json")
        end
    end

    """
        data()

    Файл с доступами и паролями. Загружается вручную.

    """
    function data()
        try
            open("./local/data.json", "r+") do io
                json = String(read(io))
                JSON.parse(json)
            end
        catch
            @error("Не удаётся открыть файл data.json")
            logging(8, "Не удаётся открыть файл data.json")
        end
    end
end
