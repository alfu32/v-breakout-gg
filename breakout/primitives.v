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

pub struct Primitive {
pub mut:
	id       string
	kind     PrimitiveType
	position Vec2
	size     Vec2
}
