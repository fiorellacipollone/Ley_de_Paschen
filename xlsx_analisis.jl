module DataProcessor
    export printable, excel_data_pd, excel_readdata_pd, group_comparative, latest, latest_all

    using LsqFit
    using DataFrames, XLSX
    using Statistics
    const DF = DataFrame

    "Printeo de algunas cosas útiles.
    y: datos
    model: ajuste (evaluado en los x densos)"
    function printable(y, model)

        #calculo del R^2
        residuos = y .- model
        ss_res = sum(residuos.^2)

        media = mean(y)
        ss_tot = sum((y.-media).^2)

        R2 = 1 - (ss_res/ss_tot)

        return R2
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

    """
    Toma un DataFrame y una distancia, y devuelve únicamente las filas
    correspondientes a la fecha más actual en la que se midió esa distancia.
    """
    function latest(df::DF, distancia::Float64)
        # 1. Filtrar el dataframe por la distancia solicitada
        df_dist = filter(:d_mm => d -> d == distancia, df)
        
        if isempty(df_dist)
            println("No se encontraron mediciones para d = $distancia mm")
            return DF()
        end
        
        # 2. Encontrar la fecha máxima (la más actual) para esa distancia
        fecha_reciente = maximum(df_dist.date)
        
        # 3. Retornar el subconjunto de datos que coincide con esa fecha
        df_final = filter(:date => f -> f == fecha_reciente, df_dist)
        
        return df_final, fecha_reciente
    end

    """
    Agrupa TODAS las distancias disponibles y retorna un único DataFrame
    donde cada distancia solo contiene los datos de su fecha más actual.
    """
    function latest_all(df::DF)
        grupos_distancia = groupby(df, :d_mm)
        
        # Iterar sobre cada grupo de distancia y quedarse con la fecha máxima
        df_recientes = combine(grupos_distancia) do sub_df
            fecha_max = maximum(sub_df.date)
            filter(:date => f -> f == fecha_max, sub_df)
        end
        
        return df_recientes
    end
end # cierre del módulo