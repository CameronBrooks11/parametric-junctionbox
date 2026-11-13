// Shows where the box isn't, inside a slab, so each hole in the slab is a
// separate piece. PROBE picks the slab:
//   "south", "north", "west", "east": one wall, away from the corner pillars
//   "floor": the floor's centre, where the four mounting holes are
include <../junctionbox.scad>;

PROBE = "east";
part = "none";
w = junctionbox_width;
h = junctionbox_height;
t = junctionbox_thickness;
s = junctionbox_skin;
m = 2 * junctionbox_radius;  // clear of the corner pillars

module slab()
{
    // Inside the wall's thickness only, so the air on either side doesn't
    // join the holes into one piece.
    if (PROBE == "south") translate([ m, 0.5, 1 ]) cube([ w - 2 * m, s - 1, t - 2 ]);
    if (PROBE == "north") translate([ m, h - s + 0.5, 1 ]) cube([ w - 2 * m, s - 1, t - 2 ]);
    if (PROBE == "west") translate([ 0.5, m, 1 ]) cube([ s - 1, h - 2 * m, t - 2 ]);
    if (PROBE == "east") translate([ w - s + 0.5, m, 1 ]) cube([ s - 1, h - 2 * m, t - 2 ]);
    if (PROBE == "floor") translate([ 10, 10, 1 ]) cube([ w - 20, h - 20, 1 ]);
}

intersection()
{
    slab();
    difference()
    {
        translate([ -2, -2, 0 ]) cube([ w + 4, h + 4, t ]);
        junctionbox();
    }
}
