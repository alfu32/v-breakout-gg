module breakout

const cell_w = 32

const cell_h = 16

pub fn parse_ascii_map(input string) []Primitive {
	mut primitives := []Primitive{}
	lines := input.split_into_lines()

	for row, line in lines {
		for col, ch in line.runes() {
			x := f32(col * breakout.cell_w)
			y := f32(row * breakout.cell_h)
			id := '\${${row}}_\${${col}}'

			match ch {
				`W` {
					primitives << Primitive{
						id: id
						kind: .wall
						position: Vec2{x, y}
						size: Vec2{breakout.cell_w, breakout.cell_h}
					}
				}
				`B` {
					primitives << Primitive{
						id: id
						kind: .brick
						position: Vec2{x, y}
						size: Vec2{breakout.cell_w, breakout.cell_h}
					}
				}
				`O` {
					primitives << Primitive{
						id: id
						kind: .ball
						position: Vec2{x + 16, y + 8}
						size: Vec2{16, 16}
					}
				}
				`P` {
					primitives << Primitive{
						id: id
						kind: .paddle
						position: Vec2{x, y}
						size: Vec2{96, 16}
					}
				}
				else {}
			}
		}
	}
	return primitives
}
