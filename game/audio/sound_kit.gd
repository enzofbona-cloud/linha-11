class_name SoundKit
## Sons gerados por código (sem arquivos de áudio). São provisórios, mas
## funcionam no PC e no navegador e não pesam no download.

const RATE := 22050

static var _cache := {}


const SFX_DIR := "res://assets/audio/sfx/"
const FOOTSTEPS := ["footstep00", "footstep01", "footstep02", "footstep03", "footstep04",
	"footstep05", "footstep06", "footstep07", "footstep08", "footstep09"]
const DOOR_OPEN := ["dooropen_1", "dooropen_2"]
const DOOR_CLOSE := ["doorclose_1", "doorclose_2", "doorclose_3", "doorclose_4"]
const CREAKS := ["creak1", "creak2", "creak3"]
const PAGES := ["bookflip1", "bookflip2", "bookflip3"]
const PICKUPS := ["handlesmallleather", "handlesmallleather2", "cloth1", "cloth2"]

static var _last_pick := {}


## Gravação real (arquivo .ogg em assets/audio/sfx). Devolve null se não existir.
static func sfx(sound_name: String) -> AudioStream:
	var key := "sfx:" + sound_name
	if not _cache.has(key):
		var path := SFX_DIR + sound_name + ".ogg"
		_cache[key] = load(path) if ResourceLoader.exists(path) else null
	return _cache[key]


## Sorteia uma variação sem repetir a anterior (evita o efeito "metralhadora").
static func pick(group: Array) -> AudioStream:
	var id := group.hash()
	var index := randi() % group.size()
	if group.size() > 1 and _last_pick.get(id, -1) == index:
		index = (index + 1) % group.size()
	_last_pick[id] = index
	return sfx(group[index])


static func _wav(samples: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = bytes
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = samples.size()
	return wav


static func _cached(key: String, builder: Callable) -> AudioStreamWAV:
	if not _cache.has(key):
		_cache[key] = builder.call()
	return _cache[key]


## Toque de telefone antigo: dois toques e uma pausa, em laço.
static func ring() -> AudioStreamWAV:
	return _cached("ring", func():
		var s := PackedFloat32Array()
		s.resize(int(RATE * 3.0))
		for i in s.size():
			var t := float(i) / RATE
			var on := (t < 0.45) or (t > 0.65 and t < 1.1)
			if on:
				var tremolo := 0.5 + 0.5 * signf(sin(TAU * 22.0 * t))
				s[i] = (sin(TAU * 1250.0 * t) + sin(TAU * 1540.0 * t)) * 0.22 * tremolo
		return _wav(s, true))


## Zumbido grave de prédio vazio, em laço.
static func hum() -> AudioStreamWAV:
	return _cached("hum", func():
		var s := PackedFloat32Array()
		s.resize(RATE * 4)
		var rng := RandomNumberGenerator.new()
		rng.seed = 11
		var low := 0.0
		for i in s.size():
			var t := float(i) / RATE
			low = lerpf(low, rng.randf_range(-1.0, 1.0), 0.004)
			s[i] = sin(TAU * 50.0 * t) * 0.10 + sin(TAU * 75.5 * t) * 0.05 + low * 0.9
		return _wav(s, true))


## Estalos úmidos e irregulares do Ouvinte, em laço.
static func clicks() -> AudioStreamWAV:
	return _cached("clicks", func():
		var s := PackedFloat32Array()
		s.resize(RATE * 3)
		var rng := RandomNumberGenerator.new()
		rng.seed = 317
		var next := 0
		while next < s.size():
			var length := rng.randi_range(60, 220)
			for j in length:
				if next + j < s.size():
					var env := 1.0 - float(j) / length
					s[next + j] = rng.randf_range(-1.0, 1.0) * env * env * 0.7
			next += rng.randi_range(900, 5200)
		return _wav(s, true))


## Rosnado gutural do Ouvinte, em laço: um ronco grave e rouco que cresce,
## racha, some, e dá lugar a uma respiração molhada antes de recomeçar.
static func growl() -> AudioStreamWAV:
	return _cached("growl", func():
		var length := 5.0
		var s := PackedFloat32Array()
		s.resize(int(RATE * length))
		var rng := RandomNumberGenerator.new()
		rng.seed = 1109
		var phase := 0.0
		var jitter := 0.0
		var breath := 0.0
		var band := 0.0
		var band_vel := 0.0
		var body := 0.0
		for i in s.size():
			var t := float(i) / RATE
			# rosnado: de 0,2 s a 3,0 s
			var g := clampf((t - 0.2) / 0.9, 0.0, 1.0) * clampf((3.0 - t) / 0.7, 0.0, 1.0)
			# respiração puxada: de 3,3 s a 4,7 s
			var b := sin(clampf((t - 3.3) / 1.4, 0.0, 1.0) * PI)
			jitter = lerpf(jitter, rng.randf_range(-1.0, 1.0), 0.02)
			var freq := 46.0 + 9.0 * sin(t * 2.1) + jitter * 14.0 + g * 8.0
			phase = fmod(phase + freq / RATE, 1.0)
			# pulso de garganta: estalo seco que decai (rico em harmônicos)
			var pulse := pow(1.0 - phase, 5.0) * 2.0 - 0.33
			# a garganta "racha" em rajadas irregulares
			var crack := 0.55 + 0.45 * sin(t * 23.0 + jitter * 6.0)
			# ressonância da boca (por volta de 380 Hz) para aparecer em caixa pequena
			var drive := pulse * g * crack
			band_vel += (drive - band) * 0.0115 - band_vel * 0.06
			band += band_vel
			body = lerpf(body, drive, 0.18)
			breath = lerpf(breath, rng.randf_range(-1.0, 1.0), 0.22)
			var rasp := breath * (b * 0.5 + g * 0.16)
			s[i] = clampf(body * 0.55 + band * 0.5 + rasp, -1.0, 1.0) * 0.8
		return _wav(s, true))


## Passo do Ouvinte: pancada pesada, com um arrastar depois.
static func monster_step() -> AudioStreamWAV:
	return _cached("monster_step", func():
		var s := PackedFloat32Array()
		s.resize(int(RATE * 0.42))
		var rng := RandomNumberGenerator.new()
		rng.seed = 77
		var drag := 0.0
		for i in s.size():
			var t := float(i) / RATE
			var thud := sin(TAU * (62.0 - 60.0 * t) * t) * exp(-t * 22.0)
			var slap := rng.randf_range(-1.0, 1.0) * exp(-t * 70.0) * 0.5
			drag = lerpf(drag, rng.randf_range(-1.0, 1.0), 0.12)
			var scrape := drag * sin(clampf((t - 0.08) / 0.34, 0.0, 1.0) * PI) * 0.35
			s[i] = clampf(thud * 0.9 + slap + scrape, -1.0, 1.0) * 0.8
		return _wav(s))


## Um passo: batida curta e abafada.
static func step() -> AudioStreamWAV:
	return _cached("step", func():
		var s := PackedFloat32Array()
		s.resize(int(RATE * 0.09))
		var rng := RandomNumberGenerator.new()
		rng.seed = 5
		for i in s.size():
			var t := float(i) / s.size()
			var env := pow(1.0 - t, 3.0)
			s[i] = (sin(TAU * 90.0 * float(i) / RATE) * 0.8 + rng.randf_range(-0.3, 0.3)) * env * 0.6
		return _wav(s))


## Clique de interruptor (lanterna, fusível, teclado).
static func click() -> AudioStreamWAV:
	return _cached("click", func():
		var s := PackedFloat32Array()
		s.resize(int(RATE * 0.03))
		for i in s.size():
			var t := float(i) / s.size()
			s[i] = sin(TAU * 2400.0 * float(i) / RATE) * pow(1.0 - t, 4.0) * 0.5
		return _wav(s))



## Notas puras para o puzzle do apartamento 304: grave, médio e agudo.
static func sequence_note(index: int) -> AudioStreamWAV:
	return _cached("sequence_%d" % index, func():
		var frequencies := [196.0, 261.6, 329.6]
		var frequency: float = frequencies[clampi(index, 0, 2)]
		var samples := PackedFloat32Array()
		samples.resize(int(RATE * 0.72))
		for i in samples.size():
			var t := float(i) / RATE
			var attack := minf(t / 0.025, 1.0)
			var release := clampf((0.72 - t) / 0.18, 0.0, 1.0)
			var fundamental := sin(TAU * frequency * t)
			var overtone := sin(TAU * frequency * 2.01 * t) * 0.16
			samples[i] = (fundamental + overtone) * attack * release * 0.28
		return _wav(samples))

## Ranger de porta.
static func creak() -> AudioStreamWAV:
	return _cached("creak", func():
		var s := PackedFloat32Array()
		s.resize(int(RATE * 0.6))
		var phase := 0.0
		for i in s.size():
			var t := float(i) / s.size()
			phase += TAU * (180.0 + 120.0 * sin(t * 9.0)) / RATE
			s[i] = signf(sin(phase)) * sin(phase * 0.31) * sin(PI * t) * 0.18
		return _wav(s))


## Acorde dissonante que cresce: usado em sustos e revelações.
static func sting() -> AudioStreamWAV:
	return _cached("sting", func():
		var s := PackedFloat32Array()
		s.resize(int(RATE * 2.4))
		for i in s.size():
			var t := float(i) / RATE
			var env := minf(t / 0.9, 1.0) * clampf((2.4 - t) / 1.2, 0.0, 1.0)
			s[i] = (sin(TAU * 110.0 * t) + sin(TAU * 116.5 * t) + sin(TAU * 233.1 * t) * 0.6 + sin(TAU * 311.0 * t) * 0.4) * 0.16 * env
		return _wav(s))


## Chiado de linha telefônica.
static func static_noise() -> AudioStreamWAV:
	return _cached("static", func():
		var s := PackedFloat32Array()
		s.resize(RATE * 2)
		var rng := RandomNumberGenerator.new()
		rng.seed = 304
		for i in s.size():
			s[i] = rng.randf_range(-1.0, 1.0) * 0.12 * (0.6 + 0.4 * sin(TAU * 3.0 * float(i) / RATE))
		return _wav(s, true))


## Cria um player 3D já configurado para terror: curto alcance, atenuação forte.
static func player_3d(parent: Node, stream: AudioStream, max_distance := 22.0, volume_db := 0.0) -> AudioStreamPlayer3D:
	var p := AudioStreamPlayer3D.new()
	p.stream = stream
	p.max_distance = max_distance
	p.unit_size = 3.0
	p.volume_db = volume_db
	p.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	parent.add_child(p)
	return p


static func player_2d(parent: Node, stream: AudioStream, volume_db := 0.0) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = volume_db
	parent.add_child(p)
	return p
