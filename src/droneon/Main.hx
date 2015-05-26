
package droneon;

import droneon.DroneView;
import droneon.model.Drone;
import droneon.model.Entity;
import js.Browser;
import js.html.Gamepad;
import nape.geom.Vec2;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.shape.Polygon;
import nape.shape.Shape;
import nape.space.Space;
import pixi.core.display.Container;

import pixi.core.graphics.Graphics;
import pixi.core.renderers.Detector;
import pixi.core.renderers.SystemRenderer;
import threejs.cameras.PerspectiveCamera;
import threejs.extras.geometries.BoxGeometry;
import threejs.lights.AmbientLight;
import threejs.lights.DirectionalLight;
import threejs.materials.MeshBasicMaterial;
import threejs.materials.MeshLambertMaterial;
import threejs.math.Vector3;
import threejs.objects.Mesh;
import threejs.renderers.WebGLRenderer;
import threejs.scenes.Scene;
import tortilla.Tortilla;
import weber.game.input.KeyboardInput;
import weber.Maths;

class Main {

	private var stage:Scene;
	private var renderer:WebGLRenderer;
	private var cam:PerspectiveCamera;

	// private var hud:Container;

	private var space:Space;
	// private var spaceGraph:Container;

	private var controllers:Array<Float->Void> = [];
	private var entities:Array<Entity> = [];
	private var views:Array<Dynamic> = [];

	private var playerDrones:Array<Drone> = [];

	// private var pad:Gamepad;

	public static function main() {
		Tortilla.game = new Main();
	}

	public function new() {

	}

	public function settings() {
		return {
			showFps: true,
			noContext: true
		};
	}

	public function init() {

		KeyboardInput.init();

		// var options:RenderingOptions = {};
		// options.backgroundColor = 0x006666;
		// options.resolution = 1;
		// options.transparent = true;
		// options.antialias = true;
		// options.view = Tortilla.canvas;

		// renderer = Detector.autoDetectRenderer(Tortilla.canvas.width, Tortilla.canvas.height, options);

		renderer = new WebGLRenderer({
			canvas: Tortilla.canvas,
			antialias: true,
			devicePixelRatio: 1
		});

		stage = new Scene();

		cam = new PerspectiveCamera(60, 1, 100, 15000);
		cam.position.z = 750;
		stage.add(cam);
		cam.lookAt(new Vector3());


		var ambient = new AmbientLight(0x557777);
		stage.add(ambient);
		// var sunTarget = new Object3D();
		// scene.add(sunTarget);
		var sun = new DirectionalLight(0x886666, 1);
		sun.position.set(1,1.5,2.5);
		stage.add(sun);
		var sun2 = new DirectionalLight(0x000011, 1);
		sun.position.set(1,-1.5,2.5);
		stage.add(sun);
		// sun.target = sunTarget;


		// hud = new Container();
		// stage.addChild(hud);

		Tortilla.addEventListener(Tortilla.EV_RESIZED, adaptToSize);
		adaptToSize();		

		space = new Space(new Vec2(0, -500));

		// spaceGraph = new Container();
		// stage.addChild(spaceGraph);

		var gs = 250;
		var gz = -50;
		// var grid = new Graphics();
		// grid.lineStyle(1, 0x111111);
		var gx = -500;
		while (gx < 6000) {
			var l = new Mesh(new BoxGeometry(1,11000,1), new MeshBasicMaterial({color: 0x111111}));
			l.position.x = gx;
			l.position.y = 5000;
			l.position.z = gz;
			stage.add(l);
			// grid.moveTo(gx, 50);
			// grid.lineTo(gx, -10050);
			gx += gs;
		}
		var gy = 0;
		while (gy < 10000) {
			var l = new Mesh(new BoxGeometry(7100,1,1), new MeshBasicMaterial({color: 0x111111}));
			l.position.x = 3000;
			l.position.y = gy;
			l.position.z = gz;
			stage.add(l);
			// grid.moveTo(-550, gy);
			// grid.lineTo(6000, gy);
			gy += gs;
		}
		// spaceGraph.addChild(grid);


		// var bloom1 = untyped __js__("new PIXI.filters.BloomFilter()");
		// bloom1.blur = 3;
		// spaceGraph.filters = [bloom1];//, bloom2, bloom3];

		var rompOffset = -70;
		var rompHeight = 30*1.25;
		var rompWidth = 80;
		var rotorDistance = 75;

		function addDroneView(drone:Drone) {
			var v = new DroneView(drone, [0x888888, 0xFFFFFF, 0x00FF00, 0x0000FF][playerDrones.indexOf(drone) + 1], stage);
			views.push(v);
		}

		for (px in 0...Std.parseInt(Tortilla.parameters.get("drones", "1"))) {
			var drone = new Drone(new Vec2(2100+px*250, 200), space, rompOffset, rompHeight, rompWidth, rotorDistance);
			playerDrones.push(drone);
			entities.push(drone);
			addDroneView(drone);
			controllers.push(function(dt:Float) {

				var pads = Browser.navigator.getGamepads();

				for (a in 0...2) {
				
					var thrust;
					if (KeyboardInput.isKeyDown([
						[KeyboardInput.KEY_Q, KeyboardInput.KEY_E],
						[KeyboardInput.KEY_I, KeyboardInput.KEY_P],
						][px][a])) {
						thrust = 1.0;
					} else {
						if (!Tortilla.parameters.has("nopad") && pads.length > px && pads[px] != null) {
							var pad = pads[px];
							var ax = [2,5][a];
							thrust = Maths.rangeNormalize(pad.axes[ax], -1, 1);
							// thrust = Math.pow(thrust, 2);
						} else {
							thrust = 0.0;
						}
					}
					drone.thrust[a] = thrust;

				}
			});

			
		}

		var hdSeq = 0;
		function addHoverDrone(rotorDistance:Float, pos:Vec2) {

			var seq = hdSeq;
			hdSeq += 1000;

			var hoverDrone = new Drone(pos, space, rompOffset, rompHeight, rompWidth, rotorDistance);
			entities.push(hoverDrone);
			addDroneView(hoverDrone);

			var targetHeight = hoverDrone.body.position.y;
			var time = 0.0;
			controllers.push(function(dt:Float) {

				time += dt;

				var timeVar = Math.abs((Math.sin(Math.floor(time / 5) + seq) * 1000) % 1);
				var th = targetHeight - timeVar * 1000;

				var thrust = Maths.clamp((hoverDrone.body.position.y - th + hoverDrone.body.velocity.y) / 300, 0, 1);

				// var thrust = hoverDrone.body.position.y > targetHeight ? 1 : 0;
				hoverDrone.thrust[0] = hoverDrone.thrust[1] = thrust;
			});
		}
		// addHoverDrone(40, new Vec2(1500, 1900));
		// addHoverDrone(100, new Vec2(2300, 2100));
		// addHoverDrone(200, new Vec2(500, 2500));

		// ================ build level ==================== //

		function addGround(x:Float, y:Float, width:Float, height:Float, color:Int = 0x8888FF, dyn = false) {

			var cx = x+(width/2);
			var cy = y-(height/2);

			var gm = new BoxGeometry(width,height,dyn ? width : 100);
			var mm = new MeshLambertMaterial({color: color});
			var ms = new Mesh(gm, mm);
			ms.position.set(cx, cy, 0);
			stage.add(ms);

			// var gg = new Graphics();
			// gg.beginFill(color);
			// gg.drawRect(-width/2,-height/2,width,height);
			// gg.endFill();
			// spaceGraph.addChild(gg);
			// gg.position.set(cx, cy);

			var b = new Body(dyn ? BodyType.DYNAMIC : BodyType.STATIC);
			var s = new Polygon(Polygon.box(width,height));
			s.material.density *= 0.1;
			s.material.dynamicFriction *= 5;
			s.material.staticFriction *= 5;
			s.body = b;
			b.position.setxy(cx, cy);
			b.space = space;

			if (dyn) views.push({update: function(dt) {
				ms.position.x = b.position.x;
				ms.position.y = b.position.y;
				ms.rotation.z = b.rotation;
			}});

		}

		var red = 0xFF4444;
		var green = 0x66FF66;
		var blue = 0x8888FF;

		// bounds
		addGround(-1500,9980,	1020,	9960, 	red); // left
		addGround(-1500,20,	8500,	1000, 	red); // bottom
		addGround(5980,	10000,	1020,	9980, 	red); // right
		addGround(-1500,11000,	8500,	1000, 	red); // top

		// --- platforms area 1
		addGround(100,800,150,20, green);
		addGround(600,750,150,20, green);
		addGround(300,400,150,20, green);
		// on left wall
		addGround(-430,1000,150,20, green);
		addGround(-440,1400,150,20, green);
		addGround(-450,1800,150,20, green);
		addGround(-460,2200,150,20, green);
		addGround(-470,2600,150,20, green);
		// on right
		// addGround(900,-1000,150,20);
		addGround(910,1400,150,20);
		addGround(920,1800,150,20);
		addGround(930,2200,150,20);
		addGround(940,2600,150,20);

		// area 1 and 2 ceiling
		addGround(-480,	3000,	4500,	20, 	blue); // top

		// gate to area 2
		addGround(1100,2980,20,(1960/2)-160+1000); // top wall
		addGround(1100,1980-(1960/2)-160,20,(1960/2)-160); // bottom wall
		addGround(1120,1980-(1960/2)+160+20,700,20); // tunnel top
		addGround(1120,1980-(1960/2)-160,700,20); // tunnel bottom

		addGround(2200,1500,20,1000);
		addGround(2220,1500,200,20);

		// platforms on right wall
		var prwy = 300;
		while (prwy < 9800) {
			addGround(5880, prwy, 100, 20, green);
			prwy += 500;
		}


		// stack
		function buildStack(count:Int, left:Float, bottom:Float, color:Int) {

			var w = 36;
			var h = 40;

			var top = bottom+h;
			while (count > 0) {
				for (x in 0...count) {
					addGround(left + w*x, top, w, h, color, true);
				}
				count--;
				left+=w/2;
				top += h;
			}
		}
		buildStack(8, 1400, 20, 0xFF44FF);
		buildStack(5, 2230, 1500, 0x880000);

		buildStack(16, 2500, 20, 0x00FF00);

		// ambush the hover drone
		addGround(2450,2500,200,20);
		buildStack(6, 2450, 2500, 0x990000);


		// Browser.window.addEventListener("gamepadconnected", function(e:Dynamic) {
		// 	if (pad != null) return;
		// 	Browser.window.console.log("Pad connected", e.gamepad);
		// 	pad = e.gamepad;
		// });


	}

	private function adaptToSize() {
		var w = Tortilla.canvas.width;
		var h = Tortilla.canvas.height;
		// renderer.resize(w,h);
		var aspect = w / h;
		trace("adapt to aspect", aspect);
		cam.aspect = aspect;
		renderer.setSize(w,h,false);

	}

	private var avgCamPos:Vector3 = null;

	

	public function frame(ctx:Dynamic, dt:Float) {

		// this updates existing Gamepad objects
		var pads = Browser.navigator.getGamepads();

		KeyboardInput.process();

		for (c in controllers) c(dt);
		

		// move the world
		var wdt = dt/1;
		for (e in entities) e.step(wdt);
		space.step(wdt);

		for (v in views) v.update(wdt);

		// --- update camera

		var pdPos = new Vec2();
		var pdVel = new Vec2();
		for (pd in playerDrones) {
			pdPos = pdPos.add(pd.body.position);
			pdVel = pdVel.add(pd.body.velocity);

			// trace(pd.body.velocity.x, pd.body.localVectorToWorld(new Vec2(0,-70)).x);
			// trace(pd.headVel.x, pd.headVel.y);
		}
		// trace(pdPos.x, pdPos.x);
		pdPos = pdPos.mul(1/playerDrones.length);
		pdVel = pdVel.mul(1/playerDrones.length);

		var pdvl = pdVel.length;
		if (pdVel.length > 200) pdVel.length = 200;

		var minZ = 0.0;
		if (playerDrones.length == 2)
			minZ = playerDrones[0].body.position.add(playerDrones[1].body.position.mul(-1)).length * 1.25;

		var camPos2d = pdPos.add(pdVel.mul(0.5));
		var camPos = new Vector3(camPos2d.x, camPos2d.y, Math.max(minZ, 700 + pdvl * 0.6));
		if (avgCamPos == null) avgCamPos = camPos;
		else {
			avgCamPos.x = Maths.averageEase(avgCamPos.x, camPos.x, 10, dt);
			avgCamPos.y = Maths.averageEase(avgCamPos.y, camPos.y, 10, dt);
			avgCamPos.z = Maths.averageEase(avgCamPos.z, camPos.z, 3, dt);
		}
		cam.position.x = avgCamPos.x;
		cam.position.y = avgCamPos.y;
		cam.position.z = avgCamPos.z;
		// spaceGraph.position.set(
			// -avgCamPos.x + Tortilla.canvas.width/2,
			// -avgCamPos.y + Tortilla.canvas.height/2
		// );

		cam.updateProjectionMatrix();
		renderer.render(stage, cam);

	}


}