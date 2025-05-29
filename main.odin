package main

import "core:fmt"


main :: proc() {
	vertices: [3]vec3_t = {{100, 200, 0}, {200, 280, 0}, {30, 500, 0}}

	add_triangle(triangle_new(vertices[0], vertices[1], vertices[2]))


	init_window()

	for (is_running()) {
		get_input()
		update()
		render()
	}
}
