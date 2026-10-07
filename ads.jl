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
df = DF(XLSX.readtable("Ley_de_Paschen/datos.xlsx", "Hoja1"))

df.pd = df.d_mm .* df.P_torr

# Agrupa combinando la fecha y la distancia
grupos = groupby(df, [:date, :d_mm]) # actualmente 06/10 arranca en 18
c = grupos[22]

# println(grupos)

g1 = scatter(c.pd, c.V_subida, xlabel=L"pd", ylabel=L"V_{subida}", label="fecha: $(c.date[1]), dist: $(c.d_mm[1])mm")

# valores de ajuste
x_dense = range(minimum(c.pd), maximum(c.pd), length=100) # x densos
# El parámetro `lower` indica los valores mínimos permitidos para [B, C, k]
ajuste = curve_fit(AP.paschen, c.pd, c.V_subida, p0, lower=[0.0, -10.0, 0.0]) # aplico ajuste con modelo de Paschen
y_fit = AP.paschen(x_dense, ajuste.param)

#ploteo el ajuste
plot!(g1, x_dense, y_fit, label="ajuste de Paschen")