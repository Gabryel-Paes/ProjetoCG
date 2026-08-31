extends PointLight2D

const ABERTURA_CONE: float = PI / 4
const RESOLUCAO_TEXTURA: int = 252

func _ready() -> void:
	var raio_maximo: float = float(RESOLUCAO_TEXTURA)
	var ponto_emissao := Vector2(0.0, RESOLUCAO_TEXTURA / 2.0)
	var imagem := Image.create(RESOLUCAO_TEXTURA, RESOLUCAO_TEXTURA, false, Image.FORMAT_RGBA8)
	
	for x in range(RESOLUCAO_TEXTURA):
		for y in range(RESOLUCAO_TEXTURA):
			var posicao_pixel := Vector2(x, y)
			var vetor_direcao := posicao_pixel - ponto_emissao
			var distancia := vetor_direcao.length()
			
			if distancia > raio_maximo:
				imagem.set_pixel(x, y, Color.TRANSPARENT)
				continue
				
			var angulo_pixel := vetor_direcao.angle()
			
			if absf(angulo_pixel) <= ABERTURA_CONE:
				var intensidade := 1.0 - (distancia / raio_maximo)
				var limite_suavizacao := ABERTURA_CONE * 0.80
				
				if absf(angulo_pixel) > limite_suavizacao:
					var gradiente: float = 1.0 - (absf(angulo_pixel) - limite_suavizacao) / (ABERTURA_CONE - limite_suavizacao)
					intensidade *= gradiente
				
				intensidade = maxf(intensidade, 0.0)
				imagem.set_pixel(x, y, Color(1.0, 1.0, 1.0, intensidade))
			else:
				imagem.set_pixel(x, y, Color.TRANSPARENT)
	
	self.texture = ImageTexture.create_from_image(imagem)
	self.offset = Vector2(RESOLUCAO_TEXTURA / 2.0, 0)
	
	self.energy = 1.5
	self.shadow_enabled = true
	self.shadow_filter = PointLight2D.SHADOW_FILTER_PCF5 
	
	self.enabled = false

func _unhandled_input(event: InputEvent) -> void:

	if event is InputEventKey and event.keycode == KEY_F and event.pressed and not event.echo:
		self.enabled = not self.enabled
