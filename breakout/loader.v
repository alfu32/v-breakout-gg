module breakout

const u = 8

const cell_w = 4 * u

const cell_h = 2 * u

pub fn parse_ascii_map(input string) []Primitive {
	mut primitives := []Primitive{}
	lines := input.split_into_lines()

	mut id_count := 0
	for row, line in lines {
		for col, ch in line.runes() {
			x := f32(col * breakout.cell_w)
			y := f32(row * breakout.cell_h)

			match ch {
				`W` {
					primitives << Primitive{
						id: 'wall_${id_count++}'
						kind: .wall
						position: Vec2{x, y}
						size: Vec2{breakout.cell_w, breakout.cell_h}
					}
				}
				`B` {
					primitives << Primitive{
						id: 'brick_${id_count++}'
						kind: .brick
						position: Vec2{x, y}
						size: Vec2{breakout.cell_w, breakout.cell_h}
					}
				}
				`O` {
					primitives << Primitive{
						id: 'ball_${id_count++}'
						kind: .ball
						position: Vec2{x + 2 * breakout.u, y + breakout.u}
						size: Vec2{breakout.u, breakout.u}
					}
				}
				`P` {
					primitives << Primitive{
						id: 'paddle_${id_count++}'
						kind: .paddle
						position: Vec2{x, y}
						size: Vec2{4 * breakout.u, breakout.u}
					}
				}
				else {}
			}
		}
	}
	return primitives
}
