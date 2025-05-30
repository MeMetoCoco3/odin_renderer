package main

import "core:fmt"
import "core:math"
import sdl "vendor:sdl3"
vec2_t :: struct {
	x, y: f32,
}

vec3_t :: struct {
	x, y, z: f32,
}

triangle_t :: struct {
	vertices: [3]vec3_t,
	color:    color_t,
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

colors: [3]color_t


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


	colors[0].r = 0xFF
	colors[1].g = 0xFF
	colors[2].b = 0xFF

	// TODO: SetFulllscreen
	return true
}

get_input :: proc() {
	event: sdl.Event
	for (sdl.PollEvent(&event)) {
		#partial switch (event.type) {case .QUIT:
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
	clear_color_buffer(0xFF555555)
	draw_grid_points(cast_u32_to_color(u32(Color.GUNMETAL)))

	angle := f32(sdl.GetTicks()) / 1000.0 * 0.1
	center := vec3_t{600.0, 400.0, 0}

	for i in 0 ..< triangle_count {
		v0 := vec2_from_vec3(vec3_rotate(triangles[i].vertices[0], center, angle))
		v1 := vec2_from_vec3(vec3_rotate(triangles[i].vertices[1], center, angle))
		v2 := vec2_from_vec3(vec3_rotate(triangles[i].vertices[2], center, angle))

		draw_triangle_fill_gradient(v0, v1, v2)
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

triangle_new :: proc(v0: vec3_t, v1: vec3_t, v2: vec3_t, color: color_t) -> triangle_t {
	return triangle_t{{v0, v1, v2}, color}
}

edge_cross :: proc(a: vec2_t, b: vec2_t, p: vec2_t) -> f32 {
	ab := vec2_t{b.x - a.x, b.y - a.y}
	ap := vec2_t{p.x - a.x, p.y - a.y}
	return ab.x * ap.y - ab.y * ap.x
}

draw_triangle_fill :: proc(v0: vec2_t, v1: vec2_t, v2: vec2_t, color: color_t) {

	x_min := math.floor(min(v0.x, v1.x, v2.x))
	x_max := math.ceil(max(v0.x, v1.x, v2.x))
	y_min := math.floor(min(v0.y, v1.y, v2.y))
	y_max := math.ceil(max(v0.y, v1.y, v2.y))

	delta_w0_col := (v1.y - v2.y)
	delta_w1_col := (v2.y - v0.y)
	delta_w2_col := (v0.y - v1.y)

	delta_w0_row := (v2.x - v1.x)
	delta_w1_row := (v0.x - v2.x)
	delta_w2_row := (v1.x - v0.x)

	area := edge_cross(v0, v1, v2)

	bias0 := is_top_left(v1, v2) ? 0 : -1
	bias1 := is_top_left(v2, v0) ? 0 : -1
	bias2 := is_top_left(v0, v1) ? 0 : -1

	p0 := vec2_t{x_min + 0.5, y_min + 0.5}
	w0_row := edge_cross(v1, v2, p0) + f32(bias0)
	w1_row := edge_cross(v2, v0, p0) + f32(bias1)
	w2_row := edge_cross(v0, v1, p0) + f32(bias2)

	for y in y_min ..= y_max {
		w0 := w0_row
		w1 := w1_row
		w2 := w2_row
		for x in x_min ..= x_max {
			is_inside := w0 >= 0 && w1 >= 0 && w2 >= 0

			if is_inside {
				draw_pixel(x, y, color)
			}
			w0 += delta_w0_col
			w1 += delta_w1_col
			w2 += delta_w2_col
		}
		w0_row += delta_w0_row
		w1_row += delta_w1_row
		w2_row += delta_w2_row
	}
}


draw_triangle_fill_gradient :: proc(v0: vec2_t, v1: vec2_t, v2: vec2_t) {
	x_min := math.floor(min(v0.x, v1.x, v2.x))
	x_max := math.ceil(max(v0.x, v1.x, v2.x))
	y_min := math.floor(min(v0.y, v1.y, v2.y))
	y_max := math.ceil(max(v0.y, v1.y, v2.y))


	delta_w0_col := (v1.y - v2.y)
	delta_w1_col := (v2.y - v0.y)
	delta_w2_col := (v0.y - v1.y)

	delta_w0_row := (v2.x - v1.x)
	delta_w1_row := (v0.x - v2.x)
	delta_w2_row := (v1.x - v0.x)

	area := edge_cross(v0, v1, v2)

	bias0 := is_top_left(v1, v2) ? 0 : -1
	bias1 := is_top_left(v2, v0) ? 0 : -1
	bias2 := is_top_left(v0, v1) ? 0 : -1

	p0 := vec2_t{x_min + 0.5, y_min + 0.5}
	w0_row := edge_cross(v1, v2, p0) + f32(bias0)
	w1_row := edge_cross(v2, v0, p0) + f32(bias1)
	w2_row := edge_cross(v0, v1, p0) + f32(bias2)

	for y in y_min ..= y_max {
		w0 := w0_row
		w1 := w1_row
		w2 := w2_row
		for x in x_min ..= x_max {
			is_inside := w0 >= 0 && w1 >= 0 && w2 >= 0

			if is_inside {
				alpha := f32(w0) / f32(area)
				beta := f32(w1) / f32(area)
				gamma := f32(w2) / f32(area)

				final_color := color_t {
					r = u8(
						f32(colors[0].r) * alpha +
						f32(colors[1].r) * beta +
						f32(colors[2].r) * gamma,
					),
					g = u8(
						f32(colors[0].g) * alpha +
						f32(colors[1].g) * beta +
						f32(colors[2].g) * gamma,
					),
					b = u8(
						f32(colors[0].b) * alpha +
						f32(colors[1].b) * beta +
						f32(colors[2].b) * gamma,
					),
					a = 0xFF,
				}
				draw_pixel(x, y, final_color)
			}
			w0 += delta_w0_col
			w1 += delta_w1_col
			w2 += delta_w2_col
		}
		w0_row += delta_w0_row
		w1_row += delta_w1_row
		w2_row += delta_w2_row
	}
}


is_top_left :: proc(start, end: vec2_t) -> bool {
	edge := vec2_t{end.x - start.x, end.y - start.y}

	is_top := edge.y == 0 && edge.x > 0
	is_left := edge.y < 0

	return is_top || is_left
}


draw_pixel :: proc(x, y: f32, color: color_t) {
	if x >= 0 && x < f32(w) && y >= 0 && y < f32(h) {
		color_buffer[int(x + (y * f32(w)))] = cast_color_to_u32(color)
	}
}

clear_color_buffer :: proc(color: u32) {
	for idx in 0 ..< color_buffer_size {
		color_buffer[idx] = color
	}
}

draw_grid_points :: proc(color: color_t) {
	for y := 0; y < int(h); y += 10 {
		for x := 0; x < int(w); x += 10 {
			draw_pixel(f32(x), f32(y), color)
		}
	}
}

set_running_state :: proc(state: bool) {
	running = state
}

is_running :: proc() -> bool {
	return running
}

//Vec2 ignoring Z
vec3_rotate :: proc(v: vec3_t, pivot: vec3_t, angle: f32) -> vec3_t {
	rot: vec3_t
	vect := v
	vect.x -= pivot.x
	vect.y -= pivot.y
	rot.x = vect.x * math.cos(angle) - vect.y * math.sin(angle)
	rot.y = vect.x * math.sin(angle) + vect.y * math.cos(angle)
	rot.x += pivot.x
	rot.y += pivot.y
	rot.z = v.z
	return rot
}
