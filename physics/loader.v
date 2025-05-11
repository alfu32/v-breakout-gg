module physics

const u = 8

const cell_w = 4 * u

const cell_h = 2 * u

pub fn parse_ascii_map(input string) []Primitive {
	mut primitives := []Primitive{}
	lines := input.split_into_lines()

	mut id_count := 0
	for row, line in lines {
		for col, ch in line.runes() {
			x := f32(col * cell_w)
			y := f32(row * cell_h)

			match ch {
				`W` {
					primitives << Primitive{
						id:       'wall_${id_count++}'
						kind:     .wall
						position: Vec2{x, y}
						size:     Vec2{cell_w, cell_h}
					}
				}
				`B` {
					primitives << Primitive{
						id:       'brick_${id_count++}'
						kind:     .brick
						position: Vec2{x, y}
						size:     Vec2{cell_w, cell_h}
					}
				}
				`O` {
					primitives << Primitive{
						id:       'ball_${id_count++}'
						kind:     .ball
						position: Vec2{x + 2 * u, y + u}
						size:     Vec2{u, u}
					}
				}
				`P` {
					primitives << Primitive{
						id:       'paddle_${id_count++}'
						kind:     .paddle
						position: Vec2{x, y}
						size:     Vec2{4 * u, u}
					}
				}
				else {}
			}
		}
	}
	return primitives
}
