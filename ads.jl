using LaTeXStrings
using Plots
using LsqFit
using DataFrames, XLSX
const DF = DataFrame # para no tener que llamar al paquete por el nombre completo

function paschen(pd, p)

    B, C, k = p

    x = pd .+ k
    denom = log.(x) .+ C

    return B .* x ./ denom

end

p0 = [100.0, -0.4, 0.0]

excel = "C:/Users/Brio/Documents/Ley_de_Paschen/datos.xlsx"
df = DF(XLSX.readtable(excel, "Hoja1"))

df.pd = df.d_mm .* df.P_torr

# Agrupa combinando la fecha y la distancia
grupos = groupby(df, [:date, :d_mm])
c = grupos[8]

scatter(c.pd, c.V_subida, xlabel="pd", ylabel=L"V_{subida}", label="fecha: $(c.date[1]), dist: $(c.d_mm[1])mm")

# valores de ajuste
x_dense = range(minimum(c.pd), maximum(c.pd), length=100) # x densos
# El parámetro `lower` indica los valores mínimos permitidos para [B, C, k]
ajuste = curve_fit(paschen, c.pd, c.V_subida, p0, lower=[0.0, -10.0, 0.0]) # aplico ajuste con modelo de Paschen
y_fit = paschen(x_dense, ajuste.param)

#ploteo el ajuste
plot!(x_dense, y_fit, label="ajuste de Paschen")