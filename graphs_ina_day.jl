using LaTeXStrings
using Plots
using LsqFit
using DataFrames, XLSX
using Statistics
const DF = DataFrame # para no tener que llamar al paquete por el nombre completo

# cargo el archivo con el modulo 
include("functions.jl")
using .AnalisisPaschen # importo todas las funciones de modelos y ajustes

const AP = AnalisisPaschen

p0 = [100.0, -0.4, 0.0]

excel = "Ley_de_Paschen/datos.xlsx"
df = DF(XLSX.readtable(excel, "Hoja1"))

df.pd = df.d_mm .* df.P_torr

# 1. Agrupar el DataFrame únicamente por fecha
grupos_fecha = groupby(df, :date)

# 2. Seleccionar el día que deseas graficar (por ejemplo, el primer día)
# Puedes cambiar el índice [1] o buscar la fecha que necesites
datos_un_dia = grupos_fecha[6]
fecha_plot = datos_un_dia.date[6]

# 06/10 = indice 6

# 3. Agrupar los datos de ese día específico por distancia
grupos_distancia = groupby(datos_un_dia, :d_mm)

# 4. Iniciar la gráfica comparativa (el lienzo base)
grafica_comparativa = plot(
    xlabel=L"pd ", 
    ylabel=L"V_{subida} ", 
    title="Curvas de Paschen - Fecha: $fecha_plot",
    legend=:bottomright,     
    palette=:tab10
)

# 4. Iterar usando enumerate para obtener un índice i para cada distancia
for (i, g) in enumerate(grupos_distancia)
    distancia = g.d_mm[1]
    
    # Puntos experimentales con el color i
    scatter!(grafica_comparativa, g.pd, g.V_subida, label="Datos d = $distancia mm", color=i)
    
    # Ajuste de Paschen
    try
        x_dense = range(minimum(g.pd), maximum(g.pd), length=100)
        ajuste = curve_fit(AP.paschen, g.pd, g.V_subida, p0, lower=[0.0, -10.0, 0.0])
        y_fit = AP.paschen(x_dense, ajuste.param)
        
        # Curva de ajuste con el MISMO color i
        plot!(grafica_comparativa, x_dense, y_fit, label="Ajuste d = $distancia mm", color=i, lw=2)
    catch e
        println("No se pudo realizar el ajuste para la distancia $distancia mm")
    end
end

# 5. Mostrar la gráfica final
display(grafica_comparativa)