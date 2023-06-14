/* [Dimension] */
// Desired number of segments or "rungs".
        // Should not this be total "wavelength", on one side?
            // Would that be hoop-wise? This might solve some issues.
    Frequency = 8;
// Full length of the mesh. (mm)
    Length = 60;
// Width of the mesh (mm).
    Width = 20;
// The breadth of the spring line (mm).
    Thickness = 2;
// Height of the mesh (mm).
    Depth = 5;
// Inward tilt of rungs (deg).
    Angle = 20; // [0 : 1 : 20]
// Roundess from straight "zig-zag" to round hoops.
    // Roundness = 0.5; // [0: 0.01 : 1]
    
/* [Terminals] */
// Add additional half-segments returning spring to center.
    Centered = false;
// Design to add to each end of the spring.
    Terminals = "None"; // [None, Hoop, Bar, RodZ, RodX]
// Include the terminal dimension in the length.
    Inclusive = false;
    
/* [Hidden] */
    $fs = 0.01;
    Clearance = 0.3;
    Overlap = 0.1;


// Computed Values
    
        // Distance that encompasses one "rung" of the spring.
    Segment = Length/Frequency;
    
        // Anchor Point (Curve Peak), constrained by width and length/frequency (segment) and then incorporating thickness of curve/line. 
        // Could augment to have the constrained point (Segment/2, Width/2-Thickness/2) be offset, as "roundness" factor.
    AnchorY = Width/2 - Thickness/2;
    AnchorX  = Segment/2;
    
        // Radius discovered by cobbling together x/y components of arm, arc and solving for the radius.
        // Discoverable because we are anchored to origin or tangent line extending to origin and the second anchor point.
    Radius = (AnchorX + tan(Angle)*AnchorY)/ (cos(Angle) + tan(Angle) + tan(Angle)*sin(Angle));
    
        // Arc/Arm Components, as used prior without absolute value.
    ArcX = Radius - cos(Angle) * Radius;
    ArcY = sin(Angle) * Radius;
    ArmY = AnchorY - Radius - sin(Angle) * Radius;   
    ArmX = tan(Angle) * ArmY;    
    
    // We need to factor, inclusive or exclusive, how an additional "rung"'s worth of distance is added, to have sectors at the start and end bringing our spring to the center.
        // Now you remember the issue, with how overhangs would effect this. By adding a sector, we run into issue of overhang. We could tend the radius so the final hoop sectors bringing us to the center have an aligning radius.
        
        // In the case of a radius worth, we are just adding an extra rung or increasing frequency by 1, and the using that distance for a circle radius = segment/2 attached and extended to center. Still retains angle, but the profile is slightly different.
        
        // Ego makes me want to solve across the whole spring though, slightly adjusting radius for a good fit, in every run. This is a big problem for me.
    
// Assertions

    // Given:
       // length/frequency - rungs explicitly spaced
       // width - a desired width to tend to
       // angle - angled rungs/additional arc
    // The extended arc can at most hit the origin, when drawing our initial sector. Thus the radius plus the width-wise component of the arc must be positive. 
    
    RequiredWidth = Radius+ArcY;
    assert(AnchorY > RequiredWidth, "Not enough space to draw segments, increase width or reduce angle.");
        
        // The "arm" doesn't matter as it will go the "last-mile" in any case, or not be present.

       
// Dimensions/segmentation guide to check accuracy.
    // Notice the overhangs.
module Guide() {
    translate([0,Segment/2,-Depth])
    for(i = [0 : 1 : 2*(Frequency-1)+1]) {
        Colour = i%2 == 0 ? "red" : "blue";
        translate([0,i*Segment/2,0])
        color(Colour)
        translate([-Width/2,-Segment/2,0])
        cube([Width,Segment/2,1]);
    }
}

Guide();


// Half of spring segment/"rung", to be mirrored.
module Sector() {
    // Arm and Overlap and Hoop and Overlap
    union() {
        // Arm and Overlap
        union() {
            // Initial arm
            // color("Pink")
            rotate([0,0,Angle])
            translate([0,-Thickness/2,0])
            rotate([90,0,90])
            //linear_extrude(Width/2)
            linear_extrude(sqrt(ArmX^2 + ArmY^2) + 0.1)
            square([Thickness,Depth]);
            
            
            // Overlap extension
            // color("purple")
            rotate([0,0,Angle])
            translate([0,-Thickness/2,0])
            rotate([90,0,90])
            square([Thickness,Depth]);
            
        }

        //color("skyblue")
        translate([AnchorY-Radius,-AnchorX,0])
        rotate_extrude(angle = 90 + Angle, $fn = 100) {
            translate([Radius-Thickness/2,0,0])
            square([Thickness,Depth]);
        }
        

    }
}

// Mirror to get full segment/"rung"
module Segment() {    
    union() {
        Sector();
        rotate([0,0,180])
        Sector();
    }
}

// Create an array of the spring segments to required length.
module Spring() {
    union() {
        for(i = [0 : 1 : Frequency-1]) {
            Mirror = i%2 == 0 ? 1 : 0;
            // Offset from drawing position
            translate([0,Segment/2,0])
            translate([0,i*Segment,0])
            mirror([0,Mirror,0])
            union() {
                // Connective tissues for hoop-to-hoop binding
                Connective = Thickness/5;
                if(i > 0 && i <= Frequency-1) {
                    if(i%2 != 0) {
                        //color("red")
                        translate([AnchorY-Thickness/2, -AnchorX-Connective/2,0])
                        cube([Thickness,Connective,Depth]);
                    } else {
                        //color("red")
                        translate([-AnchorY-Thickness/2, +AnchorX-Connective/2,0])
                        cube([Thickness,Connective,Depth]);
                    }
                }
                Segment();
            }
        }
    }
}

Spring();

// Apply additional terminals at end
module Terminals() {
}



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

