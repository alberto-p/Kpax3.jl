# This file is part of Kpax3. License is MIT.

function split!(ij::Vector{Int},
                neighbours::Vector{Int},
                S::Int,
                data::Matrix{UInt8},
                priorR::PriorRowPartition,
                priorC::PriorColPartition,
                settings::KSettings,
                support::KSupport,
                mcmcobj::AminoAcidMCMC)
  # number of clusters after the split
  k = length(mcmcobj.cl) + 1

  initsupportsplitmerge!(ij, S, k, data, priorC, support)

  # sample a new proportion for cluster 'hi'
  w = Distributions.rand(settings.distws)

  # logarithm of the product of sequential probabilities
  lq = 0.0

  # temporary / support variables
  u = 0
  lcp = zeros(Float64, 2)
  z = 0.0
  p = 0.0

  # allocate the neighbours of i and j
  for l in 1:S
    u = neighbours[l]
    lcp[1] = lcp[2] = 0.0

    # compute p(x_{u} | x_{hi,1:(u-1)}) and p(x_{u} | x_{hj,1:(u-1)})
    for b in 1:size(data, 1)
      lcp[1] += computeclusteriseqprobs!(data[b, u], b, priorC, support)
      lcp[2] += computeclusterjseqprobs!(data[b, u], b, priorC, support)
    end

    # (w * p1) / (w * p1 + (1 - w) * p2) = 1 / (1 + ((1 - w) / w) * (p2 / p1))
    # => e^(-log(1 + e^(log(1 - w) - log(w) + log(p2) - log(p1))))
    z = -log1p(exp(log(1 - w) - log(w) + lcp[2] - lcp[1]))
    p = exp(z)

    if rand() <= p
      updateclusteri!(u, data, support)
      lq += z
    else
      updateclusterj!(u, data, support)
      lq += log1p(-p)
    end
  end

  hi = mcmcobj.R[ij[1]]

  simcsplit!(k, hi, priorC, support, mcmcobj)

  support.lograR = logratiopriorrowsplit(k, support.vi, support.vj, priorR)

  logliksplit!(hi, priorC, support, mcmcobj)

  distwm = Distributions.Beta(settings.parawm + support.vi,
                              settings.parawm + support.vj)

  ratio = exp(support.lograR +
              support.logpC[1] - mcmcobj.logpC[1] +
              support.loglik - mcmcobj.loglik +
              mcmcobj.logpC[2] - support.logpC[2] +
              Distributions.logpdf(distwm, w) -
              Distributions.logpdf(settings.distws, w) -
              lq)

  if ratio >= 1 || ((ratio > 0) && (rand() <= ratio))
    performsplit!(hi, k, priorC, settings, support, mcmcobj)
  end

  nothing
end

function performsplit!(hi::Int,
                       k::Int,
                       priorC::PriorColPartition,
                       settings::KSettings,
                       support::KSupport,
                       mcmcobj::AminoAcidMCMC)
  hj = findfirst(!mcmcobj.filledcluster)

  if hj > 0
    for b in 1:size(mcmcobj.C, 2)
      idx = 0
      for g in mcmcobj.cl
        mcmcobj.C[g, b] = support.C[idx += 1, b]
      end

      mcmcobj.C[hj, b] = support.C[idx += 1, b]

      mcmcobj.n1s[hi, b] = support.ni[b]
      mcmcobj.n1s[hj, b] = support.nj[b]
    end

    mcmcobj.filledcluster[hj] = true

    mcmcobj.v[hi] = support.vi
    mcmcobj.unit[hi] = copy(support.ui[1:support.vi])

    mcmcobj.v[hj] = support.vj
    mcmcobj.unit[hj] = copy(support.uj[1:support.vj])
  else
    hj = k

    # reallocate memory
    len = min(length(mcmcobj.R), k + settings.maxclust - 1)

    C = zeros(UInt8, len, size(mcmcobj.C, 2))

    filledcluster = falses(len)
    v = zeros(Int, len)
    n1s = zeros(Float64, len, size(mcmcobj.C, 2))
    unit = Vector{Int}[zeros(Int, 0) for g in 1:len]

    idx = 0
    for g in mcmcobj.cl
      C[g, 1] = support.C[idx += 1, 1]

      v[g] = mcmcobj.v[g]
      n1s[g, 1] = mcmcobj.n1s[g, 1]
      unit[g] = copy(mcmcobj.unit[g])

      filledcluster[g] = true
    end

    C[k, 1] = support.C[idx += 1, 1]

    filledcluster[k] = true

    v[hi] = support.vi
    n1s[hi, 1] = support.ni[1]
    unit[hi] = copy(support.ui[1:support.vi])

    v[k] = support.vj
    n1s[k, 1] = support.nj[1]
    unit[k] = copy(support.uj[1:support.vj])

    for b in 2:size(mcmcobj.C, 2)
      idx = 0
      for g in mcmcobj.cl
        C[g, b] = support.C[idx += 1, b]
        n1s[g, b] = mcmcobj.n1s[g, b]
      end

      C[k, b] = support.C[idx += 1, b]

      n1s[hi, b] = support.ni[b]
      n1s[k, b] = support.nj[b]
    end

    mcmcobj.C = C

    mcmcobj.filledcluster = filledcluster

    mcmcobj.v = v
    mcmcobj.n1s = n1s
    mcmcobj.unit = unit
  end

  # move units to their new cluster
  for j in 1:support.vj
    mcmcobj.R[support.uj[j]] = hj
  end

  mcmcobj.cl = find(mcmcobj.filledcluster)

  mcmcobj.logpR += support.lograR
  copy!(mcmcobj.logpC, support.logpC)
  mcmcobj.loglik = support.loglik

  copy!(priorC.logω, support.logω)

  nothing
end
