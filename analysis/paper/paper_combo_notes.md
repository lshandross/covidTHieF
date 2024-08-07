
<fieldset>  

**Figure 1:** (a) A simple 2-level cross-sectional hierarchy for 3 time series with $n_a = 1$ and $n_b = 2$   
$\hspace{1.1cm}$ (b) A temporal hierarchy for a quarterly series ($m = 4$ and $k = \{4, 2, 1\}$)  
$\hspace{7.9cm} x_{i,\tau}^{[4]}$  
$\hspace{1.5cm} y_{T, t} \hspace{4.3cm} x_{i, 2\tau-1}^{[2]} \hspace{2cm} x_{i, 2\tau}^{[2]}$  
$\hspace{0.75cm} y_{X, t} \hspace{0.75cm} y_{Y, t} \hspace{3.0cm} y_{i, 4\tau-3} \hspace{0.5cm} y_{i, 4\tau-2} \hspace{0.65cm} y_{i, 4\tau-1} \hspace{0.5cm} y_{i, 4\tau}$  
$\hspace{1.4cm} \boldsymbol{(a)} \hspace{6cm} \boldsymbol{(b)}$  
</fieldset>  ,

<fieldset>  

**Example:** Figure 1(a)
- Two-level hierarchical structure for 3 linearly constrained time series: $y_{T, t} = y_{X, t} + y_{Y, t}$ for all $t = 1, ..., T$
$$ \boldsymbol{y}_t = \begin{bmatrix} \boldsymbol{u}_t \\ \boldsymbol{b}_t \end{bmatrix} = \begin{bmatrix} y_{1,t} \\ y_{2,t} \\ y_{3,t} \end{bmatrix}, \hspace{1cm} \textrm{ where } \boldsymbol{u}_t = \begin{bmatrix} y_{1,t} \end{bmatrix}, \boldsymbol{b}_{t} = \begin{bmatrix} y_{2,t} \\ y_{3,t} \end{bmatrix} \textrm{and } n = n_a + n_b = 1 + 2 = 3$$ 
- We also have: $$\boldsymbol{A}_{cs} = \begin{bmatrix} 1 & 1 \end{bmatrix}, \hspace{1cm} \boldsymbol{I}_{n_a} = \begin{bmatrix} 1 \end{bmatrix}, \hspace{1cm} \boldsymbol{I}_{n_b} = \begin{bmatrix} 1 & 0 \\ 0 & 1 \end{bmatrix}, \hspace{1cm}$$ which give us the results 
  $$\boldsymbol{u}_{t} = \boldsymbol{A}_{cs}\boldsymbol{b}_{t}: y_{1,t} = \begin{bmatrix} 1 & 1 \end{bmatrix} \begin{bmatrix} y_{2,t} \\ y_{3,t} \end{bmatrix} = y_{2,t} + y_{3,t},$$
  $$\boldsymbol{C}_{cs} = \begin{bmatrix} \boldsymbol{I}_{n_a}\boldsymbol{A}_{cs} \end{bmatrix} = \begin{bmatrix} 1 & -1 & -1 \end{bmatrix}, \hspace{1cm} \boldsymbol{S}_{cs} = \begin{bmatrix} \boldsymbol{A}_{cs} \\ \boldsymbol{I}_{n_b} \end{bmatrix} = \begin{bmatrix} 1 & 1 \\ 1 & 0 \\ 0 & 1 \end{bmatrix},$$
  $$\boldsymbol{y}_{t} = \boldsymbol{S}_{cs}\boldsymbol{b}_{t}: \begin{bmatrix} y_{1,t} \\ y_{2,t} \\ y_{3,t} \end{bmatrix} = \begin{bmatrix} 1 & 1 \\ 1 & 0 \\ 0 & 1\end{bmatrix} \begin{bmatrix} y_{2,t} \\ y_{3,t} \end{bmatrix} = \begin{bmatrix} y_{2,t} + y_{3,t} \\ y_{2,t} \\ y_{3,t} \end{bmatrix} = \begin{bmatrix} \boldsymbol{u}_t \\ \boldsymbol{b}_t \end{bmatrix}$$
</fieldset>  ,

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

$$ \begin{bmatrix} 0 & 0 & 0 & 1 & 0 & 0 & 0 & 0 & 0 & 0 & -1 & 0 & 0 & 0 & 0 & 0 & 0 & -1 & 0 & 0 & 0  \\ 0 & 0 & 0 & 0 & 1 & 0 & 0 & 0 & 0 & 0 & 0 & -1 & 0 & 0 & 0 & 0 & 0 & 0 & -1 & 0 & 0 \\ 0 & 0 & 0 & 0 & 0 & 1 & 0 & 0 & 0 & 0 & 0 & 0 & -1 & 0 & 0 & 0 & 0 & 0 & 0 & -1 & 0 \\ 0 & 0 & 0 & 0 & 0 & 0 & 1 & 0 & 0 & 0 & 0 & 0 & 0 & -1 & 0 & 0 & 0 & 0 & 0 & 0 & -1 \\ 1 & 0 & 0 & -1 & -1 & -1 & -1 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0  \\ 0 & 1 & 0 & 0 & -1 & -1 & -1 & -1 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 \\ 0 & 0  & 1 & 0 & 0 & -1 & -1 & -1 & -1 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 \end{bmatrix}$$