extends HBoxContainer

@onready var coins_label: Label = $VBoxContainer/CoinStats/TextFrame/Label
@onready var gems_label: Label = $VBoxContainer/GemStats/TextFrame/Label
@onready var level_label: Label = $VBoxContainer/LevelStats/TextFrame/Label

func _ready() -> void:
	# Connect to StatsManager signals
	StatsManager.coins_changed.connect(_on_coins_changed)
	StatsManager.gems_changed.connect(_on_gems_changed)
	StatsManager.level_changed.connect(_on_level_changed)

	# Initialize with current values
	_refresh_all()

func _refresh_all() -> void:
	coins_label.text = str(StatsManager.coins)
	gems_label.text = str(StatsManager.gems)
	level_label.text = "Level: " + str(StatsManager.level)

func _on_coins_changed(new_amount: int) -> void:
	coins_label.text = str(new_amount)

func _on_gems_changed(new_amount: int) -> void:
	gems_label.text = str(new_amount)

func _on_level_changed(new_level: int) -> void:
	level_label.text = "Level: " + str(new_level)

#USAGE
## Player wins a slot round
#StatsManager.add_coins(3500)
#StatsManager.add_xp(100)
#
## Player buys something
#if StatsManager.spend_coins(500):
	#print("Purchase successful!")
#else:
	#print("Not enough coins!")
#
## Buy gems (from in-app purchase flow)
#StatsManager.add_gems(10)
