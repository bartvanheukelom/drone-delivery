
package droneon;

import droneon.model.Drone;
import pixi.core.display.Container;
import pixi.core.graphics.Graphics;
import threejs.core.Object3D;
import threejs.extras.geometries.BoxGeometry;
import threejs.extras.geometries.SphereGeometry;
import threejs.materials.MeshBasicMaterial;
import threejs.materials.MeshLambertMaterial;
import threejs.objects.Mesh;
import threejs.scenes.Scene;

class DroneView {

	private static inline var DRAW_FORCES = true;

	private var views:Array<Dynamic> = [];
	private var drone:Drone;

	public function new(drone:Drone, player:Bool, spaceGraph:Scene) {

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


		for (a in 0...2) {

			var flip = [-1,1][a];

		// 	droneGraph.lineStyle(4, 0x887766);
		// 	droneGraph.moveTo(ox + flip*rompWidth * 0.4, oy + -(rompHeight/2)+rompOffset);
		// 	droneGraph.lineTo(ox + flip*(drone.rotorDistance - 5), oy + -45);

		// 	droneGraph.lineStyle();
		// 	droneGraph.beginFill(0xFFFF00);
		// 	droneGraph.drawRect(ox + drone.rotorDistance*flip - 10, oy + -50, 20, 30);
		// 	droneGraph.endFill();

			var boost = new Mesh(new BoxGeometry(20, 30, 20), new MeshLambertMaterial({color: 0xFFFF00}));
			boost.position.x = ox + drone.rotorDistance * flip;
			boost.position.y = oy + 35;
			droneGraph.add(boost);

		}
		var romp = new Mesh(new BoxGeometry(rompWidth, rompHeight, rompWidth), new MeshLambertMaterial({color: player ? 0xFFFFFF : 0x888888}));
		romp.position.x = ox;
		romp.position.y = oy + rompOffset;
		droneGraph.add(romp);
		// droneGraph.beginFill(player ? 0xFFFFFF : 0x888888);
		// droneGraph.drawRect(ox + -rompWidth/2, oy + -(rompHeight/2)+rompOffset,rompWidth,rompHeight);
		// droneGraph.endFill();

		// center of mass
		if (DRAW_FORCES) {
			// droneGraph.beginFill(0x009900);
			// droneGraph.drawCircle(0,0,1);
			droneGraph.add(new Mesh(new BoxGeometry(1,1,200), new MeshLambertMaterial({color: 0x009900})));
		}

		// var fbs = 0.05;

		for (a in 0...2) {

			var flip = [-1,1][a];

			var bar = new Mesh(new BoxGeometry(16, 200, 16), new MeshLambertMaterial({color: 0xFF8800}));
			// bar.beginFill(0xFF8800, 0.5);
			// bar.drawRect(-8, -100, 16, 100);
			// bar.endFill();

			droneGraph.add(bar);
			bar.position.y = oy+20;
			bar.position.x = ox+(drone.rotorDistance) * flip;

			views.push(function(dt) {
				bar.scale.y = drone.avgThrust[a];
			});

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

		// position.x = drone.body.position.x;
		// position.y = drone.body.position.y;
		// rotation = drone.body.rotation;

		for (v in views) v(dt);
	}

}