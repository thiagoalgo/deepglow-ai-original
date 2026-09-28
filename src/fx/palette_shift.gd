class_name PaletteShift
extends RefCounted
## Palette-step darkening shared by the night cycle and the intro: feeds
## night_shift.gdshader with the palette and each color's next darker color.
## Set the material's `level` (0-4, fractions dissolve with a dither) to darken.

## Palette color -> next darker color in its ramp. Glowing colors (neon teal,
## glow green, cyan, lights) keep their value: they are the bioluminescence.
const DARKER: Dictionary[Color, Color] = {
	Palette.SHADOW_ABSOLUTE: Palette.SHADOW_ABSOLUTE,
	Palette.SHADOW_BLUEBLACK: Palette.SHADOW_BLUEBLACK,
	Palette.SHADOW_DEEP: Palette.SHADOW_DEEP,
	Palette.SHADOW_LIFTED: Palette.SHADOW_DEEP,
	Palette.STRUCTURE_DEEP_BLUE: Palette.SHADOW_LIFTED,
	Palette.STRUCTURE_INDIGO: Palette.STRUCTURE_DEEP_BLUE,
	Palette.STRUCTURE_MID_BLUE: Palette.STRUCTURE_INDIGO,
	Palette.STRUCTURE_VIOLET: Palette.CHARACTER_OUTLINE,
	Palette.STRUCTURE_HIGHLIGHT: Palette.STRUCTURE_VIOLET,
	Palette.VEGETATION_SHADOW: Palette.SHADOW_DEEP,
	Palette.VEGETATION_MOSS: Palette.VEGETATION_SHADOW,
	Palette.VEGETATION_NEON_TEAL: Palette.VEGETATION_NEON_TEAL,
	Palette.VEGETATION_GLOW_GREEN: Palette.VEGETATION_GLOW_GREEN,
	Palette.WATER_ABYSS: Palette.SHADOW_LIFTED,
	Palette.WATER_MIDTONE: Palette.WATER_ABYSS,
	Palette.WATER_ELECTRIC_BLUE: Palette.WATER_MIDTONE,
	Palette.WATER_CYAN: Palette.WATER_CYAN,
	Palette.LIGHT_SULFUR_YELLOW: Palette.LIGHT_SULFUR_YELLOW,
	Palette.LIGHT_AMBER: Palette.LIGHT_AMBER,
	Palette.LIGHT_PINK: Palette.LIGHT_PINK,
	Palette.LIGHT_BLUE_WHITE: Palette.LIGHT_BLUE_WHITE,
	Palette.CHARACTER_OUTLINE: Palette.SHADOW_LIFTED,
	Palette.CHARACTER_MIDTONE: Palette.STRUCTURE_VIOLET,
	Palette.CHARACTER_HIGHLIGHT: Palette.CHARACTER_MIDTONE,
}


## Prepares a ShaderMaterial using night_shift.gdshader (level 0 = unchanged).
static func setup(material: ShaderMaterial) -> void:
	var colors: Array[Color] = DARKER.keys()
	var palette := PackedVector3Array()
	var darker := PackedInt32Array()
	for color: Color in colors:
		palette.append(Vector3(color.r, color.g, color.b))
		darker.append(colors.find(DARKER[color]))
	material.set_shader_parameter(&"palette", palette)
	material.set_shader_parameter(&"darker", darker)
	material.set_shader_parameter(&"level", 0.0)
