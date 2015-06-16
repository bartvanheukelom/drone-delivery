package droneon.model.levels;

import droneon.model.World;
import pixi.core.math.shapes.Rectangle;

class Level {
	
	private var world:World;

	public function new(world:World) {
		this.world = world;
	}

	private function addGround(x:Float, y:Float, width:Float, height:Float, color:Int = 0x8888FF, dyn = false, deep = false) {
		new Block(world, new Rectangle(x, y, width, height), color, dyn, deep);
	}

}