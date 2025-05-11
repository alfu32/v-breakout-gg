module breakout

import gg
import gx

const paddle_speed = 10.0

@[heap]
pub struct GameRenderer {
pub mut:
	ctx        ?&gg.Context
	engine     &PhysicsEngine
	keys       map[gg.KeyCode]bool
	score      int
	game_state string
	size       Vec2
	ball_histo SlidingChangeBuffer[Vec2] = slding_change_buffer_create[Vec2](10)
}

pub fn (mut r GameRenderer) render_loop() {
	r_handle_event := fn [mut r] (e &gg.Event, _ voidptr) {
		r.handle_event(e, mut r.ctx or { panic('failed to create graphics context: \$err') })
	}
	r_event_fn := fn [mut r] (_ voidptr) {
		r.render_frame(mut r.ctx or { panic('failed to create graphics context: \$err') })
	}
	r_handle_resize_fn := fn [mut r] (e &gg.Event, _ voidptr) {
		println(e)
		r.size.x = e.window_width
		r.size.y = e.window_height
		r.engine.size.x = e.window_width
		r.engine.size.y = e.window_height
	}
	r.ctx = gg.new_context(gg.Config{
		width:        int(r.size.x)
		height:       int(r.size.y)
		window_title: 'Breakout in V'
		user_data:    r
		frame_fn:     r_event_fn
		event_fn:     r_handle_event
		resized_fn:   r_handle_resize_fn
	})
	println('running rendering loop')

	(r.ctx or { panic('failed to create graphics context: \$err') }).run()
}

fn (mut r GameRenderer) handle_event(e &gg.Event, mut _ gg.Context) {
	if e.typ == .key_down {
		r.keys[e.key_code] = true
	} else if e.typ == .key_up {
		r.keys.delete(e.key_code)
	}
}

fn (mut r GameRenderer) render_frame(mut ctx gg.Context) {
	mut state := r.engine.get_state()

	for p in state {
		if p.kind == .paddle {
			mut new_pos := p.position
			if r.keys[.left] {
				new_pos.x -= paddle_speed
			}
			if r.keys[.right] {
				new_pos.x += paddle_speed
			}
			if r.keys[.up] {
				new_pos.y -= paddle_speed
			}
			if r.keys[.down] {
				new_pos.y += paddle_speed
			}

			if new_pos.x < 0 {
				new_pos.x = 0
			}
			if new_pos.x + p.size.x > r.engine.size.x {
				new_pos.x = r.engine.size.x - p.size.x
			}

			new_p := Primitive{
				...p
				position: new_pos
			}
			r.engine.accept_update(p, new_p, fn (err string, _ Primitive) {
				if err != '' {
					println('Update error: \$err')
				}
			})
		}
	}

	state = r.engine.get_state()
	ctx.begin()
	for p in state {
		match p.kind {
			.brick {
				ctx.draw_rect_filled(p.position.x + 1, p.position.y + 1, p.size.x - 2,
					p.size.y - 2, gx.dark_red)
			}
			.ball {
				sz := p.size.x / 2
				// ctx.draw_circle_filled(p.position.x+sz, p.position.y+sz, sz, gx.orange)
				ctx.draw_circle_filled(p.position.x, p.position.y, sz, gx.orange)
			}
			.wall {
				ctx.draw_rect_filled(p.position.x + 1, p.position.y + 1, p.size.x - 2,
					p.size.y - 2, gx.light_gray)
			}
			.paddle {
				ctx.draw_rect_filled(p.position.x, p.position.y, p.size.x, p.size.y, gx.white)
			}
		}
	}

	r.score = r.engine.score

	for _, v in r.engine.velocities {
		r.ball_histo.append[T](v)
	}
	txt := 'Score: ${r.score}, Balls ${r.ball_histo.buffer.map(it.str[Vec2]()).join(',')}'
	ctx.draw_text(10, 10, txt, gx.TextCfg{ color: gx.light_gray })

	match r.game_state {
		'win' { ctx.draw_text(300, 280, 'YOU WIN!', gx.TextCfg{ color: gx.green }) }
		'lose' { ctx.draw_text(300, 280, 'GAME OVER', gx.TextCfg{ color: gx.red }) }
		else {}
	}
	ctx.end()
	// println('rendering frame done')
}
