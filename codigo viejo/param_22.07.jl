using LsqFit
using Plots
using LinearAlgebra
using LaTeXStrings

p15 = [0.094, 0.17, 0.11, 0.22, 0.29, 0.38, 0.52, 0.56, 0.69, 0.82, 0.94]
d15 = fill(15, length(p15))
V15 = [567, 375, 458, 354, 347, 363, 392, 411, 453, 503, 560]

p20 = [0.07, 0.095, 0.081, 0.11, 0.18, 0.28, 0.33, 0.41, 0.55, 0.62, 0.74, 0.22, 0.47, 0.79, 0.91]
d20 = fill(20, length(p20))
V20 = [560, 438, 483, 390, 350, 353, 371, 393, 441, 466, 509, 357, 411, 528, 598]

p25 = [0.053, 0.065, 0.079, 0.084, 0.089, 0.13, 0.22, 0.28, 0.51, 0.67, 0.58, 0.40, 0.78]
d25 = fill(25, length(p25))
V25 = [581, 469, 402, 400, 395, 343, 351, 373, 464, 534, 499, 419, 591]

p30 = [0.047, 0.053, 0.066, 0.091, 0.10, 0.076, 0.14, 0.22, 0.30, 0.45, 0.38, 0.61, 0.68, 0.54, 0.69]
d30 = fill(30, length(p30))
V30 = [554, 471, 396, 345, 343, 375, 339, 354, 394, 459, 434, 534, 556, 514, 575]

p35 = [0.043, 0.052, 0.081, 0.06, 0.069, 0.13, 0.10, 0.088, 0.26, 0.42, 0.33, 0.62, 0.68, 0.21, 0.52, 0.18]
d35 = fill(35, length(p35))
V35 = [544, 427, 345, 392, 365, 331, 332, 347, 390, 469, 426, 552, 599, 388, 510, 351]

p40 = [0.049, 0.052, 0.067, 0.057, 0.091, 0.077, 0.20, 0.10, 0.31, 0.42, 0.53, 0.65, 0.69, 0.18, 0.24, 0.35, 0.15]
d40 = fill(40, length(p40))
V40 = [497, 428, 363, 392, 340, 351, 367, 349, 437, 486, 552, 611, 645, 375, 392, 452, 367]

p45 = [0.042, 0.046, 0.053, 0.065, 0.10, 0.071, 0.081, 0.088, 0.15, 0.23, 0.27, 0.38, 0.52, 0.60]
d45 = fill(45, length(p45))
V45 = [466, 421, 387, 353, 333, 350, 340, 344, 350, 395, 418, 470, 563, 626]

p50 = [0.043, 0.048, 0.05, 0.059, 0.072, 0.084, 0.086, 0.095, 0.10, 0.15, 0.20, 0.26, 0.34, 0.47, 0.54]
d50 = fill(50, length(p50))
V50 = [450, 406, 406, 372, 356, 351, 348, 348, 348, 361, 381, 416, 466, 542, 600]

p55 = [0.047, 0.05, 0.059, 0.072, 0.089, 0.099, 0.14, 0.24, 0.33, 0.48, 0.40]
d55 = fill(55, length(p55))
V55 = [421, 395, 375, 357, 353, 354, 368, 427, 480, 598, 531]

p60 = [0.039, 0.044, 0.049, 0.059, 0.075, 0.092, 0.11, 0.15, 0.21, 0.33, 0.45]
d60 = fill(60, length(p60))
V60 = [440, 405, 385, 361, 352, 360, 362, 386, 423, 513, 608]

gr()
#-----------------------------------------------
# Exponente
#-----------------------------------------------
n = 0.65

#-----------------------------------------------
# Incerteza en d
#-----------------------------------------------
Δd = 1.0

#-----------------------------------------------
# Modelo de Paschen
#-----------------------------------------------
function paschen(X, p)

    β, θ, κ = p

    pres = X[:,1]
    dist = X[:,2]

    x = pres .* dist.^n .+ κ

    return β .* x ./ (log.(x) .+ θ)

end

#-----------------------------------------------
# Datos
#-----------------------------------------------
datos = Dict(
    15 => (p15, d15, V15),
    20 => (p20, d20, V20),
    25 => (p25, d25, V25),
    30 => (p30, d30, V30),
    35 => (p35, d35, V35),
    40 => (p40, d40, V40),
    45 => (p45, d45, V45),
    50 => (p50, d50, V50),
    55 => (p55, d55, V55),
    60 => (p60, d60, V60)
)

#-----------------------------------------------
# Ajustes
#-----------------------------------------------
resultados = Dict()

println("\nRESULTADOS DE LOS AJUSTES\n")

for d in sort!(collect(keys(datos)))

    pdat, ddat, V = datos[d]

    X = hcat(pdat, ddat)

    p0 = [300.0, 1.0, 0.43]

    fit = curve_fit(
        paschen,
        X,
        V,
        p0,
        lower = [1.0, -10.0, -1.0],
        upper = [5000.0, 10.0, 2.0]
    )

    pars = fit.param
    errs = stderror(fit)

    σres = sqrt(sum(fit.resid.^2) / (length(V) - length(pars)))

    resultados[d] = (pars, errs, σres)

    println("d = $d mm")
    println("β = $(pars[1]) ± $(errs[1])")
    println("θ = $(pars[2]) ± $(errs[2])")
    println("κ = $(pars[3]) ± $(errs[3])")
    println("σ_res = $σres V\n")

end

#-----------------------------------------------
# Extraer resultados
#-----------------------------------------------
dvals = Float64[]

βvals = Float64[]
θvals = Float64[]
κvals = Float64[]

Δβ = Float64[]
Δθ = Float64[]
Δκ = Float64[]

for d in sort!(collect(keys(resultados)))

    pars, errs, _ = resultados[d]

    push!(dvals, d)

    push!(βvals, pars[1])
    push!(θvals, pars[2])
    push!(κvals, pars[3])

    push!(Δβ, errs[1])
    push!(Δθ, errs[2])
    push!(Δκ, errs[3])

end

#-----------------------------------------------
# Todos los ajustes
#-----------------------------------------------

pltaj = plot(
    xlabel = "p·d^n",
    ylabel = "V (V)",
    title = "Todos los ajustes",
    legend = :outerright
)

for d in sort!(collect(keys(datos)))

    pdat, ddat, V = datos[d]

    pars, _, _ = resultados[d]

    x = pdat .* ddat.^n

    scatter!(
        pltaj,
        x,
        V,
        ms = 4,
        label = "d = $d mm"
    )

    xs = range(minimum(x), maximum(x), length = 500)

    Xfit = hcat(
        xs ./ d^n,
        fill(d, length(xs))
    )

    Vf = paschen(Xfit, pars)

    plot!(
        pltaj,
        xs,
        Vf,
        lw = 2,
        label = false
    )

end

display(pltaj)
# savefig(pltaj,"todos_los_ajustes.png")

#-----------------------------------------------
# β vs d
#-----------------------------------------------
pltβ = scatter(
    dvals,
    βvals,
    xerror = fill(Δd, length(dvals)),
    yerror = Δβ,
    ms = 5,
    labelfontsize = 13,
    xlabel = "d [mm]",
    ylabel = L"\tilde{B}\ \mathrm{[V/(torr\cdot mm)]}",
    title = L"\tilde{B}\ \mathrm{vs\ distancia\ entre\ placas}",
    label = false
)

display(pltβ)

# savefig(pltβ,"B_vs_d2.png")

#-----------------------------------------------
# θ vs d
#-----------------------------------------------
pltθ = scatter(
    dvals,
    θvals,
    xerror = fill(Δd, length(dvals)),
    yerror = Δθ,
    ms = 5,
    labelfontsize = 13,
    xlabel = "d [mm]",
    ylabel = L"\tilde{C}",
    title = L"\tilde{C}\ \mathrm{vs\ distancia\ entre\ placas}",
    label = false
)

display(pltθ)
# savefig(pltθ,"C_vs_d2.png")

#-----------------------------------------------
# κ vs d
#-----------------------------------------------
pltκ = scatter(
    dvals,
    κvals,
    xerror = fill(Δd, length(dvals)),
    yerror = Δκ,
    ms = 5,
    labelfontsize = 13,
    xlabel = "d [mm]",
    ylabel = L"\tilde{k}\ \mathrm{[torr\cdot mm]}",
    title = L"\tilde{k}\ \mathrm{vs\ distancia\ entre\ placas}",
    label = false
)

display(pltκ)
# savefig(pltκ,"k_vs_d2.png")

#-----------------------------------------------
# Parámetros globales
#-----------------------------------------------
βmax = maximum(βvals)
βmin = minimum(βvals)

θmax = maximum(θvals)
θmin = minimum(θvals)

κmax = maximum(κvals)
κmin = minimum(κvals)

β = (βmax + βmin) / 2
Δβ = (βmax - βmin) / 2

θ = (θmax + θmin) / 2
Δθ = (θmax - θmin) / 2

κ = (κmax + κmin) / 2
Δκ = (κmax - κmin) / 2

println()
println("==============================")
println("PARÁMETROS GLOBALES")
println("==============================")

println("β = $β ± $Δβ")
println("θ = $θ ± $Δθ")
println("κ = $κ ± $Δκ")
