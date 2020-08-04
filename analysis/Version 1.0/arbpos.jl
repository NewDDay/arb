cd("$(@__DIR__)/..")

using Plots, Dates

open("../logs/logs", "r") do io
    global file = String(read(io))
end

rx = r".*\[4\].*"
m = eachmatch(rx, file)
f = collect(m)

rx_time = r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}|\.\d*"
rx_real = r"\t\d.*"
times = DateTime[]
number = Float64[]
limit = Float64[]
for x in f
    m = match(rx_time, x.match)
    #println(m)
    n = match(rx_real, x.match)
    #println(n)
    num = parse(Float64, n.match)
    if num > 4
        num = num - 10
    end
    tt = DateTime(m.match)
    if tt > l && tt < ll
        push!(times, tt)
        push!(number, num)
        push!(limit, 0.100023)
    end
end

times
number

pl = plot(times, [number, limit], fmt = :png)

savefig( "131233.pdf")

l = DateTime("2020-07-20T18:20:00")
ll = DateTime("2020-07-20T18:26:00")
