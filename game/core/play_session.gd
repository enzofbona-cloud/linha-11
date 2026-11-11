class_name PlaySession
extends Node
## Controla o que é comum a qualquer capítulo jogável: prender o mouse para
## ele virar a câmera, pausar, retomar, painéis e fim de capítulo.
##
## Regra do mouse: durante o jogo o cursor fica preso e invisível. No
## navegador isso só pode ser pedido em resposta a um clique ou tecla do
## jogador, então quando o cursor está solto mostramos "Clique para jogar".
## Se o navegador soltar o cursor (tecla Esc), o jogo pausa.

const MENU_SCENE := "res://game/ui/main_menu.tscn"
## Tempo de tolerância até considerar que um pedido de captura falhou.
const CAPTURE_GRACE := 0.7
## Depois de tantas falhas seguidas, libera a câmera com o cursor visível
## (último recurso, para o jogo nunca ficar sem controle).
const MAX_FAILED_ATTEMPTS := 3

var ended := false
## Último recurso: câmera segue o mouse mesmo sem captura.
var free_look := false

var _player: Player
var _hud: GameHud
var _modal: ModalLayer
var _pause: PauseMenu
var _had_lock := false
var _attempts := 0
var _since_attempt := 0.0
var _overlay: CanvasLayer
var _debug_clock := 0.0
var _objective := ""


## Decide se o cursor deveria estar preso neste momento.
static func wants_capture(paused: bool, is_ended: bool, modal_needs_cursor: bool, touch: bool, is_free_look: bool) -> bool:
	return not (paused or is_ended or modal_needs_cursor or touch or is_free_look)


func _init() -> void:
	name = "PlaySession"
	process_mode = Node.PROCESS_MODE_ALWAYS


func bind(player: Player, hud: GameHud, modal: ModalLayer, pause_menu: PauseMenu) -> void:
	_player = player
	_hud = hud
	_modal = modal
	_pause = pause_menu
	_build_overlay()
	_modal.opened.connect(_on_modal_opened)
	_modal.closed.connect(_on_modal_closed)
	_pause.resumed.connect(resume)
	_pause.quit_to_menu.connect(quit_to_menu)
	_player.pause_requested.connect(pause)
	_player.touch_mode_activated.connect(_on_touch_mode)
	_hud.set_click_hint(false)
	get_tree().paused = false
	# Fora do navegador a captura não precisa de clique. No navegador pode
	# funcionar (o clique no menu ainda vale) e, se não funcionar, o aviso
	# "Clique para jogar" aparece.
	_request_capture(false)


func set_objective(text: String) -> void:
	_objective = text
	_hud.set_objective(text)


func is_captured() -> bool:
	return Input.mouse_mode == Input.MOUSE_MODE_CAPTURED


func _wants_capture_now() -> bool:
	return wants_capture(get_tree().paused, ended, _modal.needs_cursor(),
		_player.has_touch_controls(), free_look)


func _process(delta: float) -> void:
	if _player == null:
		return
	var captured := is_captured()
	_player.look_enabled = captured or free_look
	_publish_debug_state(delta)

	if not _wants_capture_now():
		if captured:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_had_lock = false
		_overlay.visible = false
		return

	if captured:
		_had_lock = true
		_attempts = 0
		_overlay.visible = false
		return

	# Queremos o cursor preso, mas ele está solto.
	if _had_lock:
		# O navegador soltou (Esc) ou a janela perdeu o foco.
		_had_lock = false
		if _modal.is_open:
			_modal.close()
		else:
			pause()
		return

	_since_attempt += delta
	if _attempts >= MAX_FAILED_ATTEMPTS and _since_attempt > CAPTURE_GRACE:
		free_look = true
		_overlay.visible = false
		_hud.show_message("Seu navegador não deixou prender o mouse. A câmera segue o cursor.", 6.0)
		return
	_overlay.visible = _attempts == 0 or _since_attempt > CAPTURE_GRACE


func _input(event: InputEvent) -> void:
	if _player == null or not _wants_capture_now() or is_captured():
		return
	if event is InputEventMouseButton and event.pressed:
		_request_capture(true)
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode != KEY_ESCAPE:
		# Qualquer tecla (menos Esc) também vale como gesto do jogador.
		_request_capture(true)


func _unhandled_input(event: InputEvent) -> void:
	if _player == null or not event.is_action_pressed("pause") or _modal.is_open:
		return
	if ended:
		quit_to_menu()
	elif get_tree().paused:
		resume()
	else:
		pause()
	get_viewport().set_input_as_handled()


func _request_capture(counts_as_attempt: bool) -> void:
	if not _wants_capture_now():
		return
	if counts_as_attempt:
		_attempts += 1
		_since_attempt = 0.0
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func pause() -> void:
	if ended or get_tree().paused:
		return
	if _modal.is_open:
		_modal.close()
	get_tree().paused = true
	_had_lock = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_pause.open()


func resume() -> void:
	_pause.close()
	get_tree().paused = false
	_attempts = 0
	_request_capture(true)


func quit_to_menu() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file(MENU_SCENE)


## Encerra o capítulo e mostra a tela final (com botão de continuar, se houver).
func end_chapter(title: String, body: String, next_scene := "") -> void:
	ended = true
	_player.controls_enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_modal.show_ending(title, body, next_scene)


func _on_modal_opened() -> void:
	_player.controls_enabled = false


func _on_modal_closed() -> void:
	_player.controls_enabled = true
	_had_lock = false
	_attempts = 0
	_request_capture(true)


func _on_touch_mode() -> void:
	_overlay.visible = false
	_hud.show_message("Controles de toque ativados. O botão LUZ alterna a lanterna.", 6.0)


func _build_overlay() -> void:
	_overlay = CanvasLayer.new()
	_overlay.layer = 12
	_overlay.visible = false
	add_child(_overlay)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.add_child(center)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 14)
	center.add_child(box)
	var title := UiKit.label("CLIQUE PARA JOGAR", 38, UiKit.AMBER)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var hint := UiKit.label("O mouse vira a câmera.  Esc solta o mouse e pausa.", 17)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)
	var keys := UiKit.label("WASD andar  ·  Shift correr  ·  Ctrl agachar  ·  E interagir  ·  F lanterna", 15, UiKit.MUTED)
	keys.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(keys)


## No navegador, publica o estado em window.linha11 para testes automáticos.
func _publish_debug_state(delta: float) -> void:
	if not OS.has_feature("web"):
		return
	_debug_clock += delta
	if _debug_clock < 0.2:
		return
	_debug_clock = 0.0
	var state := {
		"scene": get_parent().name,
		"x": snappedf(_player.global_position.x, 0.01),
		"y": snappedf(_player.global_position.y, 0.01),
		"z": snappedf(_player.global_position.z, 0.01),
		"yaw": snappedf(rad_to_deg(_player.rotation.y), 0.1),
		"pitch": snappedf(rad_to_deg(_player.camera.rotation.x), 0.1),
		"captured": is_captured(),
		"paused": get_tree().paused,
		"overlay": _overlay.visible,
		"freeLook": free_look,
		"modal": _modal.is_open,
		"ended": ended,
		"flashlight": _player.flashlight.visible,
		"objective": _objective,
		"inventory": _player.inventory.keys(),
		"prompt": _player.current_prompt(),
	}
	JavaScriptBridge.eval("window.linha11=%s;" % JSON.stringify(state), true)
