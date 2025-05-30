package main


color_t :: struct {
	r: u8,
	g: u8,
	b: u8,
	a: u8,
}

Color :: enum u32 {
	BLUE     = 0xFF0000FF,
	RED      = 0xFFFF0000,
	GREEN    = 0xFF00FF00,
	GUNMETAL = 0xFF132E32,
}

cast_color_to_u32 :: proc(color: color_t) -> u32 {
	return (u32(0xFF) << 24) | (u32(color.r) << 16) | (u32(color.g) << 8) | u32(color.b)
}

cast_u32_to_color :: proc(color: u32) -> color_t {
	return color_t {
		a = u8((color >> 24) & 0xFF),
		r = u8((color >> 16) & 0xFF),
		g = u8((color >> 8) & 0xFF),
		b = u8((color) & 0xFF),
	}
}
