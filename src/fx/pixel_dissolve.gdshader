shader_type canvas_item;
// Pixel dissolve (same ordered dither as night_shift.gdshader): the node is drawn
// only where the 4x4 Bayer threshold of its screen cell is below `progress`, so
// an image layered on top of another replaces it pixel by pixel (0 = hidden,
// 1 = fully shown). No alpha blending: every pixel is either old or new.

uniform float progress : hint_range(0.0, 1.0) = 0.0;
// Cell size in screen pixels (2 = one background art pixel).
uniform float cell_size = 2.0;

const float BAYER[16] = float[](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0,
	3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

void fragment() {
	vec2 cell = floor(FRAGCOORD.xy / cell_size);
	int bx = int(mod(cell.x, 4.0));
	int by = int(mod(cell.y, 4.0));
	float threshold = (BAYER[by * 4 + bx] + 0.5) / 16.0;
	if (progress < threshold) {
		discard;
	}
	COLOR = texture(TEXTURE, UV);
}
