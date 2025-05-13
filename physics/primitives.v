module physics

import strconv
import gx
import math

pub enum PrimitiveType {
	paddle
	ball
	brick
	wall
}

pub struct Vec2 {
pub mut:
	x f32
	y f32
}

const vec2_null = Vec2{f32(strconv.single_minus_infinity), f32(strconv.single_minus_infinity)}

pub fn (v Vec2) copy() Vec2 {
	return Vec2{
		x: v.x
		y: v.y
	}
}

pub fn (v Vec2) str() string {
	return '${v.x},${v.y}'
}

pub fn (v Vec2) equals(b Vec2) bool {
	return '${v.x},${v.y}' == '${b.x},${b.y}'
}

pub fn (v Vec2) + (b Vec2) Vec2 {
	return Vec2{v.x + b.x, v.y + b.y}
}

pub fn (v Vec2) - (b Vec2) Vec2 {
	return Vec2{v.x - b.x, v.y - b.y}
}

pub fn (v Vec2) len2() f32 {
	return v.dot(v)
}

pub fn (v Vec2) len() f32 {
	return math.sqrtf(v.len2())
}

pub fn (v Vec2) normalized() Vec2 {
	if v.len() == 0 {
		return Vec2{v.x, v.y}
	} else {
		return v.mul(1 / v.len())
	}
}

pub fn (v Vec2) mul(s f32) Vec2 {
	return Vec2{v.x * s, v.y * s}
}

pub fn (v Vec2) dot(b Vec2) f32 {
	return v.x * b.x + v.y * b.y
}

pub fn (v Vec2) cross(b Vec2) f32 {
	return v.x * b.y - v.y * b.x
}

pub fn (v Vec2) mul2(b Vec2) Vec2 {
	return Vec2{v.x * b.x, v.y * b.y}
}

pub fn (v Vec2) apply(fun fn (x f32) f32) Vec2 {
	return Vec2{fun(v.x), fun(v.y)}
}

pub fn (v Vec2) clamp(max_size Vec2) Vec2 {
	return Vec2{
		x: if math.abs(v.x) > max_size.x { f32(math.sign(v.x)) * max_size.x } else { v.x }
		y: if math.abs(v.y) > max_size.y { f32(math.sign(v.y)) * max_size.y } else { v.y }
	}
}

pub fn (v Vec2) sign() Vec2 {
	return Vec2{
		x: if v.x < 0 {
			-1
		} else if v.x > 0 {
			1
		} else {
			0
		}
		y: if v.y < 0 {
			-1
		} else if v.y > 0 {
			1
		} else {
			0
		}
	}
}

struct Segment {
pub mut:
	a Vec2
	b Vec2
}

pub fn (s Segment) delta() Vec2 {
	return s.b - s.a
}

pub fn (wall Segment) bounce(ball_trajectory Segment) (bool, Vec2, Vec2) {
	da := wall.delta()
	db := ball_trajectory.delta()
	dp := ball_trajectory.a - wall.a
	denom := da.cross(db)

	mut hit_point := vec2_null

	if denom != 0 {
		// println('denom not zero :: ${denom}')
		t := dp.cross(db) / denom
		w := dp.cross(da) / denom

		if t >= 0 && t <= 1 && w >= 0 && w <= 1 {
			hit_point = wall.a + da.mul(t)
		} else {
			return false, vec2_null, vec2_null
		}
	} else {
		return false, vec2_null, vec2_null
	}

	// project u.b (b1) onto s (segment s.a to s.b)
	da_len_sq := da.dot(da)
	if da_len_sq == 0 {
		return false, vec2_null, vec2_null // degenerate segment
	}

	// foot of perpendicular from u.b to s
	proj_factor := (ball_trajectory.b - wall.a).dot(da) / da_len_sq
	p := wall.a + da.mul(proj_factor)

	// reflected point across projection point p
	deflected_point := p.mul(2.0) - ball_trajectory.b

	return true, hit_point, deflected_point
}

pub type OnFrameFn = fn (mut self Primitive, mut engine PhysicsEngine) Primitive

pub fn void_frame_fn(mut self Primitive, mut engine PhysicsEngine) Primitive {
	return self
}

pub type OnHitFn = fn (mut self Primitive, mut other Primitive, mut engine PhysicsEngine)

pub fn void_hit_fn(mut self Primitive, mut other Primitive, mut engine PhysicsEngine) {}

pub struct Primitive {
pub mut:
	id           string
	kind         PrimitiveType
	position     Vec2
	size         Vec2
	color        gx.Color
	on_new_frame OnFrameFn = void_frame_fn
	on_is_hit    OnHitFn   = void_hit_fn
}

pub fn (p Primitive) copy() Primitive {
	return Primitive{
		id:       p.id
		kind:     p.kind
		position: p.position.copy()
		size:     p.size.copy()
	}
}

pub fn (p Primitive) corners() (Vec2, Vec2, Vec2, Vec2) {
	// Define brick sides as wall segments
	tl := p.position
	tr := Vec2{tl.x + p.size.x, tl.y}
	br := Vec2{tl.x + p.size.x, tl.y + p.size.y}
	bl := Vec2{tl.x, tl.y + p.size.y}

	return tl, tr, br, bl // left-left
}

pub fn (p Primitive) walls() [4]Segment {
	// Define brick sides as wall segments
	tl, tr, br, bl := p.corners()

	return [
		Segment{
			a: tl
			b: tr
		}, // top
		Segment{
			a: tr
			b: br
		}, // right
		Segment{
			a: br
			b: bl
		}, // bottom
		Segment{
			a: bl
			b: tl
		}, // left
	]!
}
