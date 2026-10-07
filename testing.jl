using Revise

include("functions.jl")
include("xlsx_analisis.jl")
include("plots.jl")

using .AnalisisPaschen, .Plotter, .DataProcessor

# Código global directo sin depender de main()
datfr = DataProcessor.excel_readdata_pd("Ley_de_Paschen/datos.xlsx", "Hoja1")

# Uso de Base.invokelatest para evitar el problema de world age, 
# y corrección de 'indice=22' como keyword argument.
dia, dist = Base.invokelatest(DataProcessor.group_comparative, datfr, :date, :d_mm, indice=6)

println(typeof(dia), typeof(dist))