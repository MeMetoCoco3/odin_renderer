package main

import "core:fmt"


main :: proc() {
	vertices: [6]vec3_t = {
		{600.0, 200.0, 0}, //0
		{500.0, 400.0, 0}, //1
		{700.0, 400.0, 0}, //2
		{400.0, 600.0, 0}, //3 
		{600.0, 600.0, 0}, //4
		{800.0, 600.0, 0}, //5
	}

	add_triangle(
		triangle_new(vertices[1], vertices[0], vertices[2], cast_u32_to_color(u32(Color.RED))),
	)
	add_triangle(
		triangle_new(vertices[1], vertices[4], vertices[3], cast_u32_to_color(u32(Color.GREEN))),
	)
	add_triangle(
		triangle_new(vertices[2], vertices[5], vertices[4], cast_u32_to_color(u32(Color.BLUE))),
	)


	init_window()

	for (is_running()) {
		get_input()
		update()
		render()
	}
}
