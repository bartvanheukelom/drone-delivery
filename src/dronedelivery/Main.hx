
package dronedelivery;

import js.Browser;
import js.html.Gamepad;
import nape.geom.Vec2;
import nape.phys.Body;
import nape.shape.Polygon;
import nape.shape.Shape;
import nape.space.Space;
import pixi.core.display.Container;

import pixi.core.graphics.Graphics;
import pixi.core.renderers.Detector;
import pixi.core.renderers.SystemRenderer;
import tortilla.Tortilla;
import weber.Maths;

class Main {

	private var stage:Container;
	private var renderer:SystemRenderer;

	private var hud:Container;
	private var thrustBars:Array<Graphics>;

	private var space:Space;
	private var droneBody:Body;

	private var droneGraph:Graphics;

	private static inline var ROTOR_DISTANCE = 100.0;

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

		var options:RenderingOptions = {};
		options.backgroundColor = 0x006666;
		options.resolution = 1;
		options.transparent = true;
		options.antialias = true;
		options.view = Tortilla.canvas;

		renderer = Detector.autoDetectRenderer(Tortilla.canvas.width, Tortilla.canvas.height, options);

		stage = new Container();

		hud = new Container();
		stage.addChild(hud);

		

		space = new Space(new Vec2(0, 100));

		var rompOffset = 100;
		var rompHeight = 30;
		var rompWidth = 50;

		droneBody = new Body();
		droneBody.space = space;
		droneBody.position.setxy(800, 400);

		var sh = new Polygon(Polygon.box(rompWidth,rompHeight));
		sh.translate(new Vec2(0,rompOffset));
		droneBody.shapes.add(sh);

		// droneBody.align(); TODO

		droneGraph = new Graphics();
		droneGraph.beginFill(0xFFFFFF);
		droneGraph.drawRect(-rompWidth/2,-(rompHeight/2)+rompOffset,rompWidth,rompHeight);
		droneGraph.endFill();
		for (a in 0...2) {
			droneGraph.beginFill(0xFFFF00);
			droneGraph.drawRect(ROTOR_DISTANCE * ([-1,1][a]) - 5, -50, 10, 30);
			droneGraph.endFill();
		}
		stage.addChild(droneGraph);

		thrustBars = [];
		for (a in 0...2) {
			var bar = new Graphics();
			thrustBars.push(bar);

			bar.beginFill(0xFF0000);
			bar.drawRect(-10, -100, 20, 100);
			bar.endFill();

	
			droneGraph.addChild(bar);
			bar.y = -50;
			bar.x = (ROTOR_DISTANCE + 30) * ([-1,1][a]);

		}

		// Browser.window.addEventListener("gamepadconnected", function(e:Dynamic) {
		// 	if (pad != null) return;
		// 	Browser.window.console.log("Pad connected", e.gamepad);
		// 	pad = e.gamepad;
		// });

		Tortilla.addEventListener(Tortilla.EV_RESIZED, adaptToSize);
		adaptToSize();

	}

	private function adaptToSize() {
		var w = Tortilla.canvas.width;
		var h = Tortilla.canvas.height;
		renderer.resize(w,h);

		// thrustBars[1].x = w - 20;
		// for (tb in thrustBars) tb.y = h - 10;

	}

	public function frame(ctx:Dynamic, dt:Float) {

		// this updates existing Gamepad objects
		var pads = Browser.navigator.getGamepads();

		space.step(dt);

		if (pads.length > 0 && pads[0] != null) {

			var pad = pads[0];

			for (a in 0...2) {
				var ax = [2,5][a];
				var thrust = Maths.rangeNormalize(pad.axes[ax], -1, 1);
				var bar = thrustBars[a];

				bar.scale.y = thrust;

				// thrust = Math.pow(thrust, 1.5);

				var force = new Vec2(0, -400);
				force = force.mul(thrust);
				force = force.mul(dt);
				force.rotate(droneBody.rotation);
				
				var point = new Vec2(ROTOR_DISTANCE * [-1,1][a], -50);
				point = droneBody.localPointToWorld(point);
				// Browser.window.console.log(force.x, force.y, point.x, point.y);
				droneBody.applyImpulse(force, point);

			}
			// Browser.window.console.log("---------");

		}

		droneGraph.position.x = droneBody.position.x;
		droneGraph.position.y = droneBody.position.y;
		droneGraph.rotation = droneBody.rotation;

		renderer.render(stage);

	}


}