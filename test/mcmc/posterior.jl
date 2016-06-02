# This file is part of Kpax3. License is MIT.

# parameters to test are
# R = [1; 1; 2; 2; 3; 2]
# S = [2; 3; 1; 2]
# C = [2 3 1 2;
#      2 4 1 2;
#      2 3 1 2]

#=
# compute log(normalization constant) as accurate as possible
include("data/partitions.jl")

function computelogp(b::Int,
                     c::Vector{UInt8},
                     n1s::Matrix{Float64},
                     priorC::AminoAcidPriorCol)
  k = size(n1s, 1)
  logp = 0.0

  if c[1] == UInt8(1)
    logp = priorC.logγ[1]

    for g in 1:k
      logp += logmarglik(n1s[g, b], v[g], priorC.A[1, b], priorC.B[1, b])
    end
  elseif c1[1] == UInt8(2)
    logp = priorC.logγ[2]

    for g in 1:k
      logp += logmarglik(n1s[g, b], v[g], priorC.A[2, b], priorC.B[2, b])
    end
  else
    logp = priorC.logγ[3]

    for g in 1:k
      logp += priorC.logω[k][c[g] - 2] +
              logmarglik(n1s[g, b], v[g], priorC.A[c[g], b], priorC.B[c[g], b])
    end
  end

  logp
end

function addvalue!(b::Int,
                   c::Vector{UInt8},
                   value::Float64,
                   S::Matrix{Float64})
  if c[1] == UInt8(1)
    S[1, b] += value
  elseif c[1] == UInt8(2)
    S[2, b] += value
  else
    S[3, b] += value
  end

  nothing
end

function computelognormconst(ck,
                             k::Int,
                             lumpp::Float64,
                             data::Matrix{UInt8},
                             po::TestPartition,
                             γ::Vector{Float64},
                             r::Float64,
                             priorR::PriorRowPartition)
  (m, n) = size(data)

  priorC = AminoAcidPriorCol(data, γ, r)

  st = po.index[po.k .== k][1]
  en = any(po.k .== k + 1) ? po.index[po.k .== k + 1][1] - 1 : st

  R = zeros(Int, n)
  v = zeros(Float64, k)
  n1s = zeros(Float64, k, m)

  M = -Inf

  g = 0

  p = 0.0
  logprR = 0.0
  logpost = 0.0
  logp = zeros(Float64, m)

  for l in st:en
    fill!(R, 0)
    fill!(v, 0)
    fill!(n1s, 0.0)
    fill!(logp, 0.0)

    for a in 1:n
      g = po.partition[a, l]

      R[a] = g
      v[g] += 1

      for b in 1:m
        n1s[g, b] += float(data[b, a])
      end
    end

    logprR = logdPriorRow(R, priorR)

    for c1 in ck, c2 in ck, c3 in ck, c4 in ck
      logp[1] += computelogp(1, c1, n1s, priorC)
      logp[2] += computelogp(2, c2, n1s, priorC)
      logp[3] += computelogp(3, c3, n1s, priorC)
      logp[4] += computelogp(4, c4, n1s, priorC)

      logpost = logprR + logp[1] + logp[2] + logp[3] + logp[4]

      if logpost > M
        M = logpost
      end

      p += exp(logpost - lumpp)
    end
  end

  (M, p)
end

function lognormconst(cs,
                      data::Matrix{UInt8},
                      po::TestPartition,
                      γ::Vector{Float64},
                      r::Float64,
                      priorR::PriorRowPartition)
  # log unnormalized maximum posterior probability
  lumpp = -Inf

  println("Computing 'lumpp'...")
  for k in 1:size(data, 2)
    println("k = ", k)
    t1, t2 = computelognormconst(cs[k], k, 0.0, data, po, γ, r, priorR)

    if t1 > lumpp
      lumpp = t1
    end
  end
  println("Done.")

  # now that we know the maximum value, we can compute the logarithm of the
  # normalization constant
  z = 0.0

  println("Computing 'z'...")
  for k in 1:size(data, 2)
    println("k = ", k)
    t1, t2 = computelognormconst(cs[k], k, lumpp, data, po, γ, r, priorR)
    z += t2
  end
  println("Done.")

  (log(z), lumpp)
end

function computeProbs(cs,
                      lz::Float64,
                      lumpp::Float64,
                      data::Matrix{UInt8},
                      po::TestPartition,
                      γ::Vector{Float64},
                      r::Float64,
                      priorR::PriorRowPartition)
  (m, n) = size(data)

  P = zeros(Float64, div(n * (n - 1), 2))
  S = zeros(Float64, 3, m)
  K = zeros(Float64, n)

  u = falses(div(n * (n - 1), 2))

  R = zeros(Int, n)

  logprR = 0.0
  logpost = 0.0
  logp = zeros(Float64, m)

  println("Computing probabilities...")
  for k in 1:(n - 1)
    println("k = ", k)

    priorC = AminoAcidPriorCol(data, γ, r)

    st = po.index[po.k .== k][1]
    en = po.index[po.k .== k + 1][1] - 1

    v = zeros(Float64, k)
    n1s = zeros(Float64, k, m)

    for l in st:en
      fill!(R, 0)
      fill!(v, 0)
      fill!(n1s, 0.0)
      fill!(logp, 0.0)

      for a in 1:n
        g = po.partition[a, l]

        R[a] = g
        v[g] += 1

        for b in 1:m
          n1s[g, b] += float(data[b, a])
        end
      end

      logprR = logdPriorRow(R, priorR)

      idx = 1
      for i in 1:(n - 1)
        for j in (i + 1):n
          u[idx] = (R[i] == R[j])
          idx += 1
        end
      end

      for c1 in cs[k], c2 in cs[k], c3 in cs[k], c4 in cs[k]
        logp[1] += computelogp(1, c1, n1s, priorC)
        logp[2] += computelogp(2, c2, n1s, priorC)
        logp[3] += computelogp(3, c3, n1s, priorC)
        logp[4] += computelogp(4, c4, n1s, priorC)

        tmp = exp(logpost - lumpp)

        P[u] += tmp
        K[k] += tmp

        addvalue!(1, c1, tmp, S)
        addvalue!(2, c2, tmp, S)
        addvalue!(3, c3, tmp, S)
        addvalue!(4, c4, tmp, S)
      end
    end
  end

  # no units are in the same cluster
  k = n
  println("k = ", k)

  priorC = AminoAcidPriorCol(data, γ, r)

  v = ones(Float64, k)
  n1s = zeros(Float64, k, m)

  fill!(R, 0)
  fill!(logp, 0.0)

  for a in 1:n
    R[a] = a

    for b in 1:m
      n1s[a, b] = float(data[b, a])
    end
  end

  logprR = logdPriorRow(R, priorR)

  idx = 1
  for i in 1:(n - 1)
    for j in (i + 1):n
      u[idx] = (R[i] == R[j])
      idx += 1
    end
  end

  for c1 in cs[k], c2 in cs[k], c3 in cs[k], c4 in cs[k]
    logp[1] += computelogp(1, c1, n1s, priorC)
    logp[2] += computelogp(2, c2, n1s, priorC)
    logp[3] += computelogp(3, c3, n1s, priorC)
    logp[4] += computelogp(4, c4, n1s, priorC)

    tmp = exp(logpost - lumpp)

    P[u] += tmp
    K[k] += tmp

    addvalue!(1, c1, tmp, S)
    addvalue!(2, c2, tmp, S)
    addvalue!(3, c3, tmp, S)
    addvalue!(4, c4, tmp, S)
  end
  println("Done.")

  (exp(log(P) - lz), exp(log(S) - lz), exp(log(K) - lz))
end

settings = KSettings(ifile, ofile, α=α, θ=θ)

x = AminoAcidData(settings)

priorR = EwensPitman(settings.α, settings.θ)
po = TestPartition(size(x.data, 2))
cs = ((UInt8[1], UInt8[2], UInt8[3], UInt8[4]),
      (UInt8[1; 1], UInt8[2; 2], UInt8[3; 3], UInt8[3; 4], UInt8[4; 3],
       UInt8[4; 4]),
      (UInt8[1; 1; 1], UInt8[2; 2; 2], UInt8[3; 3; 3], UInt8[3; 3; 4],
       UInt8[3; 4; 3], UInt8[4; 3; 3], UInt8[3; 4; 4], UInt8[4; 3; 4],
       UInt8[4; 4; 3], UInt8[4; 4; 4]),
      (UInt8[1; 1; 1; 1], UInt8[2; 2; 2; 2], UInt8[3; 3; 3; 3],
       UInt8[3; 3; 3; 4], UInt8[3; 3; 4; 3], UInt8[3; 4; 3; 3],
       UInt8[4; 3; 3; 3], UInt8[3; 3; 4; 4], UInt8[3; 4; 3; 4],
       UInt8[3; 4; 4; 3], UInt8[4; 3; 3; 4], UInt8[4; 3; 4; 3],
       UInt8[4; 4; 3; 3], UInt8[3; 4; 4; 4], UInt8[4; 3; 4; 4],
       UInt8[4; 4; 3; 4], UInt8[4; 4; 4; 3], UInt8[4; 4; 4; 4]),
      (UInt8[1; 1; 1; 1; 1], UInt8[2; 2; 2; 2; 2], UInt8[3; 3; 3; 3; 3],
       UInt8[3; 3; 3; 3; 4], UInt8[3; 3; 3; 4; 3], UInt8[3; 3; 4; 3; 3],
       UInt8[3; 4; 3; 3; 3], UInt8[4; 3; 3; 3; 3], UInt8[3; 3; 3; 4; 4],
       UInt8[3; 3; 4; 3; 4], UInt8[3; 3; 4; 4; 3], UInt8[3; 4; 3; 3; 4],
       UInt8[3; 4; 3; 4; 3], UInt8[3; 4; 4; 3; 3], UInt8[4; 3; 3; 3; 4],
       UInt8[4; 3; 3; 4; 3], UInt8[4; 3; 4; 3; 3], UInt8[4; 4; 3; 3; 3],
       UInt8[3; 3; 4; 4; 4], UInt8[3; 4; 3; 4; 4], UInt8[3; 4; 4; 3; 4],
       UInt8[3; 4; 4; 4; 3], UInt8[4; 3; 3; 4; 4], UInt8[4; 3; 4; 3; 4],
       UInt8[4; 4; 3; 3; 4], UInt8[4; 3; 4; 4; 3], UInt8[4; 4; 3; 4; 3],
       UInt8[4; 4; 4; 3; 3], UInt8[3; 4; 4; 4; 4], UInt8[4; 3; 4; 4; 4],
       UInt8[4; 4; 3; 4; 4], UInt8[4; 4; 4; 3; 4], UInt8[4; 4; 4; 4; 3],
       UInt8[4; 4; 4; 4; 4]),
      (UInt8[1; 1; 1; 1; 1; 1], UInt8[2; 2; 2; 2; 2; 2],
       UInt8[3; 3; 3; 3; 3; 3], UInt8[3; 3; 3; 3; 3; 4],
       UInt8[3; 3; 3; 3; 4; 3], UInt8[3; 3; 3; 4; 3; 3],
       UInt8[3; 3; 4; 3; 3; 3], UInt8[3; 4; 3; 3; 3; 3],
       UInt8[4; 3; 3; 3; 3; 3], UInt8[3; 3; 3; 3; 4; 4],
       UInt8[3; 3; 3; 4; 3; 4], UInt8[3; 3; 3; 4; 4; 3],
       UInt8[3; 3; 4; 3; 3; 4], UInt8[3; 3; 4; 3; 4; 3],
       UInt8[3; 3; 4; 4; 3; 3], UInt8[3; 4; 3; 3; 3; 4],
       UInt8[3; 4; 3; 3; 4; 3], UInt8[3; 4; 3; 4; 3; 3],
       UInt8[3; 4; 4; 3; 3; 3], UInt8[4; 3; 3; 3; 3; 4],
       UInt8[4; 3; 3; 3; 4; 3], UInt8[4; 3; 3; 4; 3; 3],
       UInt8[4; 3; 4; 3; 3; 3], UInt8[4; 4; 3; 3; 3; 3],
       UInt8[3; 3; 3; 4; 4; 4], UInt8[3; 3; 4; 3; 4; 4],
       UInt8[3; 3; 4; 4; 3; 4], UInt8[3; 3; 4; 4; 4; 3],
       UInt8[3; 4; 3; 3; 4; 4], UInt8[3; 4; 3; 4; 3; 4],
       UInt8[3; 4; 4; 3; 3; 4], UInt8[3; 4; 3; 4; 4; 3],
       UInt8[3; 4; 4; 3; 4; 3], UInt8[3; 4; 4; 4; 3; 3],
       UInt8[4; 3; 3; 3; 4; 4], UInt8[4; 3; 3; 4; 3; 4],
       UInt8[4; 3; 4; 3; 3; 4], UInt8[4; 4; 3; 3; 3; 4],
       UInt8[4; 3; 3; 4; 4; 3], UInt8[4; 3; 4; 3; 4; 3],
       UInt8[4; 4; 3; 3; 4; 3], UInt8[4; 3; 4; 4; 3; 3],
       UInt8[4; 4; 3; 4; 3; 3], UInt8[4; 4; 4; 3; 3; 3],
       UInt8[3; 3; 4; 4; 4; 4], UInt8[3; 4; 3; 4; 4; 4],
       UInt8[3; 4; 4; 3; 4; 4], UInt8[3; 4; 4; 4; 3; 4],
       UInt8[3; 4; 4; 4; 4; 3], UInt8[4; 3; 3; 4; 4; 4],
       UInt8[4; 3; 4; 3; 4; 4], UInt8[4; 3; 4; 4; 3; 4],
       UInt8[4; 3; 4; 4; 4; 3], UInt8[4; 4; 3; 3; 4; 4],
       UInt8[4; 4; 3; 4; 3; 4], UInt8[4; 4; 3; 4; 4; 3],
       UInt8[4; 4; 4; 3; 3; 4], UInt8[4; 4; 4; 3; 4; 3],
       UInt8[4; 4; 4; 4; 3; 3], UInt8[3; 4; 4; 4; 4; 4],
       UInt8[4; 3; 4; 4; 4; 4], UInt8[4; 4; 3; 4; 4; 4],
       UInt8[4; 4; 4; 3; 4; 4], UInt8[4; 4; 4; 4; 3; 4],
       UInt8[4; 4; 4; 4; 4; 3], UInt8[4; 4; 4; 4; 4; 4]))

# lmpp = lumpp - lc = lumpp - lumpp - lz = - lz
# lc + lmpp = lumpp + lz - lz = lumpp
lz, lumpp = lognormconst(cs, x.data, po, settings.γ, settings.r, priorR)
probs = computeProbs(cs, lz, lumpp, x.data, po, settings.γ, settings.r, priorR)

@printf("%.100f\n", lz)
@printf("%.100f\n", lumpp)
@printf("%.100f\n", lumpp + lz)

for i in 1:6
  @printf("%.100f\n", probs[3][i])
end

for i in 1:15
  @printf("%.100f\n", probs[1][i])
end

for i in 1:12
  @printf("%.100f\n", probs[2][i])
end

# EwensPitmanPAUT
# lz = 2.82383600433172521348978989408351480960845947265625
# lumpp = -20.077619086471660381221226998604834079742431640625
# lc = lumpp + lz = -17.253783082139936055909856804646551609039306640625

# EwensPitmanPAZT
# lz = 3.718733440312136817595956017612479627132415771484375
# lumpp = -20.701675744062715267546082031913101673126220703125
# lc = lumpp + lz = -16.982942303750579782217755564488470554351806640625

# EwensPitmanZAPT
# lz = 4.09068229126453619670655825757421553134918212890625
# lumpp = -21.0913924952027400649967603385448455810546875
# lc = lumpp + lz = -17.00071020393820475646862178109586238861083984375

# EwensPitmanNAPT
# lz = 5.15291171975398309967886234517209231853485107421875
# lumpp = -21.99795555234826593959951424039900302886962890625
# lc = lumpp + lz = -16.845043832594281951742232195101678371429443359375
=#

function test_mcmc_algorithm()
  ifile = "data/mcmc_6.fasta"
  ofile = "../build/mcmc_6.bin"

  partition = "data/mcmc_6.csv"

  x = AminoAcidData(KSettings(ifile, ofile))

  # EwensPitmanZAPT
  α = 0.0
  θ = 1.0

  settings = KSettings(ifile, ofile, maxclust=1, maxunit=1, α=α, θ=θ)

  trueProbK = [0.0572011678382854799052026351091626565903425216674804687500000;
               0.3147244396041969372035396190767642110586166381835937500000000;
               0.3980266432259659814540952993411337956786155700683593750000000;
               0.1895011450641402861450046657409984618425369262695312500000000;
               0.0378534754499949971373595758450392168015241622924804687500000;
               0.0026931288174161633307279739568684817641042172908782958984375]

  trueProbP = [0.5647226958512603367523752240231260657310485839843750000;
               0.3859601712857648747601047034549992531538009643554687500;
               0.3859601712857648747601047034549992531538009643554687500;
               0.3877266490089570361021742428420111536979675292968750000;
               0.2495816768360757109679326504192431457340717315673828125;
               0.3859601712857648747601047034549992531538009643554687500;
               0.3859601712857648747601047034549992531538009643554687500;
               0.3877266490089570361021742428420111536979675292968750000;
               0.2495816768360757109679326504192431457340717315673828125;
               0.5647226958512601147077702989918179810047149658203125000;
               0.2495816768360775983470745131853618659079074859619140625;
               0.3877266490089560369014520802011247724294662475585937500;
               0.2495816768360764881240498880288214422762393951416015625;
               0.3877266490089572026356279366154922172427177429199218750;
               0.3775410735825202035442771375528536736965179443359375000]

  trueProbS = reshape([0.64661621099553545644056384844589047133922576904296875;
                       0.64661621099553601155207616102416068315505981445312500;
                       0.68542239667922499890551080170553177595138549804687500;
                       0.68101761387747727916064377495786175131797790527343750;
                       0.32178606699173095684329837240511551499366760253906250;
                       0.32178606699173034622063482856901828199625015258789063;
                       0.28865559061555579045688091355259530246257781982421875;
                       0.28636663896563274711581925657810643315315246582031250;
                       0.03159772201235643701577870956498372834175825119018555;
                       0.03159772201235912930661342556959425564855337142944336;
                       0.02592201270487425740496334469753492157906293869018555;
                       0.03261574715661440942993110070347029250115156173706055],
                      (4, 3))'

  kpax3mcmc(x, partition, settings)

  (estimK, estimP, estimS) = processchain(settings.ofile)

  @test maximum(abs(estimK - trueProbK)) < 0.005
  @test maximum(abs(estimP - trueProbP)) < 0.005
  @test maximum(abs(estimS - trueProbS)) < 0.005

  # EwensPitmanPAUT
  α = 0.5
  θ = -0.25

  settings = KSettings(ifile, ofile, maxclust=1, maxunit=1, α=α, θ=θ)

  trueProbK = [0.20304357310850917883726651780307292938232421875000000000;
               0.21850248716493331224697271863988135010004043579101562500;
               0.23654721412654236556427633786370279267430305480957031250;
               0.19408622743422676570901330705964937806129455566406250000;
               0.11197185302918269411698304338642628863453865051269531250;
               0.03584864513660558638097342054606997407972812652587890625]

  trueProbP = [0.570577011488977547948309165803948417305946350097656250;
               0.458274033588720208776123854477191343903541564941406250;
               0.458274033588720208776123854477191343903541564941406250;
               0.441580861997908746818808367606834508478641510009765625;
               0.356836131052323146661819919245317578315734863281250000;
               0.458274033588720208776123854477191343903541564941406250;
               0.458274033588720208776123854477191343903541564941406250;
               0.441580861997908746818808367606834508478641510009765625
               0.356836131052323146661819919245317578315734863281250000;
               0.570577011488982877018827366555342450737953186035156250;
               0.356836131052323146661819919245317578315734863281250000;
               0.441580861997908746818808367606834508478641510009765625;
               0.356836131052323146661819919245317578315734863281250000;
               0.441580861997908746818808367606834508478641510009765625;
               0.425947160536098878846900106509565375745296478271484375]

  trueProbS = reshape([0.66285546230250036447984030019142664968967437744140625;
                       0.66285546230249980936832798761315643787384033203125000;
                       0.69589543471463977120095023565227165818214416503906250;
                       0.69077860004743585342623646283755078911781311035156250;
                       0.31615424466057556740494760560977738350629806518554688;
                       0.31615424466057467922652790548454504460096359252929688;
                       0.28580920161038175786316628546046558767557144165039063;
                       0.28349570697905279725858918027370236814022064208984375;
                       0.02099029303655643163839528142489143647253513336181641;
                       0.02099029303656406442168957937610684894025325775146484;
                       0.01829536367463608509398298451742448378354310989379883;
                       0.02572569297315747613441594410232937661930918693542481],
                      (4, 3))'

  kpax3mcmc(x, partition, settings)

  (estimK, estimP, estimS) = processchain(settings.ofile)

  @test maximum(abs(estimK - trueProbK)) < 0.005
  @test maximum(abs(estimP - trueProbP)) < 0.005
  @test maximum(abs(estimS - trueProbS)) < 0.005

  # EwensPitmanPAZT
  α = 0.5
  θ = 0.0

  settings = KSettings(ifile, ofile, maxclust=1, maxunit=1, α=α, θ=θ)

  trueProbK = [0.08297365650265563219445397180606960318982601165771484375;
               0.17858186829001693185503540917125064879655838012695312500;
               0.25777307456537906782401137206761632114648818969726562500;
               0.25380237308441272459091919699858408421277999877929687500;
               0.16734077362357668850023628692724741995334625244140625000;
               0.05952825393395902442428280210151569917798042297363281250]

  trueProbP = [0.4594673179563065201769234136008890345692634582519531250;
               0.3358129241361126893217203814856475219130516052246093750;
               0.3358129241361126893217203814856475219130516052246093750;
               0.3205116334957199830668628237617667764425277709960937500;
               0.2303208685969153901584860477669280953705310821533203125;
               0.3358129241361126893217203814856475219130516052246093750;
               0.3358129241361126893217203814856475219130516052246093750;
               0.3205116334957199830668628237617667764425277709960937500;
               0.2303208685969170277374473698728252202272415161132812500;
               0.4594673179563261156133080476138275116682052612304687500;
               0.2303208685969153068917592008801875635981559753417968750;
               0.3205116334957179846654184984799940139055252075195312500;
               0.2303208685969174440710816043065278790891170501708984375;
               0.3205116334957179846654184984799940139055252075195312500;
               0.3050339698727991821769478519854601472616195678710937500]

  trueProbS = reshape([0.64877053480324242684673663461580872535705566406250000;
                       0.64877053480324509138199573499150574207305908203125000;
                       0.68950457163812417515913466559140942990779876708984375;
                       0.68205073729144993777140371093992143869400024414062500;
                       0.32761208323408452791625222744187340140342712402343750;
                       0.32761208323408497200546207750448957085609436035156250;
                       0.29105376948389805047412437488674186170101165771484375;
                       0.28762866299476752551811387093039229512214660644531250;
                       0.02361738196281831445033638772201811661943793296813965;
                       0.02361738196281834567535895530454581603407859802246094;
                       0.01944165887812039986148882064753706799820065498352051;
                       0.03032059971377802642944487843124079518020153045654297],
                      (4, 3))'

  kpax3mcmc(x, partition, settings)

  (estimK, estimP, estimS) = processchain(settings.ofile)

  @test maximum(abs(estimK - trueProbK)) < 0.005
  @test maximum(abs(estimP - trueProbP)) < 0.005
  @test maximum(abs(estimS - trueProbS)) < 0.005

  # EwensPitmanNAPT
  α = -1
  θ = 4

  settings = KSettings(ifile, ofile, maxclust=1, maxunit=1, α=α, θ=θ)

  trueProbK = [0.013987232861628222380101504995764116756618022918701171875;
               0.277957780373217555602849415663513354957103729248046875000;
               0.542335567963948439462740225280867889523506164550781250000;
               0.165719418801206025415595490812847856432199478149414062500;
               0.0;
               0.0]

  trueProbP = [0.5514954001719989395979837354389019310474395751953125000;
               0.3318939556633083709513698522641789168119430541992187500;
               0.3318939556633083709513698522641789168119430541992187500;
               0.3588148423035991685381418392353225499391555786132812500;
               0.1920174063238060946368079839885467663407325744628906250;
               0.3318939556633083709513698522641789168119430541992187500;
               0.3318939556633083709513698522641789168119430541992187500;
               0.3588148423035966150251852013752795755863189697265625000;
               0.1920174063238067885261983747113845311105251312255859375;
               0.5514954001719960530181197100318968296051025390625000000;
               0.1920174063238073713932863029185682535171508789062500000;
               0.3588148423035962819582778138283174484968185424804687500;
               0.1920174063238073713932863029185682535171508789062500000;
               0.3588148423035962819582778138283174484968185424804687500;
               0.3581303270326594012651355569687439128756523132324218750]

  trueProbS = reshape([0.63502756183906849951625872563454322516918182373046875;
                       0.63502756183906727827093163796234875917434692382812500;
                       0.68213948997024276277301169102429412305355072021484375;
                       0.67691283618100617225366022466914728283882141113281250;
                       0.32713487171921601381896493876411113888025283813476562;
                       0.32713487171921457052903292606060858815908432006835938;
                       0.28955185644545156087303894310025498270988464355468750;
                       0.28645172265069046568797261897998396307229995727539063;
                       0.03783756644177374561799354069080436602234840393066406;
                       0.03783756644177584810284642458100279327481985092163086;
                       0.02830865358422545233207934245456272037699818611145020;
                       0.03663544116819100748827509050897788256406784057617188],
                      (4, 3))'

  kpax3mcmc(x, partition, settings)

  (estimK, estimP, estimS) = processchain(settings.ofile)

  @test maximum(abs(estimK - trueProbK)) < 0.005
  @test maximum(abs(estimP - trueProbP)) < 0.005
  @test maximum(abs(estimS - trueProbS)) < 0.005

  nothing
end

test_mcmc_algorithm()
