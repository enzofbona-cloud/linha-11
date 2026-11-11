extends Node
## Registra as ações de controle do jogo (teclado, mouse e controle).
## Fica em código, e não no project.godot, para ser fácil de ler e testar.

const KEYS := {
	"move_forward": [KEY_W, KEY_UP],
	"move_back": [KEY_S, KEY_DOWN],
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"sprint": [KEY_SHIFT],
	"crouch": [KEY_CTRL, KEY_C],
	"walk_slow": [KEY_ALT],
	"jump": [KEY_SPACE],
	"interact": [KEY_E],
	"flashlight": [KEY_F],
	"pause": [KEY_ESCAPE, KEY_P],
}

const JOY_BUTTONS := {
	"jump": JOY_BUTTON_A,
	"crouch": JOY_BUTTON_B,
	"interact": JOY_BUTTON_X,
	"flashlight": JOY_BUTTON_Y,
	"sprint": JOY_BUTTON_LEFT_STICK,
	"walk_slow": JOY_BUTTON_LEFT_SHOULDER,
	"pause": JOY_BUTTON_START,
}

## ação -> [eixo, direção]
const JOY_AXES := {
	"move_forward": [JOY_AXIS_LEFT_Y, -1.0],
	"move_back": [JOY_AXIS_LEFT_Y, 1.0],
	"move_left": [JOY_AXIS_LEFT_X, -1.0],
	"move_right": [JOY_AXIS_LEFT_X, 1.0],
}

## Texto dos controles mostrado no menu e na pausa.
const HELP_TEXT := "W A S D — andar\nMouse — olhar\nShift — correr\nCtrl ou C — agachar\nAlt — andar devagar\nEspaço — pular\nE — interagir\nF — lanterna\nEsc ou P — pausar"
const HELP_TEXT_WEB := "W A S D — andar\nMouse — olhar\nShift — correr\nC — agachar\nX — andar devagar\nEspaço — pular\nE — interagir\nF — lanterna\nEsc ou P — pausar"

## No navegador, Ctrl e Alt são teclas de atalho do próprio navegador e o jogo
## não consegue bloqueá-las: Ctrl+W (agachar + andar) FECHA A ABA, Ctrl+T abre
## outra, Alt+seta volta a página. Por isso, na Web, essas teclas ficam de fora.
const WEB_UNSAFE_KEYS := [KEY_CTRL, KEY_ALT]
const WEB_EXTRA_KEYS := {"walk_slow": [KEY_X]}


func _enter_tree() -> void:
	register_actions()
	if OS.has_feature("web"):
		_guard_browser_tab()


static func is_web() -> bool:
	return OS.has_feature("web")


static func help_text(web := is_web()) -> String:
	return HELP_TEXT_WEB if web else HELP_TEXT


## Nome da tecla de agachar, para as mensagens do jogo.
static func crouch_key_name(web := is_web()) -> String:
	return "C" if web else "Ctrl"


static func slow_key_name(web := is_web()) -> String:
	return "X" if web else "Alt"


## Teclas de uma ação, já sem as que o navegador usa como atalho.
static func keys_for(action: String, web := is_web()) -> Array:
	var keys: Array = KEYS[action].duplicate()
	if web:
		for key in WEB_UNSAFE_KEYS:
			keys.erase(key)
		keys.append_array(WEB_EXTRA_KEYS.get(action, []))
	return keys


## Rede de segurança: com o jogo em andamento (mouse preso), o navegador
## pergunta antes de fechar ou sair da página.
func _guard_browser_tab() -> void:
	JavaScriptBridge.eval("""
		window.addEventListener('beforeunload', function (e) {
			if (document.pointerLockElement) { e.preventDefault(); e.returnValue = ''; }
		});
	""", true)


static func register_actions() -> void:
	for action in KEYS:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.3)
		for key in keys_for(action):
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			if not InputMap.action_has_event(action, ev):
				InputMap.action_add_event(action, ev)
	for action in JOY_BUTTONS:
		var ev := InputEventJoypadButton.new()
		ev.button_index = JOY_BUTTONS[action]
		if not InputMap.action_has_event(action, ev):
			InputMap.action_add_event(action, ev)
	for action in JOY_AXES:
		var ev := InputEventJoypadMotion.new()
		ev.axis = JOY_AXES[action][0]
		ev.axis_value = JOY_AXES[action][1]
		if not InputMap.action_has_event(action, ev):
			InputMap.action_add_event(action, ev)
