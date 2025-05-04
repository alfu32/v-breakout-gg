module breakout

import time
import math

fn aabb_collides(a Primitive, b Primitive) bool {
    return a.position.x < b.position.x + b.size.x &&
           a.position.x + a.size.x > b.position.x &&
           a.position.y < b.position.y + b.size.y &&
           a.position.y + a.size.y > b.position.y
}

@[heap]
pub struct PhysicsEngine {
    pub mut:
        primitives   map[string]Primitive
        velocities   map[string]Vec2
        running      bool
        score        int
        on_game_end  fn (string) = void_game_end
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
	println("running simulation loop")
    go e.simulation_loop()
}

pub fn (mut e PhysicsEngine) stop_simulation() {
    e.running = false
}

fn (mut e PhysicsEngine) simulation_loop() {
    for e.running {
        e.update_physics()
        time.sleep(16 * time.millisecond)
    }
}

fn (mut e PhysicsEngine) update_physics() {
    mut ids_to_remove := []string{}

    for id, mut ball in e.primitives {
        if ball.kind != .ball { continue }

        mut vel := e.velocities[id] or { Vec2{.5, -1.5} }
        mut new_pos := ball.position
        new_pos.x += vel.x
        new_pos.y += vel.y

        if new_pos.x <= 0 || new_pos.x + ball.size.x >= 800 { vel.x = -vel.x }
        if new_pos.y <= 0 { vel.y = -vel.y }
        if new_pos.y > 600 {
            e.running = false
            e.on_game_end('lose')
            return
        }

        mut pseudo_ball := ball
        pseudo_ball.position = new_pos

        for pid, other in e.primitives {
            if pid == id { continue }
            if !aabb_collides(pseudo_ball, other) { continue }
			center_diff_x := (pseudo_ball.position.x + pseudo_ball.size.x / 2) - (other.position.x + other.size.x / 2)
			center_diff_y := (pseudo_ball.position.y + pseudo_ball.size.y / 2) - (other.position.y + other.size.y / 2)

            if other.kind == .paddle {
				sx:=math.abs(2*center_diff_x/other.size.x)
				sy:=math.abs(2*center_diff_y/other.size.y)
                vel.x = f32(math.max(sx,0.8)*math.sign(center_diff_x))
				vel.y = f32(math.max(sy,0.2)*math.sign(center_diff_y))
            }
			if other.kind == .wall || other.kind == .brick {
				if pseudo_ball.position.y >= (other.position.y + other.size.y)
					|| (pseudo_ball.position.y + pseudo_ball.size.y) <= other.position.y {
					vel.y = -vel.y
				} else {
					vel.x = -vel.x
				}
			}
			if other.kind == .brick {
				ids_to_remove << pid
				e.score += 10
			}
			break
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
            e.velocities[p.id] = Vec2{1, -1}
        }
    }
}
