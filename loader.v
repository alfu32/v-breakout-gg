module main

import gx
import physics

const u = 8

const cell_w = 2 * u

const cell_h = 2 * u
const speed_init = physics.Vec2{.1, -.1}
const speed_limit = physics.Vec2{1.7, 1.7}
const speed_increase = physics.Vec2{1.01, 1.01}

pub fn make_ball(pos physics.Vec2, id string) physics.Primitive {
	return physics.Primitive{
		id:       id
		kind:     .wall
		position: physics.Vec2{pos.x, pos.y}
		size:     physics.Vec2{cell_w, cell_h}
		color:    gx.light_gray
	}
}

fn on_hit_brick_ball(mut self physics.Primitive, mut ball physics.Primitive, mut engine physics.PhysicsEngine) {
	if ball.kind == .ball {
		engine.ids_to_remove << self.id
		engine.score += 10
		new_speed := engine.velocities[ball.id].mul2(speed_increase).clamp(speed_limit)
		engine.velocities[ball.id] = new_speed
	}
}

fn on_special_brick_hit(mut self physics.Primitive, mut ball physics.Primitive, mut engine physics.PhysicsEngine) {
	if ball.kind == .ball {
		new_speed := engine.velocities[ball.id].mul2(speed_increase).clamp(speed_limit)
		engine.velocities[ball.id] = new_speed
	}
	if self.color.b > 40 {
		self.kind = .ball
		self.color = gx.orange
		self.position = ball.position.copy()
		self.size = physics.Vec2{u, u}
		self.on_is_hit = physics.void_hit_fn
		engine.velocities[self.id] = engine.velocities[ball.id].copy()
		engine.score += 50
	} else {
		self.color.b = (self.color.b + 20)
		engine.score += 5
	}
}

fn on_hard_brick_hit(mut self physics.Primitive, mut ball physics.Primitive, mut engine physics.PhysicsEngine) {
	if ball.kind == .ball {
		if self.color.r > 40 {
			engine.ids_to_remove << self.id
			engine.score += 100
			new_speed := engine.velocities[ball.id].mul2(speed_increase).clamp(speed_limit)
			engine.velocities[ball.id] = new_speed
		} else {
			self.color.r = (self.color.r + 20)
			self.color.g = (self.color.g + 20)
			self.color.b = (self.color.b + 20)
			new_speed := engine.velocities[ball.id].mul2(speed_increase).clamp(speed_limit)
			engine.velocities[ball.id] = new_speed
		}
		engine.score += 10
	}
}

fn on_paddle_hit(mut self physics.Primitive, mut ball physics.Primitive, mut engine physics.PhysicsEngine) {
	if ball.kind == .ball {
		// engine.ids_to_remove << self.id
		// engine.score += 10
		new_speed := engine.velocities[ball.id].mul2(speed_increase).clamp(speed_limit)
		engine.velocities[ball.id] = new_speed
	}
}

pub fn parse_ascii_map(input string) []physics.Primitive {
	mut primitives := []physics.Primitive{}
	lines := input.split_into_lines()

	mut id_count := 0
	for row, line in lines {
		for col, ch in line.runes() {
			x := f32(col * cell_w)
			y := f32(row * cell_h)

			match ch {
				`W` {
					primitives << physics.Primitive{
						id:       'wall_${id_count++}'
						kind:     .wall
						position: physics.Vec2{x, y}
						size:     physics.Vec2{cell_w, cell_h}
						color:    gx.light_gray
					}
				}
				`B` {
					primitives << physics.Primitive{
						id:        'brick_${id_count++}'
						kind:      .brick
						position:  physics.Vec2{x, y}
						size:      physics.Vec2{cell_w, cell_h}
						color:     gx.red
						on_is_hit: on_hit_brick_ball
					}
				}
				`Q` {
					primitives << physics.Primitive{
						id:        'brick_${id_count++}'
						kind:      .brick
						position:  physics.Vec2{x, y}
						size:      physics.Vec2{cell_w, cell_h}
						color:     gx.yellow
						on_is_hit: on_special_brick_hit
					}
				}
				`G` {
					primitives << physics.Primitive{
						id:        'brick_${id_count++}'
						kind:      .brick
						position:  physics.Vec2{x, y}
						size:      physics.Vec2{cell_w, cell_h}
						color:     gx.dark_green
						on_is_hit: on_hard_brick_hit
					}
				}
				`O` {
					primitives << physics.Primitive{
						id:       'ball_${id_count++}'
						kind:     .ball
						position: physics.Vec2{x + 2 * u, y + u}
						size:     physics.Vec2{u, u}
						color:    gx.orange
					}
				}
				`P` {
					primitives << physics.Primitive{
						id:        'paddle_${id_count++}'
						kind:      .paddle
						position:  physics.Vec2{x, y}
						size:      physics.Vec2{8 * u, 2 * u}
						color:     gx.light_gray
						on_is_hit: on_paddle_hit
					}
				}
				else {}
			}
		}
	}
	return primitives
}
