import os
import gg_renderer
import physics

fn main() {
	ascii := os.read_file('scene.txt') or { panic(err) }
	prims := physics.parse_ascii_map(ascii)

	mut engine := &physics.PhysicsEngine{
		size: physics.Vec2{800, 600}
	}
	engine.add_all(prims)

	mut game := &gg_renderer.GameRenderer{
		engine: engine
		size:   engine.size.copy()
	}

	engine.set_game_end_callback(fn [mut game] (state string) {
		game.game_state = state
	})

	engine.start_simulation()
	game.render_loop()
}
