package main

import "core:fmt"
import sdl "vendor:sdl3"

vec2_t :: struct {
	x, y: int,
}

vec3_t :: struct {
	x, y, z: int,
}

triangle_t :: struct {
	vertices: [3]vec3_t,
}

FPS :: 60
FRAME_TARGET_TIME :: (1000 / FPS)
NUM_MESHES :: 20

triangles: [NUM_MESHES]triangle_t
triangle_count: int

window: ^sdl.Window
renderer: ^sdl.Renderer
running: bool

previous_frame_time: u64
w: i32
h: i32
color_buffer_size: i32
color_buffer: []u32
color_buffer_texture: ^sdl.Texture

init_window :: proc() -> bool {
	ok := sdl.Init(sdl.INIT_VIDEO | sdl.INIT_EVENTS);assert(ok)

	ds := sdl.GetCurrentDisplayMode(1);assert(ds != nil)
	w = ds.w
	h = ds.h

	window = sdl.CreateWindow("Title", w, h, sdl.WINDOW_BORDERLESS)
	renderer = sdl.CreateRenderer(window, nil);assert(renderer != nil)

	color_buffer_size = w * h

	color_buffer = make([]u32, w * h)

	color_buffer_texture = sdl.CreateTexture(
		renderer,
		sdl.PixelFormat.ARGB8888,
		sdl.TextureAccess.STREAMING,
		w,
		h,
	)
	assert(color_buffer_texture != nil)

	set_running_state(true)

	// TODO: SetFulllscreen
	return true
}

get_input :: proc() {
	event: sdl.Event
	for (sdl.PollEvent(&event)) {
		#partial switch (event.type) {
		case .QUIT:
			set_running_state(false)
		case .KEY_DOWN:
			if (event.key.scancode == .ESCAPE || event.key.scancode == .SPACE) {
				set_running_state(false)
			}
		}
	}
}


update :: proc() {
	time_to_wait := FRAME_TARGET_TIME - (sdl.GetTicks() - previous_frame_time)
	if time_to_wait > 0 && time_to_wait <= FRAME_TARGET_TIME {
		sdl.Delay(u32(time_to_wait))
	}

	delta_time := (sdl.GetTicks() - previous_frame_time) / 1000.0
	previous_frame_time = sdl.GetTicks()

	// DO SOMETHING

}

render :: proc() {
	clear_color_buffer(0xFFFFFF00)
	draw_grid_points(0xFF132E32)

	for i in 0 ..< triangle_count {
		fmt.println("triangling")
		v0 := vec2_from_vec3(triangles[i].vertices[0])
		v1 := vec2_from_vec3(triangles[i].vertices[1])
		v2 := vec2_from_vec3(triangles[i].vertices[2])

		draw_triangle_fill(v0, v1, v2, 0xFF00FF00)
	}
	render_color_buffer()
}

render_color_buffer :: proc() {
	sdl.UpdateTexture(color_buffer_texture, nil, raw_data(color_buffer), i32(size_of(u32) * w))
	sdl.RenderTexture(renderer, color_buffer_texture, nil, nil)
	sdl.RenderPresent(renderer)
}

vec2_from_vec3 :: proc(v: vec3_t) -> vec2_t {
	return vec2_t{v.x, v.y}
}

add_triangle :: proc(triangle: triangle_t) {
	triangles[triangle_count] = triangle
	triangle_count += 1

}

triangle_new :: proc(v0: vec3_t, v1: vec3_t, v2: vec3_t) -> triangle_t {
	return triangle_t{vertices = {v0, v1, v2}}
}

edge_cross :: proc(a: vec2_t, b: vec2_t, p: vec2_t) -> int {
	ab := vec2_t{b.x - a.x, b.y - a.y}
	ap := vec2_t{p.x - a.x, p.y - a.y}
	return ab.x * ap.y - ab.y * ap.x
}

draw_triangle_fill :: proc(v0: vec2_t, v1: vec2_t, v2: vec2_t, color: u32) {
	x_min := min(v0.x, v1.x, v2.x)
	x_max := max(v0.x, v1.x, v2.x)

	y_min := min(v0.y, v1.y, v2.y)
	y_max := max(v0.y, v1.y, v2.y)


	for y in y_min ..= y_max {
		for x in x_min ..= x_max {
			p := vec2_t{x, y}

			w0 := edge_cross(v1, v2, p)
			w1 := edge_cross(v2, v0, p)
			w2 := edge_cross(v0, v1, p)

			is_inside := w0 >= 0 && w1 >= 0 && w2 >= 0

			if is_inside {
				draw_pixel(x, y, color)
			}
		}
	}
}

draw_pixel :: proc(x, y: int, color: u32) {
	if x >= 0 && x < int(w) && y >= 0 && y < int(h) {
		color_buffer[x + y * int(w)] = color
	}
}

clear_color_buffer :: proc(color: u32) {
	for idx in 0 ..< color_buffer_size {
		color_buffer[idx] = color
	}
}

draw_grid_points :: proc(color: u32) {
	for y := 0; y < int(h); y += 10 {
		for x := 0; x < int(w); x += 10 {
			draw_pixel(x, y, color)
		}
	}
}

set_running_state :: proc(state: bool) {
	running = state
}

is_running :: proc() -> bool {
	return running
}
