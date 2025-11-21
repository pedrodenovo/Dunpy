extends Control

func _ready() -> void:
	_add_file("teste","ontem")
	_add_file("puta da bota","amanha")
	_add_file("sem saida","correria")
	_add_file("teste","ontem")
	_add_file("puta da bota","amanha")
	_add_file("sem saida","correria")
	_add_file("teste","ontem")
	_add_file("puta da bota","amanha")
	_add_file("sem saida","correria")


func _process(delta: float) -> void:
	$"backcolor/ScrollContainer/1".columns = int($GetSize.size.x/(290))

func _add_file(title:String,date:String,data:Dictionary={},icon:Image=Image.load_from_file("res://icon.svg")):
	var newFileControl = $base_nodes/FileControl.duplicate()
	newFileControl.title = title
	newFileControl.date = date
	print(newFileControl)
	$"backcolor/ScrollContainer/1".add_child(newFileControl)
