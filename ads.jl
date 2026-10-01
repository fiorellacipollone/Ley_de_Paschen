using Plots
using DataFrames, XLSX
const DF = DataFrame # para no tener que llamar al paquete por el nombre completo

excel = "C:/Users/Brio/Documents/datos.xlsx"
df = DF(XLSX.readtable(excel, "Hoja1"))

df.pd = df.d_mm .* df.P_torr

scatter(df.pd, df.V_subida, xlabel="pd", ylabel="voltaje subida")


# # Guardar el DataFrame en un nuevo archivo Excel
# XLSX.writetable("C:/Users/Brio/Documents/datos.xlsx", df)