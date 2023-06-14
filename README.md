# Serpentine/Zig-Zag/Flat Spring Generator

## About:

We're using the length to determine hoop amount and radius, utilizing trigonometric components of halfway known points on the known shape. I'm sure there's a better way of doing this.

To make sure the length is inclusive of whole spring mesh, there is with current approach the matter of angle creating overhangs. By working with a length shorter this overhang, we solve the problem. Might be a desire to not compensate, but most users probably just looking for absolute constrained length.
        
Likely a way to use components at calc time, but I'm already making too many errors and probably taking wrong approach to this whole thing to begin with. Should have gone bezier.

## To-Do:

- Provide Terminal Options / Deeper Shaping
    - Hoop: Chamfer the ends so it can taper down from full depth, in case of allowing potentially small hooks to latch in.
    - Hole: Alter shape and control over sizing. 
    - Rod: Shape, extent, width/length/radius?
    - T: Width?

- Augment initial/constrained anchor point (Segment/2, Width/2-Thickness/2) to be offset, replaced with linear connection beyond, so as to allow "roundness" factor. Mesh can then be variously drawn as a zig-zag, with bevel, continuously up to the standard rounded mesh.

- Variable terminal positioning, maybe via parameterized start/end offset - offset that causes termination on center or outer, or over draw and then intersect with hull of desired length, offset appropriately? Sort of extravagant.

