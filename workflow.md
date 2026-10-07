# Arquitectura y Workflow del Proyecto: Ley de Paschen

Este proyecto está diseñado bajo una arquitectura modular en Julia para automatizar la lectura de datos experimentales, el procesamiento físico y la generación de gráficos, eliminando la carga manual de datos.

---

## 📁 Estructura del Proyecto y Módulos

* **`datos.xlsx`** $\rightarrow$ Archivo Excel con los datos experimentales (presión, voltaje de ruptura, distancias, etc.). Se sobreescribe o lee conforme se van ejecutando los códigos completando la información.
* **`xlsx_analisis.jl`** $\rightarrow$ **Módulo de Manipulación de Datos**. Se encarga de la apertura, filtrado por fechas/tandas y extracción limpia del archivo Excel.
* **`functions.jl`** $\rightarrow$ **Módulo de Física y Modelado**. Contiene la lógica teórica del experimento (ecuación de Paschen, ajustes de parámetros, cálculo de incertezas y modelos modificados).
* **`plots.jl`** $\rightarrow$ **Módulo de Visualización**. Agrupa todas las funciones dedicadas a generar gráficas (curvas de Paschen, comparaciones por fecha/distancia, estilos de figuras, etc.).
* **`ads.jl`** $\rightarrow$ **Script Principal (`Main`)**. Funciona como el orquestador del proyecto. Importa los módulos necesarios y ejecuta el flujo de trabajo completo.

---

## 🔄 Flujo de Trabajo (Workflow Execution)

1. **Ingreso de datos:** Se cargan las mediciones en `datos.xlsx`[cite: 3].
2. **Ejecución principal:** Se corre `ads.jl` (el "main"), el cual realiza de forma secuencial[cite: 3]:
   * **Lectura:** Llama a `xlsx_analisis.jl` para importar y filtrar los datos del Excel.
   * **Procesamiento:** Llama a `functions.jl` para calcular $p \cdot d$, realizar los ajustes teóricos y propagar incertezas[cite: 3].
   * **Visualización:** Llama a `plots.jl` para generar y guardar las gráficas (absorbiendo las comparaciones que antes se hacían en scripts separados como `graphs_ina_day.jl`).

---

## Contenido de los módulos
### Analisis Paschen
Funciones y modelos propios del experimento.
```julia
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
```

### DataFrames
Manejo del excel con los datos experimentales.
```julia
module DataProcessor
    export printable, excel_data_pd, excel_readdata_pd, group_comparative

    using LsqFit
    using DataFrames, XLSX
    using Statistics
    const DF = DataFrame

    function printable(string)
        println(string)
    end

    "Lee la información del excel, calcula el producto pd y retorna el DataFrame con las columnas 
    con los respectivos cálculos realizados."
    function excel_readdata_pd(ruta, hoja="Hoja1")
        dat = DF(XLSX.readtable(ruta, hoja))

        # cálculo del producto pd
        dat.pd = dat.d_mm .* dat.P_torr

        return dat
    end

    "Contrastar datos sujetos a un filtro
    filtro: sobre la información que se desea filtrar (:nom_col),
    subject_data: datos sujetos al filtro"
    function group_comparative(df, filtro, subject_data; indice=1)
        # agrupar por filtro
        grupos_filtro = groupby(df, filtro)

        simple_filtro = grupos_filtro[indice]

        # obtener los datos sujetos
        grupos_subdata = groupby(grupos_filtro, subject_data)

        return simple_filtro, grupos_subdata
    end

    function latest()
        Nothing
    end
end # cierre del módulo
```

### Ploteo
Módulo con el ploteador.
```julia
module Plotter
    export graph_comparative

    using LaTeXStrings
    using Plots
    using LsqFit
    using DataFrames, XLSX
    using Statistics
    const DF = DataFrame

    function graph_comparative(df, filtro, subject_data, filtro_label; indice=1)
        filtro_plot = sf.subject_data[indice]

        # inicializar gráfica
        grafica_comparativa = plot(
            xlabel=L"pd ", 
            ylabel=L"V_{subida} ", 
            title="Fecha: $filtro_plot",
            legend=:bottomright,     
            palette=:tab10)

        for (i,g) in enumerate(gsd)
            distancia = g.d_mm[1]

            scatter!(grafica_comparativa, g.pd, g.V_subida, label="Datos $filtro_label = $subject_data", color=i)

            # incluir el ajuste
            try
                x_dense = range(minimum(g.pd), maximum(g.pd), length=100)
                ajuste = curve_fit(AP.paschen, g.pd, g.V_subida, p0, lower=[0.0, -10.0, 0.0])
                y_fit = AP.paschen(x_dense, ajuste.param)
                
                # Curva de ajuste con el MISMO color i
                plot!(grafica_comparativa, x_dense, y_fit, label="Ajuste d = $distancia mm", color=i, lw=2)
            catch e
                println("No se pudo realizar el ajuste para la distancia $distancia mm")
            end
        end # cierre bucle

        display(grafica_comparativa)
    end # cierre graficador
end # cierre módulo
```