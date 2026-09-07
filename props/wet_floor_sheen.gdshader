shader_type canvas_item;

// --- Piso encerado/molhado ---
// Não reflete nada de verdade (Player, cenário) — é só um brilho diagonal
// que varre a área devagar, dando a impressão de luz batendo num piso
// polido.
//
// Pensado pra ir no "material" de uma TileMapLayer inteira (não num sprite
// avulso): por isso usa posição no MUNDO em vez de UV — UV, numa
// TileMapLayer, é por-tile (0 a 1 dentro de cada célula), então a faixa
// repetiria dentro de cada tile em vez de varrer a poça inteira de forma
// contínua, não importa de quantos tiles ela seja feita.

uniform float speed : hint_range(0.0, 2.0) = 0.25;
uniform float band_width : hint_range(0.02, 1.0) = 0.18;
uniform float intensity : hint_range(0.0, 3.0) = 0.8;
uniform float scale : hint_range(0.001, 0.1) = 0.02; // quão "larga" a faixa fica no mundo (px)
uniform vec4 sheen_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

varying vec2 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	// Não lê a textura embaixo pra nada além do formato/tamanho — o
	// resultado é só o brilho, transparente fora da faixa, então o tile de
	// chão de verdade continua aparecendo normalmente por baixo.
	float diag = (world_pos.x + world_pos.y) * scale;
	float t = fract(diag - TIME * speed);
	float band = smoothstep(0.0, band_width, t) * smoothstep(band_width * 2.0, band_width, t);

	COLOR = vec4(sheen_color.rgb, band * intensity * sheen_color.a);
}
