shader_type canvas_item;
// Draws a texture as a flat silhouette in `tint` (locked badges): every
// non-transparent pixel becomes the palette color, alpha stays as it is.
uniform vec4 tint : source_color = vec4(0.063, 0.102, 0.322, 1.0);

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	COLOR = vec4(tint.rgb, c.a);
}
