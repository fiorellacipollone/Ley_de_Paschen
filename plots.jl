module Plotter
    export graph_comparative

    using LaTeXStrings
    using Plots
    using LsqFit
    using DataFrames, XLSX
    using Statistics
    const DF = DataFrame

    function graph_comparative(df, filtro, subject_data, filtro_label; indice=1)
        sf, gsd = group_comparative(df, :filtro, :subject_data, indice)
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