
package droneon.model;

import nape.geom.Vec2;
import nape.phys.Body;
import nape.shape.Polygon;
import nape.space.Space;
import weber.Maths;

class Rocket 
{

	public var body:Body;
	public var maxPower:Float;
	public var inThrust = 0.0;
	public var actualThrust(default,null) = 0.0;
	public var horOffset:Float;

	public function new(pos:Vec2, space:Space, maxPower:Float, horOffset:Float) {

		this.maxPower = maxPower;
		this.horOffset = horOffset;

		body = new Body();
		body.space = space;
		body.position.set(pos);

		var sh2 = new Polygon(Polygon.box(24, 30));
		sh2.body = body;

	}

	public function step(dt:Float) {



		// --- firing

		// ease into the new thrust value
		actualThrust = Maths.averageEase(actualThrust, inThrust, 20, dt);

		// create a thrust pointing up
		var force = new Vec2(0, maxPower);
		force = force.mul(actualThrust);
		
		// it's in world space so apply body rotation
		force.rotate(body.rotation);

		// --- stabilization cheats
		// counter angular velocity
		// force.rotate(-body.angularVel * 0.1);
		// lean upwards
		// force = force.add(Vec2.fromPolar(force.length*0.33, Maths.HALFPI));
		// force = force.mul(1/1.33);

		// make the force publicly readable
		// thrustForce[a] = force;
		
		// get thruster local position
		var point = new Vec2(horOffset, -15);

		// fire!
		body.applyImpulse(force.mul(dt), body.localPointToWorld(point));




		// --- dragging

		var thrustVel = body.velocity;
		if (thrustVel.length != 0) {

			var wRompWind = thrustVel.copy().mul(-1);
			wRompWind.length = Math.pow(wRompWind.length, 2);
			var thrustAirForce = wRompWind.copy().mul(0.0002);

			body.applyImpulse(thrustAirForce.mul(dt));

		}

		// rotational
		if (body.angularVel < -10) trace(body.angularVel, Math.pow(body.angularVel, 2));
		body.applyAngularImpulse(Math.pow(body.angularVel, 2) * -20 * Maths.signum(body.angularVel) * dt); // signum because the pow loses the sign

	}

}