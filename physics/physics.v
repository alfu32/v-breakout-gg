module physics

import time
import math

struct CollisionPair {
pub mut:
	a Primitive
	b Primitive
}

fn collides_rect_rect(aa Primitive, bb Primitive) bool {
	return aa.position.x <= bb.position.x + bb.size.x && aa.position.x + aa.size.x >= bb.position.x
		&& aa.position.y <= bb.position.y + bb.size.y && aa.position.y + aa.size.y >= bb.position.y
}

fn aabb_collides(a Primitive, b Primitive) bool {
	return collides_rect_rect(a, b)
}

fn bounce(brick Primitive, ball_p_0 Vec2, speed_unit Vec2) (bool, Vec2, Vec2) {
	ball_p_1 := ball_p_0 + speed_unit
	ball_seg := Segment{
		a: ball_p_0
		b: ball_p_1
	}

	walls := brick.walls()

	for wall in walls {
		hit, hit_point, deflected := wall.bounce(ball_seg)
		if hit {
			new_speed := (deflected - hit_point).sign().mul2(speed_unit.apply(f32_abs))

			return true, deflected, new_speed
		}
	}
	return false, ball_p_1, Vec2{}
}

@[heap]
pub struct PhysicsEngine {
pub mut:
	primitives  map[string]Primitive
	velocities  map[string]Vec2
	running     bool
	score       int
	energy      int
	size        Vec2
	on_game_end fn (string) = void_game_end
}

fn void_game_end(_ string) {}

pub fn (mut e PhysicsEngine) set_game_end_callback(cb fn (string)) {
	e.on_game_end = cb
}

pub fn (mut e PhysicsEngine) get_state() []Primitive {
	return e.primitives.values()
}

pub fn (mut e PhysicsEngine) accept_update(p Primitive, new Primitive, cb fn (string, Primitive)) {
	if p.id !in e.primitives {
		cb('not found', p)
		return
	}
	e.primitives[p.id] = new
	cb('', new)
}

pub fn (mut e PhysicsEngine) start_simulation() {
	e.running = true
	println('running simulation loop')
	go e.simulation_loop()
}

pub fn (mut e PhysicsEngine) stop_simulation() {
	e.running = false
}

fn (mut e PhysicsEngine) simulation_loop() {
	for e.running {
		e.update_physics()
		time.sleep(1 * time.millisecond)
	}
}

fn (mut e PhysicsEngine) update_physics() {
	mut ids_to_remove := []string{}

	for id, mut ball in e.primitives {
		if ball.kind != .ball {
			continue
		}

		mut vel := e.velocities[id] or { Vec2{1, -1} }
		mut new_pos := ball.position
		new_pos.x += vel.x
		new_pos.y += vel.y

		if new_pos.x <= 0 || new_pos.x + ball.size.x >= e.size.x {
			vel.x = -vel.x
			e.velocities[ball.id] = vel
			e.velocities[id] = vel
			e.primitives[id] = ball
			return
		}
		if new_pos.y <= 0 || new_pos.y + ball.size.y >= e.size.y {
			vel.y = -vel.y
			e.velocities[ball.id] = vel
			e.velocities[id] = vel
			e.primitives[id] = ball
			return
		}
		// if new_pos.y > e.size.y {
		// 	e.running = false
		// 	e.on_game_end('lose')
		// 	return
		// }

		mut pseudo_ball := ball.copy()
		pseudo_ball.position = new_pos

		for pid, other in e.primitives {
			if pid == id {
				continue
			}
			if !aabb_collides(pseudo_ball, other) {
				continue
			}
			bounces, ball_pos_1, vel_1 := bounce(other, ball.position, vel)
			if bounces {
				if other.kind == .brick {
					ids_to_remove << pid
					e.score += 10
				} else if other.kind == .paddle {
					// center_diff := (pseudo_ball.position.x + pseudo_ball.size.x / 2) - (other.position.x + other.size.x / 2)
					// vel.x += center_diff * 0.05
					e.energy -= 10
				}
				new_pos = ball_pos_1
				vel = vel_1
				ball.position = new_pos
				e.velocities[id] = vel
				e.primitives[id] = ball
				break
			}
		}
		ball.position = new_pos
		e.velocities[id] = vel
		e.primitives[id] = ball
	}

	for id in ids_to_remove {
		e.primitives.delete(id)
	}

	if e.primitives.values().filter(it.kind == .brick).len == 0 {
		e.running = false
		e.on_game_end('win')
	}
}

pub fn (mut e PhysicsEngine) add_all(prims []Primitive) {
	for p in prims {
		e.primitives[p.id] = p
		if p.kind == .ball {
			e.velocities[p.id] = Vec2{.1, -.1}
		}
	}
}
