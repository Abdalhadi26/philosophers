# Philosophers — Study Guide

---

## The Problem

N philosophers sit at a round table. There is one fork between each pair of adjacent philosophers, so N philosophers means N forks. A philosopher cycles through three states:

1. **Thinking** — doing nothing, waiting to eat
2. **Eating** — holds both left and right fork, eats for `tt_eat` ms
3. **Sleeping** — releases forks, sleeps for `tt_sleep` ms

If a philosopher goes more than `tt_die` ms without starting a meal, they die and the simulation ends.

The challenge is purely about **concurrency** — making N threads cooperate on shared resources (forks) without:
- **Deadlock** — everyone waiting forever
- **Data races** — two threads reading/writing the same memory unsafely
- **Starvation** — a philosopher never getting to eat

---

## Data Structures

### `t_diner` — the shared table
```
n_philos          — number of philosophers and forks
tt_die/eat/sleep  — timing parameters in ms
start_time        — timestamp when simulation began (used for log offsets)
min_meals         — optional stop condition (-1 if not set)
is_dinning        — flag: 1 = running, 0 = stopped
is_dinning_lock   — mutex protecting is_dinning
print_lock        — mutex serializing all printf calls
*philos           — array of philosopher structs
*forks            — array of fork mutexes
```

### `t_philo` — one philosopher
```
id                — philosopher number (1 to N)
meals_eaten       — how many times this philosopher has eaten
last_meal_time    — timestamp of last meal start (in ms)
meals_lock        — mutex protecting meals_eaten and last_meal_time
thread            — the pthread for this philosopher
*left_fork        — pointer into forks array
*right_fork       — pointer into forks array
*diner            — back-pointer to shared table
```

---

## Initialization Order (Critical)

The order matters because threads must never run before everything is ready:

```
1. malloc philos array
2. malloc forks array
3. init diner-level mutexes (print_lock, is_dinning_lock)
4. init fork mutexes (forks[0..N-1])
5. init each philo: set id, meals_eaten=0, last_meal_time=get_time()
   init each philo's meals_lock
6. set is_dinning = 1
7. set start_time = get_time()
8. pthread_create for each philosopher
9. monitor() — blocks until simulation ends
```

Why `last_meal_time = get_time()` at init, not at thread start?
Because the monitor starts checking immediately after threads are created.
If `last_meal_time = 0`, the formula `get_time() - 0` is enormous — every
philosopher appears to have been starving since 1970 and dies instantly.

---

## Thread Lifecycle — `cycle()`

Each philosopher thread runs this loop:

```
1. Handle single philosopher case (can only take one fork → waits → dies)
2. Stagger even philosophers by usleep(1000) to prevent initial deadlock
3. while (is_dinning):
     eaty()   — grab forks, eat
     sleepy() — release forks, sleep
     thinky() — yield briefly, think
```

### Why stagger even philosophers?
Without staggering, all philosophers start simultaneously and try to grab their
left fork at the same time. With the odd/even strategy they may still collide.
A 1ms delay for even philosophers gives odd philosophers a head start and
breaks the initial race without adding meaningful overhead.

---

## Deadlock Prevention — Odd/Even Fork Order

The classic deadlock scenario: every philosopher picks up their left fork
simultaneously. Now everyone holds one fork and waits for the right fork which
their neighbor holds. No one proceeds — circular deadlock.

**Solution:** break the circular dependency by reversing fork order for even philosophers.

```
Odd  philosophers: lock LEFT  fork first, then RIGHT
Even philosophers: lock RIGHT fork first, then LEFT
```

This means philosopher 1 and philosopher 2 compete for the same fork (fork 1)
instead of each holding one and waiting for the other. Whoever wins proceeds to
eat; the loser blocks and waits — no circle, no deadlock.

---

## Eating — `eaty()`

```
1. Lock fork A (order depends on odd/even)
   print "has taken a fork"
2. Lock fork B
   print "has taken a fork"
3. print "is eating"
4. Lock meals_lock
   last_meal_time = get_time()    ← reset the death clock
   Unlock meals_lock
5. go_sleep(tt_eat)               ← sleep while eating
6. Unlock fork A
   Unlock fork B
7. Lock meals_lock
   meals_eaten++
   Unlock meals_lock
```

Why update `last_meal_time` AFTER taking both forks but BEFORE sleeping?
Because `tt_die` is measured from the START of the last meal, not the end.
A philosopher that takes 200ms to eat should get a full `tt_die` of safety
from the moment they start eating, not from when they finish.

Why unlock forks BEFORE incrementing `meals_eaten`?
To release forks as soon as possible so neighbors can eat. No need to hold
forks while just updating a counter.

---

## Sleeping and Thinking

### `sleepy()`
```
print "is sleeping"
go_sleep(tt_sleep)
```

### `thinky()`
```
print "is thinking"
usleep(1000)   ← 1ms yield, not a real duration
```

Thinking has no defined duration in the subject. The philosopher "thinks"
until they can grab forks in the next `eaty()` call. The 1ms yield is just
to avoid busy-spinning and hammering the CPU between cycles.

---

## The `go_sleep()` Function

A naive `usleep(tt_eat * 1000)` would block the thread for the full duration
with no way to stop early. The monitor sets `is_dinning = 0` when someone
dies, but a sleeping philosopher wouldn't see it until their sleep finishes.

`go_sleep` solves this by sleeping in small chunks:

```
start = get_time()
while get_time() - start < duration:
    usleep(20)                  ← sleep 20 microseconds
    if !is_dinning: return      ← check after each chunk
```

This lets threads react to simulation end within ~20 microseconds instead of
waiting for the full duration.

---

## The Monitor

The monitor runs in `main` (blocking) after all threads are created. It loops
over all philosophers checking two conditions:

### Death check (per philosopher)
```
lock meals_lock
elapsed = get_time() - last_meal_time
unlock meals_lock

if elapsed > tt_die:
    print "X died"
    set is_dinning = 0
    break
```

### All-fed check
```
if min_meals != -1:
    count philosophers with meals_eaten >= min_meals
    if count == n_philos:
        set is_dinning = 0
        break
```

After breaking out of the loop:
```
join all threads (wait for them to finish)
free memory and destroy mutexes
```

---

## Mutex Map — Who Protects What

| Data | Mutex | Who reads | Who writes |
|---|---|---|---|
| `is_dinning` | `is_dinning_lock` | all threads, monitor | monitor |
| stdout / printf | `print_lock` | — | all threads, monitor |
| `last_meal_time` | `meals_lock` (per philo) | monitor | philosopher thread |
| `meals_eaten` | `meals_lock` (per philo) | monitor | philosopher thread |
| fork state | fork mutex (per fork) | — | philosopher threads |

---

## The Death Message Race

The subject requires: *"A message announcing a philosopher's death must be
displayed within 10ms of their actual death."*

The monitor detects death by checking `get_time() - last_meal_time > tt_die`.
The `print_action` for "died" must then acquire `print_lock`. If another
philosopher is currently printing (holding `print_lock`), the monitor waits.

This is why `print_action` checks `is_dinning` before printing — so that a
philosopher that is about to print "is eating" yields if the simulation just
ended. This keeps the "died" message as close to the detection moment as
possible.

---

## Single Philosopher Edge Case

With 1 philosopher there is only 1 fork. A philosopher needs 2 forks to eat —
so they can never eat. The correct behavior:

```
take the one fork
print "has taken a fork"
wait tt_die ms
die (the monitor or go_sleep expiry handles this)
```

This is handled separately in `single_philo()` before the main cycle loop.

---

## Common Bugs to Know

| Bug | Symptom | Fix |
|---|---|---|
| `last_meal_time = 0` at init | Everyone dies instantly | Set to `get_time()` at init |
| Mutex not initialized | Undefined behavior / crash | Init all mutexes before `pthread_create` |
| Using `pthread_attr_init` instead of `pthread_mutex_init` | Wrong function, won't work | Use `pthread_mutex_init` |
| `go_sleep` without `is_dinning` check | Threads don't stop cleanly | Check `is_dinning` every chunk |
| Death message after `is_dinning = 0` | `print_action` checks `is_dinning` first and skips | Set `is_dinning = 0` AFTER printing "died" |
| `pthread_create` failure, threads not joined | Threads run forever | Set `is_dinning = 0`, join before returning |
| All even philosophers stagger, all odd don't | Odd cluster deadlocks | Stagger even by 1ms, let odd start first |
| `meals_lock` double-locked | Deadlock | Never lock a mutex you already hold |
| `n_philos` forks - 1 allocated | Off-by-one, philo N has no fork | Allocate exactly `n_philos` forks |

---

## Execution Flow Summary

```
main()
  └─ set_args()          parse and validate argv into t_diner
  └─ start_diner()
       └─ init_diner()
            └─ malloc philos, forks
            └─ init_diner_locks()    init print_lock, is_dinning_lock, fork mutexes
            └─ init_philos()         set philo fields, init meals_lock per philo
            └─ set is_dinning = 1
       └─ set start_time
       └─ pthread_create x N         launch philosopher threads
       └─ monitor()                  blocks here until simulation ends
            └─ while is_dinning:
                 check starvation per philo
                 check all_philos_filled
                 usleep(1)
            └─ join_threads()
            └─ free_and_destroy()
```

Each philosopher thread runs:
```
cycle()
  └─ single_philo() check
  └─ usleep(1000) if even
  └─ while is_dinning:
       eaty()    lock forks → update last_meal → go_sleep(tt_eat) → unlock forks → meals_eaten++
       sleepy()  go_sleep(tt_sleep)
       thinky()  usleep(1000)
```

---

---

## Helgrind — Testing for Data Races

### What is a data race?
A data race happens when two threads access the same memory location at the
same time, and at least one of them is writing — without any lock in between.
The result is undefined: you might get garbage values, crashes, or behavior
that changes between runs.

### What is Helgrind?
Helgrind is a Valgrind tool that instruments every memory access and mutex
operation at runtime. It tracks which locks are held when each variable is
accessed, and reports when the same variable is accessed from two threads
without a common lock.

### How to run it
```bash
valgrind --tool=helgrind ./philo 4 410 200 200 5
```

### Reading the output
A clean run ends with:
```
ERROR SUMMARY: 0 errors from 0 contexts
```

A race report looks like:
```
Possible data race during read of size 4 at 0x...
   at 0x...: monitor (monitor.c:66)
 This conflicts with a previous write of size 4 by thread #2
   at 0x...: eaty (eat.c:33)
```

This tells you:
- The variable being accessed (by address)
- Which thread read it and where
- Which thread wrote it and where
- That there was no mutex protecting both accesses

### Common race reports in philosophers and what they mean

| Report | Likely cause |
|---|---|
| Race on `last_meal_time` | Reading in monitor without `meals_lock` |
| Race on `meals_eaten` | Reading in monitor or `all_philos_filled` without `meals_lock` |
| Race on `is_dinning` | Reading in cycle without `is_dinning_lock` |
| Race on stdout | Two threads calling `printf` without `print_lock` |

### Important: Helgrind reports vs real races
Helgrind is conservative — it sometimes reports "possible" races that are
technically safe in practice. However for 42 evaluations, **any** Helgrind
error will fail you. Treat every report as real and fix it.

### DRD — alternative race detector
```bash
valgrind --tool=drd ./philo 4 410 200 200 5
```
DRD is another Valgrind tool for data races. It uses a different algorithm
(DJIT+) and sometimes catches races Helgrind misses, and vice versa. Run both
if you want to be thorough. The evaluation sheet specifically mentions both
`--tool=helgrind` and `--tool=drd`.

### Tips for a clean Helgrind run
- Every variable shared between threads must have a dedicated mutex
- Lock before EVERY access — read or write, no exceptions
- Never assume a read is "safe" without a lock just because you're not writing
- Lock ordering must be consistent: if you ever lock A then B, never lock B then A elsewhere (deadlock risk)
- Keep critical sections short — lock, read/write, unlock. Don't do heavy work inside a lock.

---

Good luck at the evaluation. You built this — you can defend it.
