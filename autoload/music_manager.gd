extends Node

# --- Trilha sonora ambiente ---
# Toca "Musica 2" e "Musica 3" alternadas, em loop entre si, bem baixinho —
# só um fundo ambiente, não pra chamar atenção. Autoload de propósito: assim
# ela continua tocando sozinha entre trocas de cena (menu, jogo, morte,
# vitória...) sem reiniciar ou cortar no meio.

const TRACKS: Array[AudioStream] = [
	preload("res://ui/assets/sounds/Musica 2.mp3"),
	preload("res://ui/assets/sounds/Musica 3.mp3"),
]

## Baixinho de propósito — é só ambiente, não pode competir com os efeitos
## (tiro, passos, etc). -20 e -10 ainda estavam baixos demais pra notar.
@export var volume_db: float = -4.0

# --- Tema do Stalker (encontro no mapa) ---
# Toca CHEIA (0 dB, bem mais alta que a ambiente) enquanto o encontro dura,
# cortando a trilha normal na hora — chamado direto pelo stalker_director.gd
# quando o encontro começa/termina.
## var (não const) de propósito — precisa poder ajustar o loop_mode dela
## logo abaixo, e o GDScript não deixa mudar propriedade de algo "const".
var STALKER_TRACK := preload("res://ui/assets/sounds/STALKER.mp3")

var _player: AudioStreamPlayer          # trilha ambiente (Musica 2/3)
var _encounter_player: AudioStreamPlayer # tema do Stalker, por cima da ambiente
var _next_track: int = 0


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	add_child(_player)
	_player.volume_db = volume_db
	_player.bus = "Master"
	_player.finished.connect(_play_next)

	_encounter_player = AudioStreamPlayer.new()
	add_child(_encounter_player)
	_encounter_player.stream = STALKER_TRACK
	_encounter_player.volume_db = 0.0 # "com tudo" — cheia, sem abaixar
	_encounter_player.bus = "Master"
	if STALKER_TRACK is AudioStreamWAV:
		STALKER_TRACK.loop_mode = AudioStreamWAV.LOOP_FORWARD

	_play_next()


func _play_next() -> void:
	_player.stream = TRACKS[_next_track]
	_player.play()
	_next_track = (_next_track + 1) % TRACKS.size()


## Chamado pelo stalker_director.gd assim que o Stalker nasce no mapa.
func play_stalker_theme() -> void:
	_player.stop() # a ambiente para na hora — o tema entra "com tudo", sem mistura
	_encounter_player.play()


## Chamado pelo stalker_director.gd quando o encontro acaba (Stalker some).
func stop_stalker_theme() -> void:
	_encounter_player.stop()
	_play_next() # volta pra trilha ambiente normal
