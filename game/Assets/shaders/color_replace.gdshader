shader_type canvas_item;

// Generic hue-based color replacement for canvas sprites.
//
// Recolors one hue family of a sprite to a new color while keeping its shading.
// It selects every pixel whose hue sits inside a band (`band_center` +/-
// `band_width`) and is saturated enough to be "paint" rather than an outline
// (`min_saturation`), then remaps that band onto `recolor`. Each selected pixel
// keeps its original brightness AND its position within the hue ramp, so a
// shaded light -> dark gradient survives the swap. Everything else (other hues,
// dark outlines, greys, whites) is left untouched.
//
// Works on any sprite: point `source_hue` / `band_center` at the color you want
// to replace and set `recolor` to the new color. Used by the player/enemy bots
// and the portals from a single shared shader.

// Master switch. When false the sprite draws untouched.
uniform bool enabled = true;
// Target color. Its hue anchors the new ramp; `source_hue` is what maps onto it.
uniform vec4 recolor : source_color = vec4(0.27, 0.78, 0.36, 1.0);
// The hue in the SOURCE sprite that should land exactly on `recolor`'s hue.
// Every other selected pixel shifts relative to it, which preserves the ramp.
uniform float source_hue : hint_range(0.0, 1.0) = 0.14;

// --- which pixels count as recolorable ---
// Center of the hue band to replace.
uniform float band_center : hint_range(0.0, 1.0) = 0.05;
// Half-width of that band, in hue. Larger grabs more neighboring hues.
uniform float band_width : hint_range(0.0, 0.5) = 0.13;
// Softness of the band edge so anti-aliased pixels don't hard-clip.
uniform float band_softness : hint_range(0.0, 0.2) = 0.03;
// Pixels less saturated than this (near-black outlines, greys, whites) stay put.
uniform float min_saturation : hint_range(0.0, 1.0) = 0.18;

// --- how the new ramp is shaded ---
// 1.0 keeps the source's hue-shifted shadows (shadows drift toward a warmer or
// cooler hue). 0.0 flattens every shade to one solid hue.
uniform float shade_hue_shift : hint_range(0.0, 1.0) = 1.0;
// How far to pull saturation toward `recolor` (0 keeps the sprite's, 1 adopts it).
uniform float saturation_mix : hint_range(0.0, 1.0) = 0.6;

vec3 rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// Shortest distance between two hues, accounting for wrap-around at 0/1.
float hue_dist(float a, float b) {
	float d = abs(a - b);
	return min(d, 1.0 - d);
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (!enabled || tex.a < 0.001) {
		COLOR = tex;
	} else {
		vec3 hsv = rgb2hsv(tex.rgb);
		vec3 target = rgb2hsv(recolor.rgb);

		// Mask: inside the hue band AND saturated enough to be paint, not outline.
		float in_band = 1.0 - smoothstep(band_width, band_width + band_softness, hue_dist(hsv.x, band_center));
		float sat_mask = smoothstep(min_saturation, min_saturation + 0.08, hsv.y);
		float mask = in_band * sat_mask;

		// This pixel's signed hue offset from the source hue, wrapped to [-0.5, 0.5].
		float dh = hsv.x - source_hue;
		dh -= round(dh);
		// New hue = target hue plus a (scalable) share of the original offset, so
		// the ramp's hue-shift between highlight and shadow is preserved.
		float new_hue = fract(target.x + shade_hue_shift * dh);
		float new_sat = mix(hsv.y, target.y, saturation_mix);
		// Keep the sprite's own brightness (hsv.z) -> the shading gradient survives.
		vec3 swapped = hsv2rgb(vec3(new_hue, new_sat, hsv.z));

		COLOR = vec4(mix(tex.rgb, swapped, mask), tex.a);
	}
}
