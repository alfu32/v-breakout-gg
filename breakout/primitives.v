module breakout

import strconv

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

fn (v Vec2) + (b Vec2) Vec2 {
	return Vec2{v.x + b.x, v.y + b.y}
}

fn (v Vec2) - (b Vec2) Vec2 {
	return Vec2{v.x - b.x, v.y - b.y}
}

fn (v Vec2) mul(s f32) Vec2 {
	return Vec2{v.x * s, v.y * s}
}

fn (v Vec2) dot(b Vec2) f32 {
	return v.x * b.x + v.y * b.y
}

fn (v Vec2) cross(b Vec2) f32 {
	return v.x * b.y - v.y * b.x
}

fn (v Vec2) mul2(b Vec2) Vec2 {
	return Vec2{v.x * b.x, v.y * b.y}
}

fn (v Vec2) apply(fun fn (x f32) f32) Vec2 {
	return Vec2{fun(v.x), fun(v.y)}
}

fn (v Vec2) sign() Vec2 {
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

fn (s Segment) delta() Vec2 {
	return s.b - s.a
}

fn (wall Segment) bounce(ball_trajectory Segment) (bool, Vec2, Vec2) {
	da := wall.delta()
	db := ball_trajectory.delta()
	dp := ball_trajectory.a - wall.a
	denom := da.cross(db)

	mut hit_point := vec2_null

	if denom != 0 {
		println('denom not zero :: ${denom}')
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

pub struct Primitive {
pub mut:
	id       string
	kind     PrimitiveType
	position Vec2
	size     Vec2
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
