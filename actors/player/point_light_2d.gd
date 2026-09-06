extends PointLight2D
class_name PlayerFlashlight

var textura_com_lanterna: ImageTexture
var textura_circulo: ImageTexture
var lanterna_ligada: bool = true

const ABERTURA_CONE: float = PI / 4
const RESOLUCAO_TEXTURA: int = 550
const RAIO_AMBIENTE: float = 30.0
const OFFSET_LANTERNA: Vector2 = Vector2 (10.0, 0.0)

func _ready() -> void:
	var raio_maximo: float = float(RESOLUCAO_TEXTURA) / 2.0
	var centro := Vector2(raio_maximo, raio_maximo)
	var imagem := Image.create(RESOLUCAO_TEXTURA, RESOLUCAO_TEXTURA, false, Image.FORMAT_RGBA8)
	
	for x in range(RESOLUCAO_TEXTURA):
		for y in range(RESOLUCAO_TEXTURA):
			var posicao_pixel := Vector2(x, y)
			
			var vetor_ambiente := posicao_pixel - centro
			var distancia_ambiente := vetor_ambiente.length()
			var intensidade_ambiente = 0.0
			
			if distancia_ambiente <= RAIO_AMBIENTE:
				# Borda menos suave: usamos pow() para manter a intensidade alta por mais tempo e cair rápido no final
				var fator = distancia_ambiente / RAIO_AMBIENTE
				intensidade_ambiente = 1.0 - pow(fator, 2.5)
				
			var posicao_offset = centro + OFFSET_LANTERNA
			var vetor_cone = posicao_pixel - posicao_offset
			var distancia_cone:= vetor_cone.length()
			var intensidade_cone := 0.0
			
			if distancia_cone <= raio_maximo:
				var angulo_pixel:= vetor_cone.angle()
				if absf(angulo_pixel) <= ABERTURA_CONE:
					var fator_cone = distancia_cone/raio_maximo
					intensidade_cone = 1 - pow(fator_cone,1.5)
					
					var limite_suavizacao:= ABERTURA_CONE * 0.85
					if absf(angulo_pixel) > limite_suavizacao:
						var gradiente: float = 1.0 - (absf(angulo_pixel) - limite_suavizacao) / (ABERTURA_CONE - limite_suavizacao)
						intensidade_cone *= gradiente
			
			# O SEGREDO: Pegar o maior valor de luz em vez de somá-los
			var intensidade_final := maxf(intensidade_ambiente, intensidade_cone)
			
			if intensidade_final > 0.0:
				imagem.set_pixel(x,y, Color(1.0,1.0,1.0, intensidade_final))
			else:
				imagem.set_pixel(x,y,Color.TRANSPARENT)
			
	#textura com a lanterna ligada criada
	textura_com_lanterna = ImageTexture.create_from_image(imagem)
	
	#cria uma segunda imagem só com o circulo e sem o cone
	var imagem_circulo = Image.create(RESOLUCAO_TEXTURA, RESOLUCAO_TEXTURA, false, Image.FORMAT_RGBA8)
	for x in range (RESOLUCAO_TEXTURA):
		for y in range(RESOLUCAO_TEXTURA):
			var pos := Vector2(x,y)
			var dist:= (pos-centro).length()
			if dist <= RAIO_AMBIENTE:
				var int_amb = 1.0 - (dist / RAIO_AMBIENTE)
				imagem_circulo.set_pixel(x,y, Color(1.0,1.0,1.0, int_amb))
			else:
				imagem_circulo.set_pixel(x,y,Color.TRANSPARENT)
	
	textura_circulo = ImageTexture.create_from_image(imagem_circulo)
	
	self.texture = textura_com_lanterna
	self.offset = Vector2.ZERO
	self.energy = 1.5
	self.shadow_enabled = true
	self.shadow_filter = PointLight2D.SHADOW_FILTER_PCF5

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_F and event.pressed and not event.echo:
		lanterna_ligada = not lanterna_ligada
		if lanterna_ligada:
			self.texture = textura_com_lanterna
		else:
			self.texture = textura_circulo
