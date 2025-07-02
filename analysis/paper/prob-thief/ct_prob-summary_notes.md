1. Introduction
  - Background and prior work
  - Paper overview: extend cross-sectional probabilistic reconciliation to cross-temporal case (also explores temporal case)
2. Notations and definitions
  - 2.0 covers representation of hierarchical time series using matrices and related equations for all three cases: cross-sectional, temporal, cross-temporal
    - Has the typical $\boldsymbol{y}_t$ linear time series; variables $k, m$, indices $i, j$
    - but also split multiple upper level time series $\boldsymbol{u}_t$ and bottom level time series $\boldsymbol{b}_t$ AND structural matrix $\boldsymbol{S} = \begin{bmatrix} \boldsymbol{A} & \boldsymbol{I}_{n_b} \end{bmatrix}'$
    - Additional equations: $\boldsymbol{u}_t = \boldsymbol{A} \boldsymbol{b}_t$, $\boldsymbol{y}_t = \boldsymbol{S} \boldsymbol{b}_t$
    - Adds zero constraints matrix $\boldsymbol{C} = \begin{bmatrix}  $\boldsymbol{I}_{n_a} & -\boldsymbol{A}$, coefficient matrix of a linear system
    - Cross-temporal case takes elements from and uses matrix operations on the cross-sectional and temporal cases
  - 2.1 Optimal point forecast reconciliation (just the cross-temporal case)
    - Seems like a generalization of cross-sectional and temporal cases explored in earlier papers, in which neither of the two axes are constant
  - 2.2 Cross-temporal bottom up forecast reconciliation
    - Necessary to reduce computational casts for a larger hierarchy scheme with two axes vs just one
3. Probabilistic forecast reconciliation (based on Wickramasuriya 2023 and Paragiotlis 2023, only for continuous case NOT count data)
  - Extend definitions from papers to Cross-temporal cases for both coherent probabilistic forecasts AND probabilistic forecast reconciliation (uses borel sigma algebra)
  - Theorem 3.1 implies that a sample from the reconciled distribution can be obtained by reconciling each member of a sample from the incoherent distribution

--

A mapping $p : R^n -> [0, 1]$ basically tells us that a (probability) function $p$ takes some value on the real number line and spits out a probability 

Basically, a probability triple defines an experiment with parameters defining all the possible outcomes (the sample space), a subset of events that have occurred or we're interested in (the event space, a type of sigma algebra), and a function that describes the probability of each possible event (the probability function)
  - Note that a probability space is a measure space in which the measure of the whole space is equal to one
  - This means the event space is a sigma algebra on the sample space, since a measure space is composed of (a set X, a sigma algebra A on the set X, a measure on the measurable space (X, A))
We constrain the event space to be a Borel sigma algebra, or the smallest sigma algebra containing all open (or closed) sets [through operations of countable union, countable intersection, and relative complement]
  - This might ensure all the events can be assigned probabilities

https://stats.stackexchange.com/questions/199280/why-do-we-need-sigma-algebras-to-define-probability-spaces


Forecast reconciliation adjusts the base forecast \hat{\boldsymbol{x}}_h by finding a mapping ψ: R^{n(m + k^*)} -> s such that
  \tilde{\boldsymbol{x}}_h = ψ(\hat{\boldsymbol{x}}_h)=s(g(\hat{\boldsymbol{x}}_h))
where \tilde{\boldsymbol{x}}_h \in s is the vector of reconciled forecasts

Probability Space (R^{n_b m}, F_{R^{n_b m}}, v) for bottom time series

Coherent Probability Space (s, F_{s}, \cup{v}), satisfying 
  \cup{v}(s(B)) = v(B) for all B in F_{R^{n_b m}}

Incoherent Probability Space (for incoherent probabilistic forecast \hat{\boldsymbol{x}}) (R^{n(m + k^*)}, F_{R^n(m)+k^*}, hat {v})
Reconciled Probability Space (s, F_{s}, \tilde{v}), satisfying 
  \tilde{v}(A) = \hat{v}(ψ^{-1}(A)) for all A in F_{s}
where ψ^{-1}(A) = x \in R^{n(m + k^*)}: ψ(x) \in A denotes the pre-image of A



A temporal hierarchy for a quarterly series (m = 4, k = {4, 2, 1})
x_{i,t}^{[4]}
x_{i,2t-1}^{[2]}  x_{i,2t}^{[2]}
x_{i,4t-3}^{[1]}  x_{i,4t-2}^{[1]}    x_{i,4t-1}^{[1]}  x_{i,4t}^{[1]}



n_a=3, n_b=5
A=[1 1 1 1 1 \\ 1 1 1 0 0 \\0 0 0 1 1]
C=[I_3   -A]



base forecasts covariance matrix is Omega
estimate for omega is sample covariance matrix Omega_hat, likely made up of empirical base forecast residuals

reconciled forecasts covariance matrix is Omega_tilde

sample covariance parameters: 
G: r = 3(7)[3(7) - 1] / 2 = 21[20] / 2 = 210 = (441-21)/2
B: 2(7)[2(7) - 1] / 2 = 91 = (196-14)/2
H: 12[11] / 2 = 66 = [9(16)-12]/2 = [96 + 48-12]/2 = 144-12/2
HB: 8[7]/2 = 28 = (64-8)/2

base forecast samples obtained (in gaussian case) using sample co-variance matrices


When using the HB approach, the COVARIANCE matrix of the reconciliation and based forecasts will be identical

--

We invert the co-variance matrix in order to properly adjust for different amounts of uncertainty, where we weight forecasts with higher uncertainty (higher variance) as lesser contributors to the overall reconcile forecast.

Matrix M is trying to get the incoherent base forecasts into the coherent subspace s. For example, you can make forecasts for x, y, and z cross-sectional dimensions that are not coherent (x + y =/= z) in such a way that the vectors span 3 dimensional space. However, coherent forecasts where x + y = z only exist on a 2 dimensional plain (since there are only two distinct directions, as x and y can be added up to get z)


x = Sb
x_tilde = SGx_hat

x_tilde = S b_tilde
implies G x_hat = b_tilde?


co-variance matrix

sigma^2(T, year1)  sigma^2(T, half1;)



variance(T) covariance(T, X) covariance(T, Y)
covariance(T, X) variance(X) covariance(X, Y)
covariance(T, Y) covariance(X, Y) variance(Y)

variance(year) covariance(year, half1) covariance(year, half2) covariance(year, quarter1) covariance(year, quarter2) covariance(year, quarter3) covariance(year, quarter4)
covariance(year, half1) variance(half1) covariance(half1, half2)covariance(half1, quarter1) covariance(half1, quarter2) covariance(half1, quarter3) covariance(half1, quarter4)
covariance(year, half2) covariance(half1, half2) variance(half2)


$\begin{bmatrix}
\sigma^2(T, \tau) & \sigma^2(T, 2\tau-1) & \sigma^2(T, 2\tau) & 


var | description | value | est | estimate | dim
:--:|:-----:|:----------:|:---------:|:---:|:-----:
$\boldsymbol{\Omega}$ | BF cov | " | $\hat{\boldsymbol{\Omega}}$ | sample cov (use resid) | $n(k^*+m) \times n(k^*+m)$
$\boldsymbol{\Omega}_{hf-bts}$ | BF cov | " | $\hat{\boldsymbol{\Omega}}$ | " for hfbts subset | $n_bm \times n_bm$
$\boldsymbol{\Omega}_{hf}$ | BF cov | " | $\hat{\boldsymbol{\Omega}}$ | " for hfbts subset | $n_bm \times n_bm$

$\tilde{\boldsymbol{\Omega}}$ | reconciled forecasts cov | $\boldsymbol{M} {\boldsymbol{\Omega}}\boldsymbol{M}'$ | $n(k^*+m) \times n(k^*+m)$ | $\tilde{\boldsymbol{\Omega}}$ | reconciled forecasts cov | $\boldsymbol{M} {\boldsymbol{\Omega}}\boldsymbol{M}'$ | $n(k^*+m) \times n(k^*+m)$