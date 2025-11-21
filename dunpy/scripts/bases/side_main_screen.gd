extends Control

@export_group("Customização")
@export var game_title: String = "JUST A EXEMPLE: THE GAME"
@export var version_text: String = "V0.0"
@export var panel_color = Color()
@export var show_exit_confirm_windown = true

@export_group("Screens")
@export var save_and_load_scene_path = "res://addons/dunbPy/scenes/bases/sava_and_load_screen.tscn"

@onready var colorRect = %ColorRect
@onready var titleLabel = %TitleLabel
@onready var versionText = %VersionTextLabel
@onready var exit_confirm_window = %Window

var save_and_load_scene 

func _ready() -> void:
	colorRect.color = panel_color
	titleLabel.text = game_title
	versionText.text = version_text


func on_pressed_new_game_button():
	pass


func _on_pressed_load_button() -> void:
	pass # Replace with function body.


func _on_pressed_options_button() -> void:
	pass


func _on_pressed_about_button() -> void:
	pass # Replace with function body.


func _on_pressed_help_button() -> void:
	pass # Replace with function body.


func on_pressed_exit_button():
	if show_exit_confirm_windown:
		exit_confirm_window.show()
	else:
		get_tree().quit()
func _on_confirm_exit_pressed() -> void:
	get_tree().quit()
func _on_cancel_exit_pressed() -> void:
	exit_confirm_window.hide()
