shader_type canvas_item;
// Palette-safe darkening for the night cycle (src/fx/night_cycle.gd).
// Every pixel is matched to the closest of the 24 palette colors, then walked
// `level` steps down its ramp through the `darker` index table. The fractional
// part of `level` is resolved with a 4x4 ordered dither on `dither_size` blocks,
// so a transition is a crisp pixel dissolve and the output is always a palette color.

uniform float level : hint_range(0.0, 4.0) = 0.0;
uniform vec3 palette[24];
uniform int darker[24];
// Size of one art pixel in texture pixels (the background is drawn at 2x).
uniform float dither_size = 2.0;

const float BAYER[16] = float[](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0,
	3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

int closest(vec3 c) {
	int best = 0;
	float best_d = 1e9;
	for (int i = 0; i < 24; i++) {
		vec3 diff = c - palette[i];
		float d = dot(diff, diff);
		if (d < best_d) {
			best_d = d;
			best = i;
		}
	}
	return best;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	int steps = int(floor(level));
	vec2 cell = floor(UV / TEXTURE_PIXEL_SIZE / dither_size);
	int bx = int(mod(cell.x, 4.0));
	int by = int(mod(cell.y, 4.0));
	float threshold = (BAYER[by * 4 + bx] + 0.5) / 16.0;
	if (fract(level) > threshold) {
		steps += 1;
	}
	int index = closest(tex.rgb);
	for (int s = 0; s < 4; s++) {
		if (s < steps) {
			index = darker[index];
		}
	}
	COLOR = vec4(palette[index], tex.a);
}
