extends RefCounted
## Inventory, ProgressionState and Needs tests (use the real game data).

const DATABASE_PATH := "res://data/game_database.tres"


func _db() -> GameDatabase:
	return load(DATABASE_PATH) as GameDatabase


func test_inventory_spend_is_atomic() -> String:
	var db := _db()
	var inv := Inventory.new()
	inv.add(&"wood", 5)
	var costs: Array[ResourceAmount] = [
		ResourceAmount.new(db.get_resource(&"wood"), 3),
		ResourceAmount.new(db.get_resource(&"fruit"), 1),
	]
	if inv.spend(costs):
		return "should not afford"
	if inv.get_amount(&"wood") != 5:
		return "failed spend must not change inventory"
	inv.add(&"fruit", 1)
	if not inv.spend(costs) or inv.get_amount(&"wood") != 2 or inv.get_amount(&"fruit") != 0:
		return "spend failed"
	return ""


func test_upgrade_cost_grows_and_levels() -> String:
	var db := _db()
	var prog := ProgressionState.new(db)
	var axe := db.get_upgrade(&"sharp_axe")
	var inv := Inventory.new()
	inv.add(&"wood", 1000)
	var first := prog.get_next_cost(axe)[0].amount
	if not prog.buy(axe, inv):
		return "buy failed"
	var second := prog.get_next_cost(axe)[0].amount
	if second <= first:
		return "cost should grow (%d -> %d)" % [first, second]
	if inv.get_amount(&"wood") != 1000 - first:
		return "wrong amount spent"
	return ""


func test_prerequisites_gate_availability() -> String:
	var db := _db()
	var prog := ProgressionState.new(db)
	var keen := db.get_upgrade(&"keen_eye")
	if prog.is_available(keen):
		return "keen_eye should need sharp_axe"
	var inv := Inventory.new()
	inv.add(&"wood", 1000)
	prog.buy(db.get_upgrade(&"sharp_axe"), inv)
	if not prog.is_available(keen):
		return "keen_eye should be available after sharp_axe"
	return ""


func test_tool_power_reduces_clicks_to_min_one() -> String:
	var db := _db()
	var prog := ProgressionState.new(db)
	var pine := db.get_source(&"tree_pine")
	var inv := Inventory.new()
	inv.add(&"wood", 100000)
	var axe := db.get_upgrade(&"sharp_axe")
	for i: int in axe.max_level:
		prog.buy(axe, inv)
	if prog.get_effective_clicks(pine) != maxi(1, pine.clicks - axe.max_level):
		return "unexpected clicks %d" % prog.get_effective_clicks(pine)
	if prog.get_effective_clicks(pine) < 1:
		return "clicks below 1"
	return ""


func test_record_phase_clamps_cps() -> String:
	var db := _db()
	var prog := ProgressionState.new(db)
	prog.record_phase(10000, 10.0)
	if prog.measured_cps > db.phase_rules.max_cps:
		return "cps not clamped"
	return ""


func test_needs_starving_factor() -> String:
	var needs := Needs.new()
	needs.drain(100.0, 1.0, 0.0)
	if not needs.is_starving() or needs.get_click_factor(0.5) != 0.5:
		return "empty hunger should starve"
	needs.restore(0.5, 0.0)
	if needs.is_starving():
		return "restore failed"
	return ""


func test_needs_penalties_are_separate() -> String:
	var db := _db()
	var wood: ResourceType = null
	var water: ResourceType = null
	for resource: ResourceType in db.resources:
		if resource.category == ResourceType.Category.MATERIAL and wood == null:
			wood = resource
		elif resource.category == ResourceType.Category.DRINK and water == null:
			water = resource
	var needs := Needs.new()
	needs.drain(100.0, 0.0, 1.0)  # thirst empty only
	if needs.get_click_factor(0.5) != 1.0:
		return "thirst must not weaken hits"
	if needs.apply_yield_penalty(6, wood, 0.5) != 3:
		return "thirst should halve materials"
	if needs.apply_yield_penalty(1, wood, 0.5) != 1:
		return "a material yield never drops below 1"
	if needs.apply_yield_penalty(6, water, 0.5) != 6:
		return "thirst must not reduce drinks"
	needs.reset()
	needs.drain(100.0, 1.0, 0.0)  # hunger empty only
	if needs.apply_yield_penalty(6, wood, 0.5) != 6:
		return "hunger must not reduce yields"
	return ""


func test_choice_group_is_exclusive() -> String:
	var db := _db()
	var a := UpgradeNode.new()
	a.id = &"test_a"
	a.choice_group = &"test_pick"
	var b := UpgradeNode.new()
	b.id = &"test_b"
	b.choice_group = &"test_pick"
	var original := db.upgrades.duplicate()
	db.upgrades.append_array([a, b])
	var prog := ProgressionState.new(db)
	var inv := Inventory.new()
	var ok := prog.buy(a, inv) and not prog.is_available(b)
	db.upgrades.assign(original)
	return "" if ok else "choice group should block the other node"


func test_story_end_opens_the_choice_groups() -> String:
	var db := _db()
	var enders: Array[UpgradeNode] = []
	for upgrade: UpgradeNode in db.upgrades:
		if upgrade.ends_story:
			enders.append(upgrade)
	if enders.size() != 1 or enders[0].id != &"heart_of_deepglow":
		return "exactly one node (heart_of_deepglow) should end the story"
	var prog := ProgressionState.new(db)
	var levels: Dictionary[StringName, int] = {&"deep_focus": 1}
	prog.restore(levels, 0, 0.0)
	var rival := db.get_upgrade(&"gold_rush")
	if prog.is_story_complete() or not prog.is_blocked_by_choice(rival):
		return "before the ending the other choice must stay blocked"
	levels[&"heart_of_deepglow"] = 1
	prog.restore(levels, 0, 0.0)
	if not prog.is_story_complete() or prog.is_blocked_by_choice(rival):
		return "after the ending every choice must be open"
	return ""


func test_all_maxed_achievement() -> String:
	var db := _db()
	var rule := Achievement.new()
	rule.kind = Achievement.Kind.ALL_MAXED
	var prog := ProgressionState.new(db)
	var levels: Dictionary[StringName, int] = {}
	for upgrade: UpgradeNode in db.upgrades:
		levels[upgrade.id] = upgrade.max_level
	var last: UpgradeNode = db.upgrades[db.upgrades.size() - 1]
	levels[last.id] = last.max_level - 1
	prog.restore(levels, 0, 0.0)
	if rule.is_unlocked(prog) or prog.count_maxed() != db.upgrades.size() - 1:
		return "one node below max must not unlock it"
	levels[last.id] = last.max_level
	prog.restore(levels, 0, 0.0)
	return "" if rule.is_unlocked(prog) else "every node maxed should unlock it"


func test_demo_stops_at_its_last_biome() -> String:
	var db := _db()
	var prog := ProgressionState.new(db)
	prog.demo_last_biome = &"glow_swamp"
	var levels: Dictionary[StringName, int] = {}
	for upgrade: UpgradeNode in db.upgrades:
		if upgrade.grid_position.y < 4:
			levels[upgrade.id] = upgrade.max_level
	prog.restore(levels, 0, 0.0)
	var caves_node: UpgradeNode = null
	for upgrade: UpgradeNode in db.upgrades:
		if upgrade.grid_position.y >= 4 and upgrade.prerequisites.all(
				func(p: Resource) -> bool: return levels.has((p as UpgradeNode).id)):
			caves_node = upgrade
			break
	if not prog.is_demo_complete():
		return "the caves gate reached should complete the demo"
	if prog.get_biome().id != &"glow_swamp":
		return "the demo biome should stay the swamp, got %s" % prog.get_biome().id
	if caves_node == null or not prog.is_beyond_demo(caves_node) or prog.is_available(caves_node):
		return "nodes after the demo must stay locked"
	prog.demo_last_biome = &""
	if prog.is_demo_complete() or not prog.is_available(caves_node):
		return "the full game has no demo limit"
	if prog.get_biome().id == &"glow_swamp":
		return "full game should reach the caves"
	return ""


func test_play_time_is_saved() -> String:
	var db := _db()
	var prog := ProgressionState.new(db)
	prog.play_seconds = 1234.5
	var data := SaveGame.capture(1, 2, Inventory.new(), prog).to_dict()
	var loaded := ProgressionState.new(db)
	SaveGame.from_dict(JSON.parse_string(JSON.stringify(data))).apply_to(Inventory.new(), loaded)
	return "" if is_equal_approx(loaded.play_seconds, 1234.5) else "play time lost: %s" % loaded.play_seconds


func test_required_points_gate() -> String:
	var db := _db()
	var gated := UpgradeNode.new()
	gated.id = &"test_gated"
	gated.required_points = 2
	var prog := ProgressionState.new(db)
	if prog.is_available(gated):
		return "gate should block with 0 points"
	var inv := Inventory.new()
	inv.add(&"wood", 100000)
	var axe := db.get_upgrade(&"sharp_axe")
	prog.buy(axe, inv)
	prog.buy(axe, inv)
	return "" if prog.is_available(gated) else "gate should open with 2 points"


func test_tree_positions_are_unique() -> String:
	var seen := {}
	for upgrade: UpgradeNode in _db().upgrades:
		if seen.has(upgrade.grid_position):
			return "%s and %s share %s" % [seen[upgrade.grid_position], upgrade.id, upgrade.grid_position]
		seen[upgrade.grid_position] = upgrade.id
	return ""


func test_inventory_discovery() -> String:
	var inv := Inventory.new()
	if inv.is_discovered(&"wood"):
		return "nothing should be discovered at start"
	inv.add(&"wood", 3)
	inv.add(&"wood", -3)
	return "" if inv.is_discovered(&"wood") else "wood should stay discovered after spending"


func test_number_format_compact() -> String:
	var cases := {999: "999", 1234: "1.2k", 25000: "25k", 1500000: "1.5M"}
	for value: int in cases:
		if NumberFormat.compact(value) != cases[value]:
			return "%d -> %s" % [value, NumberFormat.compact(value)]
	return ""


func test_biomes_gate_their_rows() -> String:
	var db := _db()
	if db.biomes.size() != 6 or db.biomes[0].required_points != 0:
		return "expected 6 biomes starting at 0 points"
	for i: int in range(1, db.biomes.size()):
		var prev := db.biomes[i - 1]
		var biome := db.biomes[i]
		if biome.required_points <= prev.required_points or biome.tree_row <= prev.tree_row:
			return "biomes must be ordered by points and tree row (%s)" % biome.id
		if biome.background == null:
			return "biome %s has no background" % biome.id
	var prog := ProgressionState.new(db)
	if prog.get_biome() != db.biomes[0]:
		return "a new run starts in the first biome"
	# A node in the second biome's rows is gated by that biome's points.
	var rod := db.get_upgrade(&"unlock_fishing_rod")
	if prog.get_required_points(rod) != db.biomes[1].required_points:
		return "fishing rod should be gated by the swamp"
	if db.get_biome_for_points(db.biomes[2].required_points) != db.biomes[2]:
		return "points should select the biome"
	# Points alone do not skip a biome: 18 points spent only in the forest
	# (rows 0-1) keep the player out of the caves until the swamp is explored.
	for id: StringName in [&"sharp_axe", &"basket", &"canteen", &"lumber_sense", &"keen_eye", &"longer_days"]:
		prog._levels[id] = 3
	if prog.get_biome() != db.biomes[1]:
		return "18 forest points should reach the swamp only (got %s)" % prog.get_biome().id
	prog._levels[&"unlock_fishing_rod"] = 1
	if prog.get_biome() != db.biomes[2]:
		return "exploring the swamp should open the caves"
	return ""


func test_every_biome_has_its_own_ambience_and_particles() -> String:
	var seen: Dictionary[AudioStream, bool] = {}
	for biome: Biome in _db().biomes:
		if biome.ambience == null or seen.has(biome.ambience):
			return "biome %s needs its own ambience loop" % biome.id
		seen[biome.ambience] = true
		if biome.ambient_effects.is_empty():
			return "biome %s has no ambient particles" % biome.id
		for effect: Resource in biome.ambient_effects:
			var fx := effect as AmbientEffect
			if fx == null or fx.colors.is_empty() or fx.count <= 0:
				return "biome %s has an invalid ambient effect" % biome.id
	return ""


func test_every_tool_unlock_lives_in_its_biome() -> String:
	# Theme check (docs/game-design.md §7.2): each biome unlocks its tools.
	var db := _db()
	var expected := {
		&"unlock_fishing_rod": &"glow_swamp",
		&"unlock_pickaxe": &"crystal_caves",
		&"unlock_crystal_pick": &"crystal_caves",
		&"unlock_ore_pick": &"ash_forest",
		&"unlock_spear": &"frozen_moon_vale",
		&"heart_of_deepglow": &"sunken_ruins",
	}
	for id: StringName in expected:
		var biome := db.get_biome_for_row(db.get_upgrade(id).grid_position.y)
		if biome.id != expected[id]:
			return "%s is in %s, expected %s" % [id, biome.id, expected[id]]
	return ""
