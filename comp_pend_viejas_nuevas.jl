using LsqFit
using Plots
using Statistics

gr()

# =========================================================
# DATOS
# =========================================================

# =========================================================
# 25 mm
# =========================================================

p253 = [5.90E-02,
7.40E-02,
8.40E-02,
9.10E-02,
9.70E-02,
1.00E-01,
1.40E-01,
1.80E-01,
2.50E-01,
3.40E-01,
3.90E-01,
4.80E-01,
5.90E-01,
6.70E-01,
7.20E-01]

V253 = [566,
426,
390,
380,
372,
362,
337,
335,
351,
382,
399,
434,
473,
506,
539]


p251 = [0.064, 0.089, 0.051, 0.049, 0.094, 0.072, 0.13, 0.26,
        0.35, 0.57, 0.47, 0.38, 0.81, 0.69, 0.18, 0.21]

V251 = [450, 379, 566, 586, 363, 414, 344, 361,
        390, 471, 445, 403, 574, 520, 357, 347]


p252 = [0.082, 0.076, 0.069, 0.053, 0.087, 0.091, 0.094,
        0.100, 0.130, 0.150, 0.190, 0.220, 0.270, 0.340,
        0.400, 0.460, 0.520, 0.600, 0.670]

V252 = [407, 415, 436, 565, 390, 380, 379, 370, 345,
        336, 337, 344, 358, 381, 401, 419, 433, 476, 498]


# =========================================================
# 35 mm
# =========================================================

p351 = [0.043, 0.052, 0.081, 0.06, 0.069, 0.13, 0.10, 0.088,
        0.26, 0.42, 0.33, 0.62, 0.68, 0.21, 0.52, 0.18]

V351 = [544, 427, 345, 392, 365, 331, 332, 347,
        390, 469, 426, 552, 599, 388, 510, 351]


p352 = [0.052, 0.067, 0.073, 0.082, 0.089, 0.094, 0.110,
        0.140, 0.210, 0.250, 0.290, 0.340, 0.420, 0.460,
        0.520, 0.570, 0.620]

V352 = [484, 403, 392, 368, 367, 358, 347, 349, 366,
        376, 397, 412, 454, 474, 503, 529, 546]

p353= [7.80E-02,
6.80E-02,
8.30E-02,
8.90E-02,
9.20E-02,
1.00E-01,
1.20E-01,
1.60E-01,
1.90E-01,
3.10E-01,
3.80E-01,
4.20E-01,
5.10E-01,
6.20E-01,
2.20E-01]

V353 = [356,
380,
350,
345,
346,
339,
335,
339,
349,
403,
432,
459,
490,
555,
369]


# =========================================================
# MODELO
# =========================================================

function paschen(pd, p)

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


recta(x, p) = p[1] .* x .+ p[2]


# =========================================================
# AJUSTE PASCHEN + PENDIENTE
# =========================================================

function analizar_curva(pd, V, n_deriv)

    orden = sortperm(pd)

    pd = pd[orden]
    V = V[orden]

    p0 = [300.0, 1.0, 0.5]

    lower = [1.0, -20.0, -1.0]
    upper = [5000.0, 20.0, 5.0]

    fit = curve_fit(
        paschen,
        pd,
        V,
        p0,
        lower = lower,
        upper = upper
    )

    pd_fit = range(
        minimum(pd),
        maximum(pd),
        length = 1000
    )

    V_fit = paschen(pd_fit, fit.param)

    xder = collect(
        pd_fit[end-n_deriv+1:end]
    )

    yder = collect(
        V_fit[end-n_deriv+1:end]
    )

    fit_lin = curve_fit(
        recta,
        xder,
        yder,
        [1.0, mean(yder)]
    )

    m, b = fit_lin.param

    return (
        fit,
        pd_fit,
        V_fit,
        xder,
        yder,
        m,
        b
    )
end


# =========================================================
# INCERTIDUMBRE DE m
# =========================================================

function pendiente_con_incertidumbre(pd, fit, n_deriv)

    pars = fit.param
    errs = stderror(fit)

    B, θ, k = pars
    dB, dθ, dk = errs

    pd_fit = range(
        minimum(pd),
        maximum(pd),
        length = 1000
    )

    V_fit = paschen(pd_fit, pars)

    xder = collect(
        pd_fit[end-n_deriv+1:end]
    )

    yder = collect(
        V_fit[end-n_deriv+1:end]
    )

    fit_lin = curve_fit(
        recta,
        xder,
        yder,
        [1.0, mean(yder)]
    )

    m0 = fit_lin.param[1]

    pendientes = Float64[]

    for sB in (-1, 1),
        sθ in (-1, 1),
        sk in (-1, 1)

        pars2 = [
            B + sB*dB,
            θ + sθ*dθ,
            k + sk*dk
        ]

        V2 = paschen(pd_fit, pars2)

        if any(isnan.(V2)) || any(isinf.(V2))
            continue
        end

        yder2 = collect(
            V2[end-n_deriv+1:end]
        )

        fit_lin2 = curve_fit(
            recta,
            xder,
            yder2,
            [m0, mean(yder2)]
        )

        push!(
            pendientes,
            fit_lin2.param[1]
        )
    end

    if isempty(pendientes)
        return m0, NaN
    end

    Δm = maximum(
        abs.(pendientes .- m0)
    )

    return m0, Δm
end


# =========================================================
# PARÁMETRO
# =========================================================

n_deriv = 300


# =========================================================
# SELECCIÓN
# =========================================================
#
# (distancia, cantidad de experimentos)
#
# Ejemplo:
#
# (25,4) -> usa p251, p252, p253 y p254
# (35,2) -> usa p351 y p352
#
# Podés poner cualquier distancia que tengas cargada.
# =========================================================

seleccion = [
    (25, 3),
    (35, 3)
]


# =========================================================
# FUNCIÓN PARA OBTENER LOS DATOS
# =========================================================

function obtener_experimento(d, id)

    nombre_p = Symbol("p$(d)$(id)")
    nombre_V = Symbol("V$(d)$(id)")

    p = getfield(Main, nombre_p)
    V = getfield(Main, nombre_V)

    return p, V
end


# =========================================================
# RESULTADOS
# =========================================================

d_vals = Float64[]
m_vals = Float64[]
dm_vals = Float64[]
exp_ids = Int[]


for (d, cantidad) in seleccion

    for id in 1:cantidad

        p, V = obtener_experimento(d, id)

        pd = p .* d

        res = analizar_curva(
            pd,
            V,
            n_deriv
        )

        m, dm = pendiente_con_incertidumbre(
            pd,
            res[1],
            n_deriv
        )

        push!(d_vals, d)
        push!(m_vals, m)
        push!(dm_vals, dm)
        push!(exp_ids, id)

        println(
            "d = $d mm (exp $id) -> m = $m ± $dm"
        )
    end
end


# =========================================================
# COLORES
# =========================================================

colores = Dict(
    1 => :blue,
    2 => :red,
    3 => :green,
    4 => :orange,
    5 => :purple,
    6 => :brown
)


# =========================================================
# GRÁFICO FINAL
# =========================================================

# 1. Calcular el ajuste lineal sobre los logaritmos base 10
log_d = log10.(d_vals)
log_m = log10.(m_vals)

# Matriz de diseño para la regresión: log(m) = log(alpha) + n * log(d)
X = hcat(ones(length(log_d)), log_d)
beta = X \ log_m

# Extraer parámetros
log_alpha_fit = beta[1]
n_exp = beta[2]
alpha_fit = 10^log_alpha_fit

println("Parámetros del ajuste: n = $(round(n_exp, digits=3)), log(alpha) = $(round(log_alpha_fit, digits=3))")

# 2. Generar la curva continua para el gráfico en escala normal
d_fit_pd = range(minimum(d_vals)-2, maximum(d_vals)+2, length=100)
m_fit_pd = alpha_fit .* (d_fit_pd .^ n_exp)

# 3. Configurar y construir el gráfico
p_final = plot(
    xlabel = "Distancia d [mm]",
    ylabel = "Pendiente m (dV/d(p·d)) [V / (p·d)]",
    title = "Pendiente m vs d (Ajuste Log-Log)",
    legend = :topright,
    grid = true, gridalpha = 0.5
)

# Graficar los puntos de cada experimento
for i in eachindex(d_vals)
    scatter!(
        p_final,
        [d_vals[i]],
        [m_vals[i]],
        yerror = [dm_vals[i]],
        ms = 6,
        color = colores[exp_ids[i]],
        label = false
    )

    annotate!(
        p_final,
        d_vals[i] + 0.5,
        m_vals[i],
        text("$(exp_ids[i])", 10)
    )
end

# Graficar la curva de ajuste sobre los puntos
plot!(
    p_final,
    d_fit_pd,
    m_fit_pd,
    color = :red,
    linewidth = 2,
    label = "Ajuste: m = $(round(alpha_fit, digits=1))·d^$(round(n_exp, digits=3))"
)

display(p_final)