module physics

fn test_vec2() {
	mut z0 := Vec2{}
	mut p0 := Vec2{0, 0}
	mut c1 := Vec2{2, 3}
	mut c2 := Vec2{-3, 4}
	mut c3 := Vec2{-2, -4}
	mut c4 := Vec2{1, -4}
	println(' z0 = ${z0}')
	println(' p0 = ${p0}')
	println(' c1 = ${c1}')
	println(' c2 = ${c2}')
	println(' c3 = ${c3}')
	println(' c4 = ${c4}')
	println(' z0 == vec2_null === ${&z0 == &vec2_null}')
	println(' p0 == vec2_null === ${&p0 == &vec2_null}')
	println(' z0 == p0 === ${z0 == p0}')
	println(' z0 + p0 = ${z0 + p0}')
	println(' z0 - p0 = ${z0 - p0}')
	println(' c1 + c2 = ${c1 + c2}')
	println(' c1 - c2 = ${c1 - c2}')
	println(' 12 * c1 = ${c1.mul(12)}')
	println(' c1 . c1 = ${c1.dot(c2)}')
	println(' c1 x c1 = ${c1.cross(c2)}')

	mut ab := Segment{
		a: c1
		b: c2
	}
	println(' ab = ${ab}')
	println(' ab = ${ab.delta()}')

	s1 := Segment{
		a: Vec2{0, 0}
		b: Vec2{10, 0}
	}
	s2 := Segment{
		a: Vec2{6, 0}
		b: Vec2{6, 10}
	}
	s3 := Segment{
		a: Vec2{8, 3}
		b: Vec2{3, -2}
	}
	println(' s1 = ${s1}')
	println(' s2 = ${s2}')
	println(' s3 = ${s3}')
	ok_v, intersection_v, projection_v := s1.bounce(s3)
	println(' is ok = ${ok_v}')
	println(' intersection_v = ${intersection_v}')
	println(' projection_v = ${projection_v}')
	ok_h, intersection_h, projection_h := s2.bounce(s3)
	println(' is ok = ${ok_h}')
	println(' intersection_h = ${intersection_h}')
	println(' projection_h = ${projection_h}')

	wall := Segment{
		a: Vec2{0, 0}
		b: Vec2{10, 0}
	}
	ball := Segment{
		a: Vec2{8, 4}
		b: Vec2{5, 2}
	}
	ok3, na_int, na_proj := wall.bounce(ball)
	println(' na_int = ${na_int}')
	println(' na_proj = ${na_proj}')
	println(' no intersection = ${na_int == vec2_null}')
	println(' is ok = ${ok3}')
}

fn test_bounce_vertical_collision() {
	wall := Segment{
		a: Vec2{5, 0}
		b: Vec2{5, 10}
	}
	ball := Segment{
		a: Vec2{0, 5}
		b: Vec2{10, 5}
	}
	hit, hit_point, deflected := wall.bounce(ball)
	println(' hit ${hit}')
	println(' hit_point ${hit_point}')
	println(' deflected ${deflected}')

	assert hit
	assert hit_point.equals(Vec2{5, 5})
	assert deflected.equals(Vec2{0, 5})
}

fn test_bounce_horizontal_collision() {
	wall := Segment{
		a: Vec2{0, 5}
		b: Vec2{10, 5}
	}
	ball := Segment{
		a: Vec2{5, 0}
		b: Vec2{5, 10}
	}
	hit, hit_point, deflected := wall.bounce(ball)
	println(' hit ${hit}')
	println(' hit_point ${hit_point}')
	println(' deflected ${deflected}')

	assert hit
	assert hit_point.equals(Vec2{5, 5})
	assert deflected.equals(Vec2{5, 0})
}

fn test_bounce_slant_collision() {
	wall := Segment{
		a: Vec2{0, 0}
		b: Vec2{10, 0}
	}
	ball := Segment{
		a: Vec2{8, 3}
		b: Vec2{3, -2}
	}
	hit, hit_point, deflected := wall.bounce(ball)
	println(' hit ${hit}')
	println(' hit_point ${hit_point}')
	println(' deflected ${deflected}')

	assert hit
	assert hit_point.equals(Vec2{5, 0})
	assert deflected.equals(Vec2{3, 2}) // reflection over p = 5,0
}

fn test_bounce_missed() {
	wall := Segment{
		a: Vec2{0, 0}
		b: Vec2{10, 0}
	}
	ball := Segment{
		a: Vec2{11, 1}
		b: Vec2{12, 2}
	}
	hit, _, _ := wall.bounce(ball)

	assert !hit
}

fn test_bounce_parallel() {
	wall := Segment{
		a: Vec2{0, 0}
		b: Vec2{10, 0}
	}
	ball := Segment{
		a: Vec2{0, 1}
		b: Vec2{10, 1}
	}
	hit, _, _ := wall.bounce(ball)

	assert !hit
}
