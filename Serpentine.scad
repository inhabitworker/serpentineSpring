// Input Values

/* [Dimension] */
// Desired number of waves (each side).
    Frequency = 4;
// Full length of the mesh. (mm)
    Length = 50;
// Width of the mesh (mm).
    Width = 12;
// The breadth of the spring line (mm).
    Thickness = 2; // [0.5 : 0.01 : 100]
// Height of the mesh (mm).
    Depth = 4;
// Inward tilt of rungs (deg).
    Angle = 15; // [0 : 1 : 45]
// Factor continuously modifying shape from straight "zig-zag" to circular wave. 
    Roundness = 0.75; // [0: 0.05 : 1]
// Draw sharp angled caps when "Roundness" factor is zero?
    Corner = false;
    
/* [Terminals] */
// How far the terminals of the spring linearly extend beyond length (mm).
    Extension = 6;
// Center the terminals so they are centered.
    Centered = true;
// Design to add to each end of the spring.
    Design = "Hole"; // [None, Hole, Hoop, T, Rod]
    
/* [Hidden] */
    $fa = 12;
    $fs = 1;
    Clearance = 0.3;
    Guides = false;


// Computed Values

    // Centering Compensation:
        // This should happen either as component wrangling or at least some kind of recursing function 
        InitialSegment = Length/(2*Frequency);
        InitialAnchorY = Width/2 - Thickness/2;

        InitialAngleExtension = tan(Angle)*(Width/2 - Thickness) - (Thickness/2)/cos(Angle);
		InitialAnchorX  = (InitialSegment/2)*Roundness - InitialAngleExtension*(1-Roundness);

        InitialRadius = (InitialAnchorX + tan(Angle)*InitialAnchorY)/ (cos(Angle) + tan(Angle) + tan(Angle)*sin(Angle));
        InitialArcX = InitialRadius - cos(Angle) * InitialRadius;
        InitialArmX = tan(Angle) * (InitialAnchorY - InitialRadius - sin(Angle) * InitialRadius); 
        
        LengthAdjustment = 2*(InitialArmX + InitialArcX) + Thickness;
	    AdjustedLength = Centered ? Length - LengthAdjustment : Length;
    
    // Main Values:
        Straight = Corner && Roundness == 0;

    	Wavelength = AdjustedLength/Frequency;
		Segment = Wavelength/2;
		Segments = Frequency*4;
		AnchorY = Width/2 - Thickness/2;
        // Allow extending into "overhang"/angle region when flattening.
        AngleExtension = tan(Angle)*(Width/2 - Thickness) - (Thickness/2)/cos(Angle);
		AnchorX  = (Segment/2)*Roundness - AngleExtension*(1-Roundness);

		Radius = (AnchorX + tan(Angle)*AnchorY)/ (cos(Angle) + tan(Angle) + tan(Angle)*sin(Angle));
		   
		ArcX = Radius - cos(Angle) * Radius;
		ArcY = sin(Angle) * Radius;
		ArmY = AnchorY - Radius - sin(Angle) * Radius;   
		ArmX = tan(Angle) * ArmY; 

    // Useful Guide Values:
		Overlap = 2*(ArmX + ArcX) + Thickness;
		RealDiameter = 2*Radius+Thickness;
		Offset = RealDiameter - Overlap;
		Gap = RealDiameter - 2 * Overlap;
    
    
// Assertions/Tests:

    // Plus thickness? Not sure.
    RequiredWidth = Radius + ArcY;
    assert(AnchorY > RequiredWidth, "Not enough space to draw segments, increase width or reduce angle.");        
       
// Dimensions/segmentation guide for visual checks.    
module Guide() {
  
    // Gap Guide   
    color("purple")
    translate([-Width/4, RealDiameter-Overlap,0])
    cube([Width/2, Overlap, Depth]);
    
    color("orange")
    translate([-Width/2,RealDiameter,0])
    cube([Width/2,Gap,Depth]);
    

    color("green")
    cube([Width/2,Offset,Depth]);
    
    // Main Segmentation Guide
    if(!Centered) {
        translate([0,Segment/2,-Depth])
        for(i = [0 : 1 : Segments-1]) {
            Colour = i%2 == 0 ? "red" : "blue";
            translate([0,i*Segment/2,0])
            color(Colour)
            translate([-Width/2,-Segment/2,0])
            cube([Width,Segment/2,1]);
        }
    } else {
        Offset = 2*(Wavelength / 2 - Radius + ArmX + ArcX);
    
        translate([-Width/2,Radius,-Depth])
        for(i = [0 : 1 : 2*Frequency-1]) {
            Colour = i%2 == 0 ? "red" : "blue";
            
            if(i%2 == 0) {
                translate([0,i*(Wavelength-Offset),0])
                color(Colour)
                translate([0,-Radius,0])
                cube([Width/2,2*Radius+Thickness,1]);
            } else {
                translate([Width/2,i*(Wavelength-Offset),0])
                color(Colour)
                translate([0,-Radius,0])
                cube([Width/2,2*Radius+Thickness,1]);
            }
        }
    }
}
    
if(Guides) {
    color("orange")
    translate([-Width/2, Length, -2*Depth])
    cube([Width, Thickness, 1]);

    Guide();
}

// For terminating spring with sector stopping centered
module Centering() {
    CenteringAnchorY = ArmY;
    CenteringAnchorX  = Overlap/2 - ArmX;
    CenteringRadius = (CenteringAnchorX + tan(Angle)*CenteringAnchorY)/ (cos(Angle) + tan(Angle) + tan(Angle)*sin(Angle));
    CenteringArcX = CenteringRadius - cos(Angle) * Radius;
    CenteringArcY = sin(Angle) * CenteringRadius;
    CenteringArmY = CenteringAnchorY - CenteringRadius - sin(Angle) * CenteringRadius;   
    CenteringArmX = tan(Angle) * CenteringArmY;
    CenteringArmExtrusion = sqrt(CenteringArmX^2 + CenteringArmY^2) + 0.1;

    union() {
        X1 = CenteringArmX + 0.01; //sqrt(ArmY^2 + ArmX^2);
        Y1 = Thickness/2; 
        X2 = -CenteringArmY - 0.01 - (Straight ? Thickness : 0);
        Y2 = -Thickness/2;

        firstPoints = [
            [X1 + (Straight ? (Thickness)*tan(Angle) + 0.01 : 0 ), Y1], 
            [X1 + (Straight ? 0.01 : 0), Y2], 
            [X2, Y2],
            [X2, Y1]
        ];
        firstPaths = [[0, 1, 2, 3]];

        rotate([0,0,180+Angle])
        linear_extrude(Depth) 
        polygon(firstPoints, firstPaths);

        // Arc 
        if(!Straight) {
            translate([CenteringAnchorY-CenteringRadius,-CenteringAnchorX,0])
            rotate_extrude(angle = 90 + Angle, $fn = 100) {
                translate([CenteringRadius-Thickness/2,0])
                square([Thickness,Depth]);
            }
        }
    }
}

// Half of spring segment/"rung", to be transformed and arrayed.
module Sector(Terminate = false) {

    union() {
        // First Arm (Arm connecting central axis.)
        if(Centered && Terminate) {
            translate([ArmY,ArmX,0])
            rotate([0,0,180])
            Centering();
        } else {
            X1 = sqrt(ArmY^2 + ArmX^2);
            Y1 = Thickness/2; 
            X2 = 0;
            Y2 = -Thickness/2;

            firstPoints = [
                [X1 + (Straight ? (Thickness)*tan(Angle) + 0.01 : 0 ), Y1], 
                [X1 + (Straight ? 0.01 : 0), Y2], 
                [X2, Y2],
                [X2, Y1]
            ];
            firstPaths = [[0, 1, 2, 3]];

            rotate([0,0,Angle])
            linear_extrude(Depth) 
            polygon(firstPoints, firstPaths);
        }

        // Second Arm (Arm to other sector, if non-full roundness.)
        if(Roundness != 1) {
            X1 = AnchorY - Thickness/2;
            Y1 = -AnchorX + (Straight ? Thickness/cos(Angle) : 0);
            X2 = AnchorY + Thickness/2;

            points = [
                [X1, -Segment/2], 
                [X1, Y1], 
                [X2, Y1], 
                [X2, -Segment/2]
            ];
            paths = [[0, 1, 2, 3]];

            linear_extrude(Depth) 
            polygon(points, paths);
        }

        // Rounding
        if(!Straight) {
            translate([AnchorY-Radius,-AnchorX,0])
            rotate_extrude(angle = 90 + Angle, $fn = 100) {
                translate([Radius-Thickness/2,0])
                square([Thickness,Depth]);
            }
        } else {
            // Insert chunk?
        }

        // Overlap Extension
        if(!Terminate) {
            rotate([0,0,Angle])
            translate([-0.1,-Thickness/2,0])
            cube([0.2,Thickness,Depth]);
        }
    }
}

// Sector();

// Full wave composed of sectors/union tissue.
module Wave(Start = false, End = false) {
    Connective = Thickness/5;
    
    Offset = Centered ? 0 +  ArcX + ArmX + Thickness/2  : Segment/2;
    translate([0, Offset, 0])
    
    union() {
        // Cap
        if(!Centered) {
            Sector();
        } else {
            translate([0,2*Segment,0])
            Sector(End);
        }
        
        rotate([0,0,180])
        Sector(Centered && Start);
        
        // Connective tissue for boolean between segments
        translate([AnchorY+Thickness/2-Width, - AnchorX - Connective/2 + Segment,0])
        cube([Thickness,Connective,Depth]);
        
        translate([0,Segment,0])
        mirror([1,0,0])
        Sector();
        
        translate([0,Segment,0])
        mirror([0,1,0])
        Sector();
        
        // Connective tissue for following sections if not endpoint
        Endpoint = Start && End;
        
        if(Roundness == 1 && (Centered || Endpoint != true)) {
            translate([AnchorY-Thickness/2, 3*AnchorX - Connective/2,0])
            cube([Thickness,Connective,Depth]);
        }
    }
}

module Terminal() {
    // Design = "None"; // [None, Hole, Hoop, T, Rod]

    // Hole
    HoleDisp = Extension*0.6 > 4 ? 4 : Extension*0.6; 

    // Hoop
    HoopOuterRadius = Extension/2;
    HoopInnerRadius = 3*HoopOuterRadius/4;

    union() {

        // Draw extension, subtract hole if desired.
        difference() {
            translate([-Thickness/2,0,0])
            cube([Thickness,Extension,Depth]);
            
            if(Design == "Hole") {
                translate([-Thickness,Extension - HoleDisp - HoleDisp/3, (Depth - 3*Depth/4)/2])
                cube([Thickness*2,HoleDisp,3*Depth/4]);
            }

            if(Design == "Hoop") {
                translate([0,3*Extension/4,-1/2])
                cylinder(Depth+1, HoopInnerRadius, HoopInnerRadius);
            }
        }
        
        // Desired Appendage

        if(Design == "Hoop") {
            difference() {
                translate([0,3*Extension/4,0])
                cylinder(Depth, HoopOuterRadius, HoopOuterRadius);

                translate([0,3*Extension/4,-1/2])
                cylinder(Depth+1, HoopInnerRadius, HoopInnerRadius);

                // Chamfer end to an Allowable Overhang
            }
        }

        if(Design == "T") {
            translate([-Width/4,Extension-Thickness,0])
            cube([Width/2, Thickness, Depth]);
        }

        if(Design == "Rod") {
            RodRadius = Thickness;

            translate([0,Extension-RodRadius/2,0])
            cylinder(2*Depth, RodRadius, RodRadius);
        }
    
        // Overlap 
        translate([-Thickness/2,-0.1,0])
        cube([Thickness,0.2,Depth]);
    }
    
}

// Create the array and union of full spring at freq. and terminals.
module Spring() {
    union() {
        for(i = [0 : 1 : Frequency-1]) {
          
            translate([0,i*Wavelength,0])
            Wave(i == 0, i == Frequency-1);   
        }
    }
}

module Draw() {
    union() {
        Spring();

        TerminalOffset = Centered ? 0 : Width/2 - Thickness/2;
        // Start
        translate([TerminalOffset,0, 0])
        rotate([0,0,180])
        Terminal(); 

        translate([TerminalOffset,Length,0])
        Terminal();
    }
}

Draw();



