
package dronedelivery.model;

import js.Browser;
import nape.geom.Vec2;
import nape.phys.Body;
import nape.shape.Polygon;
import nape.space.Space;
import weber.Maths;

class Drone implements Entity {

	public var body(default,null):Body;

	public var avgThrust(default,null) = [0.0, 0.0];
	public var thrust = [0.0, 0.0];

	public var rotorDistance:Float;

	public function new(pos:Vec2, space:Space, rompOffset:Float, rompHeight:Float, rompWidth:Float, rotorDistance:Float) {

		this.rotorDistance = rotorDistance;

		body = new Body();
		body.space = space;
		body.position.set(pos);

		var romp = new Polygon(Polygon.box(rompWidth,rompHeight));
		romp.translate(new Vec2(0,rompOffset));
		romp.body = body;

		for (a in 0...2) {
			var sh2 = new Polygon(Polygon.rect(rotorDistance * ([-1,1][a]) - 10, -50, 20, 30));
			sh2.body = body;
			sh2.material.density = 0;
		}

		// droneBody.align(); //TODO

	}

	public function step(dt:Float) {

		for (a in 0...2) {

// Browser.window.console.log(a, thrust[a], avgThrust[a]);

			avgThrust[a] = Maths.averageEase(avgThrust[a], thrust[a], 20, dt);
			var avg = avgThrust[a];

			var force = new Vec2(0, -1750);
			force = force.mul(avg);
			force = force.mul(dt);
			force.rotate(body.rotation);
			
			var point = new Vec2(rotorDistance * [-1,1][a], -50);
			point = body.localPointToWorld(point);
			
			body.applyImpulse(force, point);

		}

	}

}