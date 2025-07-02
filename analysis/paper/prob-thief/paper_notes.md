## No Reconciling Quantiles
- Bakes in assumption that quantiles across different time units exactly linked (ie some exact dependents across different time units)
- "[H]ierarchical probabilistic forecasts are coherent if the predictive distribution of each aggregate series is equal to the distribution of the children series" (*Coherent Probabilistic Forecasts for Hierarchical Time Series* section 3, Taieb 2017)
  - Simple example (in our context): $Y^{(week)} = \sum_{d=1}^7 Y^{(day)}_d$, the forecast distributions for $Y^{(week)}$ and $Y^{(day)}_1, …, Y^{(day)}_7$, are coherent if the distribution of $Y^{(week)}$ is equal to the distribution of the random variable obtained by summing the $Y^{(day)}_d$’s with their specified distributions. 
- Reconciling the quantiles is like assuming that the quantile of the distribution of $Y^{(week)}$ at some probability level $p$ is the sum of the quantiles of the distributions for each day at that probability level. Yet this claim about quantile coherence may not even hold for coherent distributions
  - *Example:* suppose the daily distributions $Y^{(day)}_d$ are all independent Normal(0, 1^2) and the weekly distribution $Y^{(week)}$ is Normal(0, 7). 
    - By definition, these distributions are coherent since the distribution of the sum of 7 independent standard normals is Normal(0, 7). 
      - Mean = $E(Y_1^{(day)}) + ... + E(Y_7^{(day)}) = 0 + ... + 0 = 0$
      - Variance = $\Sigma_{d=1}^7 \sigma_{Y_d}^2 + 2 \Sigma_{i=1}^n \Sigma_{j>i}^m Cov(Y_i, Y_j) = \Sigma_1^7 1^2 + 2 \Sigma \Sigma 0 = 7$
    - However, the quantiles do not add up in the way that is asserted if you do this quantile reconciliation: `qnorm(0.75, mean = 0, sd = sqrt(7))` = 1.78 but `7 * qnorm(0.75, mean = 0, sd = 1)` = 4.72. 
    - On the other hand, if there was exact dependence across days you would get to the result that the quantile of the weekly value at any probability level was equal to 7 * the quantile of the daily result, because the same value would be observed for all days. 
    - Note that for (s)arima models (and any reasonable time series model), we are in between these extremes, but we certainly don’t have perfect dependence across days.
- Even so, it's unclear what to do instead
- [Coherent Probabilistic Forecasts for Hierarchical Time Series](https://robjhyndman.com/papers/2017_icml_probhts.pdf)
  - Hierarchy over special units, and not time units (more classical setup)
  - To stage reconciliation process: 1) bottom-up reconciliation (in a probabilistic way) only, 2) mean adjustment for all levels of the hierarchy
    1) has some stuff with copulas to get dependence against spatial units 
    - but may not be necessary for us since *samples add single level of temporal hierarchy already include dependent structure across dates that comes out of the model* if using bootstrap option in `forecasts` package to get samples
      - so may be able to do something with samples while by passing stuff involving copulas in the paper
- Hyndman may have newer stuff in last five years


## [Coherent Probabilistic Forecasts for Hierarchical Time Series (2017)](https://robjhyndman.com/papers/2017_icml_probhts.pdf)
[associated code](https://github.com/bsouhaib/prob-hts/tree/master/simulations/code)
### 1 Introduction
- Recent work for point forecasts only: 2-stage approach of generating independent base forecasts then combined to get coherent revised forecasts
- Key problem of generating probabilistic forecasts for large scale hierarchical time series
  - Requires estimation of entire distribution of future observations, not only the main
  - Involves computing distribution of hierarchical sums of random variables and high dimensions
  - Possible variety of distributions and hierarchy (lower levels often exhibit non-normality, less so at higher levels thanks to CLT)
- proposed algorithm computes predictive distributions under form of random samples for each series in hierarchy
  1. Probabilistic forecasts independently computed for all series, samples computed from associated predictive distributions
  2. Sequence of permutations extracted from estimated copulas applied to multivariate samples in hierarchical manner to restore dependencies between variables before computing the sums
  3. Algorithm computes sparse forecast combinations for all series in hierarchy, where combination weights estimated using possibly high dimensional LASSO problem
  - results in set of coherent publicity forecasts for each series
  - advantages compared to state of the art hierarchical forecasting methods
    1) quantifies uncertainty and predictions for entire hierarchy while satisfying aggregation constraints [probabilistic hierarchical forecasts?]
    2) Scalable to high dimensional hierarchies since problem is decomposed into multiple lower - dimensional sub
    3) Synthesizers info from different levels in hierarchy to estimate marginal distributions and dependency structures through mean forecast combination and hierarchical aggregation, respectively
### 2 Mean Hierarchical Forecasting
**Step 0: Construct Hierarchy**
*Hierarchical time series:* Multivariate time series with hierarchical structure

*Figure 1:* Example of a hierarchical time series (5 bottom series, 3 aggregate series)
$\hspace{3.5cm} y_t$  
$\hspace{1.5cm} y_{A, t} \hspace{3.25cm} y_{B, t}$  
$y_{AA, t} \hspace{0.5cm} y_{AB, t} \hspace{0.5cm} y_{AC, t} \hspace{1.5cm} y_{BA, t} \hspace{0.5cm} y_{BB, t}$

- Aggregation constraints: for all time points $t = 1, ..., T$
  - $y_t = y_{A, t} + y_{B, t}$
  - $y_A = y_{AA, t} + y_{AB, t} + y_{AC, t}$
  - $y_B = y_{BA, t} + y_{BB, t}$

* $\boldsymbol{a_t}$ is $r$-vector containing observations at different levels of aggregation at time $t$
$$\boldsymbol{a_t} = \begin{bmatrix} y_t\\ {y_{A,t}}\\ {y_{B,t}} \end{bmatrix}, \hspace{1cm} (r=3)$$
* $\boldsymbol{b_t}$ is $m$-vector containing observations at the bottom level only at time $t$
$${b_t} = \begin{bmatrix} y_{AA, t}\\ {y_{AB,t}}\\ {y_{AC,t}}\\ {y_{BA,t}}\\ {y_{BB,t}} \end{bmatrix}, \hspace{1cm} (m=5)$$
* $\boldsymbol{y_t}$ is $n$-vector containing observations of all the series in the hierarchy at time $t$ with $n = r + m$
$$\boldsymbol{y_t} 
= \begin{bmatrix} \boldsymbol{a_t}\\ \boldsymbol{b_t}\end{bmatrix} 
= \begin{bmatrix} y_t\\ {y_{A,t}}\\ {y_{B,t}}\\ y_{AA, t}\\ {y_{AB,t}}\\ {y_{AC,t}}\\ {y_{BA,t}}\\ {y_{BB,t}} \end{bmatrix}, 
  \hspace{1cm} (n=8)
$$

$$\boldsymbol{y_t} = \boldsymbol{S b}_t 
= \begin{bmatrix} \boldsymbol{S}_a\\ \boldsymbol{I}_m \end{bmatrix} \begin{bmatrix} y_{AA, t}\\ {y_{AB,t}}\\ {y_{AC,t}}\\ {y_{BA,t}}\\ {y_{BB,t}} \end{bmatrix} 
= \begin{bmatrix}
  1 & 1 & 1 & 1 & 1 \\
  1 & 1 & 1 & 0 & 0 \\
  0 & 0 & 0 & 1 & 1 \\
  1 & 0 & 0 & 0 & 0 \\
  0 & 1 & 0 & 0 & 0 \\
  0 & 0 & 1 & 0 & 0 \\
  0 & 0 & 0 & 1 & 0 \\
  0 & 0 & 0 & 0 & 1 
\end{bmatrix}
\begin{bmatrix} y_{AA, t}\\ {y_{AB,t}}\\ {y_{AC,t}}\\ {y_{BA,t}}\\ {y_{BB,t}} \end{bmatrix} = 
\begin{bmatrix} 
  y_{AA, t} + y_{AB, t} + y_{AC, t} + y_{BA, t} + y_{BB, t} \\
  y_{AA, t} + y_{AB, t} + y_{AC, t} \\
  y_{BA, t} + y_{BB, t} \\
  y_{AA, t}\\ {y_{AB,t}}\\ {y_{AC,t}}\\ {y_{BA,t}}\\ {y_{BB,t}} 
\end{bmatrix}$$ 

**Step 1: Create Base Forecasts**
- Historical observations $\boldsymbol{y}_1,...,\boldsymbol{y}_T$ of a hierarchical time series
- Optimal (by MSE loss) $h$ period ahead forecasts given by conditional mean $$E[\boldsymbol{y}_{T+h} | \boldsymbol{y}_1,...,\boldsymbol{y}_T] = \boldsymbol{S} E[\boldsymbol{b}_{T+h} | \boldsymbol{y}_1,...,\boldsymbol{y}_T], \hspace{2.5cm} (1)$$ where $h = 1, 2, ..., H$
- *Base forecasts*: forecasts computed independently at all levels for all series using the above MSE loss-optimal $h$-period ahead forecasts $$E[\boldsymbol{y}_{i, T+h} | \boldsymbol{y}_{i, 1},...,\boldsymbol{y}_{i,T}]$$ where $i = 1, 2, ..., n$
  - Flexible approach that allows for use of different forecasting method for each series/aggregation level
  - Note though that aggregation constraints will not necessarily be satisfied
- *Coherency errors* (definition 1) of $h$-period ahead base forecasts $\hat{\boldsymbol{y}}_{T+h} = \begin{bmatrix} \hat{\boldsymbol{a}}_{T+h}\\ \hat{\boldsymbol{b}}_{T+h} \end{bmatrix}$ are given by 
$$\hat{\boldsymbol{r}}_{T+h} = \hat{\boldsymbol{a}}_{T+h}- \boldsymbol{S}_a \hat{\boldsymbol{b}}_{T+h}
= \begin{bmatrix} \hat{y}_{T+h}\\ {\hat{y}_{A, T+h}}\\ {\hat{y}_{B, T+h}} \end{bmatrix} - 
  \begin{bmatrix}
    1 & 1 & 1 & 1 & 1 \\
    1 & 1 & 1 & 0 & 0 \\
    0 & 0 & 0 & 1 & 1 \\
  \end{bmatrix}
  \begin{bmatrix} \hat{y}_{AA, T+h}\\ {\hat{y}_{AB, T+h}}\\ {\hat{y}_{AC, T+h}}\\ {\hat{y}_{BA, T+h}}\\ {\hat{y}_{BB, T+h}} \end{bmatrix} $$
$$= \begin{bmatrix} \hat{y}_{T+h}\\ {\hat{y}_{A, T+h}}\\ {\hat{y}_{B, T+h}} \end{bmatrix} - 
  \begin{bmatrix} 
    \hat{y}_{AA, T+h} + \hat{y}_{AB, T+h} + \hat{y}_{AC, T+h} + \hat{y}_{BA, T+h} + \hat{y}_{BB, T+h} \\
    \hat{y}_{AA, T+h} + \hat{y}_{AB, T+h} + \hat{y}_{AC, T+h} \\
    \hat{y}_{BA, T+h} + \hat{y}_{BB, T+h} \\
  \end{bmatrix}$$ 
- The $h$-period ahead base forecasts $\hat{\boldsymbol{y}}_{T+h} = \begin{bmatrix} \hat{\boldsymbol{a}}_{T+h}\\ \hat{\boldsymbol{b}}_{T+h} \end{bmatrix}$ are *(mean) coherent* (definition 2) if there are no coherency errors, ie $\hat{\boldsymbol{r}}_{T+h} = \boldsymbol{0}$

**Step 2: Reconcile Forecasts**
Best linear unbiased mean revised forecasts
- Proposed coherent hierarchical mean forecasts of form $$\tilde{\boldsymbol{y}}_{T+h} = \boldsymbol{S} \boldsymbol{P} \hat{\boldsymbol{y}}_{T+h}, \hspace{2.5cm} (2)$$ for some appropriately chosen (mxn) matrix $\boldsymbol{P}$ and base forecasts $\hat{\boldsymbol{y}}_{T+h}$
- Advantages of approach:
  1) Forecasts are coherent by construction
  2) Forecasts are generated by combining forecasts from all levels
  3) Multiple hierarchical forecasting methods can be represented as particular cases, e.g.
      - Bottom-up forecasts: $\boldsymbol{P} = [\boldsymbol{0}_{m \times r} | \boldsymbol{1}_{m \times m}]$
      - top down forecasts: $\boldsymbol{P} = [\boldsymbol{p}_{m \times 1} | \boldsymbol{0}_{m \times (n - 1)}]$, where $\boldsymbol{p}$ is a vector of proportions that sum to one
- *Theorem 1:* Let $\boldsymbol{W}_h$ be the positive definite covariance matrix of the $h$-period ahead base forecasts errors 
  $$\hat{\boldsymbol{e}_{T+h}} = \boldsymbol{Y}_{T+h} - \hat{\boldsymbol{Y}}_{T+h}, \textrm{ i.e. }\boldsymbol{W}_h=E[\hat{\boldsymbol{e}}_{T+h}\hat{\boldsymbol{e}}_{T+h}']$$
  then, assuming unbiased base forecasts the best (min sum of variances) linear runbiased revised forecasts are given by *(2)* with 
  $$\boldsymbol{P} = (\boldsymbol{S' W_H^{-1} S})^{-1} \boldsymbol{S' W_H^{-1} S}.$$
We denote this method **MinT**
- In practice, error covariance matrix $\boldsymbol{W}_h$ must be estimated with historical observations of base forecast errors
  - Wickramasuriya et al. (2015) estimated $\boldsymbol{W}_1$ and assumed that $\boldsymbol{W}_h \propto \boldsymbol{W}_1$ since estimation is difficult for $h > 1$
  - Hyndman et al (2016) considered structural assumptions on entries of sample covariance matrix to trade-off bias and estimation

Optimal Mean Combination and Reconciliation
- van Erven & Cugliari (2015) proposed splitting this step (which performs combination and record association at the same time) into two independent steps: 1) find best possible forecasts for time series without considering aggregate consistency, 2) reconcile the forecasts to achieve aggregate consistency
- GTOP method: given possibly incoherent base forecasts $\hat{\boldsymbol{y}}_{T+h}$ and weight matrix $\boldsymbol{A} \in \mathbb{R}^{n \times n}$, solving the quadratic optimization
  $$\min_{\boldsymbol{x}_a\in \mathbb{R}^r, \boldsymbol{x}_be\in \mathbb{R}^m} \bigg\|\boldsymbol{A} \hat{\boldsymbol{y}}_{T+h} - \boldsymbol{A} \begin{bmatrix} \boldsymbol{x}_a\\ \boldsymbol{x}_b \end{bmatrix} \bigg\|^2,
  \hspace{1cm} \textrm{subject to } \begin{bmatrix} \boldsymbol{x}_a\\ \boldsymbol{x}_b \end{bmatrix} \in \mathcal{A} \cap \mathcal{B} \hspace{1cm}(3)$$
where $\mathcal{A} = \{\begin{bmatrix} \boldsymbol{x}_a & \boldsymbol{x}_b \end{bmatrix}': \boldsymbol{x}_a = \boldsymbol{S}_a \boldsymbol{x}_b\}$ is the set of coherent vectors and $\mathcal{B}$ it is an additional set that allows the specification of additional constraints
  - Solution equivalent to an optimal strategy in a minimax problem with goal of minimizing maximum error between loss of reconciled and based forecasts
  - When $\boldsymbol{A} = \boldsymbol{I}, \mathcal{B} = \emptyset$ the problem reduces to finding the closest reconciled forecasts to base forecasts in terms of SSE
  $$\min_{\boldsymbol{x}_a\in \mathbb{R}^r, \boldsymbol{x}_b \in \mathbb{R}^m} \bigg\|\boldsymbol{I_n} \hat{\boldsymbol{y}}_{T+h} - \boldsymbol{I_n} \begin{bmatrix} \boldsymbol{x}_a\\ \boldsymbol{x}_b \end{bmatrix} \bigg \|^2,
  \hspace{1cm} \textrm{subject to } \begin{bmatrix} \boldsymbol{x}_a\\ \boldsymbol{x}_b \end{bmatrix} \in \mathcal{A} \cap \emptyset, \textrm{ aka no constraints}$$
- Advantages of GTOP approach vs MinT
  - guarantees revised forecasts $\tilde{\boldsymbol{y}}_{T+h} = \begin{bmatrix} \boldsymbol{x}_a^* & \boldsymbol{x}_b^*\end{bmatrix}'$ with the same or smaller SSE then the base forecasts $\hat{\boldsymbol{y}}_{T+h}$
  - Base forecasts not required to be unbiased
  - Separation of forecast combination and reconciliation allows inclusion of regularization in forecast combination step
- Weakness: GTOP does not have a closed form solution in the general case

### 3 Probabilistic Hierarchical Forecasting
- GTOP provides no quantification of uncertainty and predictions
- MinT allows calculation of forecast variances BUT may not be enough to fully describe uncertainty and predictions
- Algorithm to compute *conditional predictive cumulative distribution function* for all series in the hierarchy: $$
  F_{i,T+h}(y|\boldsymbol{y}_1,...,\boldsymbol{y}_T) = \mathbb{P}(y_{i,T+h} \leq y|\boldsymbol{y}_1,...,\boldsymbol{y}_T)$$ 
  rather than just the conditional mean $\mathbb{E}[y_{i,T+h} | \boldsymbol{y}_1,...,\boldsymbol{y}_T]$ and conditional variance $\mathbb{V}[y_{i,T+h} | \boldsymbol{y}_1,...,\boldsymbol{y}_T]$ where $i=1,...,n$
- We may independently compute probabilistic forecasts for each series in the hierarchy, but these forecasts won't necessarily be coherent
- "[H]ierarchical probabilistic forecasts are coherent if the predictive distribution of each aggregate series is equal to the distribution of the children series"
  - Probabilistic coherency implies mean coherency


## [Probabilistic Forecast Reconciliation: Properties, Evaluation and Score Optimization (2023)](https://robjhyndman.com/publications/coherentprob/)
[Paper Code](https://github.com/PuwasalaG/Probabilistic-Forecast-Reconciliation)
[Code Package: ProbReco](https://github.com/anastasiospanagiotelis/ProbReco)
### 1 Introduction
- "*Reconciliation* involves producing predictions for all variables and making a subsequent adjustment to ensure these adhere to known linear constraints" (2)
- Paper: "Formal framework for probabilistic reconciliation, derives theoretical results that allow reconciled probabilistic predictions to be constructed and evaluated, proposes algorithm for optimal probabilistic reconciliation wrt proper scoring"
- original reconciliation (2009, 2011) formulated as regression model, "reconciling the base forecasts by projecting them onto a sub space for which aggregation constraints hold"
- subsequent reconciliation as quote optimization problem where weights are chosen to minimize a loss, eg weighted square error, penalized version thereof, trace of forecast error covariance" (2010s)
...
- Early probabilistic forecast reconciliation attempt from Shang and Hyndman (2017) in which they applied reconciliation to quantiles rather than point forecasts to construct prediction intervals
- expanded to constructing full probabilistic forecasts by Jeon (2019), including one equivalent to reconciling large number of quantiles
- Ben Taieb (2020) Obtain probabilistic forecasts that cohered to linear constraints 
  - Draw sample from probabilistic forecasts, induce dependence by creating a copula that matches empirical cop ula of residuals, samples of aggregate series obtained in bottom of fashion
- Both algorithms based on sampling and neither can be used to obtain reconciled density analytically; taylor to specific applications incomplete reconciliation with steps that reorder base forecasts

### 2 Outline of Main Results
(non-technical summary of main theoretical results of paper)
- *Probabilistic coherence* (definition 3.1): Any forecast that assigns zero probability to events that do not meet the coherence condition (ie hierarchical forecasts that do not correctly add up)
- Probabilistic forecast reconciliation (definition 3.2): (distinct from probabilistic coherence)
  - Begin with incoherent probabilistic forecasts then use a (usually linear function) to map sets of incoherent points to sets of coherent points, in which the probabilities assigned to the two sets are the same
  - key implications that any existing point reconciliation method (e.g. OLS or MinT) can be extended to probabilistic settings (mapping single points vs sets of points)
- To practical ways of carrying out forecast reconciliation:
  1. Involves integration, but in *elliptical distributions* (including Gaussian distribution) case true predictive distribution can be obtained via linear reconciliation method (involving linear transformations of scale and location parameters)
  2. Distribution can be reconciled by simulating from the base (incoherent) forecasts then reconciling each simple vector as if it was a point forecast (reliant on Theorem 4.5)
- Log score is il suited when comparing performance of incoherent probabilistic forecasts with reconciled forecasts because the former can even out perform the true predictive distribution when using this evaluation method (Theorem 5.1)

### 3 Hierarchical Probabilistic Forecasts
"We follow the geometric interpretation introduced by Panagiotelis et al. (2021), since this formulation naturally generalises to probabilistic forecasting" (7)

#### 3.1 Point Forecasting
- A *hierarchical time series*: collection of time series adhering to linear constraints
- Define $\boldsymbol{y}_t$ as $n$-vector created by stacking the value of each series at time $t$
- Constraints imply that $\boldsymbol{y_t}$ lies in $m$-dimensional linear subspace of $\mathbb{R}^n$ subspace for all $t$, called the *coherent subspace*, denoted by $\mathfrak{s}$
- Typical (and original) motivating example is a collection of time series sum of which are aggregates of other series
  - Here, $\boldsymbol{b}_t \in \mathbb{R}^m$ is collection of values of the *bottom level series* at time $t$
  - Aggregation constraints: $\boldsymbol{y}_t = \boldsymbol{Sb}_t$
  - $\boldsymbol{S}$ is an $n \times m$ constant matrix for a given hierarchical structure

*Figure 1:* An example of a two-level hierarchical hierarchical structure  
$\hspace{1.8cm} \textrm{Tot}$  
$\hspace{0.75cm} A \hspace{2.25cm} B$  
$AA \hspace{0.5cm} AB \hspace{1.0cm} BA \hspace{0.5cm} BB$
- Here $n = 7$ total series, $m = 4$ bottom-level series, plus $$\boldsymbol{b}_t = \begin{bmatrix} y_{AA, t}\\ {y_{AB,t}}\\ {y_{BA,t}}\\ {y_{BB,t}} \end{bmatrix}, \hspace{1cm}
  \boldsymbol{y_t} = \begin{bmatrix} y_{Tot}\\ {y_{A,t}}\\ {y_{B,t}}\\ \boldsymbol{b}_{t} \end{bmatrix} 
  = \begin{bmatrix} y_{Tot}\\ {y_{A,t}}\\ {y_{B,t}}\\ y_{AA, t}\\ {y_{AB,t}}\\ {y_{AC,t}}\\ {y_{BA,t}}\\ {y_{BB,t}} \end{bmatrix},  \hspace{1cm}
  \boldsymbol{S} = \begin{bmatrix} 1 & 1 & 1 & 1 \\1 & 1 & 0 & 0 \\0 & 0 & 1 & 1 \\ & & \boldsymbol{I}_4 & \end{bmatrix}$$
  
- Note that the columns of $\boldsymbol{S}$ span $\mathfrak{s}$; 
  - the notation $S : \mathbb{R}^m \rightarrow \mathbb{R}^n$ when pre-multiplication by $\boldsymbol{S}$ is thought of as a mapping
- While $\boldsymbol{S}$ is defined in terms of $m$ bottom-level series here, in general any $m$ series can be chosen with the $S$ matrix redefined accordingly
  - columns of all appropriately defined $\boldsymbol{S}$ matrices span the same coherent subspace $\mathfrak{s}$

- *Incoherent base* forecasts $\hat{\boldsymbol{y}}$ are forecasts of all $n$ series that do not adhere to constraints
- However, the base forecasts may be adjusted through forecast reconciliation using the fact that the target of the forecast adheres to known linear constraints
- *Forecast reconciliation* selects a mapping (function) $\psi : \mathbb{R}^n \rightarrow \mathfrak{s}$, then setting $\tilde{\boldsymbol{y}}= \psi(\hat{\boldsymbol{y}})$, where $\tilde{\boldsymbol{y}} \in \mathfrak{s}$ is the *reconciled forecast*
  - mapping $\psi$ may be a considered composition of two mappings $\psi = s \circ g$
  1. $g: \mathbb{R}^n \rightarrow \mathbb{R}^m$ combines incoherent base forecasts of all series to produce new bottom-level forecasts
  2. $s$ aggregates these new bottom-level forecasts
- Many existing point forecasting approaches are special cases where $g$ is pre-multiplication by a matrix $\boldsymbol{G}$ and where $\boldsymbol{SG}$ is a projection matrix

*Table 1:* Summary of reconciliation methods for which $\boldsymbol{SG}$ is a projection matrix. 

Reconciliation Method | matrix G | additional matrix | Author (Date)
:--------------------:|:--------:|:-----------------:|:-------------:
bottom-up | -- | -- |Dunn (1976)
OLS | $\boldsymbol{(S'S)^{-1}S'}$ | -- | Hyndman (2011)
WLS (THieF) | $\boldsymbol{(S'WS)^{-1}S'W}$ | some diagonal matrix | Athanasopoulos (2017)
MinT (Sample) | $\boldsymbol{(S'\hat{\Sigma}_{sam}^{-1}S)^{-1}S'\hat{\Sigma}_{sam}^{-1}}$ | sample est of cov matrix | Wickramasuriya (2019)
MinT (Shrink) | $\boldsymbol{(S'\hat{\Sigma}_{shr}^{-1}S)^{-1}S'\hat{\Sigma}_{shr}^{-1}}$ | shrinkage estimator* | Wickramasuriya (2019)

*$\hat{\boldsymbol{\Sigma}}_{shr}$ proposed by Schafer and Strimmer (2005), given by $\tau diag(\hat{\boldsymbol{\Sigma}}_{sam}) + (1 - \tau) \hat{\boldsymbol{\Sigma}}_{sam}$ where $\tau = \frac{\Sigma_{i \neq j} \hat{Var}(\hat{\sigma})_{ij}}{\Sigma_{i \neq j} \hat{\sigma}_{ij}}$ and $\sigma_{ij}$ denotes the $(i,j)$th element of $\hat{\boldsymbol{\Sigma}}_{sam}$

#### 3.2 Coherent probabilistic forecasts
- Let $(\mathbb{R}^m, \mathscr{F}_{\mathbb{R}^m}, \mathcal{v})$ be a probability triple, where $\mathscr{F}_{\mathbb{R}^m}$ is the usual Borel $\sigma$-algebra on $\mathbb{R}^m$
  - triple can be thought of as probabilistic forecasts for bottom-level series
  - a $\sigma$-algebra $\mathscr{F}_{\mathbb{R}^m}$ can then be constructed as the collection of sets $s(\mathcal{B})$ for all $\mathcal{B} \in \mathscr{F}_{\mathbb{R}^m}$ where $s(\mathcal{B})$ denotes the image of $\mathcal{B}$ under the mapping $s$
- *Coherent probabilistic forecasts* (definition 3.1): Given the triple $(\mathbb{R}^m, \mathscr{F}_{\mathbb{R}^m}, \mathcal{v})$, a probability triple $(\mathfrak{s}, \mathscr{F}_{\mathfrak{s}}, \u{\mathcal{v}})$ is given by $\mathfrak{s}$, the $\sigma$-algebra $\mathscr{F}_{\mathfrak{s}}$ and a measure $\u{v}$ such that $$
    \u{v}(s(\mathcal{B})) = v(\mathcal{B}) \hspace{1cm} \forall \mathcal{B} \in \mathscr{F}_{\mathbb{R}}^m$$
  - **Without Borel sets:**

*Figure 2:* Summary of probabilistic forecast reconciliation. (Only a schematic since most applications are high dimensional.)
The probability that $\boldsymbol{y}_{t+h}$ lies in the red segment under the reconciled probabilistic forecast equals the probability of that $\boldsymbol{y}_{t+h}$ lives and the shaded blue area under the unreconciled probabilistic forecast.
<p align="center"><img src="https://robjhyndman.com/img/featured.jpg"></p>

$$\boldsymbol{y_t} = \boldsymbol{S b}_t 
= \begin{bmatrix} \boldsymbol{S}_a\\ \boldsymbol{I}_m \end{bmatrix} \begin{bmatrix} y_{AA, t}\\ {y_{AB,t}}\\ {y_{AC,t}}\\ {y_{BA,t}}\\ {y_{BB,t}} \end{bmatrix} 
= \begin{bmatrix}
  1 & 1 & 1 & 1 & 1 \\
  1 & 1 & 1 & 0 & 0 \\
  0 & 0 & 0 & 1 & 1 \\
  1 & 0 & 0 & 0 & 0 \\
  0 & 1 & 0 & 0 & 0 \\
  0 & 0 & 1 & 0 & 0 \\
  0 & 0 & 0 & 1 & 0 \\
  0 & 0 & 0 & 0 & 1 
\end{bmatrix}
\begin{bmatrix} y_{AA, t}\\ {y_{AB,t}}\\ {y_{AC,t}}\\ {y_{BA,t}}\\ {y_{BB,t}} \end{bmatrix} = 
\begin{bmatrix} 
  y_{AA, t} + y_{AB, t} + y_{AC, t} + y_{BA, t} + y_{BB, t} \\
  y_{AA, t} + y_{AB, t} + y_{AC, t} \\
  y_{BA, t} + y_{BB, t} \\
  y_{AA, t}\\ {y_{AB,t}}\\ {y_{AC,t}}\\ {y_{BA,t}}\\ {y_{BB,t}} 
\end{bmatrix}$$ 

---

## Other papers
https://scholar.google.com/citations?hl=en&user=vamErfkAAAAJ&view_op=list_works&sortby=pubdateP
- [Probabilistic Forecasts in Hierarchical Time Series (2018)](https://www.monash.edu/business/ebs/research/publications/ebs/wp11-2018.pdf)
