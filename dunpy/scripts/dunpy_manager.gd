class_name DunpyManager
extends Node

# --- SINAIS PARA A UI ---
signal dialogue_started
signal dialogue_finished
signal name_updated(char_name: String)
signal text_updated(current_text: String) # Texto progressivo (letra por letra)
signal choices_requested(choices: Array)

# Sinal interno para aguardar resposta da UI
signal _internal_choice_selected(index: int)

# --- VARIÁVEIS DE ESTADO ---
var full_json_data: Dictionary = {}
var current_tree_data: Array = []
var current_text_buffer: String = ""
var game_variables: Dictionary = {} # Dicionário para %variaveis%
var is_typing: bool = false
var _skip_flag: bool = false # Controle para pular digitação
var next_requested: bool = false

# ==============================================================================
#  CONTROLE PRINCIPAL
# ==============================================================================
func _ready() -> void:
	pass

func start_dialogue(json_data: Dictionary, variables: Dictionary = {}, other_init: String = ""):
	full_json_data = json_data
	game_variables = variables
	
	emit_signal("dialogue_started")
	
	var start_tree
	if other_init.length() > 0:
		start_tree = other_init
	else:
		start_tree = json_data.get("init_tree", "")
	if start_tree != "" and json_data.has(start_tree):
		_load_tree(start_tree)
	else:
		push_error("DunpyManager: 'init_tree' não definida ou inválida.")
		end_dialogue()

func end_dialogue():
	full_json_data = {}
	current_tree_data = []
	emit_signal("dialogue_finished")
	queue_free() # Opcional: Se destruir o manager ao fim, use isso.

func request_next():
	# Função que a UI chama quando o jogador clica para avançar
	next_requested = true
	if is_typing:
		_skip_flag = true # Pula a digitação
	else:
		# Se não está digitando, o 'await' no process_block vai liberar
		pass 

# Função que a UI chama quando um botão de escolha é clicado
func select_choice(index: int):
	emit_signal("_internal_choice_selected", index)

# ==============================================================================
#  LÓGICA DE PROCESSAMENTO DE BLOCOS
# ==============================================================================

func _load_tree(tree_name: String):
	if full_json_data.has(tree_name):
		current_tree_data = full_json_data[tree_name]
		_process_block(0)
	else:
		push_error("DunpyManager: Árvore não encontrada -> " + tree_name)
		end_dialogue()

func _process_block(index: int):
	if index >= current_tree_data.size():
		end_dialogue()
		return

	var block = current_tree_data[index]

	# 1. Executa Funções (Callable)
	if block.has("callable"):
		# Você precisará de uma lógica para chamar funções no script pai ou global
		print("Call solicitada: ", block["callable"]) 

	# 2. Muda de Árvore
	if block.has("change_tree"):
		_load_tree(block["change_tree"])
		return

	# 3. Atualiza Nome
	if block.has("char_name"):
		emit_signal("name_updated", block["char_name"])

	# 4. Processa Texto
	if block.has("text"):
		var parsed_text = _parse_variables(block["text"])
		await _type_text_with_commands(parsed_text)
		
		# Aguarda input para avançar (Simulação simples de wait)
		# Em produção, você pode usar um sinal 'advance_requested' da UI
		while true:
			if Input.is_action_just_pressed("ui_accept") or next_requested: # Ou clique
				next_requested = false
				break
			await get_tree().process_frame
			
		_process_block(index + 1)

	# 5. Processa Escolhas
	elif block.has("choices"): # Assumindo que seu JSON usa uma lista dentro da árvore
		var choice_idx = await _wait_for_choice(block["choices"])
		# Aqui você define a lógica. Ex: O bloco de escolha tem "next" ou a própria escolha tem?
		# Supondo que a escolha diga para onde ir:
		var choice_data = block["choices"][choice_idx]
		
		if choice_data.has("change_tree"):
			_load_tree(choice_data["change_tree"])
		elif choice_data.has("next_index"):
			_process_block(int(choice_data["next_index"]))
		else:
			# Se não tiver destino, apenas avança
			_process_block(index + 1)

# ==============================================================================
#  PARSING E DIGITAÇÃO (${...} e %var%)
# ==============================================================================

func _parse_variables(text: String) -> String:
	for key in game_variables.keys():
		var placeholder = "%" + key + "%"
		text = text.replace(placeholder, str(game_variables[key]))
	return text

func _type_text_with_commands(full_text: String):
	is_typing = true
	_skip_flag = false
	current_text_buffer = ""
	emit_signal("text_updated", "")
	
	var i = 0
	while i < full_text.length():
		# Se jogador pediu para pular, exibe tudo limpo (sem tags) e encerra
		if _skip_flag:
			var clean_text = _strip_commands(full_text) # Função auxiliar recomendada
			emit_signal("text_updated", clean_text)
			break

		# Detecta comando ${
		if full_text[i] == "$" and (i + 1 < full_text.length()) and full_text[i+1] == "{":
			var end_bracket = full_text.find("}", i)
			if end_bracket != -1:
				var command_str = full_text.substr(i + 2, end_bracket - (i + 2))
				await _execute_text_command(command_str)
				i = end_bracket + 1
				continue
		
		# Digitação normal
		current_text_buffer += full_text[i]
		emit_signal("text_updated", current_text_buffer)
		
		await get_tree().create_timer(0.03).timeout
		i += 1
	
	is_typing = false

func _execute_text_command(cmd_string: String):
	var params = {}
	var parts = cmd_string.split(",")
	for part in parts:
		var pair = part.split(":")
		if pair.size() >= 2:
			params[pair[0].strip_edges()] = pair[1].strip_edges()
	
	# Lógica pause/place
	var duration = float(params.get("pause", 0.0))
	
	if params.has("place"):
		var place_text = params["place"]
		if place_text.length() > 0:
			var char_delay = duration / float(place_text.length())
			for char in place_text:
				if _skip_flag: break
				current_text_buffer += char
				emit_signal("text_updated", current_text_buffer)
				await get_tree().create_timer(char_delay).timeout
		else:
			if not _skip_flag: await get_tree().create_timer(duration).timeout
	else:
		if not _skip_flag: await get_tree().create_timer(duration).timeout

# Helper para limpar tags caso o user pule o texto
func _strip_commands(text: String) -> String:
	var regex = RegEx.new()
	regex.compile("\\$\\{.*?\\}")
	return regex.sub(text, "", true)

# ==============================================================================
#  SISTEMA DE ESCOLHAS
# ==============================================================================

func _wait_for_choice(choices: Array) -> int:
	emit_signal("choices_requested", choices)
	var index = await self._internal_choice_selected
	return index
