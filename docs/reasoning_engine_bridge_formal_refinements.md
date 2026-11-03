# Reasoning Engine Bridge — Formal Refinements (Sections 10–19)

Companion addendum to [`reasoning_engine_bridge.md`](reasoning_engine_bridge.md). The foundational manuscript is retained unchanged; this addendum specifies contracts and correctness conditions for its proposed computational interface.

These refinements define an interface and verification targets. They do not assert that a particular reasoning engine, DNA model, or search implementation already satisfies them.

## 10. Formal measurement contracts

A measurement used by the bridge is not merely a function returning a number. Its contract records:

- its domain of valid states and its provenance;
- that its value is finite and strictly positive on that domain;
- its physical dimension and unit (or that it is dimensionless);
- its boundary/reference value, when one is used, in the same dimension and unit;
- its precision and comparison policy, including any tolerance used by an implementation;
- whether it is directly measured, derived, estimated, or model-dependent.

Let `U_i` be a positive reference quantity with the same dimension as `m_i`. A dimensionally meaningful logarithmic coordinate is

\[
q_i(s)=\ln\!\left(\frac{m_i(s)}{U_i}\right).
\]

Likewise, a boundary-relative position is

\[
P_{B_i}(s)=\ln\!\left(\frac{m_i(s)}{B_i}\right),
\]

where `B_i` has the same dimension as `m_i`. The logarithm's argument is therefore dimensionless. Comparing two measurements by a ratio requires compatible dimensions and units, or an explicitly defined conversion/reference mapping. A raw length cannot be compared as a ratio to a raw time.

A contract rejects zero, negative, NaN, and infinite measurements. If an underlying property can be zero or negative, the model must define a suitable positive derived measurement and document what information that mapping preserves or loses. Implementations should state whether boundary equality is exact or tolerance-based; a tolerance is a computational policy, not a change to the mathematical definition.

Multiplication is permitted only with a declared composition rule. For dimensional quantities, dimensions compose as well: for example, length times length has area dimension. The result is not silently treated as a length.

## 11. Boundary and frame invariance

A change of logarithmic reference frame can be represented by a common additive shift of coordinates. If

\[
q_i'=q_i+c
\quad\text{and}\quad
\ln(B_i'/U_i)=\ln(B_i/U_i)+c,
\]

then the boundary-relative position is unchanged:

\[
P_{B_i}'(s)=q_i'-\ln(B_i'/U_i)=P_{B_i}(s).
\]

This is a coordinated change of representation/reference, not a physical or modeled change to the measured quantity.

If the measurement changes while the boundary remains fixed, then in general `P_{B_i}` changes. For example, scaling a measured value by `a > 0` with a fixed boundary changes the position by `ln(a)`. Scaling both the measured value and its boundary by the same factor preserves their ratio. A system must declare which operation an action represents; it must not label a measurement change as a frame change merely because both can appear as coordinate shifts.

Relations `q_i-q_j` are invariant under a common shift when the coordinates have compatible reference conventions. Pairwise order is also preserved by a common shift. Independent shifts of different features do not generally preserve these relations or order.

## 12. Task-relative state equivalence

Equivalence is relative to a task `τ`, not a claim that two full computational states are identical. Write `s ~_τ t` only if all of the following task-required conditions hold:

1. The selected measurements, relevant boundary classifications, and required FNF relations agree under the declared comparison policy.
2. Goal evaluation agrees: `Goal_τ(s) = Goal_τ(t)`.
3. The same task-relevant actions are admissible from both states.
4. Corresponding action outcomes remain equivalent: for each relevant action `a`, if `s --a--> s'` and `t --a--> t'`, then `s' ~_τ t'` (or the declared transition correspondence holds for nondeterministic actions).
5. Any costs, rewards, resource effects, or terminal observations used by the task agree, when applicable.

Conditions 2–4 make equivalence a task-relative transition congruence (or bisimulation for the relevant labeled transitions); matching current measurements alone is insufficient. Search may merge equivalent states only when its duplicate-detection key preserves these conditions. For optimal-cost search, cost preservation is additionally required. If the engine cannot establish future-transition compatibility, it may use measurement similarity as a heuristic, but not as a proof that states can safely be merged.

## 13. Decomposition and reconstruction

A decomposition record must retain enough provenance to identify what was decomposed and how. At minimum, record:

- the parent object or total and its identity;
- the ordered or canonically identified components, including multiplicity;
- the composition operation and its domain/dimensional rules;
- any units, conversion factors, normalization, or rounding;
- the reconstruction rule and the equality/tolerance policy;
- the source state and transformation/history needed to reproduce the record.

For a declared multiplicative decomposition `T = c_1 ⋯ c_n` over positive compatible quantities,

\[
\ln(T/U_T)=\sum_i\ln(c_i/U_i)+\ln(K),
\]

where the reference units and any conversion factor `K` must be chosen so the product and sum are dimensionally consistent. When the components are dimensionless under a common convention, this reduces to the usual `q(T)=Σq(c_i)`.

The logarithmic sum alone is not a reconstruction certificate: many factorizations can yield the same total. Reconstruction requires the retained component identities and declared composition rule, followed by verification that recomposition reproduces the parent under the contract's equality policy. Any lossy decomposition must be labeled as such.

## 14. Transition admissibility theorem (REB-1)

Let `S` be a state space, `A` an action set, and `Inv(s)` a predicate representing all required structural, representability, measurement, and FNF invariants. Let `A_ok(s,a,s')` be the declared admissibility predicate for a transition. Assume:

1. The initial state `s₀` is representable and satisfies `Inv(s₀)`.
2. Every accepted transition from an invariant-satisfying state produces a representable successor and preserves the invariants: if `Inv(s)` and `A_ok(s,a,s')`, then `Inv(s')`.
3. The implementation accepts only transitions satisfying `A_ok` (including declared transformation and boundary rules).

Then every state reachable from `s₀` by a finite sequence of accepted transitions satisfies `Inv`.

**Proof.** Induct on path length. The length-zero path ends at `s₀`, which satisfies `Inv` by assumption. If every accepted path of length `n` ends in an invariant-satisfying state `s`, then any accepted next transition satisfies `A_ok`; assumption 2 implies its successor satisfies `Inv`. Thus the result holds for length `n+1`, and therefore for every finite path. `□`

This is a safety guarantee conditional on the assumptions and implementation conformance. It does not show that a goal is reachable, that a search terminates, or that the implementation has correctly encoded the predicates.

## 15. Search correctness, completeness, and optimality

The bridge and the search algorithm make different claims:

- **State validity:** a state is representable and satisfies its state invariants.
- **Transition admissibility:** a transition obeys the declared preconditions, measurement contracts, and invariant rules.
- **Goal satisfaction:** a state satisfies the task's goal predicate.
- **Sound path result:** every reported path starts at the initial state, uses accepted transitions, and ends in a goal state.
- **Search completeness:** under stated assumptions, every reachable goal (or a representative in the chosen equivalence quotient) is eventually found.
- **Optimality:** the returned path has minimum declared cost among goal paths.

Soundness follows only if path construction and final goal checking enforce their definitions. Completeness depends on the state/action space and search strategy—for example, finite branching and fair exploration, plus termination or a suitable resource assumption. Optimality requires a defined cost model and algorithm-specific assumptions (such as nonnegative edge costs for standard uniform-cost search). A heuristic ordering or pruning rule is not a completeness or optimality proof unless its properties are established. The FNF constraints restrict admissible transitions; by themselves they guarantee none of these search properties.

## 16. DNA structural implementation: a bounded example

A DNA-like computational state may contain a stable structure identity, coordinates, a connectivity graph, labels, and transformation history. The bridge can project selected positive measurements—for example, a declared positive geometric scale, a positive distance for an existing edge, or a positive parameter of a specified model—without replacing the graph or its identity.

An implementation should define these details explicitly:

- coordinate system and units, and which pairs of points a distance measurement uses;
- the domain on which each measurement is defined (for example, an edge length only when that edge exists);
- graph-edit actions, their preconditions, and how identity and history are updated;
- the invariants and task-specific goal predicate;
- whether model parameters are empirical, simulated, or illustrative.

Deleting a graph edge is a computational graph operation. It is not, without a validated physical model and suitable evidence, a prediction that a chemical bond will cleave. Likewise, a positive energy-like parameter is not automatically a physical energy measurement; its meaning and units must be specified. This example defines an interface test case, not a molecular simulation or chemistry claim.

## 17. Boundary–Horizon–Finitude integration

The bridge may interoperate with Boundary–Horizon–Finitude (BHF) through an explicit adapter that names the shared objects and rules. For example, a BHF bounded domain or horizon may be represented as a task constraint, a state predicate, or a termination condition. The adapter must state which interpretation is used and how it maps to the engine's states and transitions.

No mathematical equivalence follows merely from sharing terms such as boundary, horizon, or finitude. A BHF-specific property is enforced by the bridge only after it has a formal definition over the relevant state/action model and is included in `Inv` or `A_ok`.

## 18. Infinity-Algorithms integration

An Infinity-Algorithms component may supply a generative process, a representation scheme, or a declared completion/termination rule. Its adapter to the reasoning engine must specify the generated objects, finite-step transition semantics, representation bounds, and the exact condition under which a computation is considered complete or terminated.

The bridge can check finite represented states and finite transition prefixes against declared contracts. It does not convert an unbounded process into a finite one, establish termination, or settle an infinite construction merely by applying logarithmic measurements. Those claims require separate definitions and proofs. Interoperability is an interface relationship, not an assertion that the frameworks are mathematically equivalent.

## 19. Reference checks and test plan

The following small reference checks illustrate the contract boundaries; they are not a production engine. A production implementation should use a quantity/unit library where dimensional units are material and should validate all contract metadata.

```python
import math


def boundary_position(measurement: float, boundary: float) -> float:
    """Log ratio for positive finite values in the same unit."""
    if not (math.isfinite(measurement) and measurement > 0):
        raise ValueError("measurement must be finite and strictly positive")
    if not (math.isfinite(boundary) and boundary > 0):
        raise ValueError("boundary must be finite and strictly positive")
    return math.log(measurement / boundary)


def admissible_transition(state, action, transition, invariant):
    """Accept only representable successors satisfying the declared invariant."""
    successor = transition(state, action)
    return successor if successor is not None and invariant(successor) else None
```

Minimum test cases:

1. **Boundary classification:** `m < B` gives a negative position, `m == B` gives zero, and `m > B` gives a positive position (subject to the documented floating-point comparison policy).
2. **Frame invariance:** adding the same constant to the coordinate and log-boundary leaves their difference unchanged; changing only the measurement changes its position against a fixed boundary.
3. **Input contract:** zero, negative, NaN, and infinite inputs are rejected.
4. **Units:** incompatible dimensions cannot be combined into a ratio without a declared conversion or normalization.
5. **Composition/decomposition:** recorded components and the specified composition rule recompose to the original total; a mismatched component or rule is detected.
6. **Equivalence safety:** states with equal measured features but different goal outcomes or relevant action successors are not merged.
7. **Invariant induction:** every state returned by finite accepted transition sequences satisfies the invariant; rejected successors are not enqueued.
8. **Search distinction:** separately test path soundness, completeness on a small exhaustively enumerable model, and optimality against a known-cost example. Passing one test does not imply the others.
9. **DNA graph example:** graph edits preserve the declared identity/history policy and structural invariants, without interpreting an edge deletion as a physical cleavage claim.

For reproducibility, tests should specify the unit convention, numeric tolerance, transition/action model, and the exact invariant and goal predicates being tested.

---

**Status:** This addendum formalizes the proposed bridge refinements. The theorem is conditional on its stated premises; implementation verification and empirical validation remain separate work.
