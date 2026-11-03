extends Node

func calculate_risk_increase(time_taken: float, target_time: float, correct: bool, timed_out: bool = false, base_limit: float = 12.0) -> float:
	var overtime := clampf(time_taken - base_limit, 0.0, 6.0)
	var overtime_risk := overtime * 1.0
	if timed_out:
		return 10.0 + overtime_risk
	if not correct:
		return 8.0 + overtime_risk
	if overtime > 0.0:
		return 2.0 + overtime_risk
	return -2.0 if time_taken <= target_time else 2.0

func calculate_points(time_taken: float, time_limit: float, correct: bool, difficulty: int = 1, base_points: int = 100) -> int:
	if not correct:
		return 0
	var ratio := clampf(time_taken / maxf(time_limit, 0.01), 0.0, 1.0)
	return roundi(float(base_points * difficulty) * (1.0 + 0.5 * (1.0 - ratio)))
