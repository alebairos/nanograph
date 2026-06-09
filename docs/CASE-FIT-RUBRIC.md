# Case-fit rubric

A target score for candidate cases. Score a candidate before committing a goal, so selection is a number with a reason, not a vibe. The runnable form is `scripts/score-case-fit.sh`, gated by `scripts/check-case-fit-rubric.sh`. The customer this serves is [`ICP.md`](ICP.md).

## The rule

A case is a fit when four things are true at once. The "at once" is a gate, not an average. Any one factor at zero disqualifies the case, however high the others score.

The four fit factors, each scored 0, 1, or 2.

1. **Oracle hardness.** How hard the expected output is to compute independently.
   - 0. Trivial. A normal test names input and expected output cheaply. NanoGraph adds nothing.
   - 1. Some inputs are easy, some are not.
   - 2. The expected output is about as hard to compute as the function itself.
2. **Property checkable.** Whether a metamorphic relation holds without the oracle.
   - 0. No invariant. Behavior is arbitrary.
   - 1. A weak or partial relation.
   - 2. A clean self-oracling relation (round_trip, involution, idempotent, conservation).
3. **Observable.** Whether the floor can see the behavior. Today that is argv in, stdout out, plus byte integrity.
   - 0. Correctness lives in timing, analog values, concurrency, or distributed state. Out of reach.
   - 1. Observable through a thin trusted driver with effort.
   - 2. Directly observable as a pure input to output function.
4. **Silent survival.** Whether the bug is quiet and survives unit tests.
   - 0. The bug crashes or an existing test already catches it.
   - 1. Sometimes caught.
   - 2. Silent. A green test suite ships the bug. This is the value.

`fit_score` is the sum of the four, 0 to 8. It ranks among cases that pass the gate. It does not rescue a case that fails it.

## Criticality is a separate axis

Criticality is scored 0 to 2 on its own. It sets the price of a wrong answer, not the fit. A control loop in a power grid is maximally critical and still fails the gate, because its correctness is not observable through argv and stdout. Folding criticality into fit would let a high-stakes, unobservable target masquerade as a good one. It is kept separate on purpose.

`priority = fit_score * criticality`. Use it to rank among cases that already passed the gate.

## Worked examples

These ship as `fixtures/fit-cases/*.fit` and are asserted by the gate.

| Case | oracle | property | observable | silent | gate | fit | crit | priority |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| payment conservation | 2 | 2 | 2 | 2 | FIT | 8 | 2 | 16 |
| utf8 overlong | 2 | 2 | 2 | 2 | FIT | 8 | 1 | 8 |
| dna reverse-complement | 2 | 2 | 2 | 2 | FIT | 8 | 1 | 8 |
| robotics control loop | 2 | 1 | 0 | 2 | NOT-A-FIT | 6 | 2 | n/a |

Payment conservation is the bullseye, fit and most critical. The robotics control loop is the cautionary case, the most critical row and still disqualified, because `observable` is zero.

## Using it

```
scripts/score-case-fit.sh fixtures/fit-cases/payment-conservation.fit
```

Exit 0 means the gate passed, exit 1 means NOT-A-FIT, exit 2 means the scorecard is malformed, exit 3 means `parked=1` (scored for reference but excluded from the active queue). Write a `.fit` for any candidate, score it, and only commit a goal for cases that pass the gate. Rank the survivors by priority.

## Scope honesty

The score measures fit to NanoGraph's current floor, not the importance of the work. A NOT-A-FIT verdict on a critical system is a statement about the floor's reach, not the system's value. The `observable` factor is the one that moves as the runner grows new observables. When it does, re-score the parked cases.
