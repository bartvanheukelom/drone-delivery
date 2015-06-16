
package droneon;

import droneon.model.Drone;
import threejs.core.Object3D;
import threejs.extras.geometries.BoxGeometry;
import threejs.extras.geometries.CylinderGeometry;
import threejs.extras.geometries.SphereGeometry;
import threejs.lights.PointLight;
import threejs.materials.MeshBasicMaterial;
import threejs.materials.MeshLambertMaterial;
import threejs.objects.Mesh;
import threejs.scenes.Scene;

class DroneView {

	private static inline var DRAW_FORCES = false;

	private var views:Array<Dynamic> = [];
	private var drone:Drone;

	public function new(drone:Drone, color:Int, spaceGraph:Scene) {

		this.drone = drone;

		var rompOffset = -70;
		var rompHeight = 30*1.25;
		var rompWidth = 80;
		var rotorDistance = 45;

		var ox = -drone.massCenter.x;
		var oy = -drone.massCenter.y;
		trace(ox, oy);

		var ballgraph, center;

		if (drone.ball != null) {

			ballgraph = new Mesh(new SphereGeometry(20), new MeshLambertMaterial({color: 0x222222}));
			// ballgraph.beginFill(0x222222);
			// ballgraph.drawCircle(0, 0, 20);
			// ballgraph.endFill();
			spaceGraph.add(ballgraph);

			var center = new Mesh(new SphereGeometry(2), new MeshLambertMaterial({color: 0xFFFF00}));
			spaceGraph.add(center);
			// center.beginFill(0xFFFF00);
			// center.drawCircle(0, 0, 2);
			// center.endFill();
			// spaceGraph.addChild(center);

			views.push(function(dt) {

				ballgraph.position.x = drone.ball.position.x;
				ballgraph.position.y = drone.ball.position.y;
				ballgraph.rotation.z = drone.ball.rotation;

				var pos = drone.ball.position.mul(drone.ball.mass)
					.add(drone.body.position.mul(drone.body.mass))
					.mul(1/(drone.ball.mass + drone.body.mass));
				center.position.x = pos.x;
				center.position.y = pos.y;

			});

		}

		var droneGraph = new Object3D();
		spaceGraph.add(droneGraph);
		views.push(function(dt) {
			droneGraph.position.x = drone.body.position.x;
			droneGraph.position.y = drone.body.position.y;
			droneGraph.rotation.z = drone.body.rotation;
		});

		var time = 0;
		for (th in drone.thrusters) {

			var boost = new Object3D();
			spaceGraph.add(boost);

			var boostBox = new Mesh(new CylinderGeometry(12, 12, 30), new MeshLambertMaterial({color: 0xFFFF00, ambient: 0xFF0000}));
			boost.add(boostBox);

			var barMat = new MeshLambertMaterial({color: 0xFFFF00, ambient: 0xFF8800, transparent: true});
			var bar = new Mesh(new CylinderGeometry(6,3,100), barMat);
			bar.position.x = th.horOffset;
			boost.add(bar);

			var light = new PointLight(0xFF8800, 0, 500);
			light.position.x = th.horOffset;
			light.position.y = -20;
			boost.add(light);

			views.push(function(dt) {

				time += dt;

				boost.position.x = th.body.position.x;
				boost.position.y = th.body.position.y;
				boost.rotation.z = th.body.rotation;

				bar.scale.y = th.actualThrust + Math.sin(time*30) * 0.05;
				bar.scale.x = 0.25 + th.actualThrust + Math.sin(time*20) * 0.2;
				bar.position.y = -50 * bar.scale.y;
				var shaky = th.actualThrust * (0.9 + Math.sin(time*20) * 0.1);
				light.intensity = shaky;
				light.position.y = -20 + bar.scale.y * -40;
				barMat.opacity = shaky;
				// light.castShadow = light.intensity > 0;
				// bar.rotation.z = th.body.angularVel * 0.1;
			});

		}
		var romp = new Mesh(new BoxGeometry(rompWidth, rompHeight, rompWidth), new MeshLambertMaterial({color: color, ambient: color}));
		romp.position.x = ox;
		romp.position.y = oy + rompOffset;
		// romp.castShadow = true;
		droneGraph.add(romp);
	
		// center of mass
		if (DRAW_FORCES) {
			droneGraph.add(new Mesh(new BoxGeometry(1,1,200), new MeshLambertMaterial({color: 0x009900, ambient: 0x009900})));
		}

		for (a in 0...2) {

			

		// 	if (DRAW_FORCES) {

		// 		var forcebar = new Graphics();
		// 		forcebar.beginFill(0xFF8800);
		// 		forcebar.drawRect(0,-2,fbs,4);
		// 		forcebar.endFill();
		// 		forcebar.y = oy-50;
		// 		forcebar.x = ox+(drone.rotorDistance) * flip;
		// 		addChild(forcebar);

		// 		views.push(function(dt) {
		// 			forcebar.rotation = drone.thrustForce[a].angle;
		// 			forcebar.rotation -= rotation;
		// 			forcebar.scale.x = drone.thrustForce[a].length;
		// 		});

		// 	}

		}

		// if (DRAW_FORCES) {

		// 	var finbar = new Graphics();
		// 	finbar.beginFill(0x0000FF);
		// 	finbar.drawRect(0,-2,fbs,4);
		// 	finbar.endFill();
		// 	finbar.y = oy-30;
		// 	addChild(finbar);

		// 	var bodyairbar = new Graphics();
		// 	bodyairbar.beginFill(0x0000FF);
		// 	bodyairbar.drawRect(0,-2,fbs,4);
		// 	bodyairbar.endFill();
		// 	bodyairbar.y = oy+rompOffset;
		// 	addChild(bodyairbar);

		// 	var vbar = new Graphics();
		// 	vbar.beginFill(0x00FF00);
		// 	vbar.drawRect(0,-2,fbs,4);
		// 	vbar.endFill();
		// 	addChild(vbar);

		// 	views.push(function(dt) {
				
		// 		finbar.rotation = drone.finForce.angle;
		// 		finbar.rotation -= rotation;
		// 		finbar.scale.x = drone.finForce.length;

		// 		bodyairbar.rotation = drone.bodyAirForce.angle;
		// 		bodyairbar.rotation -= rotation;
		// 		bodyairbar.scale.x = drone.bodyAirForce.length;

		// 		vbar.rotation = drone.body.velocity.angle;
		// 		vbar.rotation -= rotation;
		// 		vbar.scale.x = drone.body.velocity.length;

		// 	});

		// }

		// spaceGraph.addChild(this);

	}

	public function update(dt:Float) {
		for (v in views) v(dt);
	}

}