package droneon.model;

import nape.geom.Vec2;
import nape.space.Space;

class World {

	public var space:Space;
	public var entities:Array<Entity> = [];

	public function new() {
		space = new Space(new Vec2(0, -500));
	}

	public function step(wdt:Float) {
		for (e in entities) e.step(wdt);
		// for (s in 0...10)
		// 	space.step(wdt/10);
		space.step(wdt);
	}

}