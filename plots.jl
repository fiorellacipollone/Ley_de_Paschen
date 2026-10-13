module Plotter
    export graph_comparative, plot_latest_paschen

    using LaTeXStrings
    using Plots
    using LsqFit
    using DataFrames, XLSX
    using Statistics
    const DF = DataFrame

    import .AnalisisPaschen as AP

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
    
    function plot_latest_paschen(df_reciente, distancia, fecha)
        # Inicializar la gráfica
        grafica = plot(
            xlabel=L"pd [Torr·mm]", 
            ylabel=L"V_subida [V]", 
            title="d = $distancia mm (Fecha: $fecha)",
            legend=:bottomright,
            palette=:tab10
        )
        
        # Scatter de los datos experimentales
        scatter!(grafica, df_reciente.pd, df_reciente.V_subida, label="Datos experimentales")

        # Ajuste teórico utilizando el módulo de Física (AnalisisPaschen)
        p0 = [300.0, 1.0, 0.5]
        try
            ajuste = curve_fit(AP.paschen, df_reciente.pd, df_reciente.V_subida, p0, lower=[1.0, -10.0, -1.0], upper=[5000.0, 10.0, 2.0])
            
            # Generar curva densa para el ploteo
            x_dense = range(minimum(df_reciente.pd), maximum(df_reciente.pd), length=200)
            y_fit = AP.paschen(x_dense, ajuste.param)
            
            plot!(grafica, x_dense, y_fit, label="Ajuste de Paschen", lw=2)
        catch e
            println("No se pudo realizar el ajuste teórico para d = $distancia mm")
        end

        display(grafica)
    end

end # cierre módulo