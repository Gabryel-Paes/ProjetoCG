extends PointLight2D

const ABERTURA_CONE: float = PI / 4
const RESOLUCAO_TEXTURA: int = 450
const RAIO_AMBIENTE: float = 30.0

func _ready() -> void:
	var raio_maximo: float = float(RESOLUCAO_TEXTURA) / 2.0
	var centro := Vector2(raio_maximo, raio_maximo)
	var imagem := Image.create(RESOLUCAO_TEXTURA, RESOLUCAO_TEXTURA, false, Image.FORMAT_RGBA8)
	
	for x in range(RESOLUCAO_TEXTURA):
		for y in range(RESOLUCAO_TEXTURA):
			var posicao_pixel := Vector2(x, y)
			var vetor_direcao := posicao_pixel - centro
			var distancia := vetor_direcao.length()
			
			if distancia > raio_maximo:
				imagem.set_pixel(x, y, Color.TRANSPARENT)
				continue
				
			var angulo_pixel := vetor_direcao.angle()
			var intensidade_cone := 0.0
			var intensidade_ambiente := maxf(0.0, 1.0 - (distancia / RAIO_AMBIENTE))
			
			# Calcula o cone da lanterna apontando para a direita (0 graus)
			if absf(angulo_pixel) <= ABERTURA_CONE:
				intensidade_cone = 1.0 - (distancia / raio_maximo)
				var limite_suavizacao := ABERTURA_CONE * 0.80
				if absf(angulo_pixel) > limite_suavizacao:
					var gradiente: float = 1.0 - (absf(angulo_pixel) - limite_suavizacao) / (ABERTURA_CONE - limite_suavizacao)
					intensidade_cone *= gradiente
					intensidade_cone = maxf(intensidade_cone, 0.0)
			
			# O SEGREDO: Pegar o maior valor de luz em vez de somá-los
			var intensidade_final := maxf(intensidade_ambiente, intensidade_cone)
			
			imagem.set_pixel(x, y, Color(1.0, 1.0, 1.0, intensidade_final))
			
	self.texture = ImageTexture.create_from_image(imagem)
	self.offset = Vector2.ZERO # Centraliza a luz no jogador
	self.energy = 1.5
	self.shadow_enabled = true
	self.shadow_filter = PointLight2D.SHADOW_FILTER_PCF5

func _unhandled_input(event: InputEvent) -> void:

	if event is InputEventKey and event.keycode == KEY_F and event.pressed and not event.echo:
		self.enabled = not self.enabled
