using Plots
using DataFrames, XLSX
const DF = DataFrame # para no tener que llamar al paquete por el nombre completo

excel = "C:/Users/Brio/Documents/Ley_de_Paschen/datos.xlsx"
df = DF(XLSX.readtable(excel, "Hoja1"))

df.pd = df.d_mm .* df.P_torr

scatter(df.pd, df.V_subida, xlabel="pd", ylabel="voltaje subida")

filtro_dist = groupby(df, :d_mm) # filtro de distancias [mm]
filtro_date = groupby(df, :date) # filtro para fechas [aa/mm/dd]

d1 = filtro_dist[2]
scatter(d1.pd, d1.V_subida)

# Agrupa combinando la fecha y la distancia
grupos = groupby(df, [:date, :d_mm])
println(grupos[6])

scatter(grupos[6].pd, grupos[6].V_subida, xlabel="pd", ylabel="V_subida", label="fecha: $(grupos[6].date[1]), dist: $(grupos[6].d_mm[1])mm")
