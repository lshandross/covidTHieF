# Cross-temporal Probabilistic Forecast Reconciliation
This is the most recent paper from the Hyndman group who have been thinking about how to optimize hierarchical forecasting. Their group has done work on both spatial and temporal hierarchies, for both point and probabilistic forecasting, and this work generalize is that work so that each of the previous implementations are considered special cases. Specifically, here they look at defining probabilistic forecasts with both a spatial (cross-sectional) and temporal hierarchy, calling it a cross-temporal hierarchy (which are coherent).

## Introduction
- Approach optimizes accuracy of (probabilistic) hierarchical forecasts through their reconciliation-based methodology
- Developed by the Hyndman group, who have research interests in hierarchical forecasting
- Builds on their previous work for many types of hierarchical forecasting
  - Spatial (cross-sectional) and temporal hierarchies
  - Point and probabilistic forecasts
- Generalizes different cases to single methodology: cross-temporal probabilistic forecasts
  - 2 dimensional hierarchy that's both cross-sectional and temporal
  - Single dimension of either is considered special case


## Types of hierarchical forecasts
- Two main types of hierarchy/hierarchical forecasts: cross-sectional and temporal
  - Cross-sectional more well-known
- Can be combined into 2D hierarchy structure

![](./hierarchy_types.png)

- Hierarchical forecasts (point-only) are said to be *coherent* when those at lower levels add up those at higher levels
  - *Reconciliation* is the process of making hierarchical forecasts coherent

## Why coherence/reconciliation
[Image of incoherent forecasts]

- Reconciliation: "A post-forecasting process intended to improve the quality of forecasts for system of linearly constrained multiple time series"
- Coherence means that forecasts are aligned and consistent
  - For point forecasting, this can be thought of as the forecasts at lower levels adding up to those at higher levels
- Incoherent hierarchical forecasts may predict different futures, forcing modelers to choose a single level to trust
- But if reconciliation is performed first, we can combine the information from all levels to obtain a (hopefully) better single forecast that agrees at all levels
  - Hyndman's group has shown their reconciliation methods lead to higher forecast accuracy

  - Their methods are unique because they reconcile both dimensions simultaneously instead of sequentially

## Methodology overview
1. Clearly define the hierarchy and aggregate observed data appropriately
2. Generate (incoherent) base forecasts
    - Select an estimator $\hat{\boldsymbol{\Omega}}_x$ to use for the base forecasts' covariance matrix
    - Estimate covariance matrices using residuals
3. Reconcile forecasts using one of several methods
  1. Parametric framework: Gaussian reconciliation
      1. Through Theorem 3.1 (base forecast samples)
          - Draw samples $\hat{\boldsymbol{x}}_l$ from the base forecast distribution $N(\hat{\boldsymbol{x}}, \boldsymbol{\Omega})$
          - Select an estimator $\hat{\boldsymbol{\Omega}}_{ct,x}$ to use for cross-temporal covariance matrix
          - Estimate cross temporal covariance matrix using residuals
          - Use $\tilde{\boldsymbol{x}}_l = \boldsymbol{M}\hat{\boldsymbol{x}}_l$ to obtain reconciled forecast samples
      2. High Frequency Bottom Time Series Forecasts
          - Obtain the high frequency, bottom time series reconciled forecast distribution
          - Calculate reconciled forecast samples using the cross-temporal structural matrix
  2. NonParametric framework: Bootstrap reconciliation
      - Draw samples from all (cross-sectional) series simultaneously from the most temporally aggregated level
      - Estimate the reconciled forecast's covariance matrix using the base forecast residuals

## Notation Basics
- $\boldsymbol{y}_t = [y_{1,t},...,y_{i,t},..., y_{n,t}]'$ is an $n$-variate linearly constrained time series observed at the most temporally disaggregated level (bottom-level) with a seasonality of period $m$ at time $t$
  - Note, this means that ALL values (bottom and upper levels) in a cross-sectional hierarchy will be included in this vector
  - This is generally considered the observed time series
- $\boldsymbol{x}_{i,t} = [\boldsymbol{x}_{i,t}^{[m]},...,\boldsymbol{x}_{i,t}^{[k]},..., \boldsymbol{x}_{i,t}^{[1]}]'$ is the representation for a general time series with only one (bottom) cross-sectional level
  - Here, ALL values in a temporal hierarchy will be included in this vector
  - Note that $x_{t}^{[1]} = y_{t}$, meaning that observed time series are always aggregated to create a temporal hierarchy
    - Aggregation is summarized by [eqn]
  - Also, each temporal level (associated with its factor $k$) is represented by its own vector $\boldsymbol{x}_{i,t}^{[k]}$

- The cross-sectional reconciliation approach is obtained assuming $m = 1$ while the temporal one is obtained when $n = 1$ ($n_a = 0, n_b = 1$)
  - So $n$ can be understood as the number of dimensions cross-sectionally while $m$ is related to the temporal dimension (seasonality for the bottom-level compare to the highest aggregation level)

## Notation: Temporal Aggregation
A temporal hierarchy for a quarterly series (seasonality $m = 4$, factors $k = \{4, 2, 1\}$) with only 1 cross-sectionale component (i = 1)  
$\hspace{1.5cm} x_{1, j}^{[4]} \hspace{5.8cm} x_{1,\tau}^{[4]}$  
$\hspace{1.5cm} y_{T, t} \hspace{4.3cm} x_{1, 2\tau-1}^{[2]} \hspace{2cm} x_{1, 2\tau}^{[2]}$  
$\hspace{0.75cm} y_{X, t} \hspace{0.75cm} y_{Y, t} \hspace{3.0cm} y_{1, 4\tau-3} \hspace{0.5cm} y_{1, 4\tau-2} \hspace{0.65cm} y_{1, 4\tau-1} \hspace{0.5cm} y_{1, 4\tau}$  
$\hspace{1.4cm} \boldsymbol{(a)} \hspace{6cm} \boldsymbol{(b)}$  
</fieldset>  ,

- Observed time series: {$y_{i,t}: i = 1; t = 1, ..., T$}
- Obtain aggregated values using $x_{1,j}^{[k]} = \Sigma_{t = (j-1)k+1}^{jk} y_t$ (series-based notation)
  - uses time index $j = 1, ..., T/k$, which is level-specific ($j = t$ at bottom-most level)
  - useful when considering each level of the hierarchy individually (e.g. as its own time series)
  - e.g. First ($j = 1$) semi-annual value $x_{1,1}^{[2]} = y_1 + y_2$
- Universal notation: $x_{1,j}^{[k]} = x_{M_k(\tau-1)+z}^{[k]}$
  - time index $\tau = 1, ..., N$ standardized to be defined by most-aggregate level series
  - $N$ is the length of the top-most series, $M_k = m/k$, and $z = 1, ..., M_k$ (index within $\tau$)
  - useful when considering temporal hierarchy structure as a whole

## Notation: Big Picture
Different notation used to denote same/similar aspects for cross-sectional and temporal dimensions so that they may be combined for cross-temporal case

But the same principles/equations hold for both one-dimensional cases

{We'll go through the simpler cases first, then the combined cross-temporal case, which will then be the lens through which we examine the full methodology}

## Notation: Cross Sectional vs Temporal
$\hspace{0cm} \boldsymbol{(a)} \textrm{ Cross-Sectional} \hspace{4cm} \boldsymbol{(b)} \textrm{ Temporal}$  

$\hspace{7.9cm} x_{i,\tau}^{[4]}$  
$\hspace{1.5cm} y_{T, t} \hspace{4.3cm} x_{i, 2\tau-1}^{[2]} \hspace{2cm} x_{i, 2\tau}^{[2]}$  
$\hspace{0.75cm} y_{X, t} \hspace{0.75cm} y_{Y, t} \hspace{3.0cm} y_{i, 4\tau-3} \hspace{0.5cm} y_{i, 4\tau-2} \hspace{0.65cm} y_{i, 4\tau-1} \hspace{0.5cm} y_{i, 4\tau}$  

variable | cross-sectional | temporal
:-------:|:-----------:|:-----------:
time index | $t = 1, ..., T$ | $j = 1, ..., T/k \newline$ (standardized to $\tau = 1, ..., N$)
bottom-level series | $\boldsymbol{b}_t$ | $\boldsymbol{y}_t = \boldsymbol{x}_{\tau}^{[1]}$ 
bottom-level elements | ${y}_{i,t}$ for $i = n_a+1,...,n$ | ${x}_{1, M_k(\tau-1) + z}^{[1]}$ | ${x}_{i, M_k(\tau-1)+z}^{[k]}$ for $i = n_a + 1, ...n$
upper-level series | $\boldsymbol{u}_t$ | $\boldsymbol{x}_t^{[k]}$, for $k \neq 1$
upper-level elements | ${y}_{i,t}$ for $i = 1, ...,n_a$ | ${x}_{1, M_k(\tau-1) + z}^{[k]}$
combined series | $\boldsymbol{y}_t$ | $\boldsymbol{x}_{1,\tau}$ | matrix $\boldsymbol{X}_t$, vector $\boldsymbol{x}_t$
combined elements | ${y}_{i,t}$ for $i = 1,...,n$ | $\boldsymbol{x}_{1, \tau}^{[k]}$ | ${x}_{i, M_k(\tau-1)+z}^{[k]}$ for $i = 1, ..., n$
num bottom elements | $n_b$ | $k_p = m$ (seasonality)
num upper elements | $n_a$ | $k^*$
total num elements | $n = n_b + n_a$ | $m + k^* = \Sigma K$

Differences
- Cross-sectional has single matrix for upper-level series while temporal has individual vectors for each upper-level series
- ~~Cross-sectional assumes series observed at each level while temporal assumes only bottom-most is observed and the hierarchy must be created from the bottom-level series~~
- Each cross-sectional ELEMENT in the hierarchy is considered its own series while each temporal LEVEL is considered its own series

## Notation: Equations (for Cross-Sectional and Temporal Cases)
A simple 2-level cross-sectional hierarchy for $n = 3$ time series with $n_a = 1$ and $n_b = 2$   
$\boldsymbol{y}_t \hspace{8.9cm} x_{i,\tau}^{[4]}$  
$\boldsymbol{u}_t \hspace{2.5cm} y_{T, t} \hspace{4.3cm} x_{i, 2\tau-1}^{[2]} \hspace{2cm} x_{i, 2\tau}^{[2]}$  
$\boldsymbol{b}_t \hspace{1.75cm} y_{X, t} \hspace{0.75cm} y_{Y, t} \hspace{3.0cm} y_{i, 4\tau-3} \hspace{0.5cm} y_{i, 4\tau-2} \hspace{0.65cm} y_{i, 4\tau-1} \hspace{0.5cm} y_{i, 4\tau}$  

- Aggregation matrix $\boldsymbol{A}_{cs}$ $(n_a \times n_b)$ connects upper and lower level time series $\boldsymbol{u}_t = \boldsymbol{A}_{cs}\boldsymbol{b}_t$
  - Temporal $\boldsymbol{A}_{te}$ has a specific matrix of expressions ($\begin{bmatrix} \boldsymbol{1}_{k_p} & \boldsymbol{I}_{m/(k_{p-1})} \otimes \boldsymbol{1}_{k_{p-1}} & \cdots & \boldsymbol{I}_{m/k2} \otimes \boldsymbol{1}_{k2} \end{bmatrix}'$)
  - Generally no reason for upper to be restricted to simple sums of bottom, so $\boldsymbol{A}_{cs} \in R^{n_a n_b}$
- Zero constraints matrix $\boldsymbol{C} = \begin{bmatrix} \boldsymbol{I}_{n_a} & -\boldsymbol{A}_{cs} \end{bmatrix}$, with dimensions $(n_a \times n)$
  - Constraints equation $\boldsymbol{C} \boldsymbol{y}_t = \boldsymbol{0}_{(n_a \times 1)}$ (equality to 0-vector implies coherence, i.e. upper - sum(bottom) = 0)
- Structural matrix $\boldsymbol{S}_{cs} = \begin{bmatrix} \boldsymbol{A}_{cs} & \boldsymbol{I}_{n_b} \end{bmatrix}'$ with dimensions $(n \times n_b)$
  - Structural representation: $\boldsymbol{y}_t = \boldsymbol{S}_{cs} \boldsymbol{b}_t$

## Notation: Cross-Temporal Case
We combine notation for both of the single-dimensional cases

- Stack series cross-sectionally into $[n \times (m + k^*)]$ matrix $\boldsymbol{X}_{\tau}$
- Rows and columns represent cross-sectional and temporal dimensions of $\boldsymbol{X}_{\tau}$ respectively: 
  $$\boldsymbol{X}_{\tau} = \begin{bmatrix} \boldsymbol{x}_{1,\tau}' & \cdots & \boldsymbol{x}_{i,\tau}' & \cdots & \boldsymbol{x}_{n,\tau}' \end{bmatrix}' = \begin{bmatrix} \boldsymbol{U}_{\tau}^{[k_p]} &\cdots & \boldsymbol{U}_{\tau}^{[k]} & \cdots & \boldsymbol{U}_{\tau}^{[1]} \\ \boldsymbol{B}_{\tau}^{[k_p]} & \cdots & \boldsymbol{B}_{\tau}^{[k]} & \cdots & \boldsymbol{B}_{\tau}^{[1]} \end{bmatrix}$$ 
  $$= \left[\begin{array}{c|cc|cccc}
  x^{[4]}_{1,\tau} & x^{[2]}_{1,2\tau-1} & x^{[2]}_{1,2\tau} & y_{1,4\tau-3} & y_{1,4\tau-2} & y_{1,4\tau-1} & y_{1,4\tau}\\
  \hline
  x^{[4]}_{2,\tau} & x^{[2]}_{2,2\tau-1} & x^{[2]}_{2,2\tau} & y_{2,4\tau-3} & y_{2,4\tau-2} & y_{2,4\tau-1} & y_{2,4\tau}\\
  x^{[4]}_{3,\tau} & x^{[2]}_{3,2\tau-1} & x^{[2]}_{3,2\tau} & y_{3,4\tau-3} & y_{3,4\tau-2} & y_{3,4\tau-1} & y_{3,4\tau}\\
  \end{array}\right]$$
  where for any fixed $k$, $\boldsymbol{U}_{\tau}^{[k]}$ is the $(n_a\times N_k)$ matrix grouping the upper time series and $\boldsymbol{B}_{\tau}^{[k]}$ is the $(n_b\times N_k)$ matrix grouping the bottom time series

- Vector version $\boldsymbol{x}_{\tau} = \textrm{vec}(\boldsymbol{X}_{\tau}) = \begin{bmatrix} \boldsymbol{x}_{1,\tau}' , \cdots , \boldsymbol{x}_{i,\tau}' , \cdots , \boldsymbol{x}_{n,\tau}' \end{bmatrix}'$ (append rows of original matrix into a vector)
- NO aggregation matrix $\boldsymbol{A}_{cs}$
- Zero constraints matrix $\boldsymbol{C}_{ct} = \begin{bmatrix} \boldsymbol{C}_* & \boldsymbol{I}_n \otimes \boldsymbol{C}_{te} \end{bmatrix}'$ (NOT the same as 1D cases)
  - Constraints equation $\boldsymbol{C}_{ct} \boldsymbol{x}_t = \boldsymbol{0}_{[(n_a m + nk^*) \times 1]}$ (similar to 1D cases), also
    - Cross-sectional component: $\boldsymbol{C}_{cs} \boldsymbol{X}_{\tau} = \boldsymbol{0}_{n_a \times (m+ k^*)}$
    - Temporal component: $\boldsymbol{C}_{te} * \boldsymbol{X}_{\tau}' = \boldsymbol{0}_{k^* \times n}$
- Structural matrix $\boldsymbol{S}_{ct} = \boldsymbol{S}_{cs} \otimes \boldsymbol{S}_{te}$, with dimensions $[n(k^*+m)\times n_bm]$ (NOT the same as 1D cases)
  - Structural representation: $\boldsymbol{x}_{\tau} = \boldsymbol{S}_{ct} \boldsymbol{b}_{\tau}^{[1]} = s(\boldsymbol{b}_{\tau}^{[1]})$ (similar to 1D cases), where $\boldsymbol{b}_{\tau}^{[1]} = \textrm{vec}(\boldsymbol{B}_{\tau}^{[1]})$

## Cross-Temporal Case Example
[show diagrams and figures of applied equations]

![](./ct-prob_fig2.png)
![](./ct-prob_fig3.png)

## Notation: Cross-Temporal Structural Elements
$$\boldsymbol{X}_{\tau} = \begin{bmatrix} \boldsymbol{x}_{1,\tau}' & \cdots & \boldsymbol{x}_{i,\tau}' & \cdots & \boldsymbol{x}_{n,\tau}' \end{bmatrix}' = \begin{bmatrix} \boldsymbol{U}_{\tau}^{[k_p]} &\cdots & \boldsymbol{U}_{\tau}^{[k]} & \cdots & \boldsymbol{U}_{\tau}^{[1]} \\ \boldsymbol{B}_{\tau}^{[k_p]} & \cdots & \boldsymbol{B}_{\tau}^{[k]} & \cdots & \boldsymbol{B}_{\tau}^{[1]} \end{bmatrix}$$ 
$$= \left[\begin{array}{c|cc|cccc}
x^{[4]}_{1,\tau} & x^{[2]}_{1,2\tau-1} & x^{[2]}_{1,2\tau} & y_{1,4\tau-3} & y_{1,4\tau-2} & y_{1,4\tau-1} & y_{1,4\tau}\\
\hline
x^{[4]}_{2,\tau} & x^{[2]}_{2,2\tau-1} & x^{[2]}_{2,2\tau} & y_{2,4\tau-3} & y_{2,4\tau-2} & y_{2,4\tau-1} & y_{2,4\tau}\\
x^{[4]}_{3,\tau} & x^{[2]}_{3,2\tau-1} & x^{[2]}_{3,2\tau} & y_{3,4\tau-3} & y_{3,4\tau-2} & y_{3,4\tau-1} & y_{3,4\tau}\\
\end{array}\right]$$

- Structural matrix $\boldsymbol{S}_{ct} = \boldsymbol{S}_{cs} \otimes \boldsymbol{S}_{te}$, with dimensions $[n(k^*+m)\times n_bm]$
- Structural representation: $\boldsymbol{x}_{\tau} = \boldsymbol{S}_{ct} \boldsymbol{b}_{\tau}^{[1]} = s(\boldsymbol{b}_{\tau}^{[1]})$
  - $s \textrm{ : } \mathbb{R}^{n_b m} \rightarrow \mathbb{R}^{n(m + k^*)}$ is the operator describing the pre-multiplication by $\boldsymbol{S}_{ct}$
- $\boldsymbol{x}_{\tau}$ lies in an $(n_bm)$-dimensional subspace $\mathfrak{s}_{ct}$ of $\mathbb{R}^{n(k^*+m)}$, which we refer to as the *cross-temporal coherent subspace*, spanned by the columns of $\boldsymbol{S}_{ct}$
  - The aggregated observations are coherent because this is assumed cross-sectionally and we create the temporal hierarchy from the bottom up

## Optimal Point Forecast Reconciliation (Cross-Temporal) pt1
Define (incoherent) base forecasts similarly to cross-temporal aggregated observations:
- For $h = 1, \cdots, H$, let $$\hat{\boldsymbol{X}}_{h} = \begin{bmatrix} \boldsymbol{\hat{x}}_{1, h}' \\ \vdots \\ \boldsymbol{\hat{x}}_{n, h}' \end{bmatrix} = \begin{bmatrix} \boldsymbol{\hat{U}}_{h}^{[m]} & \cdots & \boldsymbol{\hat{U}}_{h}^{[k]} & \cdots & \boldsymbol{\hat{U}}_{h}^{[1]} \\ \boldsymbol{\hat{B}}_{h}^{[m]} & \cdots & \boldsymbol{\hat{B}}_{h}^{[k]} & \cdots & \boldsymbol{\hat{B}}_{h}^{[1]} \end{bmatrix},$$ be the $h$-step ahead *base forecasts*, where 
  - $\hat{\boldsymbol{U}}_h^{[k]}$ is the $(n_a \times M_k)$ matrix grouping the upper time series,
  - $\hat{\boldsymbol{B}}_h^{[k]}$ is the $(n_b \times M_k)$ matrix grouping the bottom time series for a given temporal aggregation order $k$, and
  - $H$ is the forecast horizon for the most temporarily aggregated time series
- Since $\hat{\boldsymbol{X}}_{\tau}$ contains incoherent forecasts, the constraints equation doesn't hold $\boldsymbol{C}_{ct} \hat{\boldsymbol{x}}_t \neq \boldsymbol{0}_{[(n_a m + nk^*) \times 1]}$

## Optimal Point Forecast Reconciliation (Cross-Temporal) pt2
Transform base forecasts $\hat{\boldsymbol{x}}_h$ for a given horizon $h = 1, \cdots, H$ using mapping $\psi : \mathbb{R}^{n(m + k^*)} \rightarrow \mathfrak{s}$ to obtain reconciled forecasts
$$\tilde{\boldsymbol{x}}_h = \psi(\hat{\boldsymbol{x}}_h) = \boldsymbol{M}\hat{\boldsymbol{x}}_h \hspace{1cm} \equiv \hspace{1cm}  (s \circ g)(\hat{\boldsymbol{x}}_h) = \boldsymbol{S}_{ct}\boldsymbol{G}\hat{\boldsymbol{x}}_h$$ where 
  - $\boldsymbol{M} = \boldsymbol{I}_{n(m+k^*)} - \boldsymbol{\Omega}_{ct}\boldsymbol{C}_{ct}'(\boldsymbol{C}_{ct}\boldsymbol{\Omega}_{ct}\boldsymbol{C}_{ct}')^{-1}\boldsymbol{C}_{ct}$ for a positive definite matrix $\boldsymbol{\Omega}_{ct}$
  - $\boldsymbol{M} = \boldsymbol{S}_{ct} \boldsymbol{G}$ for $\boldsymbol{G} = (\boldsymbol{S}_{ct}' \boldsymbol{\Omega}_{ct}^{-1}\boldsymbol{S}_{ct})^{-1}\boldsymbol{S}_{ct}'\boldsymbol{\Omega}_{ct}^{-1}$
    - Here we are weighing different elements in the hierarchy (defined by the structural matrix) based on their inverse covariance, i.e. give less weight to elements that tend to vary more
  - $\tilde{\boldsymbol{x}}_h = \textrm{vec}(\tilde{\boldsymbol{X}}_h') \in \mathfrak{s}$

The minimum variance linear unbiased reconcile forecasts, satisfying the unbiasedness condition $E(\tilde{\boldsymbol{x}}_h-\boldsymbol{x}_h) = 0$, has solution(5) when $\boldsymbol{\Omega}_{ct} = \textrm{Var}(\hat{\boldsymbol{x}}_h - \boldsymbol{x}_h)$
  - Note there are many methods to obtain an estimator for this covariance matrix

## Cross-temporal bottom-up forecast reconciliation
While optimal cross-temporal reconciliation is preferred, it is computationally costly in 2D, especially for probabilistic forecasts

Instead, we first perform optimal reconciliation along one dimension, then bottom-up on the other (blue = reconciled, pink = bottom-up)

![](./ct-prob_fig4.png)

## Probabilistic Forecast Reconciliation
The authors make use of probability measures to extend cross-temporal point forecasts reconciliation to the probabilistic case, building on previous equations.
- A probability measure defines an experiment and parameters that describe various characteristics of this experiment, more specifically:
  - all the possible outcomes (the sample space), a subset of events that have occurred or we're interested in (the event space, a type of sigma algebra), and a function that describes the probability of each possible event (the probability function)

However, this math is somewhat complicated and a simpler version, more inline with the point forecasting case outlined previously, can be obtained by using samples instead from these probability measures

**Theorem 3.1** (Cross-temporal reconciled samples): Suppose that $(\hat{\boldsymbol{x}}_1, \cdots, \hat{\boldsymbol{x}}_L)$ is a sample drawn from a (cross-temporal) incoherent probability measure $\hat{v}$. Then $(\tilde{\boldsymbol{x}}_1, \cdots, \tilde{\boldsymbol{x}}_L)$ is a sample drawn from the (cross-temporal), reconcile probability measure $\tilde{v}$ defined in (7) where $\tilde{\boldsymbol{x}}_l = \psi(\hat{\boldsymbol{x}}_l)$ and $l = 1, \cdots, L$ 
($L$ is furthest out horizon, according to the top-most time index, you're interested in forecasting for)

This basically says that a sample from the reconciled distribution can be obtained by reconciling each member of a sample from the in-coherent distribution

This allows for separating the mechanism used to generate base forecast samples from the reconciliation face

## Probabilistic Forecast Reconciliation (Probability Measures)
Let $(\mathbb{R}^{n_b m}, \mathcal{F}_{\mathbb{R}^{n_b m}}, \mathcal{v})$ be a probability space for the bottom-time series $\boldsymbol{b}_{\tau}^{[1]}$, where $\mathcal{F}_{\mathbb{R}^{n_b m}}$ is the usual Borel $\sigma$-algebra on $\mathbb{R}^{n_b m}$. Then a $\sigma$-algebra $\mathcal{F}_{\mathfrak{s}}$ can then be constructed as the collection of sets $s(\mathcal{B})$ for all $\mathcal{B} \in \mathcal{F}_{\mathbb{R}^{n_b m}}$ 

**Definition 3.1** (Cross-temporal coherent probabilistic forecasts): Given the probability space $(\mathbb{R}^{n_b m}, \mathcal{F}_{\mathbb{R}^m}, \mathcal{v})$, we define the coherent probability space as the triple $(\mathfrak{s}, \mathcal{F}_{\mathfrak{s}}, \u{\mathcal{v}})$ satisfying the following property: $\u{v}(s(\mathcal{B})) = v(\mathcal{B}) \hspace{10pt} \forall \mathcal{B} \in \mathcal{F}_{\mathbb{R}^{n_b m}}$

**Definition 3.2** (Cross-temporal probabilistic forecast reconciliation): The reconciled probability measure of $\hat{\mathcal{v}}$ with respect to $\psi$ is a probability measure $\tilde{\mathcal{v}}$ on $\mathfrak{s}$ with $\sigma$-algebra $\mathcal{F}_{\mathfrak{s}}$ satisfying:
  $$\tilde{v}(\mathcal{A}) = \hat{v}(\psi^{-1}(\mathcal{A})), \hspace{1cm} \forall \mathcal{A} \in \mathcal{F}_{\mathfrak{s}} \hspace{1in} (7)$$ where
  - $\psi^{-1}(\mathcal{A}) = {x \in \mathbb{R}^{n(m + k^*)} : \psi(x) \in \mathcal{A}}$ denotes the pre-image of $\mathcal{A}$ (x is the pre-image of A)
- The map $\psi$ may be obtained as the composition $s \circ g$, as for the cross-temporal point reconciliation(6)

## Probabilistic Forecast Reconciliation (Continued)
There are two options to use the samples method to obtain reconciled probabilistic forecasts
1. Through a parametric framework, using Gaussian distributions
2. Through bootstrap sampling

(I could only get the code for the parametric framework to run, so that's what I'll be using)

## Probabilistic Forecast Reconciliation: Parametric (Gaussian) Framework
Generally it's possible to obtain reconciled probabilistic forecasts analytically for some parametric distributions
- We choose the multivariate normal due to some desirable properties and its ubiquity

Begin with base forecasts with distribution $N(\hat{\boldsymbol{x}}, \boldsymbol{\Omega})$ where $\boldsymbol{\hat{x}}$ is the mean vector and $\boldsymbol{\Omega}$ is the covariance matrix of the base forecasts

Then the reconciled forecasts have distribution $N(\tilde{\boldsymbol{x}}, \tilde{\boldsymbol{\Omega}})$ where $$\tilde{\boldsymbol{x}} = \boldsymbol{M}\hat{\boldsymbol{x}} \textrm{  and  } \boldsymbol{\tilde{\Omega}} = \boldsymbol{M \Omega M}', \hspace{3cm} (8)$$ where $\boldsymbol{M}$ is the projection matrix defined in (5)

The authors also note that if it's assumed that $\boldsymbol{\Omega}=\boldsymbol{\Omega}_{ct}$, then the co-variance matrix above simplifies to $\tilde{\boldsymbol{\Omega}}=\boldsymbol{M\Omega}_{ct}$

However, we don't know the covariance matrix in practice, and it is difficult to estimate in the two-dimensional cross-temporal case, so we either
1. Utilize the properties of elliptical distributions to simulate from the high frequency bottom time series, then calculate a simulation of the full reconciled distribution using the $\boldsymbol{S}_{ct}$ matrix OR
2. Use Theorem 3.1 to obtain reconciled forecast samples from base forecast samples, which avoids the need to calculate the co-variance matrix for the reconciled forecast distribution

## Probabilistic Forecast Reconciliation: Parametric (Gaussian) Framework
![](./ct-prob_fig5.png)

1. Use theorem 3.1 to transform transform base forecasts samples into reconciled ones
2. Use high frequency bottom time series of reconciled distribution to calculate reconciled forecast (similar to aggregation set-up/results)

Note that Theorem 3.1 is more powerful than the two equations $\tilde{\boldsymbol{x}} = \boldsymbol{M}\hat{\boldsymbol{x}}$ and $\boldsymbol{\tilde{\Omega}} = \boldsymbol{M \Omega M}'$, as the former generalizes to all vectors $\hat{\boldsymbol{x}}_l$ NOT just the mean vector (and co-variance matrix that follows)

## Probabilistic Forecast Reconciliation: Non-parametric framework (Bootstrap Reconciliation)

Parametric method may be unsuitable due to:
1. Analytical expressions for base and reconcile forecast distributions being hard to obtain
2. Parametric assumptions being restrictive and unrealistic

Cross-temporal joint (block) bootstrap (ctjb): Procedure to generate samples from base forecast distributions that preserve cross-temporal relationships 
- Draw samples of all series simultaneously from most temporarily aggregated level and using that to determine the corresponding time indices for other levels
- Important to accurately reflect underlying data distribution
- Easily scalable for large data sets or for improved speed

## Probabilistic Forecast Reconciliation: Non-parametric framework (Bootstrap Reconciliation)

Let $\mathcal{M}_i$ be the model used to calculate the base forecasts and residuals for the $i^{th}$ series (i.e. choose any forecasting model to make the initial base forecasts to be used for bootstrapping)

Assuming $H = 1$, $\tau$ is a random draw with replacement from $1, \cdots, N$ and the $l^{th}$ bootstrap incoherent sample is $\hat{\boldsymbol{x}}_{i,l}^{[k]} = f_i(\mathcal{M}_i,\hat{\boldsymbol{e}}_i^{[k]})$, where $f_i(\cdot)$ depends on the fitted model $\mathcal{M}_i$

That is, $\hat{\boldsymbol{x}}_{i,l}^{[k]}$ is a sample path simulated for the $i^{th}$ series with error approximated by the corresponding block bootstrapped sample residual $\hat{\boldsymbol{e}}_i^{[k]}$, the $i^{th}$ row of 

m = 4, k = {4, 2, 1}
$$\hat{\boldsymbol{E}}_{1}^{[1]} = \begin{bmatrix} \hat{e}_{T, 1}^{[1]} & \hat{e}_{T, 2}^{[1]} & \hat{e}_{T, 3}^{[1]} & \hat{e}_{T, 4}^{[1]} \\ \hat{e}_{X, 1}^{[1]} & \hat{e}_{X, 2}^{[1]} & \hat{e}_{X, 3}^{[1]} & \hat{e}_{X, 4}^{[1]} \\ \hat{e}_{Y, 1}^{[1]} & \hat{e}_{Y, 2}^{[1]} & \hat{e}_{Y, 3}^{[1]} & \hat{e}_{Y, 4}^{[1]} \end{bmatrix} \cdots \hat{\boldsymbol{E}}_{4}^{[1]} = \begin{bmatrix} \hat{e}_{T, 13}^{[1]} & \hat{e}_{T, 14}^{[1]} & \hat{e}_{T, 15}^{[1]} & \hat{e}_{T, 16}^{[1]} \\ \hat{e}_{X, 13}^{[1]} & \hat{e}_{X, 14}^{[1]} & \hat{e}_{X, 15}^{[1]} & \hat{e}_{X, 16}^{[1]} \\ \hat{e}_{Y, 13}^{[1]} & \hat{e}_{Y, 14}^{[1]} & \hat{e}_{Y, 15}^{[1]} & \hat{e}_{Y, 16}^{[1]} \end{bmatrix}$$
$$\hat{\boldsymbol{E}}_{1}^{[4]} = \begin{bmatrix} \hat{e}_{T, 1}^{[4]} \\ \hat{e}_{X, 1}^{[4]} \\ \hat{e}_{Y, 1}^{[4]} \end{bmatrix} \cdots \hat{\boldsymbol{E}}_{4}^{[4]} = \begin{bmatrix} \hat{e}_{T, 13}^{[4]} \\ \hat{e}_{X, 13}^{[4]} \\ \hat{e}_{Y, 13}^{[4]} \end{bmatrix}$$

(It seems like the reconciled forecasts are obtained by applying Theorem 3.1 to the bootstrapped samples/residuals)

## Probabilistic Forecast Reconciliation: Non-parametric framework (Bootstrap Reconciliation)
![](./ct-prob_fig6.png)

Example of bootstrap residuals for 3 linearly constrained quarterly time series (same recurring example from Figure 1), color coded by year (most-aggregated level)
Left: individual residual matrices $\hat{\boldsymbol{E}}^{[k]}$ for each temporal level $k \in \mathcal{K}$
Right: $L$ total bootstrapped samples (grouped by $\tau$) with replacement, e.g. $L$ = {2, 1, 2, 2, 3, 4, 1, 4}

## Cross-temporal co-variance matrix estimation
Natural estimate is empirical sample covariance matrix of base forecasts, but this involves many parameters, especially for the cross-temporal case ($r = n(k^*+m)[n(k^*+m)-1]/2$)

Common solution of using a shrinkage estimator (like global shrinkage, which shrinks non-diagonal elements to zero) may result in info loss since the co-variance matrix has built-in hierarchical structure

Instead, estimate a smaller (covariance) matrix which can be multiplied by (known) structural matrices to preserve hierarchical structure and improve estimate of covariance matrix
$$\boldsymbol{\tilde{\Omega}} = \boldsymbol{S}_{ct} \boldsymbol{\Omega}_{hf-bts} \boldsymbol{S}_{ct}' \newline
\hspace{2.15cm} = (\boldsymbol{I}_n \otimes \boldsymbol{S}_{te}) \boldsymbol{\Omega}_{hf} (\boldsymbol{I}_n \otimes \boldsymbol{S}_{te})' \newline
\hspace{3.25cm} = (\boldsymbol{S}_{cs} \otimes \boldsymbol{I}_{m+k^*}) \boldsymbol{\Omega}_{b
ts} (\boldsymbol{S}_{cs} \otimes \boldsymbol{I}_{m+k^*})'$$
3 decompositions, each characterized by well-defined structures (hierarchy types), and smaller covariance matrices

Note that $\boldsymbol{\Omega}_{HB} \neq \boldsymbol{\Omega}_{hf-bts}$, nor are their dimensions the same, as the former are estimates of the reconciled covariance matrix for the ENTIRE hierarchy while the latter are co-variance matrices of SUBSETS of the hierarchy.

Note: hf-bts = *High frequency bottom time series shrinkage matrix (HB)*

Basically, what these equations are saying is that you can obtain the co-variance for all parts of the reconciled hierarchy by summing up the co-variance from just the bottom levels of the base forecasts hierarchy AS LONG AS it's reasonable to assume that the base forecast errors and base forecasts themselves are approximately coherent. If this is not true, use the hf or bts decomposition.

## Cross-temporal co-variance matrix estimation (continued)
Apply "Stein-Type Shrinkage" to each of the following matrices by using corresponding empirical base forecasts residuals estimation (obtained from the MinT shrinkage method)

(Estimators make use of the decompositions given on previous slide)

method | matrix | series | dim | estimator for $\tilde{\boldsymbol{\Omega}}$
:-----:|:-----:|:----------:|:---------:|:----------------------------:
HB | $\boldsymbol{\Omega}_{hf-bts}$ | $\boldsymbol{b}_t^{[1]}$ | $n_bm \times n_bm$ | $\lambda \boldsymbol{S}_{ct} \hat{\boldsymbol{\Omega}}_{hf-bts,D} \boldsymbol{S}_{ct}' + (1 - \lambda) \boldsymbol{S}_{ct} \hat{\boldsymbol{\Omega}}_{hf-bts} \boldsymbol{S}_{ct}'$
H | $\boldsymbol{\Omega}_{hf}$ | $\boldsymbol{x}_t^{[1]}$ | $nm \times nm$ | $\lambda (\boldsymbol{I}_{n} \otimes \boldsymbol{S}_{te}) \hat{\boldsymbol{\Omega}}_{hf,D} (\boldsymbol{I}_{n} \otimes \boldsymbol{S}_{te})' + (1 - \lambda) (\boldsymbol{I}_{n} \otimes \boldsymbol{S}_{te}) \hat{\boldsymbol{\Omega}}_{hf} (\boldsymbol{I}_{n} \otimes \boldsymbol{S}_{te})'$
B | $\boldsymbol{\Omega}_{bts}$ | $\boldsymbol{b}_t$ | $n_b(k^*+m) \times n _b(k^*+m)$ | $\lambda (\boldsymbol{S}_{cs} \otimes \boldsymbol{I}_{m+k^*}) \hat{\boldsymbol{\Omega}}_{bts,D} (\boldsymbol{S}_{cs} \otimes \boldsymbol{I}_{m+k^*})' + (1 - \lambda) (\boldsymbol{S}_{cs} \otimes \boldsymbol{I}_{m+k^*}) \hat{\boldsymbol{\Omega}}_{bts} (\boldsymbol{S}_{cs} \otimes \boldsymbol{I}_{m+k^*})'$
G | $\boldsymbol{\Omega}$ | $\boldsymbol{x}_t$ | $n(k^*+m) \times n(k^*+m)$ | $\lambda \hat{\boldsymbol{\Omega}}_{D} + (1 - \lambda) \hat{\boldsymbol{\Omega}}$, where $ \hat{\boldsymbol{\Omega}}_{D} = \hat{\boldsymbol{\Omega}} \odot \boldsymbol{I}_{n(k^*+m)}$

where $\hat{\boldsymbol{\Omega}}_{I,D} = \boldsymbol{I}_{n_b m} \odot \hat{\boldsymbol{\Omega}}_{j}, l = \{hf-bts, hf, bts\}$ and $\lambda$ is the shrinkage parameter

These matrices are not full rank (inverses don't exist, though we need them to compute production to the coherent subspace). This is addressed using a ridge regularization of the form $\hat{\boldsymbol{\Omega}} + \omega \boldsymbol{I}$, where $\omega$ is chosen to make the matrix invertible without introducing excessive bias

We can show that the equations on the previous slide are true because M simplifies down to an identity matrix using inverse matrix rules, hence: $$\tilde{\boldsymbol{\Omega}} = \boldsymbol{M}\hat{\boldsymbol{\Omega}}_{HB}\boldsymbol{M} = \cdots = \boldsymbol{S}_{ct}' \boldsymbol{\Omega}_{hf-bts}\boldsymbol{S}_{ct} = \hat{\boldsymbol{\Omega}}_{HB}$$

## Cross-temporal co-variance matrix estimation (continued)
Visual insights on co-variance matrices obtainable with shrinkage parameter $\lambda=\{0,1\}$ for running example of cross-temporal hierarchy ($n=3,m=4$). These are all estimates of the co-variance matrix for the entire reconciled hierarchy.

![](./ct-prob_fig7.png)

black = not modified by shrinkage, light blue = modified by shrinkage, white = shrunk to zero   
dark blue = derived directly from hierarchy, not estimated

The covariance matrix can be split into 9, 7x7 squares representing the $n = 3$ cross-sectional dimension. The squares on the diagonal are the variance of the three series, with the remaining six being the covariance between series.

Each 7x7 square contains the temporal aspects of the covariance matrix. Again, the squares on the diagonal represent the variances of the 7 elements in the temporal hierarchy while the off diagonal squares represent the covariances between the 7 elements

For HB, only the variances of the bottom X, Y series for the most disaggregate quarterly time series and covariances between them need to be estimated. With full shrinkage, the covariances are shrunk to zero.
- For the other elements which are obtained by the summing matrix, this results in non-zero values for only pairs of elements in which one depends on the other. For example, the year is obtained by summing either 4 quarters or two halves, so the covariance between the year and any given half or quarter is preserved. However, the covariance between half1 and either quarter3 or quarter4 is shrunk to zero. Similarly, the covariance between any two quarters is also shrunk to zero.

## Cross-temporal co-variance matrix estimation (continued)
Number of parameters needed to be estimated: $G > B > H > HB$
- [smaller_dim(smaller_dim - 1)] / 2
  
Using HB covariance matrix assumes base error covariance matrix is coherent (valid if base forecasts are approximately coherent, which is expected for any reasonable set of forecasts)

**Theorem 4.1**   Let $\hat{\boldsymbol{\Omega}}_{hf-bts}$ be a $(n_b m \times n _b m)$ positive definite matrix. Then, using $\boldsymbol{\Omega}_{ct} = \boldsymbol{S}_{ct} \hat{\boldsymbol{\Omega}}_{hf-bts} \boldsymbol{S}_{ct}'$ in the reconciliation formulae below is equivalent to using $\boldsymbol{\Omega}_{ct} = \boldsymbol{I}_{n(m + k^*)}$ (ols approach)

$$\tilde{\boldsymbol{x}}_h = \psi(\hat{\boldsymbol{x}}_h) = \boldsymbol{M}\hat{\boldsymbol{x}}_h \hspace{1cm} \equiv \hspace{1cm}  (s \circ g)(\hat{\boldsymbol{x}}_h) = \boldsymbol{S}_{ct}\boldsymbol{G}\hat{\boldsymbol{x}}_h$$ 

\
In forecast experiments and simulation, we closely analyze these different constructions with dual purpose:
- Full co-variance matrix ($\lambda=0$) of base forecasts used to obtain base forecast samples of linearly constrained time series under that Gaussianity
- Shrinkage versions used as approximations of co-variance matrix for reconciliation (excluding HB, see Theorem 4.1)

This allows better understanding of properties and abilities of each parameterization

## Multi-step Residuals
Calculated as $e_{i,h,j}^{[k]} = x_{i,j+h}^{[k]} - \hat{x}_{i,j+h | j'}^{[k]}$, where $i = 1,...,n;j=1,...,N_k$ and 
  $\hat{x}_{i,j+h|t}^{[k]}$ is the *h*-step fitted value, calculated as the $h$-step-ahead forecast using data up to time $j$
  - in general these residuals will be auto-correlated except when $h = 1$

We can organize these residuals into various matrices, similar to the base forecasts in Section 2.1 (note those aren't shown in the same granularity) with $N$ total obs for the top-level series
- By series, temporal level, horizon ($N_k$ total): $\boldsymbol{e}_{i,h}^{[k]} = \begin{bmatrix} e_{i,h,1}^{[k]} & e_{i,h,2}^{[k]} & ... & e_{i,h,N_k}^{[k]} \end{bmatrix}'$ with $h = 1,...,M_k$
- By series and temporal level (all horizons) $$
  \boldsymbol{E}_i^{[k]} = \begin{bmatrix}
    e_{i, 1, 1}^{[k]} & e_{i, 2, 2}^{[k]} & \cdots & e_{i, M_k, M_k}^{[k]} \\
    \vdots & \vdots & & \vdots \\
    e_{i, 1, N_k-M_k+1}^{[k]} & e_{i, 2, N_k-M_k+2}^{[k]} & \cdots & e_{i, M_k, N_k}^{[k]} \\
  \end{bmatrix}.$$
- Temporal level $\boldsymbol{E}_i = \begin{bmatrix} \boldsymbol{E}_i^{[m]} & \boldsymbol{E}_i^{[k_p-1]} & \cdots & \boldsymbol{E}_i^{[1]} \end{bmatrix}$
- Entire $[N \times N(m+k^*)]$ cross-temporal residual matrix $\boldsymbol{E} = \begin{bmatrix} \boldsymbol{E}_1 & \boldsymbol{E}_2 & ... & \boldsymbol{E}_n \end{bmatrix}$

Simulation study finds that simulating base forecasts from multi-step residuals allows for more accurate estimation of covariance matrix (compared to what??) and that reconciliation further improves forecast accuracy

- Similar to (implicitly given) base forecast organization in 2.1 $\hat{\boldsymbol{x}}_{i,h}^{[k]} = \begin{bmatrix} \hat{x}_{i,h,1}^{[k]} & \hat{x}_{i,h,2}^{[k]} & ... & \hat{x}_{i, h, N_k}^{[k]} \end{bmatrix}'$ with $h = 1,...,H$ vs $\boldsymbol{e}_{i,h}^{[k]} = \begin{bmatrix} e_{i,h,1}^{[k]} & e_{i,h,2}^{[k]} & ... e_{i,h,N_k}^{[k]} \end{bmatrix}'$ with $h = 1,...,M_k$

Gaussian and bootstrap approaches used to construct cross-temporal samples of base forecasts
- Parametric approach: Multi-step residuals with different co-variance matrix structures analyzed in 4.1
- Non parametric approach: Regular one-step residuals

Reconciled co-variance matrices always closer to true matrix than base forecast matrix for both approaches, no major differences between residual types

Simulating based forecasts from multi-step residuals allows us to estimate a co-variance matrix close to the true one, with reconciliation able to further improve accuracy of estimates

1-step residuals lead to a biased estimate of coherence matrix where some correlation are zeros by definition

## Overlapping residuals
Another issue of cross-temporal reconciliation is low number of available residuals, especially for higher orders of temporal aggregation

Possible solution: use residuals calculated using overlapping series by allowing the year to have a varying starting time, e.g. for $y = [y_1, ..., y_6]$ construct $x^{[2, 0]} = [y_1 + y_2, y_3 + y_4, y_5 + y_6]$ and $x^{[2, 0]} = [y_2 + y_3, y_4 + y_5]$ with different start times

Steps to calculate overlapping residuals:
1. Fit a model to $\boldsymbol{x}^{[k, 0]}$ (i.e., select an appropriate model and estimate the model parameters using the available data) and calculate the residuals
2. Apply the same model in step 1 to $\boldsymbol{x}^{[k, s]}$ for $s = 1, \cdots, k-1$, without re-estimating the parameters and calculate the residuals

Note, this approach assumes the model used in step one is appropriate for all the different series $\boldsymbol{x}^{[k, s]}$

Some seasonal models won't be appropriate as the seasonal pattern will be shifted for different values of $s$, though this doesn't affect SARIMA models whose seasonality is defined in terms of lags, which are unaffected by the value of $s$

## Variables
Covariance matrices. Note that $\boldsymbol{\Omega}_{ct}$ is a positive definite matrix used in reconciling the base forecasts. The minimum variance linear unbiased reconciled forecasts yields the general reconciliation equation (5) when $\boldsymbol{\Omega}_{ct} = \textrm{Var}(\hat{\boldsymbol{x}}_h - \boldsymbol{x}_h)$, and (sometimes?) it is reasonable to assume that $\boldsymbol{\Omega} = \boldsymbol{\Omega}_{ct}$.
method | BF true subset | BF est subset | RF true subset | RF approx (full)
:--:|:-----:|:----------:|:---------:|:-----:
G | $\boldsymbol{\Omega}$ | $\hat{\boldsymbol{\Omega}}$ | $\tilde{\boldsymbol{\Omega}}$ | $\hat{\boldsymbol{\Omega}}_G$
H | $\boldsymbol{\Omega}_{hf}$ | $\hat{\boldsymbol{\Omega}}_{hf}$ | $\tilde{\boldsymbol{\Omega}}_{hf}$ | $\hat{\boldsymbol{\Omega}}_{H}$
B | $\boldsymbol{\Omega}_{bts}$ | $\hat{\boldsymbol{\Omega}}_{bts}$ | $\tilde{\boldsymbol{\Omega}}_{bts}$ | $\hat{\boldsymbol{\Omega}}_{B}$
HB | $\boldsymbol{\Omega}_{hf-bts}$ | $\hat{\boldsymbol{\Omega}}_{hf-bts}$ | $\tilde{\boldsymbol{\Omega}}_{hf-bts}$ | $\hat{\boldsymbol{\Omega}}_{HB}$

## Example Methodology
- oct(.) is probabilistic reconciliation using samples and theorem 3.1
- oct_h(.) is probabilistic reconciliation using the reconciled forecast distribution with its co-variance matrix $\tilde{\boldsymbol{\Omega}}$, using linked multi-step residuals
- oct_o(.) is probabilistic reconciliation using the reconciled forecast distribution with its co-variance matrix $\tilde{\boldsymbol{\Omega}}$, using overlapping residuals
- oct_oh(.) is probabilistic reconciliation using the reconciled forecast distribution with its co-variance matrix $\tilde{\boldsymbol{\Omega}}$, using overlapping, multi-step residuals


| | Base | forecasts' | sample | approach | -
:---:|:---:|:---:|:---:|:---:|:---:|
**Reconciliation** | $\textrm{ctjb}$ | - | $\textrm{Gaussian}$ | $\textrm{Approach*}$ | -
**Approach** | - | $G$ | $B$ | $H$ | $HB$
$\textrm{base}$ | $\hat{\boldsymbol{x}}_l$ bootstrap; no reconciliation | $\hat{\boldsymbol{x}}_l \sim N(\hat{\boldsymbol{x}}, \hat{\Omega})$; no rec | $\hat{\boldsymbol{x}}_l \sim N(\hat{\boldsymbol{x}}, \hat{\Omega}_{bts})$; no rec | $\hat{\boldsymbol{x}}_l \sim N(\hat{\boldsymbol{x}}, \hat{\Omega}_{hf})$; no rec | $\hat{\boldsymbol{x}}_l \sim N(\hat{\boldsymbol{x}}, \hat{\Omega}_{hf-bts})$; no rec
$\textrm{ct}(shr_{cs}, bu_{te})$ | $\hat{\boldsymbol{x}}_l$ bootstrap; $\boldsymbol{\Omega}_{cs} = \boldsymbol{W}_{shr}$ | $\hat{\boldsymbol{x}}_l \sim N(\hat{\boldsymbol{x}}, \hat{\Omega})$; $\boldsymbol{\Omega}_{cs} = \boldsymbol{W}_{shr}$ | $\hat{\boldsymbol{x}}_l \sim N(\hat{\boldsymbol{x}}, \hat{\Omega}_{bts})$; $\boldsymbol{\Omega}_{cs} = \boldsymbol{W}_{shr}$ | $\hat{\boldsymbol{x}}_l \sim N(\hat{\boldsymbol{x}}, \hat{\Omega}_{hf})$; $\boldsymbol{\Omega}_{cs} = \boldsymbol{W}_{shr}$ | $\hat{\boldsymbol{x}}_l \sim N(\hat{\boldsymbol{x}}, \hat{\Omega}_{hf-bts})$; $\boldsymbol{\Omega}_{cs} = \boldsymbol{W}_{shr}$
$\textrm{oct}(ols)$ | $\hat{\boldsymbol{x}}_l$ bootstrap; $\boldsymbol{\Omega}_{ct} = \boldsymbol{I}_{n(m + k^*)}$ | $\hat{\boldsymbol{x}}_l \sim N(\hat{\boldsymbol{x}}, \hat{\Omega})$; $\boldsymbol{\Omega}_{ct} = \boldsymbol{I}_{n(m + k^*)}$ | $\hat{\boldsymbol{x}}_l \sim N(\hat{\boldsymbol{x}}, \hat{\Omega}_{bts})$; $\boldsymbol{\Omega}_{ct} = \boldsymbol{I}_{n(m + k^*)}$ | $\hat{\boldsymbol{x}}_l \sim N(\hat{\boldsymbol{x}}, \hat{\Omega}_{hf})$; $\boldsymbol{\Omega}_{ct} = \boldsymbol{I}_{n(m + k^*)}$ | $\hat{\boldsymbol{x}}_l \sim N(\hat{\boldsymbol{x}}, \hat{\Omega}_{hf-bts})$; $\boldsymbol{\Omega}_{ct} = \boldsymbol{I}_{n(m + k^*)}$ 
$\textrm{oct}(struc)$ | $\hat{\boldsymbol{x}}_l$ bootstrap; $\boldsymbol{\Omega}_{ct} = \textrm{diag}(\boldsymbol{S}_{ct}\boldsymbol{1}_{mn_b})$ | $\hat{\boldsymbol{x}}_l \sim N(\hat{\boldsymbol{x}}, \hat{\Omega})$; $\boldsymbol{\Omega}_{ct} = \textrm{diag}(\boldsymbol{S}_{ct}\boldsymbol{1}_{mn_b})$ | $\hat{\boldsymbol{x}}_l \sim N(\hat{\boldsymbol{x}}, \hat{\Omega}_{bts})$; $\boldsymbol{\Omega}_{ct} = \textrm{diag}(\boldsymbol{S}_{ct}\boldsymbol{1}_{mn_b})$ | $\hat{\boldsymbol{x}}_l \sim N(\hat{\boldsymbol{x}}, \hat{\Omega}_{hf})$; $\boldsymbol{\Omega}_{ct} = \textrm{diag}(\boldsymbol{S}_{ct}\boldsymbol{1}_{mn_b})$ | $\hat{\boldsymbol{x}}_l \sim N(\hat{\boldsymbol{x}}, \hat{\Omega}_{hf-bts})$; $\boldsymbol{\Omega}_{ct} = \textrm{diag}(\boldsymbol{S}_{ct}\boldsymbol{1}_{mn_b})$ 
$\textrm{oct}(wlsv)$ | $\hat{\boldsymbol{x}}_l$ bootstrap; $\boldsymbol{\Omega}_{ct} = \hat{\boldsymbol{\Omega}}_{ct,wlsv}$ | $\hat{\boldsymbol{x}}_l \sim N(\hat{\boldsymbol{x}}, \hat{\Omega})$; $\boldsymbol{\Omega}_{ct} = \hat{\boldsymbol{\Omega}}_{ct,wlsv}$ | $\hat{\boldsymbol{x}}_l \sim N(\hat{\boldsymbol{x}}, \hat{\Omega}_{bts})$; $\boldsymbol{\Omega}_{ct} = \hat{\boldsymbol{\Omega}}_{ct,wlsv}$ | $\hat{\boldsymbol{x}}_l \sim N(\hat{\boldsymbol{x}}, \hat{\Omega}_{hf})$; $\boldsymbol{\Omega}_{ct} = \hat{\boldsymbol{\Omega}}_{ct,wlsv}$ | $\hat{\boldsymbol{x}}_l \sim N(\hat{\boldsymbol{x}}, \hat{\Omega}_{hf-bts})$; $\boldsymbol{\Omega}_{ct} = \hat{\boldsymbol{\Omega}}_{ct,wlsv}$ 
$\textrm{oct}(bdshr)$ | $\hat{\boldsymbol{x}}_l$ bootstrap; $\boldsymbol{\Omega}_{ct} = \boldsymbol{P}\hat{\boldsymbol{W}}_{ct,shr}^{BD}\boldsymbol{P'}$ | $\hat{\boldsymbol{x}}_l \sim N(\hat{\boldsymbol{x}}, \hat{\Omega})$; $\boldsymbol{\Omega}_{ct} = \boldsymbol{P}\hat{\boldsymbol{W}}_{ct,shr}^{BD}\boldsymbol{P'}$ | $\hat{\boldsymbol{x}}_l \sim N(\hat{\boldsymbol{x}}, \hat{\Omega}_{bts})$; $\boldsymbol{\Omega}_{ct} = \boldsymbol{P}\hat{\boldsymbol{W}}_{ct,shr}^{BD}\boldsymbol{P'}$ | $\hat{\boldsymbol{x}}_l \sim N(\hat{\boldsymbol{x}}, \hat{\Omega}_{hf})$; $\boldsymbol{\Omega}_{ct} = \boldsymbol{P}\hat{\boldsymbol{W}}_{ct,shr}^{BD}\boldsymbol{P'}$ | $\hat{\boldsymbol{x}}_l \sim N(\hat{\boldsymbol{x}}, \hat{\Omega}_{hf-bts})$; $\boldsymbol{\Omega}_{ct} = \boldsymbol{P}\hat{\boldsymbol{W}}_{ct,shr}^{BD}\boldsymbol{P'}$ 
$\textrm{oct}_h(bshr)$ | $\hat{\boldsymbol{x}}_l$ bootstrap; $\boldsymbol{\Omega}_{ct} = (\boldsymbol{S}_{cs} \otimes \boldsymbol{I}_{m + k^*})\hat{\boldsymbol{\Omega}}_{bts} (\boldsymbol{S}_{cs} \otimes \boldsymbol{I}_{m + k^*})'$ | $\hat{\boldsymbol{x}}_l \sim N(\hat{\boldsymbol{x}}, \hat{\Omega})$; $\boldsymbol{\Omega}_{ct} = (\boldsymbol{S}_{cs} \otimes \boldsymbol{I}_{m + k^*})\hat{\boldsymbol{\Omega}}_{bts} (\boldsymbol{S}_{cs} \otimes \boldsymbol{I}_{m + k^*})'$ | $\hat{\boldsymbol{x}}_l \sim N(\hat{\boldsymbol{x}}, \hat{\Omega}_{bts})$; $\boldsymbol{\Omega}_{ct} = (\boldsymbol{S}_{cs} \otimes \boldsymbol{I}_{m + k^*})\hat{\boldsymbol{\Omega}}_{bts} (\boldsymbol{S}_{cs} \otimes \boldsymbol{I}_{m + k^*})'$ | $\hat{\boldsymbol{x}}_l \sim N(\hat{\boldsymbol{x}}, \hat{\Omega}_{hf})$; $\boldsymbol{\Omega}_{ct} = (\boldsymbol{S}_{cs} \otimes \boldsymbol{I}_{m + k^*})\hat{\boldsymbol{\Omega}}_{bts} (\boldsymbol{S}_{cs} \otimes \boldsymbol{I}_{m + k^*})'$ | $\hat{\boldsymbol{x}}_l \sim N(\hat{\boldsymbol{x}}, \hat{\Omega}_{hf-bts})$; $\boldsymbol{\Omega}_{ct} = (\boldsymbol{S}_{cs} \otimes \boldsymbol{I}_{m + k^*})\hat{\boldsymbol{\Omega}}_{bts} (\boldsymbol{S}_{cs} \otimes \boldsymbol{I}_{m + k^*})'$ 
$\textrm{oct}_h(hshr)$ | $\hat{\boldsymbol{x}}_l$ bootstrap; $\boldsymbol{\Omega}_{ct} = (\boldsymbol{I}_n \otimes \boldsymbol{S}_{te})\hat{\boldsymbol{\Omega}}_{hf} (\boldsymbol{I}_n \otimes \boldsymbol{S}_{te})'$ | $\hat{\boldsymbol{x}}_l \sim N(\hat{\boldsymbol{x}}, \hat{\Omega})$; $\boldsymbol{\Omega}_{ct} = (\boldsymbol{I}_n \otimes \boldsymbol{S}_{te})\hat{\boldsymbol{\Omega}}_{hf} (\boldsymbol{I}_n \otimes \boldsymbol{S}_{te})'$ | $\hat{\boldsymbol{x}}_l \sim N(\hat{\boldsymbol{x}}, \hat{\Omega}_{bts})$; $\boldsymbol{\Omega}_{ct} = (\boldsymbol{I}_n \otimes \boldsymbol{S}_{te})\hat{\boldsymbol{\Omega}}_{hf} (\boldsymbol{I}_n \otimes \boldsymbol{S}_{te})'$ | $\hat{\boldsymbol{x}}_l \sim N(\hat{\boldsymbol{x}}, \hat{\Omega}_{hf})$; $\boldsymbol{\Omega}_{ct} = (\boldsymbol{I}_n \otimes \boldsymbol{S}_{te})\hat{\boldsymbol{\Omega}}_{hf} (\boldsymbol{I}_n \otimes \boldsymbol{S}_{te})'$ | $\hat{\boldsymbol{x}}_l \sim N(\hat{\boldsymbol{x}}, \hat{\Omega}_{hf-bts})$; $\boldsymbol{\Omega}_{ct} = (\boldsymbol{I}_n \otimes \boldsymbol{S}_{te})\hat{\boldsymbol{\Omega}}_{hf} (\boldsymbol{I}_n \otimes \boldsymbol{S}_{te})'$ 

When do we use Theorem 3.1 vs the other Gaussian reconciliation method? Also, why isn't there an example of using the high frequency, bottom time series matrix for the oct method? Is it because that's equivalent to the Ols method, as stated in Theorem 4.1?

## Example: Forecasting Australian GDP
- dataset: Australian Quarterly National Accounts (QNA), 1984Q4-2018Q1 ($n = 95$)
  - define GDP from both Income and Expenditure sides
  - training samples: Rolling, expanding window - 1984Q4-1994Q3, ..., 1984Q4-2017Q1 (91 forecast origins)
- base forecaster: Univariate ARIMA models
- aggregation scheme: quarterly, semi-annual, annual ($K = \{4, 2, 1\}$)

- reconciliation approaches (approximations for $\boldsymbol{\Omega}_{ct}$ for use in $\tilde{\boldsymbol{x}}_l = \boldsymbol{M} \hat{\boldsymbol{x}}_l$)
  - Gaussian case: uses sample covariance matrix to estimate $\tilde{\boldsymbol{\Omega}}$ (and associated ${\boldsymbol{\Omega}}$) for $N(\tilde{\boldsymbol{x}}, \tilde{\boldsymbol{\Omega}})$
    - base forecast samples (1000 total) obtained using sample co-variance matrices with G and H parameterization (not possible to identify unique representation for other cases)
    - Compare results using multi-step residuals w/ and w/o overlapping to measure benefit of overlapping residuals
  - Non-parametric case: cross-temporal joint bootstrap (ctjb) strategy to generate 1000 samples

## Forecasting Australian GDP (Evaluation)
- Probabilistic forecast accuracy evaluated using relative versions of CRPS and energy score (ES):
$$\overline{\textrm{RelCRPS}}_{j,s}^{[k]} = (\Pi_{i=1}^n CRPS_{i,j,s}^{[k]} /CRPS_{i,0,0}^{[k]})^{1/n} \hspace{0.5cm} \textrm{ and } \hspace{0.5cm} \overline{\textrm{RelES}}_{j,s}^{[k]} = ES_{j,s}^{[k]} / ES_{0,0}^{[k]}$$ with reconciliation approach $j$ and base forecast simulation approach $s$
$$\overline{\textrm{RelCRPS}}_{j,s} = (\Pi_{i=1,\cdots,n;k \in K} CRPS_{i,j,s}^{[k]} /CRPS_{i,0,0}^{[k]})^{1/[n(k^*+m)]} \hspace{0.5cm} \textrm{ and } \hspace{0.5cm} \overline{\textrm{RelES}}_{j,s} = (\Pi_{k \in K} ES_{j,s}^{[k]} / ES_{0,0}^{[k]})^{1/(k^*+m)}$$ with reconciliation approach $j$ and base forecast simulation approach $s$
  - Reference approach ($j, s = 0$) is (unreconciled) base forecasts produced by bootstrapping

  - Continuous Ranked Probability Score (CRPS): Index that considers the single series and provides a marginal evaluation of the approaches
  - Energy score (ES): CRPS extension to multivariate case, evaluates it forecast accuracy for whole system

## Forecasting Australian GDP (Results)
![](./ct-prob_tab3.png)
- bold: approach better than benchmark
- red: worse than benchmark
- blue: overall lowest value

Summary of results
- Base forecasts: Normal parametric approach >> Non-parametric bootstrap
  - Likely due to limited number of residuals available for bootstrapping (data not sufficiently explored)
- Directly specifying diagonal co-variance matrices >> Shrinking to target co-variance matrix
- $\textrm{ct}(wls_{cs}, bu_{te})$ and $\textrm{oct}(wlsv)$ show greatest relative gains over benchmark, $\textrm{oct}(hshr)$ shows least
- Greatest improvements observe for higher temporal aggregation levels

## Forecasting Australian GDP (Results)
![](./ct-prob_fig8.png)

Multiple Comparison with the Best (MCB) Nemenyi Test using CRPS to determine if forecasting performances of different techniques are significantly different from one another (intervals of two procedures don't overlap)
- Mean rank of each approach printed next to its name on y-axis
- Approaches that don't overlap with blue-interval considered significantly worse than the best, $\textrm{ct}(wls_{cs}, bu_{te})$ and $\textrm{oct}(wlsv)$
  - Note here one partly bottom up approach is not significantly worse than best-performing optimal approach

## Forecasting Australian GDP (Results Summary)
- Overlapping residuals almost always lead to greater improvement in both ES and CRPS
- Forecasts at the most aggregated level benefit the most from reconciliation
- Using one-step overlapping residuals sufficiently improves forecasts if generation of base forecasts sample paths accounts for multi-step structure

## Example: Forecasting Australian Tourism Demand
dataset: Australian Tourism Demand, measures nights Australians spent away from home
- $T=228$ monthly observations of Visitor Nights (VN) from 1/1998-12/2016; $K = \{12, 4, 3, 2, 1\}$
- Cross-sectional structure: Geography and Purpose of Travel
  - Purpose of travel: holiday, visiting friends/relatives, business, other

**Table 4:** Grouped time series for the Australian Tourism Demand dataset
- | *GD* | *PT* | **Tot**
----------:|:--:|:--:|:--
Australia | 1 | 4 | *5*
States | 7 | 28 | *35*
Zones* | 21 | 81 | *105*
Regions | 76 | 304 | *380*
**Total** | *105* | *420* | **525**

*6 Zones with only one Region are included in Regions (24 nodes not considered); GD = Geographic Division, PT = Purpose of Travel

## Example: Forecasting Australian Tourism Demand
- Rolling forecast experiment with expanding window: (85 total)
  - Training sets: 01/1998-12/2008, ..., 01/1998-12/2015
  - Testing sets (1 year of forecasts): 2009, ..., 2016
- Base forecasts for *k*-step ahead: $K = \{12, 6, 4, 2, 1\}$(aggregate to yearly)
- ETS models selected by minimizing $AIC_c$ criterion fitted to log-transformed data, than back-transformed to produce non-negative forecasts
- Final forecasts obtained similarly to those in the previous section using approaches introduced earlier in this paper
- The same evaluation metrics CRPS, ES, and MCB Nemenyi test also applied here

## Forecasting Australian Tourism Demand (Results)
![](./ct-prob_tab5.png)
- bold: approach better than benchmark
- red: worse than benchmark
- blue: overall lowest value

Summary of results
- Base forecasts: Normal parametric approach >> Non-parametric bootstrap
  - Strict truncated (non-zero) Gaussianity assumptions can lead to improved forecasts in terms of CRPS and ES given limited number of residuals (bootstrap approach's downfall)
- No big differences in using different co-variance matrix estimates for Gaussian base forecasts
  - So only using high frequency by time series can be useful to reduce estimated parameters and initial high dimensionality
- Partly Bottom-up techniques in Gaussian case >> Benchmark
  - But not guaranteed improvement greater than starting base forecasts for Gaussian approach (e.g. compare rows 1 and 2 of each block), esp for larger $k$
- Overall $\textrm{oct}(bdshr)$ always the best in terms of CRPS+ still competitive in terms of ES (loses to $\textrm{oct}_h(bdshr)$)
- Shrinkage approach $\textrm{oct}_h(hshr)$ performs well in bootstrap case: competitive with $\textrm{oct}(bdshr)$ at $k = 1, 2$ and is able to improve for $k \geq 3$
- Note: $\textrm{oct}(bdshr)$ (which doesn't use residuals) is competitive by consistently improving upon base forecasts for both metrics

## Forecasting Australian Tourism Demand (Results)
![](./ct-prob_fig9.png)

Multiple Comparison with the Best (MCB) Nemenyi Test using CRPS to determine if forecasting performances of different techniques are significantly different from one another (intervals of two procedures don't overlap)
- Mean rank of each approach printed next to its name on y-axis
- Approaches that don't overlap with blue-interval considered significantly worse than the best, $\textrm{ct}(wls_{cs}, bu_{te})$ and $\textrm{oct}(wlsv)$
  - Note here one partly bottom up approach is not significantly worse than best-performing optimal approach

- Partly Bottom of Procedure >> Monthly based forecasts, but optimal cross-temporal procedures ALWAYS better
- Bootstrap $\textrm{oct}(bdshr)$, $\textrm{oct}(hshr)$, $\textrm{oct}(struc)$ almost always in best approach group
- Gaussian $\textrm{oct}(wlsv)$, $\textrm{oct}(struc)$, $\textrm{oct}(bdshr)$ always significantly better than base forecasts and equally good for $k > 2$ (monthly $\textrm{oct}(bdshr)$ always significantly better than all others)

## Forecasting Australian Tourism Demand (Results Summary)
- Overlapping residuals almost always lead to greater improvement in both ES and CRPS
- Forecasts at the most aggregated level benefit the most from reconciliation
- Using one-step overlapping residuals sufficiently improves forecasts if generation of base forecasts sample paths accounts for multi-step structure

## Conclusion
- Extend probabilistic reconciliation setting from Panagiotelis (2023) for across sectional case to cross-temporal
  - Reinterpret and extend theorems and definitions
- General notation proposed helps investigate extensions following different probabilistic approaches developed by the Hyndman group
- Gaussian and bootstrap approach to simulate base forecasts that accounts for both cross-sectional and temporal dimensions simultaneously
- Analyze usage of residuals: one-step residuals failed to capture temporal structure -> multi-step residuals to fully capture cross-temporal relationships
- Four alternative forms of co-variance matrices to reduce number of estimated parameters due to a high-dimensionality of cross-temporal setting
  - Overlapping residuals may reduce high-dimensionality burden by increasing number of residuals available
- Both applications show optimal cross-temporal reconciliation significantly improves over base forecasts
  - Simultaneously exploiting both dimensions in reconciliation provides better results than uni-dimensional reconciliation (partly bottom-up), especially at higher levels of temporal aggregation
    - especially for tourism application's richer temporal hierarchies, allowing regression-based forecast reconciliation to capture and exploit more features of the data throughout the temporal levels
  - $\textrm{oct}(wlsv)$ and $\textrm{oct}(bdshr)$ are two best performing approaches for both improving forecast accuracy and computational efficiency (corroborates previous point forecast reconciliation results)
- cross-temporal forecast reconciliation important tool to improve accuracy of forecasts while simultaneously ensuring coherency in space and time  
- Techniques can also be customized to suit specific needs of organization, allowing for an corporation of relevant domain-specific knowledge and expertise, ensuring resulting forecasts are accurate, coherent, and more reliable for decision making process

---

Generation of base forecasts paths
1. Gaussian approach (employs a sample covariance matrix to estimate $\tilde{\boldsymbol{\Omega}}$ for $N(\tilde{\boldsymbol{x}}, \tilde{\boldsymbol{\Omega}})$?)
    1. Global, multi-step residuals $G_h$ (base forecast distribution $N(\hat{\boldsymbol{x}}, \hat{\boldsymbol{\Omega}})$)
    2. High frequency, multi-step residuals $H_h$ (base forecast distribution $N(\hat{\boldsymbol{x}}, \hat{\boldsymbol{\Omega}}_{hf})$)
    3. Global, overlapping and multi-step residuals $G_{oh}$
    4. High frequency, overlapping and multi-step residuals $H_{oh}$
2. Non-parametric approach: cross-temporal joint bootstrap (ctjb)

Reconciliation approach (approximations for $\boldsymbol{\Omega}_{ct}$ for use in $\tilde{\boldsymbol{x}}_l = \boldsymbol{M} \hat{\boldsymbol{x}}_l$)
1. Base (no reconciliation performed)
2. Cross temporal $\textrm{ct} (\cdot)$, partly bottom up starting from cross-sectional reconciled forecasts using the
    1. Shrinkage approach $\textrm{ct}(shr_{cs}, bu_{te})$
    2. Weighted Least Squares approach $\textrm{ct}(wls_{cs}, bu_{te})$
3. Optimal cross-temporal reconciliation $\textrm{oct}(\cdot)$, using the
    1. Structural approach $\textrm{oct}(struc)$
    2. Weighted Least Squares Variance approach with one-step residuals $\textrm{oct}(wlsv)$
    3.  Block diagonal shrunk cross-covariance scaling approach with one-step residuals $\textrm{oct}(bdshr)$
4. Optimal cross-temporal reconciliation $\textrm{oct}_h (\cdot)$ (Section 4) using the
    1. High Frequency Shrinkage approach $\textrm{oct}_h(hshr)$
    2. Bottom time series Shrinkage approach $\textrm{oct}_h(bshr)$
5. Optimal cross-temporal reconciliation, using overlapping residuals $\textrm{oct}_o(\cdot)$
    1. Structural approach $\textrm{oct}_o(struc)$
    2. Weighted Least Squares Variance approach with overlapping residuals $\textrm{oct}_o(wlsv)$
    3.  Block diagonal shrunk cross-covariance scaling approach with overlapping residuals $\textrm{oct}_o(bdshr)$
6. Optimal cross-temporal reconciliation, using overlapping and multi-step residuals $\textrm{oct}_{oh}(\cdot)$
    1. High Frequency Shrinkage approach $\textrm{oct}_{oh}(hshr)$
    2. Bottom time series Shrinkage approach $\textrm{oct}_{oh}(bshr)$

---

This is proved by the following:
$\tilde{\boldsymbol{x}}_h = \boldsymbol{S}_{ct}\boldsymbol{G}\hat{\boldsymbol{x}}_h \Rightarrow \boldsymbol{S}_{ct}\tilde{\boldsymbol{b}}_{h}^{[1]} = \boldsymbol{S}_{ct}\boldsymbol{G}\hat{\boldsymbol{x}}_h \Rightarrow \tilde{\boldsymbol{b}}_{h}^{[1]} = \boldsymbol{G}\hat{\boldsymbol{x}}_h \Rightarrow \tilde{\boldsymbol{b}}_{h}^{[1]} = [(\boldsymbol{S}_{ct}' \boldsymbol{\Omega}_{ct}^{-1}\boldsymbol{S}_{ct})^{-1}\boldsymbol{S}_{ct}'\boldsymbol{\Omega}_{ct}^{-1}]\hat{\boldsymbol{x}}_h$
$\tilde{\boldsymbol{b}}_{ols}^{[1]} = [(\boldsymbol{S}_{ct}'\boldsymbol{S}_{ct})^{-1}\boldsymbol{S}_{ct}']\hat{\boldsymbol{x}}_h$
$\tilde{\boldsymbol{b}}_{hb}^{[1]} = [\boldsymbol{S}_{ct}'(\boldsymbol{S}_{ct} \hat{\boldsymbol{\Omega}}_{hf-bts} \boldsymbol{S}_{ct}')^{-1}\boldsymbol{S}_{ct}]^{-1}\boldsymbol{S}_{ct}'(\boldsymbol{S}_{ct} \hat{\boldsymbol{\Omega}}_{hf-bts} \boldsymbol{S}_{ct}')^{-1} \hat{\boldsymbol{x}}_h$
Then, using inverse matrix rules, it can be shown that these two equations are equal by simplifying the latter one


where 
  - $\boldsymbol{M} = \boldsymbol{I}_{n(m+k^*)} - \boldsymbol{\Omega}_{ct}\boldsymbol{C}_{ct}'(\boldsymbol{C}_{ct}\boldsymbol{\Omega}_{ct}\boldsymbol{C}_{ct}')^{-1}\boldsymbol{C}_{ct}$ for a positive definite matrix $\boldsymbol{\Omega}_{ct}$
  - $\boldsymbol{M} = \boldsymbol{S}_{ct} \boldsymbol{G}$ for $\boldsymbol{G} = (\boldsymbol{S}_{ct}' \boldsymbol{\Omega}_{ct}^{-1}\boldsymbol{S}_{ct})^{-1}\boldsymbol{S}_{ct}'\boldsymbol{\Omega}_{ct}^{-1}$
  - $\tilde{\boldsymbol{x}}_h = \textrm{vec}(\tilde{\boldsymbol{X}}_h') \in \mathfrak{s}$

  - $\boldsymbol{M} = \boldsymbol{S}_{ct} \boldsymbol{G} = \boldsymbol{S}_{ct} (\boldsymbol{S}_{ct}' \boldsymbol{\Omega}_{ct}^{-1}\boldsymbol{S}_{ct})^{-1}\boldsymbol{S}_{ct}'\boldsymbol{\Omega}_{ct}^{-1} = \boldsymbol{S}_{ct} (\boldsymbol{S}_{ct}'( \boldsymbol{S}_{ct} \hat{\boldsymbol{\Omega}}_{hf-bts} \boldsymbol{S}_{ct}')^{-1}\boldsymbol{S}_{ct})^{-1}\boldsymbol{S}_{ct}'(\boldsymbol{S}_{ct} \hat{\boldsymbol{\Omega}}_{hf-bts} \boldsymbol{S}_{ct}')^{-1} =  \boldsymbol{S}_{ct} (\boldsymbol{S}_{ct}' \boldsymbol{S}_{ct}'^{-1} \hat{\boldsymbol{\Omega}}_{hf-bts}^{-1} \boldsymbol{S}_{ct}^{-1}\boldsymbol{S}_{ct})^{-1}\boldsymbol{S}_{ct}' \boldsymbol{S}_{ct}'^{-1} \hat{\boldsymbol{\Omega}}_{hf-bts}^{-1} \boldsymbol{S}_{ct}^{-1} =  \boldsymbol{S}_{ct} (\boldsymbol{I}_{n(m+k^*)} \hat{\boldsymbol{\Omega}}_{hf-bts}^{-1} \boldsymbol{I}_{n(m+k^*)})^{-1} \boldsymbol{I}_{n(m+k^*)}\hat{\boldsymbol{\Omega}}_{hf-bts}^{-1} \boldsymbol{S}_{ct}^{-1} =  \boldsymbol{S}_{ct} \boldsymbol{I}_{n(m+k^*)}^{-1} \hat{\boldsymbol{\Omega}}_{hf-bts} \boldsymbol{I}_{n(m+k^*)}^{-1} \boldsymbol{I}_{n(m+k^*)}\hat{\boldsymbol{\Omega}}_{hf-bts}^{-1} \boldsymbol{S}_{ct}^{-1} =  \boldsymbol{S}_{ct} \hat{\boldsymbol{\Omega}}_{hf-bts} \hat{\boldsymbol{\Omega}}_{hf-bts}^{-1} \boldsymbol{S}_{ct}^{-1} = \boldsymbol{I}_{n(m+k^*)}$

---

While we may avoid estimating the reconciled forecasts' co-variance matrix $\tilde{\boldsymbol{\Omega}}$, we still need to estimate the base forecasts' one  $\boldsymbol{\Omega}$

Natural estimate is empirical sample covariance matrix of base forecasts, but this involves many parameters, especially for the cross-temporal case ($r = n(k^*+m)[n(k^*+m)-1]/2$)

There are several different estimates that may be used

$\boldsymbol{\tilde{\Omega}} = \boldsymbol{M \Omega M}'$ where

- $\boldsymbol{M} = \boldsymbol{I}_{n(m+k^*)} - \boldsymbol{\Omega}_{ct}\boldsymbol{C}_{ct}'(\boldsymbol{C}_{ct}\boldsymbol{\Omega}_{ct}\boldsymbol{C}_{ct}')^{-1}\boldsymbol{C}_{ct}$ for a positive definite matrix $\boldsymbol{\Omega}_{ct}$
- $\boldsymbol{M} = \boldsymbol{S}_{ct} \boldsymbol{G}$ for $\boldsymbol{G} = (\boldsymbol{S}_{ct}' \boldsymbol{\Omega}_{ct}^{-1}\boldsymbol{S}_{ct})^{-1}\boldsymbol{S}_{ct}'\boldsymbol{\Omega}_{ct}^{-1}$
- Note: If we assume that $\boldsymbol{\Omega} = \boldsymbol{\Omega}_{ct}$ (see the projection matrices (5) and (6)), then the co-variance matrix (8) simplifies to $\boldsymbol{\~{\Omega}} = \boldsymbol{M \Omega}_{ct}$
  
---

Let $(\mathbb{R}^{n_b m}, \mathcal{F}_{\mathbb{R}^{n_b m}}, \mathcal{v})$ be a probability space for the bottom-time series $\boldsymbol{b}_{\tau}^{[1]}$, where $\mathcal{F}_{\mathbb{R}^{n_b m}}$ is the usual Borel $\sigma$-algebra on $\mathbb{R}^{n_b m}$. Then a $\sigma$-algebra $\mathcal{F}_{\mathfrak{s}}$ can then be constructed as the collection of sets $s(\mathcal{B})$ for all $\mathcal{B} \in \mathcal{F}_{\mathbb{R}^{n_b m}}$ 

**Definition 3.1** (Cross-temporal coherent probabilistic forecasts): Given the probability space $(\mathbb{R}^{n_b m}, \mathcal{F}_{\mathbb{R}^m}, \mathcal{v})$, we define the coherent probability space as the triple $(\mathfrak{s}, \mathcal{F}_{\mathfrak{s}}, \u{\mathcal{v}})$ satisfying the following property: $\u{v}(s(\mathcal{B})) = v(\mathcal{B}) \hspace{10pt} \forall \mathcal{B} \in \mathcal{F}_{\mathbb{R}^{n_b m}}$

**Definition 3.2** (Cross-temporal probabilistic forecast reconciliation): The reconciled probability measure of $\hat{\mathcal{v}}$ with respect to $\psi$ is a probability measure $\tilde{\mathcal{v}}$ on $\mathfrak{s}$ with $\sigma$-algebra $\mathcal{F}_{\mathfrak{s}}$ satisfying:
  $$\tilde{v}(\mathcal{A}) = \hat{v}(\psi^{-1}(\mathcal{A})), \hspace{1cm} \forall \mathcal{A} \in \mathcal{F}_{\mathfrak{s}} \hspace{1in} (7)$$ where
  - $\psi^{-1}(\mathcal{A}) = {x \in \mathbb{R}^{n(m + k^*)} : \psi(x) \in \mathcal{A}}$ denotes the pre-image of $\mathcal{A}$ (x is the pre-image of A)
- The map $\psi$ may be obtained as the composition $s \circ g$, as for the cross-temporal point reconciliation(6)


That is, $\hat{\boldsymbol{x}}_{i,l}^{[k]}$ is a sample path simulated for the $i^{th}$ series with error approximated by the corresponding block bootstrapped sample residual $\hat{\boldsymbol{e}}_i^{[k]}$, the $i^{th}$ row of 

m = 4, k = {4, 2, 1}
$$\hat{\boldsymbol{E}}_{1}^{[1]} = \begin{bmatrix} \hat{e}_{T, 1}^{[1]} & \hat{e}_{T, 2}^{[1]} & \hat{e}_{T, 3}^{[1]} & \hat{e}_{T, 4}^{[1]} \\ \hat{e}_{X, 1}^{[1]} & \hat{e}_{X, 2}^{[1]} & \hat{e}_{X, 3}^{[1]} & \hat{e}_{X, 4}^{[1]} \\ \hat{e}_{Y, 1}^{[1]} & \hat{e}_{Y, 2}^{[1]} & \hat{e}_{Y, 3}^{[1]} & \hat{e}_{Y, 4}^{[1]} \end{bmatrix} \cdots \hat{\boldsymbol{E}}_{4}^{[1]} = \begin{bmatrix} \hat{e}_{T, 13}^{[1]} & \hat{e}_{T, 14}^{[1]} & \hat{e}_{T, 15}^{[1]} & \hat{e}_{T, 16}^{[1]} \\ \hat{e}_{X, 13}^{[1]} & \hat{e}_{X, 14}^{[1]} & \hat{e}_{X, 15}^{[1]} & \hat{e}_{X, 16}^{[1]} \\ \hat{e}_{Y, 13}^{[1]} & \hat{e}_{Y, 14}^{[1]} & \hat{e}_{Y, 15}^{[1]} & \hat{e}_{Y, 16}^{[1]} \end{bmatrix}$$
$$\hat{\boldsymbol{E}}_{1}^{[4]} = \begin{bmatrix} \hat{e}_{T, 1}^{[4]} \\ \hat{e}_{X, 1}^{[4]} \\ \hat{e}_{Y, 1}^{[4]} \end{bmatrix} \cdots \hat{\boldsymbol{E}}_{4}^{[4]} = \begin{bmatrix} \hat{e}_{T, 13}^{[4]} \\ \hat{e}_{X, 13}^{[4]} \\ \hat{e}_{Y, 13}^{[4]} \end{bmatrix}$$

--

- $\boldsymbol{x}_{\tau}$ lies in an $(n_bm)$-dimensional subspace $\mathfrak{s}_{ct}$ of $\mathbb{R}^{n(k^*)}$, which we refer to as the *cross-temporal coherent subspace*, spanned by the columns of $\boldsymbol{S}_{ct}$
- Structural representation: $\boldsymbol{x}_{\tau} = \boldsymbol{S}_{ct} \boldsymbol{b}_{\tau}^{[1]} = s(\boldsymbol{b}_{\tau}^{[1]})$
  - $s \textrm{ : } \mathbb{R}^{n_b m} \rightarrow \mathbb{R}^{n(m + k^*)}$ is the operator describing the pre-multiplication by $\boldsymbol{S}_{ct}$
- **Definition 2.1**: *Forecast reconciliation* adjusts the base forecast $\hat{\boldsymbol{x}}_h$ by finding a mapping $\psi : \mathbb{R}^{n(m + k^*)} \rightarrow \mathfrak{s}$, such that $\tilde{\boldsymbol{x}}_h = \psi(\hat{\boldsymbol{x}}_h)$, where $\tilde{\boldsymbol{x}}_h \in \mathfrak{s}$ is the *vector of reconciled forecasts* and the mapping $\psi$ may be defined as a projection onto $\mathfrak{s}$

$\mathfrak{s}$ indicates a coherent subspace spanned by the columns of matrix $\boldsymbol{S}$
$\mathcal{B}$ is a vector of dimension $n_b m$, aka the length of $\boldsymbol{x}_{\tau}$
The coherent probability space is
  
v(A) = u(x), where w(x) E Av(A) = u(x), where w(x) E A
  
- Vector of truth data at time tau x_t lies in the cross-temporal coherent subspace s_{ct} where truth_t = s(bottom_t) = S bottom_t
- Vector of reconciled forecasts x_h lies in the "cross-temporal reconciled subspace" s, where rec_h = psi (base_h) = s(g(base_h)) = SG base_h

- Probability space for bottom time series (R^{n_b m}, F_{n_b m}, v) is a probability space with a Borel sigma algebra
- Coherent probability space for bottom time series (s, F_s, v_cup) has a sigma algebra constructed as the collection of sets s(B) for all B in F_{R}^{n_b m}


A mapping $p : R^n -> [0, 1]$ basically tells us that a (probability) function $p$ takes some value on the real number line and spits out a probability 

Basically, a probability triple defines an experiment with parameters defining 1) all the possible outcomes (the sample space), 2) a subset of events that have occurred or we're interested in (the event space, a type of sigma algebra), 3) and a function that describes the probability of each possible event (the probability measurer, a type of probability function)
  - Note that a probability space is a measure space in which the measure of the whole space is equal to one
  - This means the event space is a sigma algebra on the sample space, since a measure space is composed of (a set X, a sigma algebra A on the set X, a measure on the measurable space (X, A))

We constrain the event space to be a Borel sigma algebra, or the smallest sigma algebra containing all open (or closed) sets [through operations of countable union, countable intersection, and relative complement]
  - This might ensure all the events can be assigned probabilities


---

- $\boldsymbol{y}_t = [y_{1,t},...,y_{i,t},..., y_{n,t}]'$ is an $n$-variate linearly constrained time series observed at the most temporally disaggregated level (bottom-level) with a seasonality of period $m$ at time $t$
  - Note, this means that ALL values (bottom and upper levels) in a cross-sectional hierarchy will be included in this vector
- The cross-sectional reconciliation approach is obtained assuming $m = 1$ while the temporal one is obtained when $n = 1$ ($n_a = 0, n_b = 1$)
  - So $n$ can be understood as the number of dimensions cross-sectionally while $m$ is the temporal dimension (seasonality for the bottom-level compare to the highest aggregation level)

- Old thief notation
  - Observed time series: {$y_t: t = 1, ..., T$}
  - Observation index $j$ varies at each aggregation level
  - Observation index $i$ at most aggregate level series
  - Series-based aggregation: $y_j^{[k]} = \Sigma_{t = t^*+(j-1)k}^{t^*+jk-1} y_t$
    - where $t^* = T - floor{T/m}m + 1, j = 1, ..., floor{T}/k$
  - Universal notation: $y_j^{[k]} = y_{M_k(i-1)+z}^{[k]}$

- New notation
  - Observed time series: {$y_{i,t}: i = 1,..., n; t = 1, ..., T$}
    - Number of variables n = bottom_dim + upper_dim
  - Series index $i$ describes which particular time series we're looking at
    - Note this means that each of $y_{T,t}, y_{X,t}, y_{Y,t}$ is its own series BUT this is not the case for the temporal series
  - Observation index $j$ varies at each aggregation level (j = t at the bottom most level)
  - Observation index $\tau$ at most aggregate level series
  - Series-based aggregation: $x_{1,j}^{[k]} = \Sigma_{t = (j-1)k+1}^{jk} y_t$
  - Universal notation: $x_{1,\tau}^{[k]} = y_{M_k(\tau-1)+z}^{[k]}$

Quarterly time series with 6 years of data
- k_p = m = 4, N = 6, T = Nm = 24, K = {4, 2, 1}, k_1 = 1, p = 3; N_k = T/k = 24/1
- seasonal period M_k = m / k
- x_{i,j}^{[1]} = y_{i,t}
- Observed series: $y_{1,1}, 
- Quarterly: k_1 = 1, j = 1, ...24
  - $x_{i,1}^{[1]} = y_{i,(j-1)k+1} = y_{i,jk} = y_{i,1}$
  ...
  - $x_{i,24}^{[1]} = y_{i,24}$


Shared elements
- Bottom series: A vector of ONLY the bottom-most time series
- Upper series: a vector of all upper level time series
- Combined series ([upper   bottom]')
- Aggregation matrix $\boldsymbol{A}$ connects upper and lower level time series (upper = A * bottom); equation does NOT hold for cross-temporal case
  - For temporal, $\boldsymbol{A}_{te}$ has a specific matrix of expressions ($\begin{bmatrix} \boldsymbol{1}_{k_p} & \boldsymbol{I}_{m/(k_{p-1})} \otimes \boldsymbol{1}_{k_{p-1}} & \cdots & \boldsymbol{I}_{m/k2} \otimes \boldsymbol{1}_{k2} \end{bmatrix}'$)
  - Generally no reason for upper to be restricted to simple sums of bottom, so A \in R^{upper_dim * lower_dim}
- Zero constraints matrix $\boldsymbol{C}$ = [I_{upper_dim}   -A], with dimensions (upper_dim x (bottom_dim + upper_dim)) (equation does NOT hold for cross temporal case)
  - Constraints equation C * combined = 0_{(upper_dim * 1)}
  - Cross-temporal: C_ct = [C_*   I_n \otimes C_te]', C_ct x_t = 0
    - For each dimension: C_{cs} * combined_ct = 0_{upper_dim_cs * combo_dim_te} AND C_{te} * combined_ct' = 0_{upper_dim_te * combo_dim_cs}
- Structural matrix $\boldsymbol{S}$ = [A   I_{lower_dim}]' (equation does NOT hold for the cross-temporal case)
  - Structural representation: combined = S * bottom


variable | cross-sectional | temporal | cross-temporal
:-------:|:-----------:|:-----------:|:----------------:
bottom-level series | $\boldsymbol{b}_t$ | $\boldsymbol{y}_t = \boldsymbol{x}_t^{[1]}$ | $\boldsymbol{x}_{i,\tau}' = \boldsymbol{B}_{\tau}^{[k]}$
bottom-level elements | ${y}_{i,t}$ for $i = n_a+1,...,n$ | ${y}_{1, M_k(\tau-1) + z} = {x}_{1, M_k(\tau-1) + z}^{[1]}$ | ${x}_{i, M_k(\tau-1)+z}^{[k]}$ for $i = n_a + 1, ...n$
upper-level series | $\boldsymbol{u}_t$ | $\boldsymbol{x}_t^{[k]}$ | $\boldsymbol{U}_t^{[k]}$
upper-level elements | ${y}_{i,t}$ for $i = 1, ...,n_a$ | ${x}_{1, M_k(\tau-1) + z}^{[k]}$ | ${x}_{i, M_k(\tau-1)+z}^{[k]}$ for $i = 1, ..., n_a$
combined series | $\boldsymbol{y}_t$ | $\boldsymbol{x}_{1,\tau}$ | matrix $\boldsymbol{X}_t$, vector $\boldsymbol{x}_t$
combined elements | ${y}_{i,t}$ for $i = 1,...,n$ | $\boldsymbol{x}_{1, \tau}^{[k]}$ | ${x}_{i, M_k(\tau-1)+z}^{[k]}$ for $i = 1, ..., n$
num bottom series | $n_b$ | $k_p = m$ | [$n_b m$]
num upper series | $n_a$ | $k^*$ | [$n_a m + nk^*$]
total num series | $n = n_b + n_a$ | $p$ | [$n(m + k^*)$]

- Rows and columns represent cross-sectional and temporal dimensions of $\boldsymbol{X}_{\tau}$ respectively: 
  $$\boldsymbol{X}_{\tau} = \begin{bmatrix} \boldsymbol{x}_{1,\tau}' \\ \boldsymbol{x}_{2,\tau}' \\ \boldsymbol{x}_{3,\tau}' \end{bmatrix} = \begin{bmatrix} \boldsymbol{U}_{\tau}' \\ \boldsymbol{B}_{\tau}' \end{bmatrix}$$ 
  $$ = \begin{bmatrix} \boldsymbol{x}_{1,\tau}^{[4]'} & \boldsymbol{x}_{1,\tau}^{[2]'} & \boldsymbol{x}_{1,\tau}^{[1]'} \\ \boldsymbol{x}_{2,\tau}^{[4]'} & \boldsymbol{x}_{2,\tau}^{[2]'} & \boldsymbol{x}_{2,\tau}^{[1]'} \\ \boldsymbol{x}_{3,\tau}^{[4]'} & \boldsymbol{x}_{3,\tau}^{[2]'} & \boldsymbol{x}_{3,\tau}^{[1]'} \end{bmatrix} = \begin{bmatrix} \boldsymbol{U}_{\tau}^{[4]} & \boldsymbol{U}_{\tau}^{[2]} & \boldsymbol{U}_{\tau}^{[1]} \\ \boldsymbol{B}_{\tau}^{[4]} & \boldsymbol{B}_{\tau}^{[2]} & \boldsymbol{B}_{\tau}^{[1]} \end{bmatrix}$$ 
  $$= \left[\begin{array}{c|cc|cccc}
  x^{[4]}_{1,\tau} & x^{[2]}_{1,2\tau-1} & x^{[2]}_{1,2\tau} & y_{1,4\tau-3} & y_{1,4\tau-2} & y_{1,4\tau-1} & y_{1,4\tau}\\
  \hline
  x^{[4]}_{2,\tau} & x^{[2]}_{2,2\tau-1} & x^{[2]}_{2,2\tau} & y_{2,4\tau-3} & y_{2,4\tau-2} & y_{2,4\tau-1} & y_{2,4\tau}\\
  x^{[4]}_{3,\tau} & x^{[2]}_{3,2\tau-1} & x^{[2]}_{3,2\tau} & y_{3,4\tau-3} & y_{3,4\tau-2} & y_{3,4\tau-1} & y_{3,4\tau}\\
  \end{array}\right]$$
  where for any fixed $k$, $\boldsymbol{U}_{\tau}^{[k]}$ is the $(n_a\times N_k)$ matrix grouping the upper time series and $\boldsymbol{B}_{\tau}^{[k]}$ is the $(n_b\times N_k)$ matrix grouping the bottom time series

- Rows and columns represent cross-sectional and temporal dimensions of $\boldsymbol{X}_{\tau}$ respectively: 
  $$\boldsymbol{X}_{\tau} = \begin{bmatrix} \boldsymbol{x}_{1,\tau}' & \cdots & \boldsymbol{x}_{i,\tau}' & \cdots & \boldsymbol{x}_{n,\tau}' \end{bmatrix}' = \begin{bmatrix} \boldsymbol{U}_{\tau}^{[k_p]} &\cdots & \boldsymbol{U}_{\tau}^{[k]} & \cdots & \boldsymbol{U}_{\tau}^{[1]} \\ \boldsymbol{B}_{\tau}^{[k_p]} & \cdots & \boldsymbol{B}_{\tau}^{[k]} & \cdots & \boldsymbol{B}_{\tau}^{[1]} \end{bmatrix}$$ 
  $$= \left[\begin{array}{c|cc|cccc}
  x^{[4]}_{1,\tau} & x^{[2]}_{1,2\tau-1} & x^{[2]}_{1,2\tau} & y_{1,4\tau-3} & y_{1,4\tau-2} & y_{1,4\tau-1} & y_{1,4\tau}\\
  \hline
  x^{[4]}_{2,\tau} & x^{[2]}_{2,2\tau-1} & x^{[2]}_{2,2\tau} & y_{2,4\tau-3} & y_{2,4\tau-2} & y_{2,4\tau-1} & y_{2,4\tau}\\
  x^{[4]}_{3,\tau} & x^{[2]}_{3,2\tau-1} & x^{[2]}_{3,2\tau} & y_{3,4\tau-3} & y_{3,4\tau-2} & y_{3,4\tau-1} & y_{3,4\tau}\\
  \end{array}\right]$$
  where for any fixed $k$, $\boldsymbol{U}_{\tau}^{[k]}$ is the $(n_a\times N_k)$ matrix grouping the upper time series and $\boldsymbol{B}_{\tau}^{[k]}$ is the $(n_b\times N_k)$ matrix grouping the bottom time series
