module AnalisisPaschen
    export paschen, analizar_curva, ajustar_paschen

    function paschen(pd, p)
        # valores
        B, C, k = p
        # modelo
        x = pd .+ k
        denom = log.(x) .+ C

        return B .* x ./ denom
    end

    function ajustar_paschen(pd, V)

        p0 = [300.0, 1.0, 0.5]
        lower = [1.0, -10.0, -1.0]
        upper = [5000.0, 10.0, 2.0]

        fit = curve_fit(
            paschen,
            pd,
            V,
            p0,
            lower = lower,
            upper = upper)

        pars = fit.param
        errs = stderror(fit)

        N = length(V)
        npar = length(pars)

        σ_res = sqrt(
            sum(fit.resid.^2) / (N - npar))

        return fit, pars, errs, σ_res

    end

    function recta(x, p)
        m, b = p
        return m .* x .+ b
    end

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
end # cierra el modulo