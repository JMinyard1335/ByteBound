shader_type canvas_item;

// Drifting atmospheric haze for a foggy night. Designed to be drawn on a
// full-screen ColorRect inside a CanvasLayer so it sits in screen space.

uniform vec4 fog_color : source_color = vec4(0.56, 0.62, 0.78, 1.0);
// Overall opacity of the haze. 0 = invisible, 1 = thick.
uniform float density : hint_range(0.0, 1.0) = 0.30;
// How the noise is scrolled over time (screen-space units per second-ish).
uniform vec2 scroll_speed = vec2(0.012, 0.004);
// Size of the noise features. Larger = finer/smaller fog wisps.
uniform float noise_scale : hint_range(0.5, 8.0) = 2.5;
// Vertical falloff so the haze is denser toward the bottom of the screen.
uniform float bottom_bias : hint_range(0.0, 1.0) = 0.35;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), u.x),
			   mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * value_noise(p);
		p *= 2.0;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 uv = UV * noise_scale;
	float n1 = fbm(uv + TIME * scroll_speed * 10.0);
	float n2 = fbm(uv * 1.7 - TIME * scroll_speed * 6.0);
	float f = clamp(n1 * 0.6 + n2 * 0.4, 0.0, 1.0);
	f = smoothstep(0.15, 0.85, f);
	// Thicker toward the bottom of the screen.
	float vbias = mix(1.0, UV.y, bottom_bias);
	COLOR = vec4(fog_color.rgb, f * density * vbias * fog_color.a);
}
