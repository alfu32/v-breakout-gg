import os
import breakout

fn main() {
	ascii := os.read_file('scene.txt') or { panic(err) }
	prims := breakout.parse_ascii_map(ascii)

	mut engine := &breakout.PhysicsEngine{}
	engine.add_all(prims)

	mut game := &breakout.GameRenderer{
		engine: engine
	}

	engine.set_game_end_callback(fn [mut game] (state string) {
		game.game_state = state
	})

	engine.start_simulation()
	game.render_loop()
}
