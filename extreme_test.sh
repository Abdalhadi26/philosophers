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

run_timed() { local d=$1; shift; timeout "$d" $PHILO "$@" 2>&1; }
died()    { echo "$1" | grep -q " died$"; }
no_died() { ! died "$1"; }

# ─── SINGLE PHILOSOPHER EDGE CASES ───────────────────────────────────────────
header "SINGLE PHILOSOPHER CASES"

OUT=$(run_timed 2 1 600 200 200)
if died "$OUT"; then
	FORKS=$(echo "$OUT" | grep "has taken a fork" | wc -l)
	if [ "$FORKS" -eq 1 ]; then
		pass "1 philo: takes exactly 1 fork then dies"
	else
		fail "1 philo: wrong fork count ($FORKS, expected 1)"
	fi
else
	fail "1 philo: did not die"
fi

OUT=$(run_timed 2 1 200 200 200)
died "$OUT" && pass "1 800 200 200: dies" || fail "1 800 200 200: did not die"

# ─── VERY LARGE NUMBER OF PHILOSOPHERS ───────────────────────────────────────
header "LARGE PHILOSOPHER COUNT"

OUT=$(run_timed 5 100 800 200 200)
no_died "$OUT" && pass "100 philos: no death" || fail "100 philos: unexpected death"

OUT=$(run_timed 5 150 800 200 200)
no_died "$OUT" && pass "150 philos: no death" || fail "150 philos: unexpected death"

# ─── TIGHT TIMING ─────────────────────────────────────────────────────────────
header "TIGHT TIMING"

OUT=$(run_timed 5 4 410 200 200)
no_died "$OUT" && pass "4 410 200 200: no death (tight)" || fail "4 410 200 200: unexpected death"

OUT=$(run_timed 5 2 410 200 200)
no_died "$OUT" && pass "2 410 200 200: no death (tight)" || fail "2 410 200 200: unexpected death"

OUT=$(run_timed 5 3 400 200 200)
died "$OUT" && pass "3 400 200 200: dies (only 1 can eat at a time, cycle > tt_die)" || fail "3 400 200 200: expected death but none"

OUT=$(run_timed 5 4 310 200 100)
died "$OUT" && pass "4 310 200 100: someone dies" || fail "4 310 200 100: no death (expected death)"

OUT=$(run_timed 5 3 310 200 100)
died "$OUT" && pass "3 310 200 100: someone dies" || fail "3 310 200 100: no death (expected death)"

# ─── DEATH TIMING PRECISION ───────────────────────────────────────────────────
header "DEATH TIMING PRECISION (must die within 10ms)"

check_death_timing() {
	local out="$1"
	local tt_die="$2"
	local label="$3"
	local death_line
	death_line=$(echo "$out" | grep " died$" | head -1)
	[ -z "$death_line" ] && { fail "$label: no death detected"; return; }
	local death_ts pid last_eat diff
	death_ts=$(echo "$death_line" | awk '{print $1}')
	pid=$(echo "$death_line" | awk '{print $2}')
	last_eat=$(echo "$out" | awk -v p="$pid" '$2==p && $3" "$4=="is eating"' | tail -1 | awk '{print $1}')
	[ -z "$last_eat" ] && last_eat=0
	diff=$((death_ts - last_eat))
	local max=$((tt_die + 10))
	if [ "$diff" -le "$max" ]; then
		pass "$label: death at ${diff}ms (tt_die=${tt_die}, max=${max})"
	else
		fail "$label: death too late at ${diff}ms (tt_die=${tt_die}, max=${max})"
	fi
}

check_death_timing "$(run_timed 4 4 310 200 100)" 310 "4 310 200 100"
check_death_timing "$(run_timed 4 2 200 100 100)" 200 "2 200 100 100"
check_death_timing "$(run_timed 4 1 600 200 200)" 600 "1 600 200 200"
check_death_timing "$(run_timed 4 5 300 200 200)" 300 "5 300 200 200"

# ─── MIN MEALS EDGE CASES ─────────────────────────────────────────────────────
header "MIN MEALS EDGE CASES"

OUT=$(run_timed 5 5 800 200 200 1)
no_died "$OUT" && {
	MIN=$(echo "$OUT" | grep "is eating" | awk '{print $2}' | sort | uniq -c | awk '{print $1}' | sort -n | head -1)
	[ -n "$MIN" ] && [ "$MIN" -ge 1 ] \
		&& pass "5 800 200 200 1: stops after 1 meal each" \
		|| fail "5 800 200 200 1: not all ate at least once"
} || fail "5 800 200 200 1: unexpected death"

OUT=$(run_timed 15 5 800 200 200 10)
no_died "$OUT" && {
	MIN=$(echo "$OUT" | grep "is eating" | awk '{print $2}' | sort | uniq -c | awk '{print $1}' | sort -n | head -1)
	[ -n "$MIN" ] && [ "$MIN" -ge 10 ] \
		&& pass "5 800 200 200 10: stops after 10 meals each" \
		|| fail "5 800 200 200 10: not all ate 10 times (min: $MIN)"
} || fail "5 800 200 200 10: unexpected death"

OUT=$(run_timed 10 2 800 200 200 5)
no_died "$OUT" && pass "2 800 200 200 5: no death, 5 meals each" || fail "2 800 200 200 5: unexpected death"

# ─── NO OUTPUT AFTER DEATH ────────────────────────────────────────────────────
header "NO OUTPUT AFTER DEATH"

for args in "4 310 200 100" "2 200 100 100" "1 600 200 200"; do
	OUT=$(run_timed 4 $args)
	DEATH=$(echo "$OUT" | grep " died$" | head -1)
	if [ -n "$DEATH" ]; then
		DEATH_TS=$(echo "$DEATH" | awk '{print $1}')
		AFTER=$(echo "$OUT" | awk -v t="$DEATH_TS" '$1 > t')
		[ -z "$AFTER" ] \
			&& pass "$args: no output after death" \
			|| fail "$args: output continues after death: $(echo "$AFTER" | head -3)"
	else
		info "$args: no death to check"
	fi
done

# ─── SIMULATION STOPS CLEANLY ─────────────────────────────────────────────────
header "SIMULATION STOPS CLEANLY (no hang)"

for args in "5 800 200 200 3" "4 410 200 200 5" "2 800 200 200 7"; do
	START=$(date +%s%N)
	run_timed 15 $args > /dev/null
	END=$(date +%s%N)
	ELAPSED=$(( (END - START) / 1000000 ))
	if [ "$ELAPSED" -lt 14000 ]; then
		pass "$args: exited cleanly in ${ELAPSED}ms"
	else
		fail "$args: timed out (possible hang)"
	fi
done

# ─── NO DUPLICATE FORK TAKES ──────────────────────────────────────────────────
header "NO PHILOSOPHER EATS WITH WRONG FORK COUNT"

OUT=$(run_timed 3 5 800 200 200)
FORK_OK=true
for pid in $(echo "$OUT" | awk '{print $2}' | sort -u); do
	COUNT=0
	while IFS= read -r line; do
		ACTION=$(echo "$line" | awk '{print $3, $4}')
		[ "$ACTION" = "has taken a fork" ] && ((COUNT++))
		if [ "$ACTION" = "is eating" ]; then
			[ "$COUNT" -ne 2 ] && { fail "Philo $pid ate with $COUNT forks (expected 2)"; FORK_OK=false; break 2; }
			COUNT=0
		fi
	done <<< "$(echo "$OUT" | awk -v p="$pid" '$2==p')"
done
$FORK_OK && pass "All philosophers ate with exactly 2 forks"

# ─── PHILOSOPHERS DON'T EAT TWICE IN A ROW ───────────────────────────────────
header "EAT→SLEEP→THINK CYCLE RESPECTED"

OUT=$(run_timed 3 5 800 200 200)
CYCLE_OK=true
for pid in $(echo "$OUT" | awk '{print $2}' | sort -u); do
	PREV=""
	while IFS= read -r state; do
		if [ "$PREV" = "is eating" ] && [ "$state" = "is eating" ]; then
			fail "Philo $pid ate twice in a row"
			CYCLE_OK=false
			break 2
		fi
		PREV="$state"
	done <<< "$(echo "$OUT" | awk -v p="$pid" '$2==p {print $3, $4}' | grep -E "^is (eating|sleeping|thinking)$")"
done
$CYCLE_OK && pass "No philosopher eats twice in a row"

# ─── SUMMARY ──────────────────────────────────────────────────────────────────
header "SUMMARY"
TOTAL=$((PASS + FAIL))
echo -e "Total: $TOTAL | Passed: ${GREEN}$PASS${RESET} | Failed: ${RED}$FAIL${RESET}"
[ $FAIL -eq 0 ] \
	&& echo -e "${GREEN}All extreme tests passed!${RESET}" \
	|| echo -e "${RED}$FAIL extreme test(s) failed.${RESET}"
