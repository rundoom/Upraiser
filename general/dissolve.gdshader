shader_type canvas_item;

uniform float dissolveState: hint_range(0.0, 1.0) = 0.5;
uniform sampler2D noise;
uniform vec3 border: source_color;
uniform float border_ticc: hint_range(0.0, 1.0) = 0.2;

void fragment() {
	vec4 textureColor = texture(TEXTURE, UV);
	float textureBrightness = texture(noise, UV).g;
	
	float dissolveDiff = 1.0;
//	if (dissolveState != 0.0){
		dissolveDiff = abs(textureBrightness - dissolveState);
//	};
	
	COLOR = textureColor;
	COLOR.rgb += border * step(dissolveDiff, border_ticc);
	COLOR.a *= step(dissolveState, textureBrightness);
}
