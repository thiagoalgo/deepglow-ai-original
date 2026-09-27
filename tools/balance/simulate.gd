extends SceneTree
## Balance simulator entry point. Usage (from the project root):
##
##   godot --headless --path . -s res://tools/balance/simulate.gd -- [options]
##
## Options:
##   --runs N              runs per profile (default 20)
##   --target-minutes M    minimum minutes for the "average" profile to finish the tree
##                         (default 120 = full game; use the milestone target while content grows)
##   --profiles a:3,b:4    name:clicks-per-second[:needs-threshold] list
##                         (default slow:2.2,average:3.0,fast:4.5; threshold 0 = ignores hunger/thirst)
##   --out PATH            markdown report path (default res://tools/balance/reports/latest.md)
##
## Exit code 1 when an acceptance check fails (usable in CI).

const Simulator := preload("res://tools/balance/balance_simulator.gd")
const DATABASE_PATH := "res://data/game_database.tres"
const BOARD_CONFIG_PATH := "res://data/board/default_board.tres"

## Acceptance targets (docs/game-design.md §8).
const MAX_FIRST_UPGRADE_PHASE := 2
## Fast players save time (shorter timers) but must not snowball: same
## phase count as average, and at most this much faster in wall-clock.
const MAX_FAST_SPEEDUP := 1.40
const MAX_PHASE_COUNT_GAP := 0.10
const CLEARED_RATIO_RANGE := Vector2(0.15, 0.6)
## In the last quarter of the game, at least this share of what the player
## collects must still be needed by some upgrade (otherwise the end drags).
const MIN_LATE_USEFUL_SHARE := 0.5

var _runs: int = 20
var _target_minutes: float = 120.0
var _profiles: Array = [["slow", 2.2], ["average", 3.0], ["fast", 4.5]]
var _out: String = "res://tools/balance/reports/latest.md"


func _initialize() -> void:
	_parse_args(OS.get_cmdline_user_args())
	var database := load(DATABASE_PATH) as GameDatabase
	var board := load(BOARD_CONFIG_PATH) as BoardConfig
	var simulator := Simulator.new(database, board.size)

	var summaries: Dictionary = {}
	var lines: PackedStringArray = []
	lines.append("# Balance report")
	lines.append("")
	lines.append("Generated %s — %d runs/profile, target (average) ≥ %d min." % [
		Time.get_datetime_string_from_system(), _runs, int(_target_minutes)])
	lines.append("")
	lines.append("| Profile | CPS | Done | Minutes (min / avg / max) | Phases (avg) | 1st upgrade (phase) | Cleared % | Sources/phase (first → last) | Income/phase (first → last) | Starving % | Useful income (last quarter) |")
	lines.append("|---|---|---|---|---|---|---|---|---|---|---|")

	for entry: Array in _profiles:
		var profile := Simulator.Profile.new(entry[0], entry[1])
		if entry.size() > 2:
			profile.needs_threshold = entry[2]
		var results: Array = []
		for i: int in _runs:
			results.append(simulator.run(profile, 1000 + i))
		var summary := _summarize(results)
		summaries[profile.name] = summary
		lines.append("| %s | %.1f | %d/%d | %.1f / %.1f / %.1f | %.0f | %.1f | %.0f%% | %.0f → %.0f | %.0f → %.0f | %.1f%% | %.0f%% |" % [
			profile.name, profile.cps, summary["completed"], _runs,
			summary["min_minutes"], summary["avg_minutes"], summary["max_minutes"],
			summary["avg_phases"], summary["avg_first_upgrade_phase"],
			summary["cleared_ratio"] * 100.0,
			summary["first_sources"], summary["last_sources"],
			summary["first_income"], summary["last_income"],
			summary["starving_ratio"] * 100.0, summary["late_useful_share"] * 100.0])
		if profile.name == "average":
			lines.append_array(_milestones(results, database))

	var checks := _checks(summaries)
	lines.append("")
	lines.append("## Acceptance checks")
	lines.append("")
	var failed := false
	for check: Array in checks:
		lines.append("- [%s] %s" % ["x" if check[1] else " ", check[0]])
		failed = failed or not check[1]

	var report := "\n".join(lines) + "\n"
	print(report)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out.get_base_dir()))
	var file := FileAccess.open(_out, FileAccess.WRITE)
	if file:
		file.store_string(report)
		print("Report written to %s" % ProjectSettings.globalize_path(_out))
	quit(1 if failed else 0)


func _summarize(results: Array) -> Dictionary:
	var minutes: Array[float] = []
	var phases := 0.0
	var completed := 0
	var first_phase := 0.0
	var cleared := 0.0
	var total_phases := 0.0
	var first_sources := 0.0
	var last_sources := 0.0
	var starving := 0.0
	var seconds := 0.0
	var first_income := 0.0
	var last_income := 0.0
	var late_useful := 0.0
	for r: Object in results:
		var shares: Array[float] = r.get("useful_share_per_phase")
		var start := int(shares.size() * 0.75)
		var sum := 0.0
		for i: int in range(start, shares.size()):
			sum += shares[i]
		late_useful += sum / maxf(1.0, float(shares.size() - start))
		minutes.append(r.get("seconds") / 60.0)
		phases += r.get("phases")
		completed += 1 if r.get("completed") else 0
		first_phase += r.get("first_upgrade_phase")
		cleared += r.get("phases_cleared")
		total_phases += r.get("phases")
		var sources: Array[int] = r.get("sources_per_phase")
		first_sources += sources.front()
		last_sources += sources.back()
		starving += r.get("starving_seconds")
		var income: Array[int] = r.get("income_per_phase")
		first_income += income.front()
		last_income += income.back()
		seconds += r.get("seconds")
	var n := float(results.size())
	minutes.sort()
	var avg := 0.0
	for m: float in minutes:
		avg += m
	return {
		"completed": completed,
		"min_minutes": minutes.front(),
		"avg_minutes": avg / n,
		"max_minutes": minutes.back(),
		"avg_phases": phases / n,
		"avg_first_upgrade_phase": first_phase / n,
		"cleared_ratio": cleared / total_phases,
		"first_sources": first_sources / n,
		"last_sources": last_sources / n,
		"starving_ratio": starving / seconds,
		"first_income": first_income / n,
		"last_income": last_income / n,
		"late_useful_share": late_useful / n,
	}


func _milestones(results: Array, database: GameDatabase) -> PackedStringArray:
	var lines: PackedStringArray = []
	lines.append("")
	lines.append("<details><summary>Average profile — upgrade timeline (median minutes)</summary>")
	lines.append("")
	lines.append("| Upgrade | First level | Maxed |")
	lines.append("|---|---|---|")
	for upgrade: UpgradeNode in database.upgrades:
		lines.append("| %s | %s | %s |" % [upgrade.id,
			_median_minutes(results, "first_purchase", upgrade.id),
			_median_minutes(results, "maxed_at", upgrade.id)])
	lines.append("")
	lines.append("</details>")
	lines.append("")
	return lines


func _median_minutes(results: Array, field: String, id: StringName) -> String:
	var values: Array[float] = []
	for r: Object in results:
		var times: Dictionary = r.get(field)
		if times.has(id):
			values.append(times[id] / 60.0)
	if values.is_empty():
		return "—"
	values.sort()
	return "%.1f" % values[values.size() / 2]


func _checks(summaries: Dictionary) -> Array:
	var checks: Array = []
	if summaries.has("average"):
		var avg: Dictionary = summaries["average"]
		checks.append(["average finishes the tree in every run", avg["completed"] == _runs])
		checks.append(["average takes ≥ %d min (got %.1f)" % [int(_target_minutes), avg["avg_minutes"]],
			avg["avg_minutes"] >= _target_minutes])
		checks.append(["first upgrade by phase %d (got %.1f)" % [MAX_FIRST_UPGRADE_PHASE, avg["avg_first_upgrade_phase"]],
			avg["avg_first_upgrade_phase"] <= MAX_FIRST_UPGRADE_PHASE])
		checks.append(["phases are tight: cleared %d–%d%% (got %.0f%%)" % [
			int(CLEARED_RATIO_RANGE.x * 100), int(CLEARED_RATIO_RANGE.y * 100), avg["cleared_ratio"] * 100],
			avg["cleared_ratio"] >= CLEARED_RATIO_RANGE.x and avg["cleared_ratio"] <= CLEARED_RATIO_RANGE.y])
		checks.append(["end game stays useful: ≥ %d%% of last-quarter income still needed (got %.0f%%)" % [
			roundi(MIN_LATE_USEFUL_SHARE * 100), avg["late_useful_share"] * 100],
			avg["late_useful_share"] >= MIN_LATE_USEFUL_SHARE])
		if summaries.has("fast"):
			var speedup: float = avg["avg_minutes"] / summaries["fast"]["avg_minutes"]
			checks.append(["fast is ≤ %d%% faster than average (got %.0f%%)" % [
				roundi((MAX_FAST_SPEEDUP - 1) * 100), (speedup - 1) * 100], speedup <= MAX_FAST_SPEEDUP])
			var gap: float = absf(avg["avg_phases"] - summaries["fast"]["avg_phases"]) / avg["avg_phases"]
			checks.append(["no snowball: fast needs about the same phases (gap %.0f%%, max %d%%)" % [
				gap * 100, roundi(MAX_PHASE_COUNT_GAP * 100)], gap <= MAX_PHASE_COUNT_GAP])
	return checks


func _parse_args(args: PackedStringArray) -> void:
	var i := 0
	while i < args.size():
		var arg := args[i]
		var value := args[i + 1] if i + 1 < args.size() else ""
		match arg:
			"--runs":
				_runs = int(value)
			"--target-minutes":
				_target_minutes = float(value)
			"--out":
				_out = value
			"--profiles":
				_profiles = []
				for pair: String in value.split(","):
					var parts := pair.split(":")
					var spec: Array = [parts[0], float(parts[1])]
					if parts.size() > 2:
						spec.append(float(parts[2]))
					_profiles.append(spec)
			_:
				i -= 1
		i += 2
