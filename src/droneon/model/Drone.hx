
package droneon.model;

import js.Browser;
import nape.constraint.DistanceJoint;
import nape.geom.Vec2;
import nape.phys.Body;
import nape.shape.Circle;
import nape.shape.Polygon;
import nape.space.Space;
import weber.Maths;

class Drone implements Entity {

	private static inline var BALL = false;

	public var body(default,null):Body;
	public var ball:Body;

	public var avgThrust(default,null) = [0.0, 0.0];
	public var thrust = [0.0, 0.0];

	public var rotorDistance:Float;

	public var massCenter:Vec2;

	public var finForce = new Vec2();
	public var bodyAirForce = new Vec2();
	public var thrustForce = [new Vec2(), new Vec2()];

	private var finPos:Vec2;
	private var rompPos:Vec2;

	public function new(pos:Vec2, space:Space, rompOffset:Float, rompHeight:Float, rompWidth:Float, rotorDistance:Float) {

		this.rotorDistance = rotorDistance;

		body = new Body();
		body.space = space;
		body.position.set(pos);

		var romp = new Polygon(Polygon.box(rompWidth,rompHeight));
		romp.material.density *= 1.5;
		romp.translate(new Vec2(0,rompOffset));
		romp.body = body;

		for (a in 0...2) {
			var sh2 = new Polygon(Polygon.rect(
				rotorDistance * ([-1,1][a]) - 10, 
				20,
				20, 30
			));
			sh2.body = body;
			// sh2.material.density *= 0.1;
		}

		massCenter = body.localCOM.copy();
		body.align();

		finPos = new Vec2(0, 30).sub(massCenter);
		rompPos = new Vec2(0, rompOffset).sub(massCenter);

		if (!BALL) {
			ball = null;
		} else {

			ball = new Body();
			ball.position.set(body.position.add(new Vec2(0, -100)));
			ball.space = space;

			var ballsh = new Circle(20);
			ballsh.material.density = 5;
			ballsh.body = ball;

			var chain = new DistanceJoint(body, ball, rompPos, new Vec2(0,0), 30, 210);
			chain.stiff = false;
			chain.damping = 1;
			chain.space = space;

		}

	}

	public function step(dt:Float) {

		// thrusters
		for (a in 0...2) {

			// ease into the new thrust value
			avgThrust[a] = Maths.averageEase(avgThrust[a], thrust[a], 20, dt);
			var avg = avgThrust[a];

			// create a thrust pointing up
			var force = new Vec2(0, ball == null ? 3500 : 4500);
			force = force.mul(avg);
			
			// it's in world space so apply body rotation
			force.rotate(body.rotation);

			// --- stabilization cheats
			// counter angular velocity
			force.rotate(-body.angularVel * 0.1);
			// lean upwards
			force = force.add(Vec2.fromPolar(force.length*0.33, Maths.HALFPI));
			force = force.mul(1/1.33);

			// make the force publicly readable
			thrustForce[a] = force;
			
			// get thruster local position
			var point = new Vec2(rotorDistance * [-1,1][a], 50).sub(massCenter);

			// fire!
			body.applyImpulse(force.mul(dt), body.localPointToWorld(point));

		}

		// fin drag
		var finVel = getPointWorldVelocity(body, finPos);		
		if (finVel.length != 0) {

			var wFinWind = finVel.copy().mul(-1);
			wFinWind.length = Math.pow(wFinWind.length, 2);
			// finForce = wFinWind.copy().mul(0.0005);

			// determine the wind vector in fin space
			var fFinWind = wFinWind.copy().rotate(-body.rotation);

			// handle horizontal and vertical differently
			finForce = new Vec2();
			finForce.x = fFinWind.x * 0.0005;
			finForce.y = 0;//fFinWind.y * 0.0005;

			finForce = finForce.rotate(body.rotation);

			body.applyImpulse(finForce.mul(dt), body.localPointToWorld(finPos));

		}

		// romp drag
		var rompVel = getPointWorldVelocity(body, rompPos);
		if (rompVel.length != 0) {

			var wRompWind = rompVel.copy().mul(-1);
			wRompWind.length = Math.pow(wRompWind.length, 2);
			bodyAirForce = wRompWind.copy().mul(0.00075);

			body.applyImpulse(bodyAirForce.mul(dt), body.localPointToWorld(rompPos));

		}

	}

	private static function getPointWorldVelocity(body:Body, localPoint:Vec2):Vec2 {

		var wPos = body.localPointToWorld(localPoint);
		var wPosRelCenter = wPos.sub(body.position);

		// var headVelLen = Math.sin(body.angularVel) * wHeadPosRelCenter.length;
		// headVel = wHeadPosRelCenter.copy();
		// headVel = headVel.rotate(Maths.HALFPI);
		// headVel.length = headVelLen;

		// velocity in world resulting from angular velocity
		// TODO figure out this magic
		var pointVel = wPosRelCenter.copy();
		pointVel.x *= body.angularVel;
		pointVel.y *= body.angularVel;
		pointVel = pointVel.rotate(Maths.HALFPI);

		// add body velocity for total world velocity
		return pointVel.add(body.velocity);

	}

}