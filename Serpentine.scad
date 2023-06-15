// Input Values

/* [Dimension] */
// Desired number of waves (each side).
    Frequency = 4;
// Full length of the mesh. (mm)
    Length = 50;
// Width of the mesh (mm).
    Width = 12;
// The breadth of the spring line (mm).
    Thickness = 2;
// Height of the mesh (mm).
    Depth = 5;
// Inward tilt of rungs (deg).
    Angle = 0; // [0 : 1 : 45]
// Factor ranging beveled "zig-zag" to circular wave.
    Roundness = 1; // [0: 0.05 : 1]
    
/* [Terminals] */
// How far the terminals of the spring linearly extend beyond length (mm).
    Extension = 6;
// Center the terminals so they are centered.
    Centered = true;
// Design to add to each end of the spring.
    Design = "Hole"; // [None, Hole, Hoop, T, Rod]
    
/* [Hidden] */
    $fa = 36;
    $fs = 2;
    Clearance = 0.3;
    Guides = false;


// Computed Values

    RoundnessNormalized = 0.9 * Roundness + 0.1;

    // Centering Compensation:
    
        InitialAnchorY = Width/2 - Thickness/2;
        InitialAnchorX  = (Length/(4*Frequency))*RoundnessNormalized;
        
        InitialRadius = (InitialAnchorX + tan(Angle)*InitialAnchorY)/ (cos(Angle) + tan(Angle) + tan(Angle)*sin(Angle));
        
        InitialArcX = InitialRadius - cos(Angle) * InitialRadius;
        InitialArmX = tan(Angle) * (InitialAnchorY - InitialRadius - sin(Angle) * InitialRadius); 
        
        LengthAdjustment = 2*(InitialArmX + InitialArcX) + Thickness;
    
	    AdjustedLength = Centered ? Length - LengthAdjustment : Length;
    
    // Main Values:
    
		Wavelength = AdjustedLength/Frequency;
		Segment = Wavelength/2;
		Segments = Frequency*4;

		AnchorY = Width/2 - Thickness/2;
		AnchorX  = (Segment/2)*RoundnessNormalized;
		
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
    RequiredWidth = Radius+ArcY;
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


// Centering shape for terminating center loops
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
        // Arm to arc
        translate([CenteringArmY,CenteringArmX,0])
        rotate([0,0,Angle])
        translate([0,0,Depth/2])
        rotate([90,0,90])
        mirror([0,0,1])
        linear_extrude(CenteringArmExtrusion)
        square([Thickness,Depth], center=true);
        
        // Arc to arm to arc
        translate([CenteringAnchorY-CenteringRadius,-CenteringAnchorX,0])
        rotate_extrude(angle = 90 + Angle, $fn = 100) {
            translate([CenteringRadius-Thickness/2,0])
            square([Thickness,Depth]);
        }
        
    }
    
}

// Half of spring segment/"rung", to be transformed and arrayed.
module Sector(Terminate = false) {
    // Arm and Overlap and Hoop and Overlap
    union() {
        // Arm and Overlap
        union() {
            // Initial arm
            ArmExtrusion = Terminate ? 1 : sqrt(ArmX^2 + ArmY^2) + 0.1;
            
            if(!Terminate) {
                translate([ArmY,ArmX,0])
                rotate([0,0,Angle])
                translate([0,0,Depth/2])
                rotate([90,0,90])
                mirror([0,0,1])
                linear_extrude(ArmExtrusion)
                square([Thickness,Depth], center=true);
            } else {
                translate([ArmY,ArmX,0])
                rotate([0,0,180])
                Centering();
            }
            
            // Overlap extension
            if(!Terminate) {
                rotate([0,0,Angle])
                translate([-0.1,-Thickness/2,0])
                cube([0.2,Thickness,Depth]);
            }
        }

        translate([AnchorY-Radius,-AnchorX,0])
        rotate_extrude(angle = 90 + Angle, $fn = 100) {
            translate([Radius-Thickness/2,0])
            square([Thickness,Depth]);
        }

        // Linear arm for non-roundness 
        if(Roundness != 1) {
            NonRoundArm = Segment/2 - AnchorX;

            translate([AnchorY,-AnchorX,0])
            translate([0,0,Depth/2])
            rotate([90,0,0])
            linear_extrude(NonRoundArm+0.01)
            square([Thickness,Depth], center=true);
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
        Sector(Start);
        
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

union() {
    Spring();

    // Start
    rotate([0,0,180])
    Terminal(); 

    translate([0,Length,0])
    Terminal();
}

