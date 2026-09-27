shader_type canvas_item;
// Soft CRT look applied at the window resolution to the 640x360 game image
// (drawn by the SubViewportContainer in src/main/app.tscn). When `enabled` is
// false the image passes through untouched (crisp, integer-scaled pixels).

uniform bool enabled = true;
// Barrel distortion ("slightly curved tube"). 0 = flat.
uniform float curvature : hint_range(0.0, 0.2) = 0.02;
// Darkening between the rows of game pixels.
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.34;
// Darker screen edges.
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.28;
// Red/blue offset in game pixels (very small colour fringing).
uniform float chroma_offset : hint_range(0.0, 1.0) = 0.25;
// Rounded tube corners, as a fraction of the screen height.
uniform float corner_radius : hint_range(0.0, 0.2) = 0.025;
// Compensates the average darkening of scanlines + vignette.
uniform float brightness : hint_range(0.5, 1.5) = 1.14;
uniform vec2 source_size = vec2(640.0, 360.0);

vec2 warp(vec2 uv) {
	vec2 c = uv * 2.0 - 1.0;
	c *= 1.0 + curvature * (c.yx * c.yx);
	return c * 0.5 + 0.5;
}

float corner_mask(vec2 uv) {
	// Rounded-rectangle mask in screen units (aspect-corrected), 1 inside.
	vec2 aspect = vec2(source_size.x / source_size.y, 1.0);
	vec2 p = abs(uv - 0.5) * aspect;
	vec2 half_size = 0.5 * aspect - vec2(corner_radius);
	vec2 q = max(p - half_size, vec2(0.0));
	float d = length(q) - corner_radius;
	return 1.0 - smoothstep(-0.002, 0.002, d);
}

void fragment() {
	if (!enabled) {
		COLOR = texture(TEXTURE, UV);
	} else {
		vec2 uv = warp(UV);
		if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
			COLOR = vec4(0.0, 0.0, 0.0, 1.0);
		} else {
			vec2 px = vec2(chroma_offset / source_size.x, 0.0);
			vec3 col;
			col.r = texture(TEXTURE, uv + px).r;
			col.g = texture(TEXTURE, uv).g;
			col.b = texture(TEXTURE, uv - px).b;
			// Scanlines: each game-pixel row is a little darker at its top/bottom edge.
			float row = fract(uv.y * source_size.y);
			col *= 1.0 - scanline_strength * pow(abs(row - 0.5) * 2.0, 2.0);
			// Vignette.
			vec2 d = uv - 0.5;
			col *= 1.0 - vignette_strength * dot(d, d) * 2.0;
			col *= brightness;
			COLOR = vec4(col * corner_mask(uv), 1.0);
		}
	}
}
