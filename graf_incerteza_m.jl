using LsqFit
using Plots
using Statistics

gr()

# =========================================================
# DATOS
# =========================================================
# p15,d15,V15
# p20,d20,V20
# ...
# p60,d60,V60

# =========================================================
# PRODUCTOS pd
# =========================================================

pd15 = p15 .* d15
pd20 = p20 .* d20
pd25 = p25 .* d25
pd30 = p30 .* d30
pd35 = p35 .* d35
pd40 = p40 .* d40
pd45 = p45 .* d45
pd50 = p50 .* d50
pd55 = p55 .* d55
pd60 = p60 .* d60

# =========================================================
# MODELO PASCHEN
# (igual al tuyo)
# =========================================================

function paschen(pd,p)

    B, θ, k = p
    x = pd .+ k

    if any(x .<= 0)
        return fill(1e20, length(pd))
    end

    denom = log.(x) .+ θ

    if any(abs.(denom) .< 1e-12)
        return fill(1e20, length(pd))
    end

    y = B .* x ./ denom

    if any(isnan.(y)) || any(isinf.(y))
        return fill(1e20, length(pd))
    end

    return y
end

# =========================================================
# MODELO LINEAL
# =========================================================

recta(x,p) = p[1] .* x .+ p[2]

# =========================================================
# AJUSTE PASCHEN
# =========================================================

function analizar_curva(pd,V,n_deriv)

    orden = sortperm(pd)

    pd = pd[orden]
    V  = V[orden]

    p0 = [300.0,1.0,0.5]
    lower = [1.0,-20.0,-1.0]
    upper = [5000.0,20.0,5.0]

    fit = curve_fit(paschen, pd, V, p0, lower=lower, upper=upper)

    pd_fit = range(minimum(pd), maximum(pd), length=1000)
    V_fit = paschen(pd_fit, fit.param)

    xder = collect(pd_fit[end-n_deriv+1:end])
    yder = collect(V_fit[end-n_deriv+1:end])

    fit_lin = curve_fit(recta, xder, yder, [1.0, mean(yder)])

    m,b = fit_lin.param

    return (fit, pd_fit, V_fit, xder, yder, m, b)
end

# =========================================================
# INCERTIDUMBRE DE m
# =========================================================

function pendiente_con_incertidumbre(pd, fit, n_deriv)

    pars = fit.param
    errs = stderror(fit)

    B, θ, k = pars
    dB, dθ, dk = errs

    pd_fit = range(minimum(pd), maximum(pd), length=1000)

    V_fit = paschen(pd_fit, pars)

    xder = collect(pd_fit[end-n_deriv+1:end])
    yder = collect(V_fit[end-n_deriv+1:end])

    fit_lin = curve_fit(recta, xder, yder, [1.0, mean(yder)])

    m0 = fit_lin.param[1]

    pendientes = Float64[]

    for sB in (-1,1), sθ in (-1,1), sk in (-1,1)

        pars2 = [B + sB*dB, θ + sθ*dθ, k + sk*dk]

        xmin = minimum(pd) + pars2[3]
        if xmin <= 0
            continue
        end

        V2 = paschen(pd_fit, pars2)

        if any(isnan.(V2)) || any(isinf.(V2))
            continue
        end

        yder2 = collect(V2[end-n_deriv+1:end])

        fit_lin2 = curve_fit(recta, xder, yder2, [m0, mean(yder2)])

        push!(pendientes, fit_lin2.param[1])
    end

    if isempty(pendientes)
        return m0, NaN
    end

    Δm = maximum(abs.(pendientes .- m0))

    return m0, Δm
end

# =========================================================
# AJUSTES
# =========================================================

n_deriv = 500

res15 = analizar_curva(pd15,V15,n_deriv)
res20 = analizar_curva(pd20,V20,n_deriv)
res25 = analizar_curva(pd25,V25,n_deriv)
res30 = analizar_curva(pd30,V30,n_deriv)
res35 = analizar_curva(pd35,V35,n_deriv)
res40 = analizar_curva(pd40,V40,n_deriv)
res45 = analizar_curva(pd45,V45,n_deriv)
res50 = analizar_curva(pd50,V50,n_deriv)
res55 = analizar_curva(pd55,V55,n_deriv)
res60 = analizar_curva(pd60,V60,n_deriv)

# =========================================================
# EXTRAER m vs d
# =========================================================

d_vals = Float64[]
m_vals = Float64[]
dm_vals = Float64[]



for (d,pd,res) in [
    (15,pd15,res15),
    (20,pd20,res20),
    (25,pd25,res25),
    (30,pd30,res30),
    (35,pd35,res35),
    (40,pd40,res40),
    (45,pd45,res45),
    (50,pd50,res50),
    (55,pd55,res55),
    (60,pd60,res60)
]

    m, dm = pendiente_con_incertidumbre(pd, res[1], n_deriv)

    push!(d_vals, d)
    push!(m_vals, m)
    push!(dm_vals, dm)

    println("d = $d mm -> $m ± $dm")
end

# =========================================================
# LOG-LOG
# =========================================================

logd = log.(d_vals)
logm = log.(m_vals)

σlogm = dm_vals ./ m_vals

Δd = 1.0

σlogd = Δd ./ d_vals


# =========================================================
# AJUSTE POTENCIA
# =========================================================

fit = curve_fit(recta, logd, logm, [1.0, mean(logm)])
a, b = fit.param

errs = stderror(fit)

Δa = errs[1]
Δb = errs[2]

println()
println("================================")
println("AJUSTE POTENCIA")
println("================================")
println("a = ", round(a,digits=4), " ± ", round(Δa,digits=4))

K = exp(b)

println("K = ", round(K,digits=4))
println()
println("m = K d^a")
println("m = ", round(K,digits=4),
        " d^(",
        round(a,digits=4),
        " ± ",
        round(Δa,digits=4),
        ")")

errs = stderror(fit)

Δa = errs[1]
Δb = errs[2]

K = exp(b)
ΔK = K * Δb
println("a = ", round(a,digits=4),
        " ± ",
        round(Δa,digits=4))

println("K = ", round(K,digits=4),
        " ± ",
        round(ΔK,digits=4))
# =========================================================
# GRÁFICO FINAL
# =========================================================

plot(
    logd,
    logm,
    xerror = σlogd,
    yerror = σlogm,
    seriestype = :scatter,
    ms = 5,
    xlabel = "log(d)",
    ylabel = "log(m)",
    title = "Ajuste lineal log(m) vs log(d)",
    label = "Datos"
)
plot!(
    logd,
    recta(logd,[a,b]),
    lw=2,
    label=false
)

display(current())
#savefig("mvsd.png")