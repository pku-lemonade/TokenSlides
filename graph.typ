#import "lemonade.typ": *
#import "@preview/numbly:0.1.0": numbly

#show: lemonade-theme.with(
    aspect-ratio: "16-9",
    box-compact: true,
    title: [Introduction to Algebraic Graph Theory],
    short-title: [Intro to Algebraic Graph Theory],
    subtitle: [Discrete Mathematics],
    author: [Youwei Zhuo],
    date: [Nov 11, 2025],
    institution: [Peking University],
    email: "youwei@pku.edu.cn",
    github: "pku-lemonade",
)

#set heading(numbering: numbly("{1}.", default: "1.1"))

#title-slide()

#outline-slide()

= Graph Cuts

== Finding a Community in a Graph

Real-world networks are often modeled as graphs $G = (V, E, W)$, where $V$ is the set of nodes and $W$ contains affinity weights.


We need to identify *coherent groups* or *communities*:
- *Social networks*: Friend groups, professional communities
- *The Web*: Related pages, topic clusters
- *Biological networks*: Protein complexes, gene modules
- *Infrastructure*: Communication networks, power grids

== Defining a 'Good' Community

#v(1em)

#tbox(weight: "bold", alignment: center)[
    What makes a community "good"?
]

#vboxs(
    sbox[
        - Strong internal connections
        - Many edges within $S$
        - High density
    ],
    ebox[
        - Weak external connections
        - Few edges leaving $S$
        - Low boundary size
    ],
    gap: 20pt,
    fill-height: false,
)

#tbox(weight: "bold", alignment: center)[
    How do we formalize this mathematically?
]

== Defining a Cut in a Graph

A *cut* separates a subset $S subset V$ from the rest $overline(S) = V without S$.

#hbox[
    *Cut Size:*

    $ "cut"(S, overline(S)) = sum_(u in S, v in.not S) w_(u,v) $

    where $w_(u,v)$ represents the affinity weight between nodes $u$ and $v$.
]
This measures the total weight of edges crossing the boundary between $S$ and $overline(S)$.

== Minimum Cut

Minimize the raw size of the cut.

#hbox([
    *Max Flow-Min Cut Theorem:* \
    The maximum $s$-$t$ flow value equals the minimum $s$-$t$ cut capacity.
])

#nbox([
    *Computational Complexity:*
    - Focus: Finding the bottleneck capacity
    - Approximation algorithms can achieve $O(n^(3\/2))$ for sparse graphs

])

#ibox[
    *Question*: Is this the right objective for community detection?
]

== Limitation of Min-Cut

#nbox[
    *Problem Scenario:*
    - Community A: Very large, sparsely connected (10,000 nodes)
    - Community B: A path (10 nodes)
    - Connection: Single weak link between them

    The global minimum cut might cut the link at any edge, even though Community A itself may not be cohesive *relative to its size*.
]

#ebox[
    *Critical Issue:* Raw cut size does NOT capture *coherence*!
]

= Graph Conductances

== Need for Normalization

We need to normalize the external connection relative to the cluster's *internal size* or *volume*.

#hbox([
    *Volume of a set S:* Sum of degrees of nodes within $S$.

    $ "vol"(S) = sum_(u in S) "deg" (u) = sum_(u in S) sum_(v in V) w_(u,v) $

    Measures the total edge weight incident to nodes in $S$.
])

== Ratio/Conductance

#hbox[
    *Ratio of a cut:* Normalizes the cut by the cluster size.
    $ R(S)="ratio"(S) = frac("cut"(S, overline(S)), abs(S)abs(overline(S))) $
]

#hbox[
    *Conductance:* Normalizes the cut by the volume.
    $ phi.alt(S)="conductance"(S) = frac("cut"(S, overline(S)), min("vol"(S), "vol"(overline(S)))) $
]

== Cut vs. Conductance

Conductance quantifies whether internal connections are *significantly richer* than external connections.

#vboxs(
    ebox[
        *Cut:*
        - Global separation
        - Minimize absolute capacity
        - Not scale-invariant
        - Raw measurements
    ],
    sbox[
        *Conductance:*
        - Internal coherence
        - Normalized measure
        - Scale-invariant (values in $[0,1]$)
        - Structural significance
    ],
    // gap: 10pt,
    fill-height: false,
)

== Min-Conductance

#sbox[
    *Key:* A group $S$ is a *good cluster* if it has *low conductance*.
]

#ibox[
    *Goal*: Find the set $S$ that minimizes conductance (best cluster) in graph $G$:
    $ phi.alt(G) = min_(S subset V) phi.alt(S) $
]

#ebox([
    *Challenge:* Finding the exact minimum conductance cut is NP-hard.
])

= Graph Laplacians

== Beyond Counting: An Algebraic Approach

How can we *approximate* the minimum conductance cut?

#sbox([*Key Idea:* Represent the graph as a matrix and analyze its properties.])

== Adjacency Matrix

#nbox[From now on, we will consider undirected and unweighted graphs. However, the conclusions will extend to directed/weighted graphs]

#nbox[
    *Adjacency Matrix ($W$):*
    $W_(i j)=1$ if edge exists, 0 otherwise.
    $
        W = mat(
            0, 1, 1, 0;
            1, 0, 1, 0;
            1, 1, 0, 1;
            0, 0, 1, 0;
        )
    $

    *Degree Matrix ($D$):* Diagonal matrix of  degrees. $D_(i i) = sum_j W_(i j)$.

    $
        D = mat(
            2, 0, 0, 0;
            0, 2, 0, 0;
            0, 0, 3, 0;
            0, 0, 0, 1;
        )
    $
]

== Laplacian Matrix

#hbox([
    *Graph Laplacian*: A matrix representing graph connectivity.

    $ L = D - W $

    where:
    - $D$ is the diagonal degree matrix
    - $W$ is the weighted adjacency matrix
])

#nbox([
    *Laplacian Matrix Example:*

    $
        L = mat(
            2, 0, 0, 0;
            0, 2, 0, 0;
            0, 0, 3, 0;
            0, 0, 0, 1;
        ) - mat(
            0, 1, 1, 0;
            1, 0, 1, 0;
            1, 1, 0, 1;
            0, 0, 1, 0;
        )
        = mat(
            2, -1, -1, 0;
            -1, 2, -1, 0;
            -1, -1, 3, -1;
            0, 0, -1, 1;
        )
    $
])

== The Laplacian Quadratic Form

#ibox[
    *Key Property (Quadratic Form):* For any vector $x in RR^n$:
    $
        x^T L x & = x^T (D - W) x = x^T D x - x^T W x \
                & = sum_((i,j) in E) (x_i^2 + x_j^2) - sum_((i,j) in E) (x_i x_j + x_j x_i) \
                & = sum_((i,j) in E) w_(i j) (x_i - x_j)^2
    $
]

#nbox[
    You can verify this example:

    $
        L = mat(
            2, -1, -1, 0;
            -1, 2, 1, 0;
            -1, -1, 3, -1;
            0, 0, -1, 1;
        ), x = vec(x_1, x_2, x_3, x_4)
    $

    $ x^T L x = (x_1 - x_2)^2 + (x_2 - x_3)^2 + (x_1 - x_3)^2 + (x_3 - x_4)^2 $

]

== Laplacian Quadratic Form and Cuts

#ibox[
    Consider indicator vector $x$ for a cut $(S, overline(S))$: $x_u = cases(+1 " if " u in S, -1 " if " u in overline(S))$

    $
        (x_u - x_v)^2 = cases(0 " if" u "and" v "both in" S "or" overline(S), 4 "if" u in S ", " v in overline(S) " or vice versa")
    $

    #pause

    $
        x^T L x & = sum_((u,v) in E) w_(u,v) (x_u - x_v)^2 \
         #pause & = sum_(u in S, v in overline(S)) w_(u,v) (1 - (-1))^2 + sum_(u in overline(S), v in S) w_(u,v) (-1 - 1)^2 \
         #pause & = sum_(u in S, v in overline(S)) 4 w_(u,v) = 4 times "cut"_W(S, overline(S))
    $
]

#v(-0.5em)
#sbox[The Laplacian quadratic form directly encodes *cut sizes*!
    <=>
    Minimizing $x^T L x$ over certain vectors $x$ is finding minimum cuts.]

== The Zero Eigenvalue and Connectivity

#hbox[
    *Zero Eigenvector*: Consider vectors $v$ such that

    $ v^T L v = sum_((u,v) in E) w_(u,v) (x_u - x_v)^2 = 0 $

    Note: You can always find at least one $v = (1, 1, ..., 1)$
]

#hbox[
    *Zero Eigenvalue*:


    The multiplicity $mu(lambda_0)$ (number of zero eigenvalues) of the laplacian $L$
    equals the number of connected components of the graph $G$.
]

== The Number of Zero Eigenvalues

Assume that $G$ has $k$ connected components.

#ibox[

    Show that $mu(lambda_0)$ is at least $k$ <=>

    #pause

    Find $k$ orthogonal eigenvectors with eigenvalue 0 <=>

    #pause

    Consider vectors where all elements are 1 in the same connected component and 0 otherwise.
]

#pause

#ibox[
    Show that $mu(lambda_0)$ is at most $k$ <=>

    #pause

    Show that no way to find $k+1$ orthogonal zero eigenvectors:

    #pause

    This $k+1$st vector must have a non-zero element.

    The sum of squares can only be zero if each term is zero.
    $ v^T L v = sum_((u,v) in E) w_(u,v) (x_u - x_v)^2 = 0 $
    => This $k+1$st vector is non-zero and constant on all indices.

]

== The Second Eigenvalue and Cut Ratio

#hbox[
    (Fiedler, 1973) proved that the second smallest non-zero eigenvalue

    $ lambda_2 = n min_(x != 0)frac(x^T L x, sum_(a<b) (x_a - x_b)^2) $
]

#ibox[
    Consider indicator vector $x$ for a cut $(S, overline(S))$: $x_u = cases(+1 " if " u in S, -1 " if " u in overline(S))$

    $ x^T L x = 4 times "cut"_W(S, overline(S)), sum_(a<b) (x_a - x_b)^2 = abs(S)abs(overline(S)) $

    $
        R(S)="ratio"(S)= frac("cut"(S, overline(S)), abs(S)abs(overline(S))) tilde frac(x^T L x, sum_(a<b) (x_a - x_b)^2) = lambda_2
    $
]

#pause

#sbox[The second smallest eigenvalue of Laplacian is the *ratio of a cut*! <=> Finding $lambda_2$ is related to finding a cut of minimum ratio.]

== The Second Eigenvalue and Conductance

#hbox[ *Normalized Laplacian*:

    $ L = D^(-1\/2) L D^(-1\/2) = I - D^(-1\/2) W D^(-1\/2) $ ]

#ibox[
    *Insight*: We normalize the Laplacian by $D^(-1\/2)$ to account for varying node degrees, connecting it to conductance rather than just ratio.
]

#pause
#hbox[
    (Cheeger, 1973) proved that the second smallest non-zero eigenvalue of a normalized Laplacian $v_2$ is bouned:

    $ phi.alt(G) <= v_2 <= phi.alt(G)^2/2 $

    where $phi.alt(G) = min_(S subset V) phi.alt(S)$
]

#sbox[The second eigenvalue of normalized Laplacian is related to the *min-conductance*! <=> Finding $v_2$ is related to finding a cut of min-conductance.]

== Key Takeaway

#vboxs(
    nbox[
        *Cut*:
        $ "cut"(S, overline(S)) $
    ],
    nbox[
        *Ratio:*
        $ R(S)= frac("cut"(S, overline(S)), abs(S)abs(overline(S))) $
    ],
    nbox[
        *Conductance*:
        $ phi.alt(S)= frac("cut"(S, overline(S)), min("vol"(S), "vol"(overline(S)))) $
    ],
    widths: (1fr, 1fr, 1.5fr),
    gap: 5pt,
    fill-height: false,
)
#pause
#sbox[The Laplacian quadratic form directly encodes *cut sizes*!
    <=>
    Minimizing $x^T L x$ over certain vectors $x$ is finding minimum cuts.]

#sbox[The second smallest eigenvalue of Laplacian is the *ratio of a cut*! <=> Finding $lambda_2$ is related to finding a cut of minimum ratio.]

#sbox[The second eigenvalue of normalized Laplacian is related to the *min-conductance*! <=> Finding $v_2$ is related to finding a cut of min-conductance.]

== Summary

1. *Conductance* measures normalized cluster quality
#pause
2. *Laplacian Matrices* reveal graph structure:
    - The quadratic form encodes cut sizes
    - Zero eigenvalues = connected components
    - Second eigenvalue = cut ratio / conductance

#pause
#v(1em)
#sbox[*Question*: How does the *eigenvectors* correspond to the cuts?]
#pause
#pbox[*Hint*: Nodes in the same partition should have similar values.]
#pause
#ebox[*Challenge*: How to *efficiently* compute these eigenvalues and eigenvectors for large graphs? ]

#thank-you-slide(
    title: [Questions?],
)
