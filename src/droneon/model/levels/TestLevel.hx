package droneon.model.levels;

import droneon.model.World;

class TestLevel extends Level {
	
	public function new(world:World) {
		super(world);
	}

	public function build() {

		var red = 0xFF4444;
		var green = 0x66FF66;
		var blue = 0x8888FF;

		// bounds
		addGround(-1500,10000,	1020,	9960, 	red, false, true); // left
		addGround(-1500,20,	8500,	1000, 	red, false, true); // bottom
		addGround(5980,	10000,	1020,	9980, 	red, false, true); // right
		addGround(-1500,11000,	8500,	1000, 	red, false, true); // top

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
			addGround(5830, prwy, 150, 20, green);
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

	}

}