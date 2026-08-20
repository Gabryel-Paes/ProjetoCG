extends PointLight2D
const ABERTURA_CONE: float = PI / 6.0 # 30 graus para cada lado
const RESOLUCAO_TEXTURA: int = 512

func _ready() -> void:
	var raio_maximo: float = float(RESOLUCAO_TEXTURA)
	# Origem calculada na borda esquerda e centralizada verticalmente
	var ponto_emissao := Vector2(0.0, RESOLUCAO_TEXTURA / 2.0)
	
	var imagem := Image.create(RESOLUCAO_TEXTURA, RESOLUCAO_TEXTURA, false, Image.FORMAT_RGBA8)
	
	# Processamento vetorial iterativo para a projeção do feixe
	for x in range(RESOLUCAO_TEXTURA):
		for y in range(RESOLUCAO_TEXTURA):
			var posicao_pixel := Vector2(x, y)
			var vetor_direcao := posicao_pixel - ponto_emissao
			var distancia := vetor_direcao.length()
			
			if distancia > raio_maximo:
				imagem.set_pixel(x, y, Color.TRANSPARENT)
				continue
				
			var angulo_pixel := vetor_direcao.angle()
			
			# Valida a angulação dentro do limite do cone
			if abs(angulo_pixel) <= ABERTURA_CONE:
				# Atenuação linear baseada no inverso da distância
				var intensidade := 1.0 - (distancia / raio_maximo)
				
				# Interpolação para suavização das bordas longitudinais
				var limite_suavizacao := ABERTURA_CONE * 0.80
				if abs(angulo_pixel) > limite_suavizacao:
					var gradiente = 1.0 - (abs(angulo_pixel) - limite_suavizacao) / (ABERTURA_CONE - limite_suavizacao)
					intensidade *= gradiente
					
				imagem.set_pixel(x, y, Color(1.0, 1.0, 1.0, intensidade))
			else:
				imagem.set_pixel(x, y, Color.TRANSPARENT)
	
	# Aplica a textura diretamente ao nó atual
	self.texture = ImageTexture.create_from_image(imagem)
	
	# Correção de Offset: Compensa o ponto de emissão para que a base do cone 
	# coincida exatamente com a posição (0,0) do nó no espaço 2D.
	self.offset = Vector2(RESOLUCAO_TEXTURA / 2.0, 0)
	
	# Configurações físicas rigorosas para o estilo do jogo
	self.energy = 1.2
	self.shadow_enabled = true
	self.shadow_filter = PointLight2D.SHADOW_FILTER_PCF5 # Suavização das sombras
