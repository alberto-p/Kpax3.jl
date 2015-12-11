# This file is part of Kpax3. License is MIT.

function rpostpartitioncols!(C::Matrix{UInt8},
                             cl::Vector{Int},
                             v::Vector{Int},
                             n1s::Matrix{Float64},
                             logγ::Vector{Float64},
                             logω::Vector{Float64},
                             A::Matrix{Float64},
                             B::Matrix{Float64})
  logq = zeros(Float64, 4, length(cl))

  γ = zeros(Float64, 3)
  lγ = zeros(Float64, 3)

  ω = zeros(Float64, 2, length(cl))

  g = 0
  M = 0.0
  tmp = 0.0

  for b in 1:size(C, 2)
    lγ[1] = logγ[1]
    lγ[2] = logγ[2]
    lγ[3] = logγ[3]

    for l in 1:length(cl)
      g = cl[l]

      logq[1, l] = logmarglik(n1s[g, b], v[g], A[1, b], B[1, b])
      logq[2, l] = logmarglik(n1s[g, b], v[g], A[2, b], B[2, b])
      logq[3, l] = logω[3] + logmarglik(n1s[g, b], v[g], A[3, b], B[3, b])
      logq[4, l] = logω[4] + logmarglik(n1s[g, b], v[g], A[4, b], B[4, b])

      lγ[1] += logq[1, l]
      lγ[2] += logq[2, l]

      if logq[3, l] > logq[4, l]
        tmp = log1p(exp(logq[4, l] - logq[3, l]))

        lγ[3] += logq[3, l] + tmp

        ω[1, l] = exp(-tmp)
        ω[2, l] = exp(logq[4, l] - logq[3, l] - tmp)
      else
        tmp = log1p(exp(logq[3, l] - logq[4, l]))

        lγ[3] += logq[4, l] + tmp

        ω[1, l] = exp(logq[3, l] - logq[4, l] - tmp)
        ω[2, l] = exp(-tmp)
      end
    end

    if (lγ[1] >= lγ[2]) && (lγ[1] >= lγ[3])
      tmp = lγ[1] + log1p(exp(lγ[2] - lγ[1]) + exp(lγ[3] - lγ[1]))
    elseif (lγ[2] >= lγ[1]) && (lγ[2] >= lγ[3])
      tmp = lγ[2] + log1p(exp(lγ[1] - lγ[2]) + exp(lγ[3] - lγ[2]))
    else
      tmp = lγ[3] + log1p(exp(lγ[1] - lγ[3]) + exp(lγ[2] - lγ[3]))
    end

    γ[1] = exp(lγ[1] - tmp)
    γ[2] = exp(lγ[2] - tmp)
    γ[3] = exp(lγ[3] - tmp)

    u = StatsBase.sample(StatsBase.WeightVec(γ))

    if u == 1
      for g in cl
        C[g, b] = 0x01
      end
    elseif u == 2
      for g in cl
        C[g, b] = 0x02
      end
    else
      for l in 1:length(cl)
        g = cl[l]
        C[g, b] = UInt8(2 + StatsBase.sample(StatsBase.WeightVec(vec(ω[:, l]))))
      end
    end
  end

  nothing
end