module breakout

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

pub fn (v Vec2) copy() Vec2 {
	return Vec2{
		x: v.x
		y: v.y
	}
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
		id: p.id
		kind: p.kind
		position: p.position.copy()
		size: p.size.copy()
	}
}
