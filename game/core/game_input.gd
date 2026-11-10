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


func _enter_tree() -> void:
	register_actions()


static func register_actions() -> void:
	for action in KEYS:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.3)
		for key in KEYS[action]:
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
