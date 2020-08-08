cd("$(@__DIR__)")

using Plots, Dates, CSV, DataFrames

file = DataFrame(CSV.file("uptLTCBTC_1"))

times = Time[]
upt = Integer[]
rx_time = r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}|\.\d*"
m = match(rx_time, file[1][1])
ttold = parse(DateTime, m.match)
i = 0
println(" -  - - - - - - -- ")
for x in eachrow(file)
    global ttold, i
    m = match(rx_time, x[1])
    tt = parse(DateTime, m.match)
    #println(tt, " - ", ttold)
    if tt == ttold
        i = i + 1
    end
    if tt > (ttold + Second(1))
        while tt != (ttold + Second(1))
            ttold = ttold + Second(1)
            push!(times, ttold)
            push!(upt, 0)
            #println(ttold, " - ", 0)
        end
    end
    if tt == (ttold + Second(1))
        push!(times, ttold)
        push!(upt, i)
        ttold = tt
        #println(i)
        i = 1
    end
end


plot!(title = "upt/sec\n3 websocket channel", xlabel = "time", ylabel = "uptdates")
plot(times, upt, lab = "")

upt
cumsum(upt)
