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

fn collides_rect_circ(re Primitive, ci Primitive) bool {
	return re.position.x <= ci.position.x + ci.size.x && re.position.x + re.size.x >= ci.position.x
		&& re.position.y <= ci.position.y + ci.size.y && re.position.y + re.size.y >= ci.position.y
}

fn collides_circ_circ(aa Primitive, bb Primitive) bool {
	sz1 := aa.size.x / 2
	c1 := Vec2{aa.position.x + sz1, aa.position.y + sz1}
	sz2 := bb.size.x / 2
	c2 := Vec2{bb.position.x + sz2, bb.position.y + sz2}
	d2 := (c1.x - c2.x) * (c1.x - c2.x) + (c1.y - c2.y) * (c1.y - c2.y)
	return d2 <= (sz1 + sz2) * (sz1 + sz2)
}

fn aabb_collides(a Primitive, b Primitive) bool {
	return collides_rect_rect(a, b)
	// return match a.kind {
	// 	.paddle{match a.kind {
	// 		.paddle{rect_rect(a,b)}
	// 		.ball {rect_circ(a,b)}
	// 		.brick {rect_rect(a,b)}
	// 		.wall {rect_rect(a,b)}
	// 	}}
	// 	.ball {match a.kind {
	// 		.paddle{rect_circ(b,a)}
	// 		.ball {circ_circ(b,a)}
	// 		.brick {rect_circ(b,a)}
	// 		.wall {rect_circ(b,a)}
	// 	}}
	// 	.brick {match a.kind {
	// 		.paddle{rect_rect(a,b)}
	// 		.ball {rect_circ(a,b)}
	// 		.brick {rect_rect(a,b)}
	// 		.wall {rect_rect(a,b)}
	// 	}}
	// 	.wall {match a.kind {
	// 		.paddle{rect_rect(a,b)}
	// 		.ball {rect_circ(a,b)}
	// 		.brick {rect_rect(a,b)}
	// 		.wall {rect_rect(a,b)}
	// 	}}
	// }
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

fn (col CollisionPair) resolve_precise_collision(velocity Vec2) (Vec2, Vec2) {
	ball := col.a
	brick := col.b
	ball_pos := ball.position
	ball_size := ball.size
	brick_pos := brick.position
	brick_size := brick.size
	// Compute ball AABB min/max
	ball_min := ball_pos.copy()
	ball_max := ball_pos + ball_size

	// Compute brick AABB min/max
	brick_min := brick_pos.copy()
	brick_max := brick_pos + brick_size

	// Avoid division by zero
	inv_dx := if velocity.x != 0 {
		1.0 / velocity.x
	} else {
		print('velocity.x is 0')
		1
	}
	inv_dy := if velocity.y != 0 {
		1.0 / velocity.y
	} else {
		print('velocity.y is 0')
		1
	}

	// Compute entry and exit times
	mut tx_entry := (if velocity.x > 0 {
		brick_min.x - ball_max.x
	} else {
		brick_max.x - ball_min.x
	}) * inv_dx

	mut ty_entry := (if velocity.y > 0 {
		brick_min.y - ball_max.y
	} else {
		brick_max.y - ball_min.y
	}) * inv_dy

	mut tx_exit := (if velocity.x > 0 {
		brick_max.x - ball_min.x
	} else {
		brick_min.x - ball_max.x
	}) * inv_dx

	mut ty_exit := (if velocity.y > 0 {
		brick_max.y - ball_min.y
	} else {
		brick_min.y - ball_max.y
	}) * inv_dy

	entry_time := f32(math.max(tx_entry, ty_entry))
	exit_time := f32(math.min(tx_exit, ty_exit))

	// No collision if times invalid
	if entry_time > exit_time || (tx_entry < 0 && ty_entry < 0) || tx_entry > 1.0 || ty_entry > 1.0 {
		// no collision — move full frame
		println('no collision — move full frame')
		return ball_pos + velocity, velocity
	}

	// Position at collision time
	// After entry_time is known and new_vel is computed
	mut final_pos := ball_pos

	if tx_entry > ty_entry {
		// horizontal hit → resolve x
		if velocity.x > 0 {
			final_pos.x = brick_pos.x - ball_size.x
		} else {
			final_pos.x = brick_pos.x + brick_size.x
		}
		final_pos.y += velocity.y * entry_time
	} else {
		// vertical hit → resolve y
		if velocity.y > 0 {
			final_pos.y = brick_pos.y - ball_size.y
		} else {
			final_pos.y = brick_pos.y + brick_size.y
		}
		final_pos.x += velocity.x * entry_time
	}

	mut new_vel := velocity.copy()
	if tx_entry > ty_entry {
		new_vel.x = -velocity.x
	} else {
		new_vel.y = -velocity.y
	}

	return final_pos, new_vel
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

fn (mut e PhysicsEngine) update_physics2() {
	mut ids_to_remove := []string{}
	mut balls := e.primitives.values().filter(fn (it Primitive) bool {
		return it.kind == .ball
	})
	mut others := e.primitives.values().filter(fn (it Primitive) bool {
		return it.kind != .ball
	})
	mut collisions := map[string]CollisionPair{}
	for ball in balls {
		mut new_ball := ball.copy()
		mut vel := e.velocities[new_ball.id] or { Vec2{2, -2} }
		mut new_pos := ball.position
		new_pos.x += vel.x
		new_pos.y += vel.y

		if new_pos.x <= 0 || new_pos.x + new_ball.size.x >= e.size.x {
			vel.x = -vel.x
			e.velocities[new_ball.id] = vel
		}
		if new_pos.y <= 0 || new_pos.y + new_ball.size.y >= e.size.y {
			vel.y = -vel.y
			e.velocities[new_ball.id] = vel
		}
		// if new_pos.y <= 0 { vel.y = -vel.y }
		// if new_pos.y > e.size.y {
		// 	e.running = false
		// 	e.on_game_end('lose')
		// 	return
		// }
		for other in others {
			if collides_rect_rect(other, new_ball) {
				collisions['${new_ball.id}/${other.id}'] = CollisionPair{new_ball, other}
			}
		}
		new_ball.position = new_pos
		e.primitives[new_ball.id] = new_ball
	}
	// println ("balls : ${balls.len} others : ${others.len}")
	println('${collisions.len} collisions')

	for _, c in collisions {
		mut new_ball := c.a
		new_pos := new_ball.position
		mut vel := e.velocities[new_ball.id] or { Vec2{3, -3} }
		other := c.b
		print(other)
		// center_diff_x := (new_pos.x + new_ball.size.x / 2) - (other.position.x + other.size.x / 2)
		// center_diff_y := (new_pos.y + new_ball.size.y / 2) - (other.position.y + other.size.y / 2)

		if other.kind == .paddle {
			// center_diff := (new_ball.position.x + new_ball.size.x / 2) - (other.position.x + other.size.x / 2)
			// vel.x = math.sign(center_diff) * vel.x
			// vel.x =-vel.x
			// if vel.y < 0 {
			// 	if new_ball.position.y < other.position.y {
			// 		vel.y = -vel.y
			// 	} else if new_ball.position.y > (other.position.y + other.size.y) {
			// 		vel.y = -vel.y
			// 	} else {
			// 		new_ball.position.y
			// 	}
			// }
			vel.y = -vel.y
		} else if other.kind == .wall || other.kind == .brick {
			cba := Vec2{
				x: new_pos.x + new_ball.size.x / 2
				y: new_pos.y + new_ball.size.y / 2
			}
			cbri := Vec2{
				x: other.position.x + other.size.x / 2
				y: other.position.y + other.size.y / 2
			}
			diff := Vec2{
				x: cba.x - cbri.x
				y: cba.y - cbri.y
			}
			ang := i32((math.atan2(diff.y, diff.x) + 4 * math.pi) * 180 / math.pi) % 360
			alpha := i32(math.atan2(new_ball.size.y + other.size.y, new_ball.size.x + other.size.x) * 180 / math.pi) % 360
			if ang < alpha || ang > (360 - alpha) || (ang > (180 - alpha) && ang < (180 + alpha)) {
				vel.x = -vel.x
			} else {
				vel.y = -vel.y
			}
		}
		// if other.kind == .paddle {
		// 		vel.y=-vel.y
		// }
		if other.kind == .brick {
			ids_to_remove << other.id
			e.score += 10
		}
		// if other.kind == .wall {
		//	walls_to_transform << other.id
		//	e.score += 10
		//}
		e.velocities[new_ball.id] = vel
		if other.kind == .wall || other.kind == .brick || other.kind == .paddle {
			break
		}
	}

	for id in ids_to_remove {
		e.primitives.delete(id)
	}

	// for id in walls_to_transform {
	//	e.primitives[id].kind=.wall
	//}

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
