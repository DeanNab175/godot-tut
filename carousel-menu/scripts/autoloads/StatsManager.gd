# StatsManager.gd
extends Node

# --- Signals ---
signal coins_changed(new_amount: int)
signal gems_changed(new_amount: int)
signal level_changed(new_level: int)
signal xp_changed(new_xp: int)

const default_coins: int = 5000
const default_gems: int = 5
const default_level: int = 1
const default_xp: int = 0
const default_xp_to_next_level: int = 100

# --- Stats ---
var coins: int = default_coins
var gems: int = default_gems
var level: int = default_level
var xp: int = default_xp
var xp_to_next_level: int = default_xp_to_next_level  # XP needed to level up

const SAVE_PATH = "user://player_stats.save"

# --- Coins ---
func add_coins(amount: int) -> void:
	coins += amount
	emit_signal("coins_changed", coins)
	save_stats()

func spend_coins(amount: int) -> bool:
	if coins >= amount:
		coins -= amount
		emit_signal("coins_changed", coins)
		save_stats()
		return true
	return false  # Not enough coins

# --- Gems ---
func add_gems(amount: int) -> void:
	gems += amount
	emit_signal("gems_changed", gems)
	save_stats()

func spend_gems(amount: int) -> bool:
	if gems >= amount:
		gems -= amount
		emit_signal("gems_changed", gems)
		save_stats()
		return true
	return false  # Not enough gems

# --- XP & Leveling ---
func add_xp(amount: int) -> void:
	xp += amount
	emit_signal("xp_changed", xp)
	_check_level_up()
	save_stats()

func _check_level_up() -> void:
	while xp >= xp_to_next_level:
		xp -= xp_to_next_level
		level += 1
		xp_to_next_level = _calculate_xp_threshold(level)
		emit_signal("level_changed", level)
		print("Level Up! Now level: ", level)

func _calculate_xp_threshold(current_level: int) -> int:
	# XP required scales with level
	return 1000 + (current_level - 1) * 500

# --- Save / Load ---
func save_stats() -> void:
	var save_data = {
		"coins": coins,
		"gems": gems,
		"level": level,
		"xp": xp,
		"xp_to_next_level": xp_to_next_level
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_var(save_data)
	file.close()

func load_stats() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return  # No save file yet, use defaults
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var save_data = file.get_var()
	file.close()
	coins = save_data.get("coins", default_coins)
	gems  = save_data.get("gems", default_gems)
	level = save_data.get("level", default_level)
	xp    = save_data.get("xp", default_xp)
	xp_to_next_level = save_data.get("xp_to_next_level", default_xp_to_next_level)

func _ready() -> void:
	load_stats()
