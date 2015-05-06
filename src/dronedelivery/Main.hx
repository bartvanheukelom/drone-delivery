
package dronedelivery;

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
import tortilla.Tortilla;
import weber.game.input.KeyboardInput;
import weber.Maths;

class Main {

	private var stage:Container;
	private var renderer:SystemRenderer;

	private var hud:Container;
	private var thrustBars:Array<Graphics>;

	private var space:Space;
	private var droneBody:Body;

	private var spaceGraph:Container;
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

		KeyboardInput.init();

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

		

		space = new Space(new Vec2(0, 500));

		var rompOffset = 100;
		var rompHeight = 30;
		var rompWidth = 100;

		droneBody = new Body();
		droneBody.space = space;
		droneBody.position.setxy(800, -400);

		var sh = new Polygon(Polygon.box(rompWidth,rompHeight));
		sh.translate(new Vec2(0,rompOffset));
		droneBody.shapes.add(sh);

		// droneBody.align(); //TODO

		spaceGraph = new Container();
		stage.addChild(spaceGraph);

		droneGraph = new Graphics();
		for (a in 0...2) {

			droneGraph.lineStyle(4, 0x887766);
			droneGraph.moveTo(([-1,1][a]) * rompWidth * 0.4,-(rompHeight/2)+rompOffset);
			droneGraph.lineTo(([-1,1][a]) * (ROTOR_DISTANCE - 5),-45);

			droneGraph.lineStyle();
			droneGraph.beginFill(0xFFFF00);
			droneGraph.drawRect(ROTOR_DISTANCE * ([-1,1][a]) - 10, -50, 20, 30);
			droneGraph.endFill();

			var sh2 = new Polygon(Polygon.rect(ROTOR_DISTANCE * ([-1,1][a]) - 10, -50, 20, 30));
			sh2.body = droneBody;
			sh2.material.density = 0;


		}
		droneGraph.beginFill(0xFFFFFF);
		droneGraph.drawRect(-rompWidth/2,-(rompHeight/2)+rompOffset,rompWidth,rompHeight);
		droneGraph.endFill();
		spaceGraph.addChild(droneGraph);

		function addGround(x:Float, y:Float, width:Float, height:Float) {
			var gg = new Graphics();
			gg.beginFill(0x0000FF);
			gg.drawRect(0,0,width,height);
			gg.endFill();
			spaceGraph.addChild(gg);
			gg.position.set(x, y);

			var b = new Body(BodyType.STATIC);
			var s = new Polygon(Polygon.rect(0,0,width,height));
			s.body = b;
			b.position.setxy(x, y);
			b.space = space;

		}

		// bounds
		addGround(0,-2000,3000,20); // top
		addGround(0,-1980,20,1960); // left
		addGround(0,-20,3000,20); // bottom
		addGround(2980,-1980,20,1960); // right

		// platforms area 1
		addGround(100,-800,150,20);
		addGround(600,-750,150,20);
		addGround(300,-400,150,20);

		// gate to area 2
		addGround(1100,-1980,20,(1960/2)-160);
		addGround(1100,-1980+(1960/2)+160,20,(1960/2)-160);
		addGround(1120,-1980+(1960/2)-160-20,700,20);
		addGround(1120,-1980+(1960/2)+160,700,20);

		addGround(2200,-1500,20,1000);

		thrustBars = [];
		for (a in 0...2) {
			var bar = new Graphics();
			thrustBars.push(bar);

			bar.beginFill(0xFF8800);
			bar.drawRect(-8, -50, 16, 50);
			bar.endFill();

	
			droneGraph.addChild(bar);
			bar.y = -20;
			bar.x = (ROTOR_DISTANCE) * ([-1,1][a]);

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

	private var avgCamPos:Vec2 = null;

	private var avgThrust = [0.0, 0.0];

	public function frame(ctx:Dynamic, dt:Float) {

		// this updates existing Gamepad objects
		var pads = Browser.navigator.getGamepads();

		KeyboardInput.process();

		space.step(dt);

		var camPos = droneBody.position.add(droneBody.velocity.mul(0.33));
		if (avgCamPos == null) avgCamPos = camPos;
		else {
			avgCamPos.x = Maths.averageEase(avgCamPos.x, camPos.x, 5, dt);
			avgCamPos.y = Maths.averageEase(avgCamPos.y, camPos.y, 5, dt);
		} 

		spaceGraph.position.set(
			-avgCamPos.x + Tortilla.canvas.width/2,
			-avgCamPos.y + Tortilla.canvas.height/2
		);

		for (a in 0...2) {
			
			var thrust;
			if (KeyboardInput.isKeyDown([KeyboardInput.KEY_Q, KeyboardInput.KEY_P][a])) {
				thrust = 1.0;
			} else {
				if (!Tortilla.parameters.has("nopad") && pads.length > 0 && pads[0] != null) {
					var pad = pads[0];
					var ax = [2,5][a];
					thrust = Maths.rangeNormalize(pad.axes[ax], -1, 1);
				} else {
					thrust = 0.0;
				}
			}

			avgThrust[a] = Maths.averageEase(avgThrust[a], thrust, 20, dt);
			var avg = avgThrust[a];

			// avg = Maths.rangeExpand(avg, 0.5, 1);

			var bar = thrustBars[a];
			bar.scale.y = -avg;

			// thrust = Math.pow(thrust, 1.5);



			var force = new Vec2(0, -1500);
			force = force.mul(avg);
			force = force.mul(dt);
			force.rotate(droneBody.rotation);
			
			var point = new Vec2(ROTOR_DISTANCE * [-1,1][a], -50);
			point = droneBody.localPointToWorld(point);
			// Browser.window.console.log(force.x, force.y, point.x, point.y);
			droneBody.applyImpulse(force, point);

		}

		droneGraph.position.x = droneBody.position.x;
		droneGraph.position.y = droneBody.position.y;
		droneGraph.rotation = droneBody.rotation;

		renderer.render(stage);

	}


}