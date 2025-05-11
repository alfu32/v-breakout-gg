module physics

import math

pub struct IndexedPacket[T] {
	id     int
	packet T
}

pub fn (a IndexedPacket[T]) str() string {
	return '${a.id}:${a.packet}'
}

pub struct SlidingBuffer[T] {
pub mut:
	max_len    int
	buffer     []IndexedPacket[T]
	current_id int
}

pub fn slding_buffer_create[T](max_len int) SlidingBuffer[T] {
	mut buf := SlidingBuffer[T]{
		max_len: max_len
	}
	return buf
}

pub fn (mut sb SlidingBuffer[T]) append[T](e T) {
	mut b2 := sb.buffer.filter(true)
	b2 << IndexedPacket[T]{
		id:     sb.current_id
		packet: e
	}
	sb.current_id += 1
	if b2.len > sb.max_len {
		sb.buffer = b2[1..math.min(sb.max_len, b2.len + 1)]
	} else {
		sb.buffer = b2
	}
}

pub fn (mut sb SlidingBuffer[T]) prepend[T](e T) {
	mut b2 := []IndexedPacket[T]{}
	b2 << IndexedPacket[T]{
		id:     sb.current_id
		packet: e
	}
	sb.current_id += 1
	for bb in sb.buffer {
		b2 << bb
	}
	sb.buffer = b2[0..math.min(sb.max_len, b2.len - 1)]
}

pub struct SlidingChangeBuffer[T] {
pub mut:
	max_len    int
	buffer     []IndexedPacket[T]
	current_id int
}

pub fn slding_change_buffer_create[T](max_len int) SlidingChangeBuffer[T] {
	mut buf := SlidingChangeBuffer[T]{
		max_len: max_len
	}
	return buf
}

pub fn (mut sb SlidingChangeBuffer[T]) append[T](e T) {
	mut b2 := sb.buffer.filter(true)
	if sb.buffer.len == 0 || sb.buffer.last().packet.str() != e.str() {
		b2 << IndexedPacket[T]{
			id:     sb.current_id
			packet: e
		}
		sb.current_id += 1
		if b2.len > sb.max_len {
			sb.buffer = b2[1..math.min(sb.max_len, b2.len + 1)]
		} else {
			sb.buffer = b2
		}
	}
}

pub fn (mut sb SlidingChangeBuffer[T]) prepend[T](e T) {
	mut b2 := []IndexedPacket[T]{}
	if sb.buffer.len == 0 || sb.buffer.last().packet.str() != e.str() {
		b2 << IndexedPacket[T]{
			id:     sb.current_id
			packet: e
		}
		sb.current_id += 1
		for bb in sb.buffer {
			b2 << bb
		}
		sb.buffer = b2[0..math.min(sb.max_len, b2.len - 1)]
	} else {
		b2 << IndexedPacket[T]{
			id:     sb.current_id
			packet: e
		}
		sb.current_id += 1
	}
}
