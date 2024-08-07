## [Cross-temporal Probabilistic Forecast Reconciliation (2023)](https://arxiv.org/pdf/2303.17277.pdf)
[FoReco package](https://danigiro.github.io/FoReco/articles/FoReco_prob.html#temporal-framework)
### 1 Introduction
*Probabilistic Forecasting in cross-sectional and temporal frameworks:* Ben Taieb et al. (2017), Panamtash & Zhou (2018), Jeon et al. (2019), Yang (2020), Yagli et al. (2020), Ben Taieb et al. (2021), Corani et al. (2021), Corani et al. (2022), Zambon et al. (2022), and Wickramasuriya (2023)
- Panagiotelis et al (2023) significant contribution: formalizing cross-sectional probabilistic reconciliation using geometric framework for point forecast reconciliation of Panagiotelis et al (2021)
  - Show how reconcile forecast can be constructed from arbitrary base forecasts when its density is available and only a sample can be drawn AND 
  - For elliptical distributions, the corrective predictive distribution can be recovered via than your reconciliation, regardless and derived conditions for this to hold in the special case of reconciliation via projection
- Paper overview: "Extend cross-sectional probabilistic reconciliation to the cross-temporal case, working on the issues related to the 2-fold nature of this framework"
  1. Revise and develop Di Fonzo & Girolimetto (2023) notation to **generalize the work of Panagiotleis (2023)**; Cross-temporal Point Reconciliation -> Probabilistic setting (by generalizing definitions + theorems well-established in cross-sectional framework) [**Section 2: Unified notation for cross-sectional, temporal, and cross-temporal point reconciliation**]
  2. **Propose effective and practical solutions to draw sample from base forecasts distribution according to either parametric approach (assumes normality) or non-parametric approach that bootstraps based model residuals** [Section 3]
  3. Proposed solutions to specific problems that arise when combining cross-sectional and temporal dimensions [Section 4: **Analyze structure of cross-temporal co-variance matrix, proposing for alternative forms, and proposed shrinkage approaches for reconciliation; explore pros/cons of cross-temporal residuals (overlapping and multi-step)**]
      - Use multi-step residuals to estimate relationships between different forecast horizons when dealing with temporal levels (1-step residuals not suitable for this purpose)
      - Solve high-dimensionality issues by introducing the idea of overlapping residuals and consider alternative forms for constructing covariance matrix
  4. Proposed new shrinkage procedures for reconciliation that aim to identify feasible cross-temporal structure
  5. Section 5: **Australian GDP data set empirical application**
  6. Section 6: **Australian Tourism Demand data set empirical application**
  7. Section 7: Conclusions + future research agenda

Forecasting accuracy results are evaluated based on CRPS and ES (energy (variogram) score); two applications show optimal cross-temporal reconciliation approaches significantly outperform incoherent base forecasts for both scores

#### My own initial impressions
Consider using the Temporal framework and bootstrap approach, with wlsv ($\textrm{te}(wlsv): \boldsymbol{\Omega} = \hat{\boldsymbol{\Omega}}_{wlsv}$) approximation to the temporal covariance matrix, based on Athanasopoulos (2017)
  - though note the bootstrap method showed poorer performance compared to the gaussian approach -> Gaussian approach is okay
  - but it seems like these results are only for cross-temporal and cross-sectional and cross-temporal combo types of data
    -ct=cross-temporal; oct=optimal-cross-temporal
- There is a simple data set that compares this package with the thief one
  - It shows how to get the same results from the thief example using the new package


**Generally to describe co-variance matrix omega**  
D: Diagonal?  
G: Global shrinkage (off-diagonal) elements shrunk towards zero -> Oct(shr)  
HB: High frequency Bottom Time series shrinkage  
H: High frequency shrinkage matrix  
B: Bottom time series shrinkage matrix  

---

#### My own notes on notation
- $i$ is an index for data points in all levels of the hierarchy, based on the original observation index of the top-level, most aggregate series
- $j$

### 2 Notations and definitions
- $\boldsymbol{y}_t = [y_{1,t},...,y_{i,t},..., y_{n,t}]'$ is an $n$-variate linearly constrained time series observed at the most temporally disaggregated level (bottom-level) with a seasonality of period $m$
  - e.g. $m = 12$ for monthly data, $m = 4$ for quarterly data, $m = 24$ for hourly data
- The constraints may be represented by linear equations such that Di Fonzo & Girolimetto (2023a) 
  $$\boldsymbol{C}_{cs}\boldsymbol{y}_t = \boldsymbol{0}_{(n_a \times 1)}, \hspace{1cm} t = 1, ..., T, $$ 
  where $\boldsymbol{C}_{cs}$ is the $(n_a \times n)$ zero constraints cross-sectional matrix, that can be seen as the coefficient matrix of a linear system with $n_a$ equations and $n$ variables
- An example is a hierarchical series where series at upper levels can be expressed by appropriately summing part or all of the series at the bottom-level

<fieldset>  

**Figure 1:** (a) A simple 2-level cross-sectional hierarchy for 3 time series with $n_a = 1$ and $n_b = 2$   
$\hspace{1.1cm}$ (b) A temporal hierarchy for a quarterly series ($m = 4$ and $k = \{4, 2, 1\}$)  
$\hspace{7.9cm} x_{i,\tau}^{[4]}$  
$\hspace{1.5cm} y_{T, t} \hspace{4.3cm} x_{i, 2\tau-1}^{[2]} \hspace{2cm} x_{i, 2\tau}^{[2]}$  
$\hspace{0.75cm} y_{X, t} \hspace{0.75cm} y_{Y, t} \hspace{3.0cm} y_{i, 4\tau-3} \hspace{0.5cm} y_{i, 4\tau-2} \hspace{0.65cm} y_{i, 4\tau-1} \hspace{0.5cm} y_{i, 4\tau}$  
$\hspace{1.4cm} \boldsymbol{(a)} \hspace{6cm} \boldsymbol{(b)}$  
</fieldset>  ,

- Let $\boldsymbol{y}_t = \begin{bmatrix} \boldsymbol{u}_t' & \boldsymbol{b}_t' \end{bmatrix}'$ where $\boldsymbol{u}_t = \begin{bmatrix} {y}_{1,t} & ... & {y}_{n_a,t} \end{bmatrix}'$ is the $n_a$-vector of upper level time series and $\boldsymbol{b}_t = \begin{bmatrix} {y}_{(n_a + 1),t} & ... & {y}_{n,t} \end{bmatrix}'$ is the $n_b$-vector of bottom-level time series with $n = n_a + n_b$
- Upper and lower level times series connected by cross-sectional aggregation matrix $\boldsymbol{A}_{cs}$ such that $\boldsymbol{u}_t = \boldsymbol{A}_{cs}\boldsymbol{b}_t$
- We can always construct a zero-constraints cross-sectional matrix from aggregation matrix $\boldsymbol{C}_{cs} = \begin{bmatrix} \boldsymbol{I}_{n_a} & - \boldsymbol{A}_{cs} \end{bmatrix}$ where $\boldsymbol{I}_{n_a}$ is a dimension $n_a$ identity matrix (by Girolimetto & Di Fonzo 2023b)
- The cross-sectional structural matrix is given by $\boldsymbol{S}_{cs} = \begin{bmatrix} \boldsymbol{A}_{cs} \\ \boldsymbol{I}_{n_b} \end{bmatrix}$, providing the structural representation $\boldsymbol{y}_t = \boldsymbol{S}_{cs} \boldsymbol{b}_t$ (Hyndman 2011)

<fieldset>  

**Example:** Figure 1(a)
- Two-level hierarchical structure for 3 linearly constrained time series: $y_{T, t} = y_{X, t} + y_{Y, t}$ for all $t = 1, ..., T$
$$ \boldsymbol{y}_t = \begin{bmatrix} \boldsymbol{u}_t \\ \boldsymbol{b}_t \end{bmatrix} = \begin{bmatrix} y_{1,t} \\ y_{2,t} \\ y_{3,t} \end{bmatrix}, \hspace{1cm} \textrm{ where } \boldsymbol{u}_t = \begin{bmatrix} y_{1,t} \end{bmatrix}, \boldsymbol{b}_{t} = \begin{bmatrix} y_{2,t} \\ y_{3,t} \end{bmatrix} \textrm{and } n = n_a + n_b = 1 + 2 = 3$$ 
- We also have: $$\boldsymbol{A}_{cs} = \begin{bmatrix} 1 & 1 \end{bmatrix}, \hspace{1cm} \boldsymbol{I}_{n_a} = \begin{bmatrix} 1 \end{bmatrix}, \hspace{1cm} \boldsymbol{I}_{n_b} = \begin{bmatrix} 1 & 0 \\ 0 & 1 \end{bmatrix}, \hspace{1cm}$$ which give us the results 
  $$\boldsymbol{u}_{t} = \boldsymbol{A}_{cs}\boldsymbol{b}_{t}: y_{1,t} = \begin{bmatrix} 1 & 1 \end{bmatrix} \begin{bmatrix} y_{2,t} \\ y_{3,t} \end{bmatrix} = y_{2,t} + y_{3,t},$$
  $$\boldsymbol{C}_{cs} = \begin{bmatrix} \boldsymbol{I}_{n_a}\boldsymbol{A}_{cs} \end{bmatrix} = \begin{bmatrix} 1 & -1 & -1 \end{bmatrix}, \hspace{1cm} \boldsymbol{S}_{cs} = \begin{bmatrix} \boldsymbol{A}_{cs} \\ \boldsymbol{I}_{n_b} \end{bmatrix} = \begin{bmatrix} 1 & 1 \\ 1 & 0 \\ 0 & 1 \end{bmatrix},$$
  $$\boldsymbol{y}_{t} = \boldsymbol{S}_{cs}\boldsymbol{b}_{t}: \begin{bmatrix} y_{1,t} \\ y_{2,t} \\ y_{3,t} \end{bmatrix} = \begin{bmatrix} 1 & 1 \\ 1 & 0 \\ 0 & 1\end{bmatrix} \begin{bmatrix} y_{2,t} \\ y_{3,t} \end{bmatrix} = \begin{bmatrix} y_{2,t} + y_{3,t} \\ y_{2,t} \\ y_{3,t} \end{bmatrix} = \begin{bmatrix} \boldsymbol{u}_t \\ \boldsymbol{b}_t \end{bmatrix}$$
</fieldset>  ,

* In general, there is no reason for $\boldsymbol{u_t}$ to be restricted to simple sums of $\boldsymbol{b_t}$; thus $\boldsymbol{A}_{cs} \in \mathbb{R}^{n_a \times n_b}$

Temporal framework
- Denote $\mathcal{K} = \{k_p, k_{p-1}, \cdots, k_2, k_1\}$, the set of $p$ factors of $m$ in descending order where $k_1 = 1$ and $k_p = m$ (Athanasopoulos 2017)
- Given a factor $k$ of $m$ and assuming $T = Nm$, we can construct a temporally aggregated version of the time series of a single variable $\{\boldsymbol{y}_{i,t}\}_{t=1,\cdots,T}$ through the non-overlapping sums of its $k$ success of values
  - where $N$ is the length of the most temporarily aggregated version of the series (top-level)
  - with seasonal period $M_k = m/k: x_{i,j}^{[k]} = \Sigma_{t=(j-1)k+1}^{jk} y_{i,t}$
  - and $j=1,\cdots,N_k$, $i=1,\cdots,n$, $N_k=T/k$, and $x_{i,j}^{[1]} = y_{i,t}$
- Define $\tau$ as the observation index of the most aggregate level $k_p$
- For a fixed temporal agg order $k \in \mathcal{K}$, we stack the obs in column vector $\boldsymbol{x}_{i, \tau}^{[k]} = \begin{bmatrix} x_{i, M_k(\tau-1)+1}^{[k]} & x_{i, M_k(\tau-1)+2}^{[k]} & \cdots& x_{i, M_k \tau}^{[k]} \end{bmatrix}'$ and obtain the vector for all temporal aggregation orders $\boldsymbol{x}_{i, \tau} = \begin{bmatrix} \boldsymbol{x}_{i, \tau}^{[k_p]} & \boldsymbol{x}_{i, \tau}^{[k_{p-1}]'} & \cdots & \boldsymbol{x}_{i, \tau}^{[1]'} \end{bmatrix}'$ where $\tau = 1, \cdots, N$
- Structural representation of temporal hierarchy: $\boldsymbol{x}_{i, \tau} = \boldsymbol{S}_{te}\boldsymbol{x}_{i, \tau}^{[1]}$ (Athanasopoulos 2017) where
  - $\boldsymbol{S}_{te} = \begin{bmatrix} \boldsymbol{A}_{te} \\ \boldsymbol{I}_m \end{bmatrix}$ is the $[(m + k^*)\times m ]$ is the temporal structural matrix
  - $\boldsymbol{A}_{te} = \begin{bmatrix} \boldsymbol{1}_{k_p} & \boldsymbol{I}_{m/(k_{p-1})} \otimes \boldsymbol{1}_{k_{p-1}} & \cdots & \boldsymbol{I}_{m/k2} \otimes \boldsymbol{1}_{k2} \end{bmatrix}'$ is the $[ k^*\times m ]$ is the temporal aggregation matrix with
    - the number of upper time series of the temporal hierarchy $k^* = \Sigma_{k \in \mathcal{K}/\{k_1\}} M_k$
  - $\boldsymbol{1}_{k_p}$ is a $(k_p \times 1)$ is a vector of all ones
  - $\otimes$ is the [Kronecker product](https://en.wikipedia.org/wiki/Kronecker_product), i.e. for $m \times n$ matrix $\boldsymbol{A}$ and $p \times q$ matrix $\boldsymbol{B}$, the Kronecker product is $\boldsymbol{A} \otimes \boldsymbol{B} = \begin{bmatrix} a_{11}\boldsymbol{B} & \cdots & a_{1n}\boldsymbol{B} \\ \vdots & \ddots & \vdots \\ a_{m_1}\boldsymbol{B} & \cdots & a_{mn}\boldsymbol{B} \end{bmatrix}$ (a $pm \times qn$ block matrix)
- For each series $x_{i,\tau}, i = 1,\cdots,n$, we also have the zero-constrained representation (2)
  $$\boldsymbol{C}_{te}\boldsymbol{x}_{i,\tau} = \boldsymbol{0}_{[k^* \times (m + k^*)]}, \hspace{1cm} \tau = 1, ..., N, \hspace{1cm} i = 1, \cdots, n$$ 
  where $\boldsymbol{C}_{te} = \begin{bmatrix} \boldsymbol{I}_{k^*} & -\boldsymbol{A}_{te} \end{bmatrix}$ is the $[k^* \times (m + k^*)]$ zero constraints temporal matrix

<fieldset>

**Example:** Figure 1(b) Quarterly time series
- $m = 4$, $p = 3$, and $\mathcal{K} = \{k_3, k_2, k_1\} = \{4, 2, 1\}$; number of upper time series $k^* = 3$
- We also have: $$\hspace{1cm} \boldsymbol{I}_{k^*} = \boldsymbol{I}_{3}, \hspace{1cm} \boldsymbol{I}_{k_p} = \boldsymbol{I}_{4}, \hspace{1cm}$$ which give us the results 
$$\boldsymbol{A}_{te} = \begin{bmatrix} \boldsymbol{1}_{k_p} \\ \boldsymbol{I}_{m/(k_{p-1})} \otimes \boldsymbol{1}_{k_{p-1}} \\ \cdots \\ \boldsymbol{I}_{m/k2} \otimes \boldsymbol{1}_{k2} \end{bmatrix} = \begin{bmatrix} \boldsymbol{1}_{k_3} \\ \\ \boldsymbol{I}_{m/k_2} \otimes \boldsymbol{1}_{k_2} \end{bmatrix} = \begin{bmatrix} \boldsymbol{1}_{4} \\ \\ \boldsymbol{I}_{2} \otimes \boldsymbol{1}_{2} \end{bmatrix} = \begin{bmatrix} 1 & 1 & 1 & 1 \\ 1 & 1 & 0 & 0 \\ 0 & 0 & 1 & 1 \end{bmatrix}$$
$\hspace{1.25cm} $ from $\boldsymbol{I}_2 \otimes \boldsymbol{1}_2= \begin{bmatrix} 1 & 0 \\ 0 & 1 \end{bmatrix} \otimes \begin{bmatrix} 1 \\ 1 \end{bmatrix} = \begin{bmatrix} 1 \begin{bmatrix} 1 \\ 1 \end{bmatrix} & 0 \begin{bmatrix} 1 \\ 1 \end{bmatrix} \\ 0 \begin{bmatrix} 1 \\ 1 \end{bmatrix} & 1 \begin{bmatrix} 1 \\ 1 \end{bmatrix} \end{bmatrix} = \begin{bmatrix} 1 & 1 & 0 & 0 \\ 0 & 0 & 1 & 1 \end{bmatrix}$

  $$\bigg( \begin{bmatrix} \boldsymbol{x}_{i,\tau}^{[4]} \\ \boldsymbol{x}_{i,\tau}^{[2]} \end{bmatrix} = \boldsymbol{A}_{te}\boldsymbol{x}_{i,\tau}^{[1]}: x_{i,\tau} = \begin{bmatrix} 1 & 1 & 1 & 1 \\ 1 & 1 & 0 & 0 \\ 0 & 0 & 1 & 1 \end{bmatrix} \begin{bmatrix} y_{i,4\tau-3} \\ y_{i,4\tau-2} \\ y_{i,4\tau-1} \\ y_{i,4\tau} \end{bmatrix} = \begin{bmatrix} y_{i,4\tau-3} + y_{i,4\tau-2} + y_{i,4\tau-1} + y_{i,4\tau} \\  y_{i,4\tau-3} + y_{i,4\tau-2} \\ y_{i,4\tau-1} + y_{i,4\tau} \end{bmatrix} \bigg),$$
  $$\boldsymbol{C}_{te} = \begin{bmatrix} \boldsymbol{I}_{k^*} & \boldsymbol{A}_{te} \end{bmatrix} = \begin{bmatrix} 1 & 0 & 0 & -1 & -1 & -1 & -1 \\ 0 & 1 & 0 & -1 & -1 & 0 & 0 \\ 0 & 0 & 1 & 0 & 0 & -1 & -1 \end{bmatrix}, \hspace{0.75cm} \boldsymbol{S}_{te} = \begin{bmatrix} \boldsymbol{A}_{te} \\ \boldsymbol{I}_{k_p} \end{bmatrix} = \begin{bmatrix} 1 & 1 & 1 & 1 \\ 1 & 1 & 0 & 0 \\ 0 & 0 & 1 & 1 \\ & \boldsymbol{I}_{4} & \end{bmatrix},$$
  $$\boldsymbol{x}_{i,\tau} = \boldsymbol{S}_{te}\boldsymbol{x}_{i, \tau}^{[1]}: \begin{bmatrix} \boldsymbol{x}_{i, \tau}^{[4]} \\ \boldsymbol{x}_{i,\tau}^{[2]} \\ \boldsymbol{x}_{i,\tau}^{[1]} \end{bmatrix} =  \begin{bmatrix} 1 & 1 & 1 & 1 \\ 1 & 1 & 0 & 0 \\ 0 & 0 & 1 & 1 \\ & \boldsymbol{I}_{4} & \end{bmatrix} \begin{bmatrix} y_{i,4\tau-3} \\ y_{i,4\tau-2} \\ y_{i,4\tau-1} \\ y_{i,4\tau} \end{bmatrix} = \begin{bmatrix} y_{i,4\tau-3} + y_{i,4\tau-2} + y_{i,4\tau-1} + y_{i,4\tau} \\  y_{i,4\tau-3} + y_{i,4\tau-2} \\ y_{i,4\tau-1} + y_{i,4\tau} \\ \boldsymbol{x}_{i,\tau}^{[1]} \end{bmatrix}$$
</fieldset>  ,

Cross-section AND Temporal framework
- For the unified framework, stack series into $[n \times(m + k^*)]$ matrix $\boldsymbol{X}_{\tau}$ with
  - total number of time series $n$
  - seasonal period $m$
  - total number of time series $k^*$
- Rows and columns represent cross-sectional and temporal dimensions of $\boldsymbol{X}_{\tau}$ respectively: 
  $$\boldsymbol{X}_{\tau} = \begin{bmatrix} \boldsymbol{x}_{1,\tau}' \\ \vdots \\ \boldsymbol{x}_{n,\tau}' \end{bmatrix} = \begin{bmatrix} \boldsymbol{U}_{\tau}^{[k_p]} & \boldsymbol{U}_{\tau}^{[k_p-1]} & \cdots & \boldsymbol{U}_{\tau}^{[1]} \\ \boldsymbol{B}_{\tau}^{[k_p]} & \boldsymbol{B}_{\tau}^{[k_p-1]} & \cdots & \boldsymbol{B}_{\tau}^{[1]} \end{bmatrix},$$ 
  where for any fixed $k$, $\boldsymbol{U}_{\tau}^{[k]}$ is the $(n_a\times N_k)$ matrix grouping the upper time series and $\boldsymbol{B}_{\tau}^{[k]}$ is the $(n_b\times N_k)$ matrix grouping the bottom time series

<fieldset>  

**Example:** *Cross-Temporal framework* (combining cross-sectional and temporal hierarchies of Figure 1)  
a) A simple 2-level cross-sectional hierarchy for 3 time series with $n_a = 1$ and $n_b = 2$   
b) A temporal hierarchy for a quarterly series ($m = 4$ and $k = \{4, 2, 1\}$)  

$\hspace{7.9cm} x_{i,\tau}^{[4]}$  
$\hspace{1.5cm} y_{T, t} \hspace{4.3cm} x_{i, 2\tau-1}^{[2]} \hspace{2cm} x_{i, 2\tau}^{[2]}$  
$\hspace{0.75cm} y_{X, t} \hspace{0.75cm} y_{Y, t} \hspace{3.0cm} y_{i, 4\tau-3} \hspace{0.5cm} y_{i, 4\tau-2} \hspace{0.65cm} y_{i, 4\tau-1} \hspace{0.5cm} y_{i, 4\tau}$  
$\hspace{1.4cm} \boldsymbol{(a)} \hspace{6cm} \boldsymbol{(b)}$  

Combine the zero-constraints matrices $$\boldsymbol{C}_{cs} = \begin{bmatrix} 1 & -1 & -1 \end{bmatrix}, \hspace{1.25cm} \boldsymbol{C}_{te} = \begin{bmatrix} 1 & 0 & 0 & -1 & -1 & -1 & -1 \\ 0 & 1 & 0 & -1 & -1 & 0 & 0 \\ 0 & 0 & 1 & 0 & 0 & -1 & -1 \end{bmatrix}$$ to obtain 

**Figure 2**: Visual representation of the zero constraints cross-temporal matrix $\boldsymbol{C}_{ct}$ for a system of 3 linearly constrained quarterly time series (see Figure 1). White represents 0s, black 1s, red -1s 
- *Four upper rows*: Cross-sectional constraints (1-per-quarter)
- *Remaining rows*: Temporal constraints (1 per time series)

![](./ct-prob_fig2.png)

Cross temporal structure from Figure 1:
  $$\boldsymbol{X}_{\tau} = \left[\begin{array}{c|cc|cccc}
  x^{[4]}_{T,\tau} & x^{[2]}_{T,2\tau-1} & x^{[2]}_{T,2\tau} & y_{T,4\tau-3} & y_{T,4\tau-2} & y_{T,4\tau-1} & y_{T,4\tau}\\
  \hline
  x^{[4]}_{X,\tau} & x^{[2]}_{X,2\tau-1} & x^{[2]}_{X,2\tau} & y_{X,4\tau-3} & y_{X,4\tau-2} & y_{X,4\tau-1} & y_{X,4\tau}\\
  x^{[4]}_{Y,\tau} & x^{[2]}_{Y,2\tau-1} & x^{[2]}_{Y,2\tau} & y_{Y,4\tau-3} & y_{Y,4\tau-2} & y_{Y,4\tau-1} & y_{Y,4\tau}\\
  \end{array}\right]$$
where rows and columns represent the cross-sectional and temporal dimensions respectively 

Recall that $n_a = 1, n_b = 2, n = 3; m = 4, k^* = 3$ and that $$\boldsymbol{C}_{cs} = \begin{bmatrix} 1 & -1 & -1 \end{bmatrix} \textrm{ and } \boldsymbol{C}_{te} = \begin{bmatrix} 1 & 0 & 0 & -1 & -1 & -1 & -1 \\ 0 & 1 & 0 & -1 & -1 & 0 & 0 \\ 0 & 0 & 1 & 0 & 0 & -1 & -1 \end{bmatrix},$$ hence:
  $$\boldsymbol{C}_{cs}\boldsymbol{X}_{\tau} = \begin{bmatrix} x_{T,\tau}^{[4]} - x_{X,\tau}^{[4]} - x_{Y,\tau}^{[4]} & \cdots & y_{T,4\tau} - y_{X,4\tau} - y_{Y,4\tau} \end{bmatrix} = \boldsymbol{0}_{1 \times 7} = \boldsymbol{0}_{[n_a \times 
  (m + k^*)]}$$
  $$\boldsymbol{C}_{te}\boldsymbol{X}_{\tau}' = \cdots = \boldsymbol{0}_{(3 \times 3)} = \boldsymbol{0}_{(k^* \times n)}$$
</fieldset>  ,

- Further, $\boldsymbol{C}_{cs}\boldsymbol{X}_{\tau} = \boldsymbol{0}_{[n_a \times (m + k^*)]}$ and $\boldsymbol{C}_{te}\boldsymbol{X}_{\tau}' = \boldsymbol{0}_{(k^* \times n)}$
- Cross-temporal framework is generalization of cross-sectional and temporal frameworks that simultaneously takes both types of constraints into account
  - Cross-sectional reconciliation (Hyndman 2011) obtained with $m = 1$
  - Temporal reconciliation (Athanasopoulos 2017) with $n = 1$ ($n_a = 0, n_b = 1$)
- D&G 2023a show cross-temporal constraints working on complete set of observations corresponding to time period $\tau$ can be expressed in zero-constraint representation through full rank $[(n_a m + nk^*) \times  n(m + k^*)]$ zero constraints cross-temporal matrix $\boldsymbol{C}_{ct}$ such that $$\boldsymbol{C}_{ct} = \begin{bmatrix} \boldsymbol{C}_{*}\\ \boldsymbol{I}_n \otimes \boldsymbol{C}_{te} \end{bmatrix} \rightarrow \boldsymbol{C}_{ct} \boldsymbol{x}_{\tau} = \boldsymbol{0}_{[(n_am+nk^*)\times 1]} \hspace{10pt} \textrm{ for } \tau = 1, \cdots, N \hspace{1cm} (3)$$ where:
  - $\boldsymbol{x}_{\tau} = \textrm{vec}(\boldsymbol{X}_{\tau}') = \begin{bmatrix} \boldsymbol{x}_{1,\tau'}' & \cdots & \boldsymbol{x}_{n,\tau'}' \end{bmatrix}'$,
  - $\boldsymbol{C}_{*} = \begin{bmatrix} \boldsymbol{0}_{(n_a m \times nk^*)} & \boldsymbol{I}_m \otimes \boldsymbol{C}_{cs} \end{bmatrix} \boldsymbol{P}'$
  - $\boldsymbol{P}$ is the commutation matrix (Magnus & Neudecker 2019) such that $\boldsymbol{P} \textrm{vec}(\boldsymbol{P}_{\tau}) = \textrm{vec}(\boldsymbol{P}_{\tau}')$
    - *Key property:* commutation matrix $\boldsymbol{P}$ allows us to interchange (commute) the two matrices of a Kronecker product
    - *Application:* allows transformation of the vec of a Kronecker product into the Kronecker product of the Vex
  - The operater $\textrm{vec}(\cdot)$ converts a matrix into a vector
- Figure 2 shows a visual example for the zero constraints cross-temporal matrix
- Structural representation: $\boldsymbol{x}_{\tau} = \boldsymbol{S}_{ct}\boldsymbol{b}_{\tau}^{[1]} = s(\boldsymbol{b}_{\tau}^{[1]})$, where $$\boldsymbol{S}_{ct} = \boldsymbol{S}_{cs} \otimes \boldsymbol{S}_{te} \hspace{3cm} (4)$$ is the $[n(k^*+m)\times n_bm]$ cross-temporal summation matrix
  - $s \textrm{ : } \mathbb{R}^{n_b m} \rightarrow \mathbb{R}^{n(m + k^*)}$ is the operator describing the pre-multiplication by $\boldsymbol{S}_{ct}$
  - $\boldsymbol{b}_{\tau}^{[1]} = \textrm{vec}(\boldsymbol{B}_{\tau}^{[1]'})$
  
<fieldset>

**Figure 3**: Visual representation of the cross-temporal summation matrix $\boldsymbol{S}_{ct} = \boldsymbol{S}_{cs} \otimes \boldsymbol{S}_{te}$ defined in (4) for a system of 3 linearly constrained quarterly time series (Figure 1).  
- White represents 0s, black 1s, red -1s 

![](./ct-prob_fig3.png)
</fieldset>  ,

- Figure 3 represents $\boldsymbol{S}_{ct}$ for system of 3 linearly constrained quarterly time series (see Figure 1)
- $\boldsymbol{x}_{\tau}$ lies in an $(n_bm)$-dimensional subspace $\mathfrak{s}_{ct}$ of $\mathbb{R}^{n(k^*)}$, which we refer to as the *cross-temporal coherent subspace*, spanned by the columns of $\boldsymbol{S}_{ct}$


<fieldset>

We show that Equation(3) is true:  
$$\boldsymbol{C}_{ct} = \begin{bmatrix} \boldsymbol{C}_{*}\\ \boldsymbol{I}_n \otimes \boldsymbol{C}_{te} \end{bmatrix} \rightarrow \boldsymbol{C}_{ct} \boldsymbol{x}_{\tau} = \boldsymbol{0}_{[(n_am+nk^*)\times 1]} \hspace{10pt} \textrm{ for } \tau = 1, \cdots, N \hspace{1cm} (3)$$

$$\boldsymbol{C}_{ct} = \begin{bmatrix} \boldsymbol{C}_{*}\\ \boldsymbol{I}_n \otimes \boldsymbol{C}_{te} \end{bmatrix} = \begin{bmatrix} \boldsymbol{0}_{(n_a m \times nk^*)}\boldsymbol{P}' & (\boldsymbol{I}_m \otimes \boldsymbol{C}_{cs})\boldsymbol{P}' \end{bmatrix}$$ 

$$\rightarrow \boldsymbol{C}_{ct} \boldsymbol{x}_{\tau} = \boldsymbol{0}_{[(n_am+nk^*)\times 1]} \hspace{10pt} \textrm{ for } \tau = 1, \cdots, N \hspace{1cm} (3)$$

Some notes  
  - $\boldsymbol{x}_{\tau} = \textrm{vec}(\boldsymbol{X}_{\tau}') = \begin{bmatrix} \boldsymbol{x}_{1,\tau'}' & \boldsymbol{x}_{2,\tau'}' & \boldsymbol{x}_{3,\tau'}' \end{bmatrix}'$ is dim $n(m+k^*) = 3(7) = 21$
  ,
  - $\boldsymbol{C}_{*} = \begin{bmatrix} \boldsymbol{0}_{(n_a m \times nk^*)} & \boldsymbol{I}_m \otimes \boldsymbol{C}_{cs} \end{bmatrix} \boldsymbol{P}' = \begin{bmatrix} \boldsymbol{0}_{1 \times 7} & \boldsymbol{I}_4 \otimes \begin{bmatrix} 1 & -1 & -1 \end{bmatrix} \end{bmatrix} \boldsymbol{P}'$
  
- Structural representation: $\boldsymbol{x}_{\tau} = \boldsymbol{S}_{ct}\boldsymbol{b}_{\tau}^{[1]} = s(\boldsymbol{b}_{\tau}^{[1]})$
  - $\boldsymbol{b}_{\tau}^{[1]} = \textrm{vec}(\boldsymbol{B}_{\tau}^{[1]}) = \textrm{vec}(\begin{bmatrix} \hat{y}_{X,1} & \hat{y}_{X,2} & \hat{y}_{X,3} & \hat{y}_{X,4} \\ \hat{y}_{Y,1} & \hat{y}_{Y,2} & \hat{y}_{Y,3} & \hat{y}_{Y,4} \end{bmatrix})$
, where $$\boldsymbol{S}_{ct} = \boldsymbol{S}_{cs} \otimes \boldsymbol{S}_{te} \hspace{3cm} (4)$$ is the $[n(k^*+m)\times n_bm]$ cross-temporal summation matrix
  - $s \textrm{ : } \mathbb{R}^{n_b m} \rightarrow \mathbb{R}^{n(m + k^*)}$ is the operator describing the pre-multiplication by $\boldsymbol{S}_{ct}$
</fieldset>  ,


### 2.1 Optimal Point Forecast Reconciliation
- For $h = 1, \cdots, H$, let $$\hat{\boldsymbol{X}}_{h} = \begin{bmatrix} \boldsymbol{\hat{x}}_{1, h}' \\ \vdots \\ \boldsymbol{\hat{x}}_{n, h}' \end{bmatrix} = \begin{bmatrix} \boldsymbol{\hat{U}}_{h}^{[m]} & \cdots & \boldsymbol{\hat{U}}_{h}^{[k]} & \cdots & \boldsymbol{\hat{U}}_{h}^{[1]} \\ \boldsymbol{\hat{B}}_{h}^{[m]} & \cdots & \boldsymbol{\hat{B}}_{h}^{[k]} & \cdots & \boldsymbol{\hat{B}}_{h}^{[1]} \end{bmatrix},$$ be the $h$-step ahead *base forecasts*, where 
  - $\hat{\boldsymbol{U}}_h^{[k]}$ is the $(n_a \times M_k)$ matrix grouping the upper time series,
  - $\hat{\boldsymbol{B}}_h^{[k]}$ is the $(n_b \times M_k)$ matrix grouping the bottom time series for a given temporal aggregation order $k$, and
  - $H$ is the forecast horizon for the most temporarily aggregated time series

<fieldset>

**Example:** *Incoherent Base Forecasts (Point)* (Cross-temporal combination of Figure 1)  
a) A simple 2-level cross-sectional hierarchy for 3 time series with $n_a = 1$ and $n_b = 2$   
b) A temporal hierarchy for a quarterly series ($m = 4$ and $k = \{4, 2, 1\}$)  

$\hspace{7.9cm} x_{i,\tau}^{[4]}$  
$\hspace{1.5cm} y_{T, t} \hspace{4.3cm} x_{i, 2\tau-1}^{[2]} \hspace{2cm} x_{i, 2\tau}^{[2]}$  
$\hspace{0.75cm} y_{X, t} \hspace{0.75cm} y_{Y, t} \hspace{3.0cm} y_{i, 4\tau-3} \hspace{0.5cm} y_{i, 4\tau-2} \hspace{0.65cm} y_{i, 4\tau-1} \hspace{0.5cm} y_{i, 4\tau}$  
$\hspace{1.4cm} \boldsymbol{(a)} \hspace{6cm} \boldsymbol{(b)}$  

Based on the example in Figure 1 for $H=1$:
  $$\boldsymbol{\hat{X}}_{1} = \left[\begin{array}{c|cc|cccc}
  \hat{x}^{[4]}_{T,1} & \hat{x}^{[2]}_{T,1} & \hat{x}^{[2]}_{T,2} & \hat{y}_{T,1} & \hat{y}_{T,2} & \hat{y}_{T,3} & \hat{y}_{T,4}\\
  \hline
  \hat{x}^{[4]}_{\hat{X},1} & \hat{x}^{[2]}_{\hat{X},1} & \hat{x}^{[2]}_{X,2} & \hat{y}_{X,1} & \hat{y}_{X,2} & \hat{y}_{X,3} & \hat{y}_{X,4}\\
  \hat{x}^{[4]}_{Y,1} & \hat{x}^{[2]}_{Y,1} & \hat{x}^{[2]}_{Y,2} & \hat{y}_{Y,1} & \hat{y}_{Y,2} & \hat{y}_{Y,3} & \hat{y}_{Y,4}\\
  \end{array}\right]$$ where rows and columns represent the cross-sectional and temporal dimensions respectively 

</fieldset>  ,

- The matrix $\boldsymbol{\hat{X}}_{h}$ contains incoherent forecasts, such as $\boldsymbol{C}_{ct}\hat{\boldsymbol{x}}_h \neq \boldsymbol{0}_{[(n_am+mk^*) \times 1]}$ with $h = 1, \cdots, H$ and $\hat{\boldsymbol{x}}_{h} = \textrm{vec}(\hat{\boldsymbol{X}}_h')$
- In this framework, the definition for forecast-reconciliation and the cross-sectional framework given by Panagiotelis (2021) can be generalized as follows
- **Definition 2.1**: *Forecast reconciliation* adjusts the base forecast $\hat{\boldsymbol{x}}_h$ by finding a mapping $\psi : \mathbb{R}^{n(m + k^*)} \rightarrow \mathfrak{s}$, such that $\tilde{\boldsymbol{x}}_h = \psi(\hat{\boldsymbol{x}}_h)$, where $\tilde{\boldsymbol{x}}_h \in \mathfrak{s}$ is the *vector of reconciled forecasts*
- For given forecast horizon $h = 1, \cdots, H$, the mapping $\psi$ may be defined as a projection onto $\mathfrak{s}$ given by $$\tilde{\boldsymbol{x}}_h = \psi(\hat{\boldsymbol{x}}_h) = \boldsymbol{M}\hat{\boldsymbol{x}}_h \hspace{2in} (5)$$ where 
  - $\boldsymbol{M} = \boldsymbol{I}_{n(m+k^*)} - \boldsymbol{\Omega}_{ct}\boldsymbol{C}_{ct}'(\boldsymbol{C}_{ct}\boldsymbol{\Omega}_{ct}\boldsymbol{C}_{ct}')^{-1}\boldsymbol{C}_{ct}$ for
    - a positive definite matrix $\boldsymbol{\Omega}_{ct}$ and
    - $\tilde{\boldsymbol{x}}_h = \textrm{vec}(\tilde{\boldsymbol{X}}_h')$
- The minimum variance linear unbiased reconcile forecasts, satisfying the unbiasedness condition $E(\tilde{\boldsymbol{x}}_h-\boldsymbol{x}_h) = 0$, has solution(5) when $\boldsymbol{\Omega}_{ct} = \textrm{Var}(\hat{\boldsymbol{x}}_h - \boldsymbol{x}_h)$ (Wickramasuriya 2019)
- Alternatively, the Cross-temporal reconciled forecasts $\tilde{\boldsymbol{X}}_h$ may be found according to the structural approach proposed by Hyndman (2011) for the cross-sectional framework, yielding $\tilde{\boldsymbol{x}}_h = \boldsymbol{S}_{ct}\boldsymbol{G}\hat{\boldsymbol{x}}_h$ for some matrix $\boldsymbol{G}$
- Wickramasuriya 2019 showed this leads to a solution equivalent to the cross-temporarily reconcile forecasts in (5), given by 
  $$\tilde{\boldsymbol{x}}_h = \psi(\hat{\boldsymbol{x}}_h) = (s \circ g)(\hat{\boldsymbol{x}}_h) = \boldsymbol{S}_{ct}\boldsymbol{G}\hat{\boldsymbol{x}}_h \hspace{1.5in} (6)$$ where 
  - $\boldsymbol{G} = (\boldsymbol{S}_{ct}' \boldsymbol{\Omega}_{ct}^{-1}\boldsymbol{S}_{ct})^{-1}\boldsymbol{S}_{ct}'\boldsymbol{\Omega}_{ct}^{-1}$
  - $\boldsymbol{M}=\boldsymbol{S}_{ct}\boldsymbol{G}$
- In this case $\psi$ is a composition of two transformations, say $s \circ g$, where $g \textrm{ : } \mathbb{R}^{n(m + k^*)} \rightarrow \mathbb{R}^{n_b m}$ is a continuous function

<fieldset>

**Online Appendix A**: Approximations for the covariance matrix to be used (5) and (6)

*Table A.1 (modified):* Approximations for Cross-Sectional, Temporal, and Cross-temporal co-variance matrices for one-step ahead in-sample forecast errors

Method | Cross-Sectional framework $\boldsymbol{W}$ | Temporal framework $\boldsymbol{\Omega}_{t}$ | Cross-temporal framework $\boldsymbol{\Omega}_{ct}$
:-----:|:--------:|:--------------:|:-------------:
identity | cs(*ols*): $\boldsymbol{I}_n$ | cs(*ols*): $\boldsymbol{I}_{k^*+m}$ | oct(*ols*): $\boldsymbol{I}_{n(k^*+m)}$
structural | cs(*struc*): $\textrm{diag}(\boldsymbol{S}_{cs}\boldsymbol{1}_{n_b})$ | cs(*struc*): $\textrm{diag}(\boldsymbol{S}_{te}\boldsymbol{1}_{m})$ | oct(*struc*): $\textrm{diag}(\boldsymbol{S}_{ct}\boldsymbol{1}_{mn_b})$
series variance | cs(*wls*): $\hat{\boldsymbol{W}}_D = \boldsymbol{I}_n \odot \hat{\boldsymbol{W}}$ | te(*wls*): $\hat{\boldsymbol{\Omega}}_{wlsv}$ | oct(*wls*): $\hat{\boldsymbol{\Omega}}_{ct, wlsv}$
block-diagonal shrunk cross-covariance scaling | -- | -- | oct(*shr*): $\boldsymbol{P} \hat{\boldsymbol{W}}_{ct, shr}^{BD} \boldsymbol{P}'$
MinT-shr | cs(*shr*): $\lambda \hat{\boldsymbol{W}}_D + (1 - \lambda) \hat{\boldsymbol{W}}$ | te(*shr*): $\hat{\lambda} \hat{\boldsymbol{\Omega}}_{D} + (1 - \hat{\lambda}) \hat{\boldsymbol{\Omega}_{te}}$ | oct(*shr*): $\hat{\lambda} \hat{\boldsymbol{\Omega}}_{ct,D} + (1 - \hat{\lambda}) \hat{\boldsymbol{\Omega}_{ct}}$
MinT-sam | cs(*sam*): $\hat{\boldsymbol{W}}$ | te(*sam*): $\hat{\boldsymbol{\Omega}}_{te}$ | oct(*sam*): $\hat{\boldsymbol{\Omega}}_{ct}$

Where:   
- $\hat{\boldsymbol{\Omega}}_{wlsv}$ is a diagonal matrix presented by Athanasopoulos 2017
- $\hat{\boldsymbol{W}}_{ct, shr}^{BD}$ is a block-diagonal matrix with
  - each $k$-block ($k = m, k_{p-1}, \cdots, 1$) is $\boldsymbol{I}_{M_k} \otimes \hat{\boldsymbol{W}}_{shr}^{[k]}$
  - $\hat{\boldsymbol{W}}_{shr}^{[k]}$ is the shrunk estimate of the cross-sectional co-variance matrix proposed by Wickramasuriya 2019
- $\boldsymbol{P}$ is the commutation matrix such that $\boldsymbol{P} \textrm{vec}(\boldsymbol{Y}_{\tau}) = \textrm{vec}(\boldsymbol{Y}_{\tau}')$
- $\hat{\lambda}$ is an estimated shrinkage coefficient (Ledoit & Wolf 2004)
- $\hat{\boldsymbol{\Omega}_{ct, D}} = \boldsymbol{I}_{n(k^*+m)} \odot \hat{\boldsymbol{\Omega}}_{ct}$ with
  - $\odot$ denoting the [Hadamard product](https://en.wikipedia.org/wiki/Hadamard_product_(matrices)), i.e. for $m \times n$ matrices $\boldsymbol{A}$ and $\boldsymbol{B}$, the Hadamard product is $\boldsymbol{A} \odot \boldsymbol{B} = \begin{bmatrix} a_{11}b_{11} & \cdots & a_{1n} b_{1n} \\ \vdots & \ddots & \vdots \\ a_{m1}b_{m1} & \cdots & a_{mn} b_{mn} \end{bmatrix}$ 
</fieldset>  ,


### 2.2 Cross-temporal bottom-up forecast reconciliation
- The classic bottom-up approach simply consists of summing-up base forecasts of the most disaggregated level in the hierarchy to obtain forecasts of the upper-level series
- To reduce computational cost of optimal cross-temporal reconciliation, we may apply a reconciliation of cross-only one dimension (cross-sectional or temporal) and reconstructing the cross-temporal structure using a partly bottom-up approach
- Figure 4 provides a visual representation of partly bottom-up in a two-step cross-temporal reconciliation approach
  - ct($rec_{cs}, bu_{te}$) is cross-temporal approach with temporaly reconciled forecasts for the highest frequency temporal level, then applying cross-sectional bottom-up
  - ct($rec_{te}, bu_{cs}$) is cross-temporal approach with temporarily reconciled forecasts for the most dis aggregate cross-sectional level, then applying cross-sectional bottom-up
  - Note ct($bu_{cs}, bu_{te}$) = ct($bu_{te}, bu_{cs}$) = ct($bu$)
<fieldset>

**Figure 4**: Visual representation of the partly-bottom-up-starting-from   
- (4a) Cross-sectionally reconciled forecasts for temporal order $k = 1$ ($\tilde{\boldsymbol{U}}^{[1]}$ and $\tilde{\boldsymbol{B}}^{[1]}$) followed by temporal bottom-up and
- (4b) Temporally reconciled forecasts of the cross-sectional bottom-time series ($\tilde{\boldsymbol{B}}^{[1]}$, $k \in \mathcal{K}$) followed by cross-sectional bottom-up   

The blue background indicates generating reconciled forecasts along one dimension, while the pink background indicates the forecasts obtained using bottom-up along the other

![](./ct-prob_fig4.png)
</fieldset>  ,


## 3 Probabilistic forecast reconciliation
- To re-introduce coherence and probabilistic forecast reconciliation, adapt notations/formal definitions in Wickramasuriya 2023 and Panagiotelis 2023 for the Cross-Sectional Probabilistic case
  - Can be generalized to Cross-temporal framework for count data using Corani 2023 but here we only focus on the continuous case
  - Aim to extend definitions to *cross-temporal coherent probabilistic forecasts* and *Cross-temporal probabilistic forecast reconciliation*
- Let $(\mathbb{R}^{n_b m}, \mathcal{F}_{\mathbb{R}^{n_b m}}, \mathcal{v})$ be a probability space for the bottom-time series $\boldsymbol{b}_{\tau}^{[1]}$, where $\mathcal{F}_{\mathbb{R}^{n_b m}}$ is the usual Borel $\sigma$-algebra on $\mathbb{R}^{n_b m}$. Then a $\sigma$-algebra $\mathcal{F}_{\mathfrak{s}}$ can then be constructed as the collection of sets $s(\mathcal{B})$ for all $\mathcal{B} \in \mathcal{F}_{\mathbb{R}^{n_b m}}$ 
  - A *probability space* or a probability triple $(\Omega, \mathcal{F}, P)$ is a mathematical construct that provides a formal model of a random process or experiment, e.g. a probability triple modeling throwing a die, consisting of three elements [Wikipedia](https://en.wikipedia.org/wiki/Probability_space):
    1. A *sample space* $\Omega$, the set of all possible outcomes
    2. An *event space*, a set of events $\mathcal{F}$ (where an event being a set of outcomes in the sample space)
    3. A *probability function* $P$ which assigns a probability to each event in the event space
  - A *Borel $\sigma$-algebra* is a sigma-algebra generated by the open sets (or equivalently, the closed sets) of a topological space. It is the smallest sigma-algebra containing all open sets or closed sets
    - A *sigma-algebra* is a special type of collection that satisfies certain properties ensuring that the collection is closed under set operations like a union, intersection, and complement, ie performing these operations on any two sets from the collection will produce a result still in the collection
    - A *Borel set* (all of which together on a single topological space forms the Borel sigma-algebra) is formed by combining either open or closed sets using specific operations:
      - Countable union: take a bunch of open or closed sets and merge them together
      - Countable intersection: consider the overlapping parts of these sets
      - Relative complement: Remove some parts from one set based on another set
- **Definition 3.1** (Cross-temporal coherent probabilistic forecasts): Given the probability space $(\mathbb{R}^{n_b m}, \mathcal{F}_{\mathbb{R}^m}, \mathcal{v})$, we define the coherent probability space as the triple $(\mathfrak{s}, \mathcal{F}_{\mathfrak{s}}, \u{\mathcal{v}})$ satisfying the following property: $\u{v}(s(\mathcal{B})) = v(\mathcal{B}) \hspace{10pt} \forall \mathcal{B} \in \mathcal{F}_{\mathbb{R}}^{n_b m}$
- Let $(\mathbb{R}^{n(m + k^*)}, \mathcal{F}_{\mathbb{R}^{n(m+k^*)}}, \hat{\mathcal{v}})$ be a probability space referring to the incoherent probabilistic forecast ($\hat{\boldsymbol{x}}$) for all the $n$ series in the system at any temporal aggregation order $k \in \mathcal{K}$
- **Definition 3.2** (Cross-temporal probabilistic forecast reconciliation): The reconciled probability measure of $\hat{\mathcal{v}}$ with respect to $\psi$ is a probability measure $\tilde{\mathcal{v}}$ on $\mathfrak{s}$ with $\sigma$-algebra $\mathcal{F}_{\mathfrak{s}}$ satisfying:
  $$\tilde{v}(\mathcal{A}) = \hat{v}(\psi^{-1}(\mathcal{A})), \hspace{1cm} \forall \mathcal{A} \in \mathcal{F}_{\mathfrak{s}} \hspace{1in} (7)$$ where
  - $\psi^{-1}(\mathcal{A}) = {x \in \mathbb{R}^{n(m + k^*)} : \psi(x) \in \mathcal{A}}$ denotes the pre-image of $\mathcal{A}$
- The map $\psi$ may be obtained as the composition $s \circ g$, as for the cross-temporal point reconciliation(6)
- **Theorem 3.1** (Cross-temporal reconciled samples): Suppose that $(\hat{\boldsymbol{x}}_1, \cdots, \hat{\boldsymbol{x}}_L)$ is a sample drawn from a (cross-temporal) incoherent probability measure $\hat{v}$. Then $(\tilde{\boldsymbol{x}}_1, \cdots, \tilde{\boldsymbol{x}}_L)$ is a sample drawn from the (cross-temporal), reconcile probability measure $\tilde{v}$ defined in (7) where $\tilde{\boldsymbol{x}}_l = \psi(\hat{\boldsymbol{x}}_l)$ and $l = 1, \cdots, L$
  - For proof, see Theorem 4.5 in Panagiotelis 2023 using Definition 3.2
- Theorem 3.1 is the cross-temporal extension of Theorem 4.5 in Panagiotelis 2023, valid for only the cross-sectional case
  - *Meaning: a sample from the reconciled distribution can be obtained by reconciling each member of a sample from the incoherent distribution*
  - Hence, we can separate the mechanism used to generate the base forecast samples from the reconciliation phase


### 3.1 Parametric framework: Gaussian reconciliation
- Possible to obtain reconciled probabilistic forecasts analytically for some parametric distributions, e.g. multivariate normal
- In cross-sectional framework, Panagiotelis 2023 show that (starting from elliptical distribution for base forecasts), the reconcile forecast distribution is also elliptical
- We extend this to cross-temporal case using results in Section 2 (Notation and Definitions)
- To obtain a reconcile forecasts with the multivariate normal distribution, begin with a base forecast distributed as $\mathcal{N}(\boldsymbol{\hat{x}}, \boldsymbol{\Omega})$ where
  - $\boldsymbol{\hat{x}}$ is the mean vector and
  - $\boldsymbol{\Omega}$ is the covariance matrix of the base forecasts
- Using standard results for the Gaussian case, the reconciled forecast distribution is given by $\mathcal{N}(\boldsymbol{\tilde{x}}, \boldsymbol{\tilde{\Omega}})$, where $$\tilde{\boldsymbol{x}} = \boldsymbol{M}\hat{\boldsymbol{x}} \textrm{  and  } \boldsymbol{\tilde{\Omega}} = \boldsymbol{M \Omega M}', \hspace{3cm} (8)$$ where $\boldsymbol{M}$ is the projection matrix defined (5)
- Note: If we assume that $\boldsymbol{\Omega} = \boldsymbol{\Omega}_{ct}$ (see the production matrices (5) and (6)), then the co-variance matrix (8) simplifies to $\boldsymbol{\~{\Omega}} = \boldsymbol{M \Omega}_{ct}$
- In the cross-temporal case, sensibly estimating the co-variance matrix $\boldsymbol{\Omega}$ can be difficult because we need to simultaneously consider both the temporal and cross-sectional structures
  - Requires estimating many parameters, which can be challenging and practice
  - Naively using one-step residuals to estimate the cross-temporal correlation structure can lead to inappropriate estimates of the covariance matrix
- Computationally, we can reduce the time needed to obtain simulations from the reconciled forecast distribution:
  - When dealing with a genuine hierarchical structure, we can utilize properties of elliptical distributions to simulate from high frequency bottom time series, then obtain the complete simulation through the $\boldsymbol{S}_{ct}$ matrix
    - Instead of serializing from a normal distribution with a defined coherence matrix for the entire structure
  - If we already have a sample from the normal distribution of the base forecasts, we may simply apply point forecast reconciliation (5) as outlined in Theorem M3.1
    - Instead of calculating the reconciled mean and variance and generating a new sample

<fieldset>

**Figure 5**: Overview of Cross-temporal forecast reconciliation in the Gaussian framework: Two different but equivalent ways of obtaining reconcile forecast samples, as described in Section 3.1 with acronyms:
1. From the base distribution through Theorem 3.1
2. From the reconciled distribution through the high frequency bottom time series forecasts $\tilde{\boldsymbol{b}}^{[1]}$ only

- The two rectangles represent the base and reconciled forecast distributions
- The circles contain the distribution parameters involved in the point forecast reconciliation process, transforming $\hat{\boldsymbol{x}}$ into $\tilde{\boldsymbol{x}}$ and ${\boldsymbol{\Omega}}$ into $\tilde{\boldsymbol{\Omega}}$
- The wave - like arrows represent the simulation process, generating both base and reconciled forecast samples
- The bold double arrow illustrates the generation of the reconciled forecast distributions as demonstrated in Theorem 3.1
- RF and BF stand for Reconciled and Base Forecasts
- HF-BTS Stands for High Frequency Bottom Time Series

![](./ct-prob_fig5.png)


</fieldset>  ,


### 3.2 Non-Parametric Framework: Bootstrap Reconciliation
- Analytical expressions for the base and reconcile forecast distributions are sometimes challenging to obtain
- Parametric assumptions may also be restrictive and unrealistic
- Propose *cross-temporal joint (block) bootstrap* (**ctjb**) procedure to generate samples from base forecast distributions that preserve cross-temporal relationships
  - Approach draws samples of all series simultaneously from most temporarily aggregated level and uses most temporarily abrogated levels to determine corresponding time indices for other levels
- Let $\hat{\boldsymbol{E}}^{[k]}$ be the $(n \times N_k)$ matrix of the residuals for $k \in \mathcal{K}$
- Figure 6 visualizes these matrices and how they relate to e/o for the example in Figure 1

<fieldset>

**Figure 6**: Example of bootstrapped residuals for 3 linearly constrained quarterly time series (see Figure 1, a temporal hierarchy for a quarterly series M = 4, k = {4, 2, 1}).
1. Left: Residual matrices with 4 years of data ($N = 4$) color coded as: (1) green, (2) blue, (3) red, (4) black
2. Right: Bootstrapped residuals


![](./ct-prob_fig6.png)

</fieldset>  ,

- Let $\mathcal{M}_i$ be the model used to calculate the base forecasts and residuals for the $i^{th}$ series
- Assuming $H = 1$, $\tau$ is a random draw with replacement from $1, \cdots, N$ and the $l^{th}$ bootstrap incoherent sample is $\hat{\boldsymbol{x}}_{i,l}^{[k]} = f_i(\mathcal{M}_i,\hat{\boldsymbol{e}}_i^{[k]})$, where $f_i(\cdot)$ depends on the fitted model $\mathcal{M}_i$
- That is, $\hat{\boldsymbol{x}}_{i,l}^{[k]}$ is a sample path simulated for the $i^{th}$ series with ever approximated by the corresponding block bootstrapped sample residual $\hat{\boldsymbol{e}}_i^{k}$, the $i^{th}$ row of $$\hat{\boldsymbol{E}}_{\tau}^{[k]} = \begin{bmatrix} \hat{e}_{1, M_k(\tau-1)+1}^{[k]} & \cdots & \hat{e}_{1, M_k\tau}^{[k]} \\ \vdots & \ddots & \vdots \\ \hat{e}_{n, M_k(\tau-1)+1}^{[k]} & \cdots & \hat{e}_{1, M_k\tau}^{[k]} \end{bmatrix} \hspace{1cm} k \in \mathcal{K}$$
- Main advantage of cross-temporal joint bootstrap
  1. Can accurately account for dependents between different temper aggregation levels, not only cross-sectional dependencies
    - sampling residuals from most temporarily aggregated level plus using it to determine indices for other levels ensures bootstrap sample reflects underlying data distribution
  2. Practical and efficient since it's easy to implement for many forecasting models
  3. Easily scalable to utilize multiple computing power simultaneously for individual series
    - Especially useful for large datasets or speeding up analysis process


## 4 Cross-Temporal co-variance matrix estimation
- Natural estimate of unknown (in practice) co-variance matrix $\boldsymbol{\Omega}$ is empirical sample co-variance matrix of base forecasts $\boldsymbol{\hat{\Omega}}$ 
- This section focuses exclusively on cross-temporal framework, meaning we have to estimate $r = n(k^*+m)[n(k^*+m)-1]/2$ different parameters
- Possible solution to estimating many parameters from fewer observations and $r$ is to construct shrinkage estimator using a *convex combination* of $\boldsymbol{\hat{\Omega}}$ and a diagonal target matrix $\boldsymbol{\hat{\Omega}}_d = \boldsymbol{\hat{\Omega}} \odot \boldsymbol{I}_{n(k^*+m)}$ such that
  - $\boldsymbol{\hat{\Omega}}_G = \lambda \boldsymbol{\hat{\Omega}}_D + (1 - \lambda) \boldsymbol{\hat{\Omega}}$ where $\lambda \in [0, 1]$ is the shrinkage intensity parameter that can be estimated using the unbiased estimate are proposed by Lodoit & Wolf 2004
  - *convex combination*: a linear combo of points (vectors, scalars, or points in an affine space) where all coefficients are non- and sum to one, i.e. a standard weighted average but the weights are expressed as a percentage of the total weight instead of a fraction of the count of weights ([Wikipedia](https://en.wikipedia.org/wiki/Convex_combination))
- Linear combo involving these 2 matrices referred to as *Global shrinkage* ($G$), where all off-diagonal elements are shrunk towards zero
- $\hat{\boldsymbol{\Omega}}_G$ corresponds to the matrix used by the reconciliation approach $\textrm{oct}(shr)$
- To avoid information loss re cross-sectional and/or temporal structure from shrinking off-diagonal elements to zero, propose estimation of smaller matrix and use of cross-sectional and/or temporal structure for better estimator of entire system's co-variance matrix
- Given that $\boldsymbol{S}_{ct} = \boldsymbol{S}_{cs} \otimes \boldsymbol{S}_{te}$, we can express the actual covariance matrix in terms of three smaller matrices such that 
  $$\boldsymbol{\tilde{\Omega}} = \boldsymbol{S}_{ct} \boldsymbol{\Omega}_{hf-bts} \boldsymbol{S}_{ct}'$$
  $$\hspace{1cm} = (\boldsymbol{I}_n \otimes \boldsymbol{S}_{te}) \boldsymbol{\Omega}_{hf} (\boldsymbol{I}_n \otimes \boldsymbol{S}_{te})'$$
  $$\hspace{1cm} = (\boldsymbol{S}_{cs} \otimes \boldsymbol{I}_{m+k^*}) \boldsymbol{\Omega}_{bts} (\boldsymbol{S}_{cs} \otimes \boldsymbol{I}_{m+k^*})'$$
-where 
  - $\boldsymbol{\Omega}_{hf-bts}$ is the $(n_b m \times n _b m)$ covariance matrix for the bottom time series at temporal aggregation level $k = 1$ (highest frequency)
  - $\boldsymbol{\Omega}_{hf}$ is the $(nm \times n m)$ covariance matrix related to all high frequency time series time series
  - $\boldsymbol{\Omega}_{bts}$ is the $[n_b(k^*+m) \times n _b(k^*+m)]$ covariance matrix related to bottom time series at any temporal aggregation
- Equation (9) offers three de-compositions of the covariance matrix $\boldsymbol{\tilde{\Omega}}$, each characterized by well-defined structures
  - $\boldsymbol{S}_{ct}$ captures cross-temporal
  - $\boldsymbol{I}_n \otimes \boldsymbol{S}_{te}$ captures temporal
  - $\boldsymbol{S}_{cs} \otimes \boldsymbol{I}_{m+k^*}$ captures cross-sectional
- At the same time, each decomposition involves smaller co-variance matrices as $\boldsymbol{\Omega}_{hf-bts}, \boldsymbol{\Omega}_{hf}, \boldsymbol{\Omega}_{bts}$
- We propose three different approaches (HB, H, B) to approximate $\tilde{\boldsymbol{\Omega}}$
  - Apply "Stein-type shrinkage" by using corresponding empirical base forecasts residuals estimation and obtain the following expressions (details in Online Appendix B)
  1. *High frequency bottom time series shrinkage matrix (HB)*: $\hat{\boldsymbol{\Omega}}_{HB} = \lambda \boldsymbol{S}_{ct} \hat{\boldsymbol{\Omega}}_{hf-bts,D} \boldsymbol{S}_{ct}' + (1 - lambda) \boldsymbol{S}_{ct} \hat{\boldsymbol{\Omega}}_{hf-bts,D} \boldsymbol{S}_{ct}'$;
  2. *High frequency shrinkage matrix (H)*: $\hat{\boldsymbol{\Omega}}_{H} = \lambda (\boldsymbol{I}_{n} \otimes \boldsymbol{S}_{te}) \hat{\boldsymbol{\Omega}}_{hf,D} (\boldsymbol{I}_{n} \otimes \boldsymbol{S}_{te})' + (1 - lambda) (\boldsymbol{I}_{n} \otimes \boldsymbol{S}_{te}) \hat{\boldsymbol{\Omega}}_{hf,D} (\boldsymbol{I}_{n} \otimes \boldsymbol{S}_{te})'$;
  3. *Bottom time series shrinkage matrix (B)*: $\hat{\boldsymbol{\Omega}}_{B} = \lambda (\boldsymbol{S}_{cs} \otimes \boldsymbol{I}_{m+k^*}) \hat{\boldsymbol{\Omega}}_{bts,D} (\boldsymbol{S}_{cs} \otimes \boldsymbol{I}_{m+k^*})' + (1 - lambda) (\boldsymbol{S}_{cs} \otimes \boldsymbol{I}_{m+k^*}) \hat{\boldsymbol{\Omega}}_{bts,D} (\boldsymbol{S}_{cs} \otimes \boldsymbol{I}_{m+k^*})'$;
where $\hat{\boldsymbol{\Omega}}_{I,D} = \boldsymbol{I}_{n_b m} \odot \hat{\boldsymbol{\Omega}}_{j,l} = \{hf-bts, hf, bts\}$ and $\lambda$ is the shrinkage parameter

These matrices are not full rank (inverses don't exist, though we need them to compute production to the coherent subspace). This is addressed using a ridge regularization of the form $\hat{\boldsymbol{\Omega}} + \omega \boldsymbol{I}$, where $\omega$ is chosen to make the matrix in vertical without introducing excessive bias

![](./ct-prob_fig7.png)
**Figure 7:** Representation of four types of co-variance matrices that may be obtained from the cross-temporal hierarchical structure (based on Figure 1 example) for two different values of $\lambda \in \{0, 1\}$, the shrinkage parameter. The entries in black are not modified by shrinkage, the entries in light blue are those actively involved in the shrinkage phase, while the entries in darker blue are derived directly from the cross-sectional and/or temporal strucNture and hence not estimated. Additionally, for $\lambda=1$, the white entries correspond to a zero value.

*Table *1:** Number of different parameters that must be estimated for the Australian GDP (see Section 5) and Tourism Demand (see Section 6) forecasting experiments. Percentage reductions in number parameter is compared to the global approach G are reported parentheses

Method | # of different parameters | GDP | Tourism
:-----:|:-----------------------:|:----:|:--------:
G | $r = \frac{n(k^*+m)[n(k^*+m)-1]}{2}$ | 221,445 | 108,052,350
B | $r_{HB} < \frac{n_b (k^*+m)[n_b (k^*+m)-1]}{2} < r$ | 94,395 (57%)| 36,231,328 (66%)
H | $r_{HB} < \frac{nm[nm-1]}{2} < r$ | 72,390 (67%) | 19,848,150 (82%)
HB | $r_{HB} = \frac{n_b m[n_b m-1]}{2} < r$ | 30,876 (86%) | 6,655,776 (94%)

Number of parameters needed to be estimated: $G > B > H > HB$

Using HB covariance matrix assumes base error covariance matrix is coherent (valid if base forecasts are approximately coherent, which is expected for any reasonable set of forecasts)

**Theorem 4.1**   Let $\hat{\boldsymbol{\Omega}}_{hf-bts}$ be a $(n_b m \times n _b m)$ positive definite matrix. Then, using $\boldsymbol{\Omega}_{ct} = \boldsymbol{S}_{ct} \hat{\boldsymbol{\Omega}}_{hf-bts} \boldsymbol{S}_{ct}'$ in the reconciliation formulae (5) and (6) is equivalent to using $\boldsymbol{\Omega}_{ct} = \boldsymbol{I}_{n(m + k^*)}$ (ols approach)

$$\tilde{\boldsymbol{x}}_h = \psi(\hat{\boldsymbol{x}}_h) = \boldsymbol{M}\hat{\boldsymbol{x}}_h \hspace{1cm} \equiv \hspace{1cm}  (s \circ g)(\hat{\boldsymbol{x}}_h) = \boldsymbol{S}_{ct}\boldsymbol{G}\hat{\boldsymbol{x}}_h$$ 

\

In following forecast experiments and simulation, we closely analyze these different constructions with dual purpose:
- Full co-variance matrix ($\lambda=0$) of base forecasts used to obtain base forecast samples of linearly concerned time series under that Gaussianity
- Shrinkage versions used as approximations of co-variance matrix for reconciliation (excluding HB, see Theorem 4.1)
- This allows better understanding of properties and abilities of each parameterization

### 4.1 Multi step residuals
- Use model residuals to estimate co-variance matrix in cross-temporal forecast reconciliation
- Time series analysis: common to use residuals corresponding to one-step ahead forecasts
- Temporal dimension of setting (cross-sectional overall?) requires residuals corresponding to different forecast horizons
- Multi-step residuals $e_{i,h,j}^{[k]} = x_{i,j+h}^{[k]} - \hat{x}_{i,j+h | j'}^{[k]}$, where $i = 1,...,n;j=1,...,N_k$ and 
  $\hat{x}_{i,j+h|t}^{[k]}$ is the *h*-step fitted value, calculated as the $h$-step-ahead forecast using data up to time $j$
  - in general these residuals will be auto-correlated except when $h = 1$
- Use matrix organisation of residuals similar to that for base forecasts (Section 2.1), following Di Fonzo & Girolimetto (2023a)
  - let $N$ be the total number of observations for the most temporarily aggregate (top-level) time series
  - The $N_k$-vectors of multi-step residuals for the temporal aggregation $k$ and series $i$, $\boldsymbol{e}_{i,h}^{[k]} = \begin{bmatrix} e_{i,h,1}^{[k]} & e_{i,h,2}^{[k]} & ... e_{i,h,N_k}^{[k]} \end{bmatrix}'$ with $h = 1,...,M_k$, can be organized in matrix form as $$
    \boldsymbol{E}_i^{[k]} = \begin{bmatrix}
      e_{i, 1, 1}^{[k]} & e_{i, 2, 2}^{[k]} & \cdots & e_{i, M_k, M_k}^{[k]} \\
      \vdots & \vdots & & \vdots \\
      e_{i, 1, N_k-M_k+1}^{[k]} & e_{i, 2, N_k-M_k+2}^{[k]} & \cdots & e_{i, M_k, N_k}^{[k]} \\
    \end{bmatrix}.$$
  - Let $\boldsymbol{E}_i = \begin{bmatrix} \boldsymbol{E}_i^{[m]} & \boldsymbol{E}_i^{[k_p-1]} & \cdots & \boldsymbol{E}_i^{[1]} \end{bmatrix}$, then the $[N \times N(m+k^*)]$ cross-temporal residual matrix is given by $\boldsymbol{E} = \begin{bmatrix} \boldsymbol{E}_1 & \boldsymbol{E}_2 & ... & \boldsymbol{E}_n \end{bmatrix}$

## 5 Forecasting Australian GDP
- Probabilistic forecast accuracy evaluated using CRPS and energy score (ES)
  - Continuous Ranked Probability Score (CRPS): Index that considers the single series and provides a marginal evaluation of the approaches
  - Energy score (ES): CRPS extension to multivariate case, evaluates it forecast accuracy for whole system
- Use relative versions of CRPS and ES, calculated as follows for a single temporal aggregation order $k$: $$\bar{\textrm{RelCRPS}}_{j,s}^{[k]} = (\Pi_{i=1}^n CRPS_{i,j,s}^{[k]} /CRPS_{i,0,0}^{[k]})^{1/n} \hspace{1cm} \textrm{ and } \hspace{1cm} \bar{\textrm{RelES}}_{j,s}^{[k]} = ES_{j,s}^{[k]} / ES_{0,0}^{[k]}$$ with reconciliation approach $j$ and base forecast simulation approach $s$
  - Reference approach ($j, s = 0$) is (unreconciled) base forecasts produced by bootstrapping
- Use relative versions of CRPS and ES for the overall accuracy indices, calculated as follows for all temporal aggregation orders: $$\bar{\textrm{RelCRPS}}_{j,s}^{[k]} = (\Pi_{i=1,\cdots,n;k \in K} CRPS_{i,j,s}^{[k]} /CRPS_{i,0,0}^{[k]})^{1/[n(k^*+m)]} \hspace{1cm} \textrm{ and } \hspace{1cm} \bar{\textrm{RelES}}_{j,s}^{[k]} = (\Pi_{k \in K} ES_{j,s}^{[k]} / ES_{0,0}^{[k]})^{1/(k^*+m)}$$ with reconciliation approach $j$ and base forecast simulation approach $s$


## 7 Conclusion
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