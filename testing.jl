# Carga de módulos
include("xlsx_analisis.jl")
include("functions.jl")
include("plots.jl")

using .DataProcessor
using .AnalisisPaschen
using .Plotter

ruta_excel = "G:/Mi unidad/programacióm/proyectos_física/Ley_de_Paschen/datos.xlsx"
df_completo = DataProcessor.excel_readdata_pd(ruta_excel, "Hoja1")

# Distancias
distancia_deseada = [10.0,15.0,20.0,25.0,30.0,35.0,40.0]  

for didi in distancia_deseada
    df_filtrado, fecha_max = DataProcessor.latest(df_completo, didi)

    # 5. Graficar si se encontraron datos
    if !isempty(df_filtrado)
        Plotter.plot_latest_paschen(df_filtrado, didi, fecha_max)
    end
end