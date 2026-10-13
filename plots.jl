module Plotter
    export graph_comparative, plot_latest_all_paschen

    using LaTeXStrings
    using Plots
    using LsqFit
    using DataFrames, XLSX
    using Statistics
    const DF = DataFrame

    import Main.AnalisisPaschen as AP

    function graph_comparative(df, filtro, subject_data, filtro_label; indice=1)
        filtro_plot = sf.subject_data[indice]

        # inicializar gráfica
        grafica_comparativa = plot(
            xlabel=L"pd ", 
            ylabel=L"V_{subida}", 
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
    
    function plot_latest_all_paschen(df_recientes)
        # Inicializar la gráfica general vacía
        grafica = plot(
            xlabel=L"pd [Torr·mm]", 
            ylabel=L"V_{subida} [V]", 
            title="Medición más actual por distancia",
            legend=:outertopright, # Mueve la leyenda afuera para que no tape las curvas
            legendfontsize=8,
            size=(850,550),
            palette=:tab10
        )
        
        # Agrupar el DataFrame filtrado por cada distancia
        grupos_distancia = groupby(df_recientes, :d_mm)
        
        # Iterar sobre cada grupo (cada distancia)
        for (i, grupo) in enumerate(grupos_distancia)
            dist = grupo.d_mm[1]
            fecha = grupo.date[1]
            
            # Formatear la etiqueta para que quede como tu esquema "10mm - 08/09"
            etiqueta = "$(dist)mm - $(fecha)"
            
            # Ploteo de puntos usando el índice 'i' para fijar el color
            scatter!(grafica, grupo.pd, grupo.V_subida, label="Datos " * etiqueta, color=i)
            
            # Ajuste y ploteo de la curva teórica usando el mismo color 'i'
            try
                fit, pars, errs, σ_res = AP.ajustar_paschen(grupo.pd, grupo.V_subida)
                
                x_dense = range(minimum(grupo.pd), maximum(grupo.pd), length=200)
                y_fit = AP.paschen(x_dense, pars)
                
                plot!(grafica, x_dense, y_fit, label="Ajuste " * etiqueta, color=i, lw=2)
            catch e
                println("Fallo al ajustar d = $dist mm. Causa: $e")
            end
        end
        
        # Mostrar la gráfica final con todas las curvas superpuestas
        display(grafica)
    end

end # cierre módulo