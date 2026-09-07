extends GPUParticles2D
class_name DustMotes

# --- Poeira ambiente ---
# De propósito NÃO é "unshaded": reage às mesmas sombras/luzes de tudo mais
# no jogo — quase invisível no escuro, e só fica bem visível cruzando o
# facho da lanterna ou o luar das janelas (MoonLight). Isso é o que faz
# parecer poeira "flutuando na luz", não uma névoa constante.

## Mesma convenção do MoonLight — qual andar essa poeira pertence, pra não
## acender com luz do andar errado nem desenhar por cima dele.
@export var andar: int = 1:
	set(value):
		andar = value
		light_mask = value
		z_index = value - 1

## Tamanho (em px) da área onde a poeira flutua — encaixe no cômodo. O nó
## fica no centro dessa área.
@export var area_size: Vector2 = Vector2(200.0, 150.0)

@export var quantidade: int = 12
@export var velocidade_max: float = 6.0 # px/s — bem lento, só flutuando

## Direção central da pluma, em graus (-90 = pra cima, no sistema de ângulos
## do Godot). Só importa quando spread_deg < 180.
@export var direction_deg: float = -90.0
## Abertura do cone de emissão. 180° = todas as direções (poeira de
## ambiente, o padrão). Um valor menor vira uma "pluma" saindo só numa
## direção — ex: fumacinha subindo de um item.
@export var spread_deg: float = 180.0

const RESOLUCAO_TEXTURA: int = 8

static var _textura_compartilhada: GradientTexture2D = null


func _ready() -> void:
	light_mask = andar
	z_index = andar - 1

	amount = quantidade
	lifetime = 14.0
	preprocess = lifetime # já nasce com a poeira espalhada, não "some" tudo junto no início
	texture = _obter_textura_compartilhada()
	# Sem filtro suavizado: com a textura pequena, isso é o que faz o
	# pontinho parecer um grão nítido em vez de uma bolha borrada.
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	# Único por instância de propósito — se reaproveitasse um resource
	# compartilhado do .tscn, mudar o tamanho de uma DustMotes mudaria a
	# área de todas as outras (mesmo cuidado do MoonLight com a textura).
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(area_size.x / 2.0, area_size.y / 2.0, 0.0)
	mat.gravity = Vector3.ZERO
	mat.direction = Vector3(cos(deg_to_rad(direction_deg)), sin(deg_to_rad(direction_deg)), 0.0)
	mat.spread = spread_deg
	mat.initial_velocity_min = velocidade_max * 0.3
	mat.initial_velocity_max = velocidade_max
	mat.angular_velocity_min = -20.0
	mat.angular_velocity_max = 20.0
	mat.scale_min = 0.15
	mat.scale_max = 0.4
	mat.color = Color(1.0, 0.96, 0.85, 0.35) # tom quente e sutil
	process_material = mat


static func _obter_textura_compartilhada() -> GradientTexture2D:
	if _textura_compartilhada == null:
		# Fica opaco até quase a borda e só aí corta — em vez do degradê
		# suave do centro até fora, que parecia uma bolha borrada. Os dois
		# primeiros set_color mexem nos pontos padrão (0.0 e 1.0); o
		# add_point vem por último pra não embaralhar esses índices.
		var gradiente := Gradient.new()
		gradiente.set_color(0, Color(1, 1, 1, 1))
		gradiente.set_color(1, Color(1, 1, 1, 0))
		gradiente.add_point(0.7, Color(1, 1, 1, 1))

		var tex := GradientTexture2D.new()
		tex.gradient = gradiente
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.5)
		tex.fill_to = Vector2(1.0, 0.5)
		tex.width = RESOLUCAO_TEXTURA
		tex.height = RESOLUCAO_TEXTURA
		_textura_compartilhada = tex

	return _textura_compartilhada
