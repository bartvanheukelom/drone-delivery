
package droneon;

import droneon.DroneView;
import droneon.model.Block;
import droneon.model.Drone;
import droneon.model.Entity;
import droneon.model.levels.TestLevel;
import droneon.model.World;
import js.Browser;
import js.html.Gamepad;
import nape.geom.Vec2;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.shape.Polygon;
import nape.shape.Shape;
import nape.space.Space;

import pixi.core.math.shapes.Rectangle;
import threejs.cameras.PerspectiveCamera;
import threejs.extras.geometries.BoxGeometry;
import threejs.lights.AmbientLight;
import threejs.lights.DirectionalLight;
import threejs.materials.MeshBasicMaterial;
import threejs.materials.MeshLambertMaterial;
import threejs.materials.MeshPhongMaterial;
import threejs.math.Vector3;
import threejs.objects.Mesh;
import threejs.renderers.WebGLRenderer;
import threejs.scenes.Fog;
import threejs.scenes.Scene;
import tortilla.Tortilla;
import weber.game.input.KeyboardInput;
import weber.Maths;

class Main {

	private var stage:Scene;
	private var renderer:WebGLRenderer;
	private var cam:PerspectiveCamera;

	private var controllers:Array<Float->Void> = [];	
	private var views:Array<Dynamic> = [];

	private var playerDrones:Array<Drone> = [];

	private var world:World;

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
		// renderer.shadowMapEnabled = true;

		stage = new Scene();

		cam = new PerspectiveCamera(45, 1, 100, 15000);
		cam.position.z = 750;
		stage.add(cam);
		cam.lookAt(new Vector3());

		stage.fog = new Fog(0x000000, 0, 1000);

		var ambient = new AmbientLight(0x557777);
		// var ambient = new AmbientLight(0xFF0000);
		stage.add(ambient);
		var sun = new DirectionalLight(0x886666, 1);
		sun.position.set(1,1.5,2.5);
		stage.add(sun);
		var sun2 = new DirectionalLight(0x000011, 1);
		sun2.position.set(1,-1.33,2.5);
		stage.add(sun2);


		// hud = new Container();
		// stage.addChild(hud);

		Tortilla.addEventListener(Tortilla.EV_RESIZED, adaptToSize);
		adaptToSize();		

		world = new World();

		// spaceGraph = new Container();
		// stage.addChild(spaceGraph);

		var gs = 250;
		var gz = -100;
		while (gz > -2000) {
			
			// var grid = new Graphics();
			// grid.lineStyle(1, 0x111111);
			var gx = -500;
			while (gx < 6000) {
				var l = new Mesh(new BoxGeometry(1,11000,1), new MeshBasicMaterial({color: 0x111122}));
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
				var l = new Mesh(new BoxGeometry(7100,1,1), new MeshBasicMaterial({color: 0x112211}));
				l.position.x = 3000;
				l.position.y = gy;
				l.position.z = gz;
				stage.add(l);
				// grid.moveTo(-550, gy);
				// grid.lineTo(6000, gy);
				gy += gs;
			}
			// spaceGraph.addChild(grid);

			gz -= 500;
		}

		// var bloom1 = untyped __js__("new PIXI.filters.BloomFilter()");
		// bloom1.blur = 3;
		// spaceGraph.filters = [bloom1];//, bloom2, bloom3];

		var rompOffset = -70;
		var rompHeight = 30*1.25;
		var rompWidth = 80;
		var rotorDistance = 75;

		

		for (px in 0...Std.parseInt(Tortilla.parameters.get("drones", "1"))) {
			var drone = new Drone(new Vec2(3700+px*250, 200), world, rompOffset, rompHeight, rompWidth, rotorDistance);
			playerDrones.push(drone);
			controllers.push(function(dt:Float) {

				var pads = Browser.navigator.getGamepads();

				for (a in 0...drone.thrusters.length) {
				
					var thrust;
					if (KeyboardInput.isKeyDown([
						[KeyboardInput.KEY_Q, KeyboardInput.KEY_E],
						[KeyboardInput.KEY_I, KeyboardInput.KEY_P],
						][px][a])) {
						thrust = 1.0;
					} else {
						if (!Tortilla.parameters.has("nopad") && pads.length > px && pads[px] != null) {
							var pad = pads[px];
							var ax = [2,5,0,1,3,4][a];
							thrust = Maths.rangeNormalize(pad.axes[ax], -1, 1);
							// thrust = Math.pow(thrust, 2);
						} else {
							thrust = 0.0;
						}
					}
					drone.thrusters[a].inThrust = thrust;

				}
			});

			
		}

		var hdSeq = 0;
		function addHoverDrone(rotorDistance:Float, pos:Vec2) {

			var seq = hdSeq;
			hdSeq += 1000;

			var hoverDrone = new Drone(pos, world, rompOffset, rompHeight, rompWidth, rotorDistance);

			var targetHeight = hoverDrone.body.position.y;
			var time = 0.0;
			controllers.push(function(dt:Float) {

				time += dt;

				var timeVar = Math.abs((Math.sin(Math.floor(time / 5) + seq) * 1000) % 1);
				var th = targetHeight - timeVar * 1000;

				var thrust = Maths.clamp((hoverDrone.body.position.y - th + hoverDrone.body.velocity.y) / 300, 0, 1);

				// var thrust = hoverDrone.body.position.y > targetHeight ? 1 : 0;
				for (t in 0...2)
					hoverDrone.thrusters[t].inThrust = thrust;
			});
		}
		// addHoverDrone(40, new Vec2(1500, 1900));
		// addHoverDrone(100, new Vec2(2300, 2100));
		// addHoverDrone(200, new Vec2(500, 2500));

		// ================ build level ==================== //

		new TestLevel(world).build();

		// Browser.window.addEventListener("gamepadconnected", function(e:Dynamic) {
		// 	if (pad != null) return;
		// 	Browser.window.console.log("Pad connected", e.gamepad);
		// 	pad = e.gamepad;
		// });

		for (e in world.entities) {
			if (Std.is(e, Drone)) {
				addDroneView(cast e);
			} else if (Std.is(e, Block)) {
				addBlockView(cast e);
			}
		}

	}

	private function addDroneView(drone:Drone) {
		var v = new DroneView(drone, [0x888888, 0xFFFFFF, 0x00FF00, 0x0000FF][playerDrones.indexOf(drone) + 1], stage);
		views.push(v);
	}

	private function addBlockView(b:Block) {

		var cx = b.rect.x+(b.rect.width/2);
		var cy = b.rect.y-(b.rect.height/2);

		var gm = new BoxGeometry(b.rect.width,b.rect.height, b.dyn ? b.rect.width : (b.deep ? 6000 : 200));
		var mm = new MeshPhongMaterial({color: b.color, ambient: b.color});
		var ms = new Mesh(gm, mm);
		// ms.receiveShadow = true;
		// ms.castShadow = true;
		ms.position.set(cx, cy, b.deep ? -3000 + 100 : 0);
		stage.add(ms);

		if (b.dyn) views.push({update: function(dt) {
			ms.position.x = b.body.position.x;
			ms.position.y = b.body.position.y;
			ms.rotation.z = b.body.rotation;
		}});

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
		world.step(wdt);

		for (v in views) v.update(wdt);

		// --- update camera

		var pdPos = new Vec2();
		var pdPosDiv = 0;
		var pdVel = new Vec2();
		for (pd in playerDrones) {
			pdPos = pdPos.add(pd.body.position);
			pdPosDiv++;
			pdVel = pdVel.add(pd.body.velocity);

			for (th in pd.thrusters) {
				pdPos = pdPos.add(th.body.position);
				pdPosDiv++;
			}

			// trace(pd.body.velocity.x, pd.body.localVectorToWorld(new Vec2(0,-70)).x);
			// trace(pd.headVel.x, pd.headVel.y);
		}
		// trace(pdPos.x, pdPos.x);
		pdPos = pdPos.mul(1/pdPosDiv);
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
		cam.position.z = avgCamPos.z * 60/cam.fov;

		stage.fog.near = cam.position.z + 0;
		stage.fog.far = stage.fog.near + 1000;
		

		// spaceGraph.position.set(
			// -avgCamPos.x + Tortilla.canvas.width/2,
			// -avgCamPos.y + Tortilla.canvas.height/2
		// );

		cam.updateProjectionMatrix();
		renderer.render(stage, cam);

	}


}