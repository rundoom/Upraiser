shader_type canvas_item;

uniform float dissolveState: hint_range(0.0, 1.0) = 0.5;
uniform sampler2D noise;
uniform vec3 border: source_color;
uniform float border_ticc: hint_range(0.0, 1.0) = 0.2;

void fragment() {
	vec4 textureColor = texture(TEXTURE, UV);
//	float textureBrightness = (textureColor.r + textureColor.g + textureColor.b) / 3.0;
	float textureBrightness = texture(noise, UV).r;
//	vec4 gradientColor = texture(gradient, vec2(textureBrightness - dissolveState));
	COLOR = textureColor;
	float dissolveDiff = abs(textureBrightness - dissolveState);
//	COLOR = gradientColor;
	COLOR.rgb += border * step(dissolveDiff, border_ticc);
	COLOR.a *= step(dissolveState, textureBrightness);
}
