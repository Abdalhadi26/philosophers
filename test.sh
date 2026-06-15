#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

PHILO=./philo
PASS=0
FAIL=0

pass() { echo -e "${GREEN}[PASS]${RESET} $1"; ((PASS++)); }
fail() { echo -e "${RED}[FAIL]${RESET} $1"; ((FAIL++)); }
info() { echo -e "${CYAN}[INFO]${RESET} $1"; }
header() { echo -e "\n${YELLOW}==============================${RESET}"; echo -e "${YELLOW} $1${RESET}"; echo -e "${YELLOW}==============================${RESET}"; }

run_timed() {
	local duration=$1; shift
	timeout "$duration" $PHILO "$@" 2>&1
}

died()    { echo "$1" | grep -q " died$"; }
no_died() { ! died "$1"; }

# ─── BUILD ────────────────────────────────────────────────────────────────────
header "BUILD"
make re > /dev/null 2>&1
if [ ! -f "$PHILO" ]; then fail "Binary not found after make"; exit 1; fi
pass "Build successful"

# ─── GLOBAL VARIABLES ─────────────────────────────────────────────────────────
header "GLOBAL VARIABLES"
GLOBALS=$(nm philo 2>/dev/null | grep -E "^[0-9a-f]+ [BDCG] " \
	| grep -v "__" | grep -v "_IO" | grep -v "_edata" \
	| grep -v "_end" | grep -v "_bss_start")
if [ -z "$GLOBALS" ]; then
	pass "No global variables found"
else
	fail "Global variables detected:"
	echo "$GLOBALS"
fi

# ─── INVALID ARGS ─────────────────────────────────────────────────────────────
header "INVALID ARGUMENT HANDLING"
check_invalid() {
	$PHILO "$@" > /dev/null 2>&1
	[ $? -ne 0 ] && pass "Rejected: $*" || fail "Not rejected: $*"
}
check_invalid
check_invalid 0 800 200 200
check_invalid -1 800 200 200
check_invalid abc 800 200 200
check_invalid 5 -1 200 200
check_invalid 5 800 200 200 0
check_invalid 5 800 200 200 1 2
check_invalid 5 800 200

# ─── OUTPUT FORMAT ────────────────────────────────────────────────────────────
header "OUTPUT FORMAT"
OUT=$(run_timed 3 5 800 200 200)
BAD=$(echo "$OUT" | grep -vE "^[0-9]+ [0-9]+ (has taken a fork|is eating|is sleeping|is thinking|died)$")
if [ -z "$BAD" ]; then
	pass "All lines match expected format"
else
	fail "Malformed output lines:"
	echo "$BAD" | head -10
fi

# ─── TIMESTAMP MONOTONICITY ───────────────────────────────────────────────────
header "TIMESTAMP MONOTONICITY"
OUT=$(run_timed 3 5 800 200 200)
PREV=0
MONO=true
while IFS= read -r line; do
	TS=$(echo "$line" | awk '{print $1}')
	if [ -n "$TS" ] && [ "$TS" -lt "$PREV" ] 2>/dev/null; then
		MONO=false
		fail "Timestamp went backwards: $TS after $PREV"
		break
	fi
	PREV=$TS
done <<< "$OUT"
$MONO && pass "Timestamps are monotonically non-decreasing"

# ─── PHILOSOPHER CYCLE ORDER ──────────────────────────────────────────────────
header "PHILOSOPHER CYCLE ORDER (eat→sleep→think)"
OUT=$(run_timed 3 5 800 200 200)
CYCLE_OK=true
for pid in $(echo "$OUT" | awk '{print $2}' | sort -u); do
	STATES=$(echo "$OUT" | awk -v p="$pid" '$2 == p {print $3, $4}' \
		| grep -E "^(is eating|is sleeping|is thinking)$")
	PREV_STATE=""
	while IFS= read -r state; do
		if [ "$PREV_STATE" = "is eating" ] && [ "$state" != "is sleeping" ]; then
			fail "Philo $pid: eating not followed by sleeping (got: $state)"
			CYCLE_OK=false
			break 2
		fi
		if [ "$PREV_STATE" = "is sleeping" ] && [ "$state" != "is thinking" ]; then
			fail "Philo $pid: sleeping not followed by thinking (got: $state)"
			CYCLE_OK=false
			break 2
		fi
		PREV_STATE="$state"
	done <<< "$STATES"
done
$CYCLE_OK && pass "All philosophers follow eat→sleep→think order"

# ─── FORK COUNT PER MEAL ──────────────────────────────────────────────────────
header "FORK COUNT (2 forks before eating)"
OUT=$(run_timed 3 5 800 200 200)
FORK_OK=true
for pid in $(echo "$OUT" | awk '{print $2}' | sort -u); do
	LINES=$(echo "$OUT" | awk -v p="$pid" '$2 == p')
	FORK_COUNT=0
	while IFS= read -r line; do
		ACTION=$(echo "$line" | awk '{print $3, $4}')
		if [ "$ACTION" = "has taken a fork" ]; then
			((FORK_COUNT++))
		elif [ "$ACTION" = "is eating" ]; then
			if [ "$FORK_COUNT" -lt 2 ]; then
				fail "Philo $pid ate with fewer than 2 forks"
				FORK_OK=false
				break 2
			fi
			FORK_COUNT=0
		fi
	done <<< "$LINES"
done
$FORK_OK && pass "Each philosopher takes 2 forks before eating"

# ─── NO SIMULTANEOUS EATING (same fork) ──────────────────────────────────────
header "NO SIMULTANEOUS EATING ON ADJACENT PHILOS"
OUT=$(run_timed 3 5 800 200 200)
N=5
SIMUL_OK=true
while IFS= read -r line; do
	TS=$(echo "$line" | awk '{print $1}')
	PID=$(echo "$line" | awk '{print $2}')
	ACTION=$(echo "$line" | awk '{print $3, $4}')
	if [ "$ACTION" = "is eating" ]; then
		LEFT=$(( (PID - 2 + N) % N + 1 ))
		RIGHT=$(( PID % N + 1 ))
		WINDOW_START=$((TS - 5))
		WINDOW_END=$((TS + 5))
		NEIGHBORS=$(echo "$OUT" | awk -v l="$LEFT" -v r="$RIGHT" \
			-v ws="$WINDOW_START" -v we="$WINDOW_END" \
			'($2 == l || $2 == r) && $1 >= ws && $1 <= we && $3" "$4 == "is eating"')
		if [ -n "$NEIGHBORS" ]; then
			fail "Philo $pid and neighbor eating at same time (~${TS}ms)"
			SIMUL_OK=false
			break
		fi
	fi
done <<< "$OUT"
$SIMUL_OK && pass "No adjacent philosophers eating simultaneously"

# ─── DEATH TIMING ─────────────────────────────────────────────────────────────
header "DEATH TIMING (within 10ms)"
OUT=$(run_timed 4 4 310 200 100)
DEATH_LINE=$(echo "$OUT" | grep " died$" | head -1)
if [ -n "$DEATH_LINE" ]; then
	DEATH_TS=$(echo "$DEATH_LINE" | awk '{print $1}')
	PHILO_ID=$(echo "$DEATH_LINE" | awk '{print $2}')
	LAST_EAT=$(echo "$OUT" | awk -v p="$PHILO_ID" \
		'$2 == p && $3" "$4 == "is eating"' | tail -1 | awk '{print $1}')
	[ -z "$LAST_EAT" ] && LAST_EAT=0
	DIFF=$((DEATH_TS - LAST_EAT))
	if [ "$DIFF" -le 320 ]; then
		pass "Death timing OK: philo $PHILO_ID died ${DIFF}ms after last meal (tt_die=310)"
	else
		fail "Death too late: ${DIFF}ms after last meal (tt_die=310, max=320)"
	fi
else
	fail "No death detected in 4 310 200 100"
fi

# ─── DEATH MESSAGE IS LAST ────────────────────────────────────────────────────
header "DEATH MESSAGE IS LAST FOR THAT PHILOSOPHER"
OUT=$(run_timed 4 4 310 200 100)
DEATH_LINE=$(echo "$OUT" | grep " died$" | head -1)
if [ -n "$DEATH_LINE" ]; then
	DEATH_TS=$(echo "$DEATH_LINE" | awk '{print $1}')
	PHILO_ID=$(echo "$DEATH_LINE" | awk '{print $2}')
	AFTER=$(echo "$OUT" | awk -v p="$PHILO_ID" -v t="$DEATH_TS" \
		'$2 == p && $1 > t')
	if [ -z "$AFTER" ]; then
		pass "No messages from philo $PHILO_ID after death"
	else
		fail "Philo $PHILO_ID has messages after its death:"
		echo "$AFTER"
	fi
else
	info "No death in this test — skipping"
fi

# ─── MANDATORY TEST CASES ─────────────────────────────────────────────────────
header "MANDATORY TEST: 1 800 200 200 (should die)"
OUT=$(run_timed 3 1 800 200 200)
if died "$OUT"; then pass "Philosopher died"; else fail "Philosopher did not die"; fi

header "MANDATORY TEST: 5 800 200 200 (no death)"
OUT=$(run_timed 5 5 800 200 200)
if no_died "$OUT"; then pass "No philosopher died"; else fail "A philosopher died"; fi

header "MANDATORY TEST: 5 800 200 200 7 (stop after 7 meals)"
OUT=$(run_timed 10 5 800 200 200 7)
if died "$OUT"; then
	fail "A philosopher died"
else
	MIN=$(echo "$OUT" | grep "is eating" | awk '{print $2}' \
		| sort | uniq -c | awk '{print $1}' | sort -n | head -1)
	if [ -n "$MIN" ] && [ "$MIN" -ge 7 ]; then
		pass "Stopped cleanly, all ate at least 7 times"
	else
		fail "Stopped but min meals was $MIN (expected >=7)"
	fi
fi

header "MANDATORY TEST: 4 410 200 200 (no death)"
OUT=$(run_timed 5 4 410 200 200)
if no_died "$OUT"; then pass "No philosopher died"; else fail "A philosopher died"; fi

header "MANDATORY TEST: 4 310 200 100 (one should die)"
OUT=$(run_timed 5 4 310 200 100)
if died "$OUT"; then pass "A philosopher died as expected"; else fail "No death detected"; fi

header "MANDATORY TEST: 2 800 200 200 (no death)"
OUT=$(run_timed 5 2 800 200 200)
if no_died "$OUT"; then pass "No philosopher died"; else fail "A philosopher died"; fi

# ─── HELGRIND DATA RACES ──────────────────────────────────────────────────────
header "DATA RACES (helgrind)"
if command -v valgrind > /dev/null 2>&1; then
	HELGRIND=$(timeout 10 valgrind --tool=helgrind --error-exitcode=1 \
		$PHILO 4 410 200 200 3 2>&1)
	if echo "$HELGRIND" | grep -q "ERROR SUMMARY: 0 errors"; then
		pass "No data races detected"
	else
		RACE_COUNT=$(echo "$HELGRIND" | grep "ERROR SUMMARY" | awk '{print $4}')
		fail "Data races detected ($RACE_COUNT errors) — run manually to inspect"
	fi
else
	info "valgrind not installed — skipping helgrind"
fi

# ─── MEMORY LEAKS ─────────────────────────────────────────────────────────────
header "MEMORY LEAKS (valgrind)"
if command -v valgrind > /dev/null 2>&1; then
	LEAKS=$(timeout 10 valgrind --leak-check=full --show-leak-kinds=definite \
		$PHILO 4 410 200 200 3 2>&1)
	if echo "$LEAKS" | grep -qE "definitely lost: 0 bytes|no leaks are possible|All heap blocks were freed"; then
		pass "No memory leaks"
	else
		DEF=$(echo "$LEAKS" | grep "definitely lost")
		fail "Memory leaks detected: $DEF"
	fi
else
	info "valgrind not installed — skipping leak check"
fi

# ─── SUMMARY ──────────────────────────────────────────────────────────────────
header "SUMMARY"
TOTAL=$((PASS + FAIL))
echo -e "Total: $TOTAL | Passed: ${GREEN}$PASS${RESET} | Failed: ${RED}$FAIL${RESET}"
[ $FAIL -eq 0 ] \
	&& echo -e "${GREEN}All tests passed!${RESET}" \
	|| echo -e "${RED}$FAIL test(s) failed.${RESET}"
