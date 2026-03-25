# https://tmptesting.godotforums.randommomentania.com/d/17779-how-to-create-a-robust-stats-system
# https://antipixel-games.itch.io/antipixel-stats-system-godot
extends Node

# Signals - emitted when values change so UI updates automatically
signal coins_changed(new_amount: int)
signal gems_changed(new_amount: int)
signal level_changed(new_level: int)

# Player Stats
var coins: int = 100
var gems: int = 2
var level: int = 1

# XP for leveling (optional but recommended)
var xp: int = 0
var xp_to_next_level: int = 1000

const SAVE_PATH = "user://player_stats.save"

func _ready() -> void:
	load_stats()

# ─── COINS ───────────────────────────────────────────
func add_coins(amount: int) -> void:
	coins += amount
	emit_signal("coins_changed", coins)
	save_stats()

func remove_coins(amount: int) -> bool:
	if coins >= amount:
		coins -= amount
		emit_signal("coins_changed", coins)
		save_stats()
		return true
	return false  # Not enough coins

func has_enough_coins(amount: int) -> bool:
	return coins >= amount

# ─── GEMS ────────────────────────────────────────────
func add_gems(amount: int) -> void:
	gems += amount
	emit_signal("gems_changed", gems)
	save_stats()

func remove_gems(amount: int) -> bool:
	if gems >= amount:
		gems -= amount
		emit_signal("gems_changed", gems)
		save_stats()
		return true
	return false  # Not enough gems

# ─── LEVEL / XP ──────────────────────────────────────
func add_xp(amount: int) -> void:
	xp += amount
	while xp >= xp_to_next_level:
		_level_up()

func _level_up() -> void:
	xp -= xp_to_next_level
	level += 1
	xp_to_next_level = int(xp_to_next_level * 1.5)  # Scale difficulty
	emit_signal("level_changed", level)
	save_stats()
	print("Level Up! Now level: ", level)

# ─── SAVE / LOAD ──────────────────────────────────────
func save_stats() -> void:
	var data = {
		"coins": coins,
		"gems": gems,
		"level": level,
		"xp": xp,
		"xp_to_next_level": xp_to_next_level
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_var(data)
	file.close()

func load_stats() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		var data = file.get_var()
		file.close()
		coins = data.get("coins", 5000)
		gems = data.get("gems", 5)
		level = data.get("level", 1)
		xp = data.get("xp", 0)
		xp_to_next_level = data.get("xp_to_next_level", 1000)
