---
title: "A Toy Algebra of Commands"
author: ["Ada Example", "Ben Placeholder"]
date: "2026"
---

# Abstract

This is a made-up paper written for testing. It shows how the pdf2epub skill
transcribes maths-heavy text: a small algebra of commands with sequential,
parallel and separating composition, ordered by refinement $\sqsubseteq$. None of
its results are new, and some are deliberately trivial.

# 1 Introduction

We write $p; q$ for sequential composition, $C_1 \| C_2$ for parallel composition
and $p \ast q$ for separating composition. The command $\mathsf{skip}$ does
nothing, and $\mathtt{abort}$ is the worst command, written $\bot$. The best
command, $\top$, is miraculous.[^1]

Commands are ordered by refinement: $p \sqsubseteq q$ means that $q$ is at least as
good as $p$, and $q \sqsupseteq p$ says the same. Joins and meets are written
$p \sqcup q$ and $p \sqcap q$, with big versions $\bigsqcup_{i \in \mathbb{N}} p_i$
and $\bigsqcap_{i \in \mathbb{N}} p_i$.

[^1]: The terms "worst" and "best" follow the refinement order, not any notion of
    usefulness.

# 2 States

A state is a finite partial function $h : \mathbb{N} \rightharpoonup_f \mathbb{N}$.
The empty state is $\mathit{emp}$, with $\mathit{dom}(\mathit{emp}) = \emptyset$, and
$h[n \mapsto l]$ updates $h$ at $n$. Two states are compatible, $h_0 \# h_1$, when
their domains are disjoint; then $h_0 \bullet h_1$ is their union.

**Definition 2.1.** For a set $S$ of states, let
$\mathit{Traces}(S) = \bigcup \{ \mathit{dom}(h) \mid h \in S \}$. We say $S$ is
*closed* if $S \subseteq T$ and $T \supseteq S$ imply nothing new, and *open*
if $S \nsubseteq \mathit{Traces}(S)$.

## 2.1 Fixed points

The loop $\mathsf{while}\ b\ \mathsf{do}\ c$ is the least fixed point
$\mu X.\, (b; c; X) \sqcup \neg b$. Its unfolding gives the equation

$$
\mu X.\, F(X) = F(\mu X.\, F(X)) \tag{1}
$$

and every finite approximation lies below it.

**Lemma 2.2.** If $F$ is monotone, then (1) holds and
$\mu X.\, F(X) \sqsubseteq Y$ whenever $F(Y) \sqsubseteq Y$.

*Proof.* This is the Knaster–Tarski theorem applied to the lattice of commands. ∎

# 3 Laws

The context $(-) \ast \mathsf{skip}$ leaves a command unchanged. The main laws are
collected below.

$$
\begin{aligned}
p \ast (q \ast r) &= (p \ast q) \ast r \\
p \ast q &= q \ast p \\
(p \ast q); (p' \ast q') &\sqsubseteq (p; p') \ast (q; q')
\end{aligned}
\tag{2}
$$

$$
\begin{array}{rc}
\text{(unit)} & p \ast \mathsf{skip} = p \\
\text{(zero)} & p \ast \bot = \bot
\end{array}
$$

| Law | Statement | Also for parallel? |
|---|---|---|
| associativity | $p \ast (q \ast r) = (p \ast q) \ast r$ | yes |
| commutativity | $p \ast q = q \ast p$ | yes |
| exchange | $(p \ast q); (p' \ast q') \sqsubseteq (p; p') \ast (q; q')$ | no |

# 4 Triples

A Hoare triple $\{p\}\, c\, \{q\}$ holds if $p; c \sqsubseteq q$, and a Plotkin
triple $p \to_c q$ holds if $q \sqsupseteq p; c$. We write
$\langle\langle X \rangle\rangle$ for the Dijkstra triple of $X$.

**Theorem 4.1.** $\{p\}\, c\, \{q\} \Leftrightarrow p \to_c q$, and
$\vdash \{p\}\, c\, \{q\} \Rightarrow \{p \ast r\}\, c\, \{q \ast r\}$.

*Proof.* Both sides unfold to the same inequality. The frame rule is

$$
\frac{\{p\}\, c\, \{q\} \qquad \mathit{dom}(r) \cap \mathit{dom}(c) = \emptyset}
     {\{p \ast r\}\, c\, \{q \ast r\}}
$$

and it follows from the exchange law (2), since
$\text{if } r \text{ is stable then } r \Longrightarrow r$. ∎

# References

[1] A. Example. *Notes on imaginary algebras*. Unpublished, 2026.

[2] B. Placeholder. *Further notes on imaginary algebras*. Unpublished, 2026.
