module AnalisisPaschen

export paschen

function paschen(pd, p)
    # valores
    B, C, k = p
    # modelo
    x = pd .+ k
    denom = log.(x) .+ C

    return B .* x ./ denom
end

end # cierra el modulo