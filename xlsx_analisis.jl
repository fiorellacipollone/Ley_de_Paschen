module DataProcessor
    export printable, excel_data_pd, excel_readdata_pd, group_comparative

    using LsqFit
    using DataFrames, XLSX
    using Statistics
    const DF = DataFrame

    function printable(string)
        println(string)
    end

    "Lee la información del excel, calcula el producto pd y retorna el DataFrame con las columnas 
    con los respectivos cálculos realizados."
    function excel_readdata_pd(ruta, hoja="Hoja1")
        dat = DF(XLSX.readtable(ruta, hoja))

        # cálculo del producto pd
        dat.pd = dat.d_mm .* dat.P_torr

        return dat
    end

    "Contrastar datos sujetos a un filtro
    filtro: sobre la información que se desea filtrar (:nom_col),
    subject_data: datos sujetos al filtro"
    function group_comparative(df, filtro, subject_data; indice=1)
        # agrupar por filtro
        grupos_filtro = groupby(df, filtro)

        simple_filtro = grupos_filtro[indice]

        # obtener los datos sujetos
        grupos_subdata = groupby(grupos_filtro, subject_data)

        return simple_filtro, grupos_subdata
    end

    function latest()
        Nothing
    end
end # cierre del módulo