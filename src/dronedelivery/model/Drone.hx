
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
		romp.material.density *= 2;
		romp.translate(new Vec2(0,rompOffset));
		romp.body = body;

		for (a in 0...2) {
			var sh2 = new Polygon(Polygon.rect(rotorDistance * ([-1,1][a]) - 10, -50, 20, 30));
			sh2.body = body;
			// sh2.material.density *= 0.1;
		}

		massCenter = body.localCOM.copy();
		body.align();

		finPos = new Vec2(0, -30).sub(massCenter);
		rompPos = new Vec2(0, rompOffset).sub(massCenter);

	}

	public function step(dt:Float) {

		for (a in 0...2) {

// Browser.window.console.log(a, thrust[a], avgThrust[a]);

			avgThrust[a] = Maths.averageEase(avgThrust[a], thrust[a], 20, dt);
			var avg = avgThrust[a];

			var force = new Vec2(0, -3500);
			force = force.mul(avg);
			// force.rotate((body.rotation*2 + -body.velocity.angle)/3);
			force.rotate(body.rotation);
			force.rotate(-body.angularVel * 0.1);
			force = force.add(Vec2.fromPolar(force.length*0.33, -Maths.HALFPI));
			force = force.mul(1/1.33);
			// force.rotate(-body.rotation * 0.25);

			thrustForce[a] = force;
			
			var point = new Vec2(rotorDistance * [-1,1][a], -50);
			point.sub(massCenter);
			point = body.localPointToWorld(point);
			
			body.applyImpulse(force.mul(dt), point);

		}

		// fin position in world
		var wFinPos = body.localPointToWorld(finPos);
		// world vector from drone center to fin
		var wFinPosRelCenter = wFinPos.sub(body.position);

		// var headVelLen = Math.sin(body.angularVel) * wHeadPosRelCenter.length;
		// headVel = wHeadPosRelCenter.copy();
		// headVel = headVel.rotate(Maths.HALFPI);
		// headVel.length = headVelLen;

		// linear fin velocity in world resulting from drone angular velocity
		// TODO figure out this magic
		var finVel = wFinPosRelCenter.copy();
		finVel.x *= body.angularVel;
		finVel.y *= body.angularVel;
		finVel = finVel.rotate(Maths.HALFPI);
		// add drone velocity for total world fin velocity
		finVel = finVel.add(body.velocity);

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

			body.applyImpulse(finForce.mul(dt), wFinPos);

		}



		// romp position in world
		var wRompPos = body.localPointToWorld(rompPos);
		// world vector from drone center to fin
		var wRompPosRelCenter = wRompPos.sub(body.position);

		// var headVelLen = Math.sin(body.angularVel) * wHeadPosRelCenter.length;
		// headVel = wHeadPosRelCenter.copy();
		// headVel = headVel.rotate(Maths.HALFPI);
		// headVel.length = headVelLen;

		// linear fin velocity in world resulting from drone angular velocity
		// TODO figure out this magic
		var rompVel = wRompPosRelCenter.copy();
		rompVel.x *= body.angularVel;
		rompVel.y *= body.angularVel;
		rompVel = rompVel.rotate(Maths.HALFPI);
		// add drone velocity for total world fin velocity
		rompVel = rompVel.add(body.velocity);

		if (rompVel.length != 0) {

			var wRompWind = rompVel.copy().mul(-1);
			wRompWind.length = Math.pow(wRompWind.length, 2);
			bodyAirForce = wRompWind.copy().mul(0.00075);

			// // determine the wind vector in romp space
			// var fRompWind = wRompWind.copy().rotate(-body.rotation);
			// // handle horizontal and vertical differently
			// bodyAirForce = new Vec2();
			// bodyAirForce.x = fRompWind.x * 0.0005;
			// bodyAirForce.y = fRompWind.y * 0.0005;
			// bodyAirForce = bodyAirForce.rotate(body.rotation);

			body.applyImpulse(bodyAirForce.mul(dt), wRompPos);

		}

	}

}