import os
import gg_renderer
import physics

fn main() {
	println(os.args[1..])
	mut scene_file := if os.args.len > 1 {
		os.args[1]
	} else {
		'scene.txt'
	}
	ascii := os.read_file(scene_file) or { panic(err) }
	prims := parse_ascii_map(ascii)

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
