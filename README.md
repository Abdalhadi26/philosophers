*This project has been created as part of the 42 curriculum by aayasrah.*

## Description

Philosophers is a concurrency project implementing the classic Dining Philosophers problem. One or more philosophers sit at a round table with a bowl of spaghetti and one fork between each pair. A philosopher must pick up both adjacent forks to eat, then puts them down to sleep, then thinks, and repeats. The simulation ends when a philosopher dies of starvation or when all philosophers have eaten a minimum number of times.

The mandatory part implements each philosopher as a POSIX thread with each fork protected by a mutex.

## Instructions

### Compilation

```bash
make
```

### Usage

```bash
./philo number_of_philosophers time_to_die time_to_eat time_to_sleep [min_meals]
```

| Argument | Description |
|---|---|
| `number_of_philosophers` | Number of philosophers (and forks) at the table |
| `time_to_die` | Time in ms before a philosopher dies if they haven't started eating |
| `time_to_eat` | Time in ms a philosopher spends eating |
| `time_to_sleep` | Time in ms a philosopher spends sleeping |
| `min_meals` | (Optional) Simulation stops when all philosophers eat this many times |

### Examples

```bash
./philo 5 800 200 200        # 5 philosophers, none should die
./philo 4 310 200 100        # one philosopher should die
./philo 5 800 200 200 7      # stops after each philosopher eats 7 times
./philo 1 800 200 200        # single philosopher, should die
```

### Testing

```bash
bash test.sh
```

## Resources

- [POSIX Threads Programming — Lawrence Livermore](https://hpc-tutorials.llnl.gov/posix/)
- [The Dining Philosophers Problem — Wikipedia](https://en.wikipedia.org/wiki/Dining_philosophers_problem)
- `man pthread_create`, `man pthread_mutex_init`, `man gettimeofday`

### AI Usage

AI was used as a learning companion throughout this project — not to generate code, but to deepen understanding. Specifically:
- To clarify threading concepts such as how `pthread_mutex_lock` blocks, why mutexes must be initialized before threads are spawned, and how to reason about lock ordering
- To ask guided questions that helped design the data structures and monitor logic independently
- To review written code and identify bugs (uninitialized variables, wrong argument counts, lock leaks)
- To write the Makefile and test script, which are infrastructure rather than core logic
