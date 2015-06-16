package droneon.model;

import nape.phys.Body;
import nape.phys.BodyType;
import nape.shape.Polygon;
import pixi.core.math.shapes.Rectangle;

class Block implements Entity {
	
	public var rect:Rectangle;
	public var color:Int;
	public var dyn:Bool;
	public var deep:Bool;

	public var body:Body;

	public function new(world:World, rect:Rectangle, color:Int = 0x8888FF, dyn = false, deep = false) {

		this.rect = rect;
		this.color = color;
		this.dyn = dyn;
		this.deep = deep;

		var cx = rect.x+(rect.width/2);
		var cy = rect.y-(rect.height/2);

		body = new Body(dyn ? BodyType.DYNAMIC : BodyType.STATIC);
		var s = new Polygon(Polygon.box(rect.width, rect.height));
		s.material.density *= 0.1;
		s.material.dynamicFriction *= 5;
		s.material.staticFriction *= 5;
		s.body = body;
		body.position.setxy(cx, cy);
		body.space = world.space;

		world.entities.push(this);

	}

	public function step(dt:Float) {}

}