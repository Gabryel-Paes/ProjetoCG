extends PointLight2D
class_name MoonLight

## Luz estática (não segue o jogador) pra simular luar entrando por uma
## janela. Funciona exatamente como a lanterna: respeita oclusão (paredes
## bloqueiam), então só ilumina o que está "à vista" da janela.
##
## Uso: instancie essa cena em cima/na frente de uma janela no mapa. O
## polígono de oclusão da própria parede (que já tem o buraco da janela,
## sem tile de oclusão ali) deixa a luz vazar só por aquela abertura.

## Qual andar essa janela ilumina — 1 = térreo, 2 = mezanino.
## Precisa bater com o "occlusion_layer_0/light_mask" do TileSet daquele andar.
@export var andar: int = 1:
	set(value):
		andar = value
		range_item_cull_mask = value
		shadow_item_cull_mask = value

@export var cor_luar: Color = Color(0.55, 0.65, 1.0)
@export var intensidade: float = 0.45
@export var raio_px: float = 140.0

const RESOLUCAO_TEXTURA: int = 256

func _ready() -> void:
	range_item_cull_mask = andar
	shadow_item_cull_mask = andar

	color = cor_luar
	energy = intensidade
	shadow_enabled = true
	shadow_filter = PointLight2D.SHADOW_FILTER_PCF5

	texture = _criar_textura_suave()
	texture_scale = raio_px / (RESOLUCAO_TEXTURA / 2.0)

func _criar_textura_suave() -> ImageTexture:
	var raio_maximo := float(RESOLUCAO_TEXTURA) / 2.0
	var centro := Vector2(raio_maximo, raio_maximo)
	var imagem := Image.create(RESOLUCAO_TEXTURA, RESOLUCAO_TEXTURA, false, Image.FORMAT_RGBA8)

	for x in range(RESOLUCAO_TEXTURA):
		for y in range(RESOLUCAO_TEXTURA):
			var distancia := Vector2(x, y).distance_to(centro)
			var fator := clampf(distancia / raio_maximo, 0.0, 1.0)
			# Queda suave (mais larga e macia que o cone da lanterna, pra
			# parecer uma luz ambiente difusa, não um facho focado).
			var intensidade_pixel := 1.0 - pow(fator, 1.8)
			if intensidade_pixel > 0.0:
				imagem.set_pixel(x, y, Color(1.0, 1.0, 1.0, intensidade_pixel))
			else:
				imagem.set_pixel(x, y, Color.TRANSPARENT)

	return ImageTexture.create_from_image(imagem)
