# Carga de módulos
include("xlsx_analisis.jl")
include("functions.jl")
include("plots.jl")

using .DataProcessor
using .AnalisisPaschen
using .Plotter

# El bloque 'let' aísla las variables locales y elimina el warning de soft scope
let
    ruta_excel = "G:/Mi unidad/programacióm/proyectos_física/Ley_de_Paschen/datos.xlsx"
    df_completo = DataProcessor.excel_readdata_pd(ruta_excel, "Hoja1")

    df_ultimos = DataProcessor.latest_all(df_completo)

    if !isempty(df_ultimos)
        Plotter.plot_latest_all_paschen(df_ultimos)
    else
        println("No hay datos para graficar.")
    end
end