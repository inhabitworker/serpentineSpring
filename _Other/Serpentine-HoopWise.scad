/* [Dimension] */
// Desired number of segments/hoops.
    Frequency = 8;
// Absolute length of the spring, without terminals. (mm)
    Length = 80;
// Maximum width of the spring (mm).
    Width = 15;
// The breadth of the spring line (mm).
    Thickness = 2;

/* [Mesh] */
// Height of the mesh (mm).
    Depth = 5;
// Roundess from straight "zig-zag" to round hoops.
    Roundness = 0.5; // [0: 0.01 : 1]
// Inward tilt of rungs (deg).
    Angle = 15; // [0 : 1 : 20]
// Design to add to each end of the spring.
    Terminals = "None"; // [None, Hoop, Bar, RodZ, RodX]
    
/* [Hidden] */
    $fs = 0.01;
    Clearance = 0.3;


// Computed Values

        // For our Hoop-Wise 
    
        // Distance that encompasses one "rung" of the spring.
    WorkingLength = Length * (1 + 1/Frequency);
    Segment = WorkingLength/Frequency;
    
    
        // Anchor Point (Curve Peak), constrained by width and length/frequency (segment) and then incorporating thickness of curve/line. 
        // Could augment to have the constrained point (Segment/2, Width/2-Thickness/2) be offset, as "roundness" factor.
    AnchorY = Width/2 - Thickness/2;
    AnchorX  = Segment/2;
    
        // Radius is such that it spans half a segment in any case, but accounts for thickness.
    Radius = Segment/2 - Thickness/2;
    
        // Segment = 2*Radius + Thickness
        // Segment = Length/(2*Radius + Thickness)
    
        // Arc/Arm Components, as used prior without absolute value.
        // This are the same. Wow!
        
        // Perhaps we can truly control the wave start/end by adjusting one of our anchor points, which is used to dynamically also judge an offset for mirroring and so on.abs
        
    ArcX = Radius - cos(Angle) * Radius;
    ArcY = sin(Angle) * Radius;
    ArmY = AnchorY - Radius - ArcY;   
    ArmX = tan(Angle) * ArmY;    
    
// Assertions

    // Given:
       // length/frequency - rungs explicitly spaced
       // width - a desired width to tend to
       // angle - angled rungs/additional arc
    // The extended arc can at most hit the origin, when drawing our initial sector. Thus the radius plus the width-wise component of the arc must be positive. 
    
    RequiredWidth = Radius+ArcY;
    assert(AnchorY > RequiredWidth, "Not enough space to draw segments, increase width or reduce angle.");
        
        // The "arm" doesn't matter as it will go the "last-mile" in any case, or not be present.

       
Offset = 2*(Segment / 2 - Radius + ArmX + ArcX);

// Dimensions/segmentation guide to check accuracy.
module Guide() {
    Offset = 2*(Segment / 2 - Radius + ArmX + ArcX);

    Gap = Segment - 2 * Offset;
    
    color("orange")
    translate([-Width/2,Segment,0])
    cube([Width/2,Gap,Depth]);
    
    Overlap = Segment - Offset;

    color("pink")
    cube([Width/2,Segment - Offset,Depth]);
    
    
    translate([-Width/2,Radius,-10])
    for(i = [0 : 1 : 2*(Frequency-2)-1]) {
        Colour = i%2 == 0 ? "red" : "blue";
        
        if(i%2 == 0) {
            translate([0,i*(Segment-Offset),0])
            color(Colour)
            translate([0,-Radius,0])
            cube([Width/2,2*Radius+Thickness,1]);
        } else {
            translate([Width/2,i*(Segment-Offset),0])
            color(Colour)
            translate([0,-Radius,0])
            cube([Width/2,2*Radius+Thickness,1]);
        }
    }
}

Guide();


// Half of spring segment/"rung", to be mirrored.
module Sector() {
    
    Offset = -(Segment / 2 - Radius + ArmX + ArcX);
    Extrude = sqrt(ArmX^2 + ArmY^2);
    
    // Arm and Overlap and Hoop and Overlap
    union() {
        // Arm and Overlap
        union() {
            // Initial arm
            // color("Pink")
            translate([0,Offset,Depth/2])
            rotate([90,0,90+Angle])
            linear_extrude(sqrt(ArmX^2 + ArmY^2) + 0.1)
            square([Thickness,Depth], center=true);
            
            // Overlap extension
            // color("purple")
            translate([0,Offset,Depth/2])
            rotate([90,0,90+Angle])
            square([Thickness,Depth],center=true);    
        }

        // color("skyblue")
        translate([AnchorY-Radius,-AnchorX,0])
        rotate_extrude(angle = 90 + Angle, $fn = 100) {
            translate([Radius-Thickness/2,0,0])
            square([Thickness,Depth]);
        }
        

    }
}

//Sector();

// Mirror to get full segment/"rung"
module Loop() {
    
    /* Width-wise segment
    union() {
        Sector();
        rotate([0,0,180])
        Sector();
    }*/
    
    union() {
        Sector();
        
        mirror([0,1,0])
        translate([0,Segment,0])
        Sector();
        
        // Connective tissues for hoop-to-hoop binding
        Connective = Thickness/5;
        //color("red")
        translate([AnchorY-Thickness/2, -AnchorX-Connective/2,0])
        cube([Thickness,Connective,Depth]);
    }
}

//Loop();


module Spring() {
    //Offset = Segment/2 - Radius;
    
    union() {
        for(i = [0 : 1 : Frequency+2]) {
            Mirror = i%2 == 0 ? 1 : 0;
            
            translate([0,(i+1)*Segment-i*Offset,0])
            mirror([Mirror,0,0])
                Loop();
        }
    }    
}

Spring();

// Apply additional terminals at end
module Terminals() {
    // Inclusive/Exclusive of distance?
    // None, Hooks, Rods, Hole, Block?
    
    union() {
        Spring();
    }
}

// Kind of ugly to wrap the spring in terminals module even when none are desired
// Terminals();


/*

    To-Do:

    - Actually accurate length, compnesating for the angle? This would involve incorporating the lengthwise component into... Where?
        - I think this would just be a case of having a "working length" that removes this component*2?
        - No, quite simply we subtract 2*component divided by frequency from the loop instance radius, which results in the spring overall being 2x less  this amount. In fact we can just dictate that the width is less this amount. 
        - There's probably a real nice way to include a variable that adjusts for the overhang nicely, but for now it's probably best to use Rung-wise and Hoop-wise methods seperately to get exact segments and length. Anything else would be a cop out cheat?

        - Perhaps it will involve adjusting the "origin" point, such that the radius stays within the segment.
            - In doing this, 

    - Parameterise start/end, either by offset that causes termination on center or outer, or over draw and then intersect with hull of desired length, offset appropriately.

    - Augment initial/constrained anchor point (Segment/2, Width/2-Thickness/2) to be offset, as "roundness" factor, so the mesh can be drawn as a zig-zag with bevel, continuously up to the standard rounded mesh.

*/

