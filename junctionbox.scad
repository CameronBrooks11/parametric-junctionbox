// junctionbox.scad: a parametric electrical junction box.
//
// A rounded box with cable-gland holes in its walls and a screw-down lid, and two
// accessories: a slit bushing that grips a thin cable in a gland, and a plug for a
// hole you don't use. The box stands on z = 0 with a corner at the origin.
// MIT licence; see LICENSE.

/* [Part] */
// What to draw
part = "box"; // [box, lid, bushing, blocker, none]

/* [Box] */
// Outside size along x (mm)
junctionbox_width = 100; // [40:1:300]
// Outside size along y (mm)
junctionbox_height = 100; // [40:1:300]
// Outside height, along z (mm)
junctionbox_thickness = 50; // [20:1:200]
// Wall, floor and lid thickness (mm)
junctionbox_skin = 3; // [1.6:0.2:8]
// Corner radius; the lid-screw pillars are twice this across (mm)
junctionbox_radius = 8; // [4:0.5:20]

/* [Holes] */
// Gland hole diameter: 20.5 fits M20 glands (mm)
junctionbox_cablediam = 20.5; // [6:0.5:40]
// Gland holes in the north wall (+y)
nh = 2; // [0:5]
// Gland holes in the south wall (-y)
sh = 2; // [0:5]
// Gland holes in the west wall (-x)
wh = 2; // [0:5]
// Gland holes in the east wall (+x)
eh = 2; // [0:5]
// Lid screws, for self-tapping screws into the pillars (mm)
junctionbox_lidscrewdiam = 3; // [2:0.5:5]
// Holes in the floor for fixing the box to a surface (mm)
junctionbox_mountscrewdiam = 3; // [2:0.5:6]
// How far in from each edge the floor holes are (mm)
junctionbox_mountoffset = 20; // [8:1:60]

/* [Bushing] */
// Outside diameter: the gland's cable range (mm)
bushing_od = 12; // [4:0.5:30]
// Inside diameter: the thinner cable (mm)
bushing_id = 6.8; // [2:0.1:25]
// Length (mm)
bushing_length = 30; // [5:1:60]
// Width of the slit along it, as an angle (degrees)
bushing_slitangle = 18; // [5:1:60]

/* [Hidden] */
$fa = 1;
$fs = 0.4;

W = junctionbox_width;
H = junctionbox_height;
T = junctionbox_thickness;
SKIN = junctionbox_skin;
R = junctionbox_radius;
// The pillars' centres sit on the corners' arcs' centres.
CORNERS = [[R, R], [W - R, R], [R, H - R], [W - R, H - R]];

// The box's outline, corner at the origin.
module outline(inset = 0) {
  hull() for (c = CORNERS) translate(c) circle(r = R - inset);
}

module pillars() {
  for (c = CORNERS) translate([c[0], c[1], 0]) cylinder(r = R, h = T);
}

// n holes through a wall, each centred in an equal share of the wall between the
// corner pillars, at half the box's inside height. `at` places the wall's start and
// `dir` runs along it.
module wall_holes(n, at, dir, span, normal) {
  assert((span - 4 * R) / n >= junctionbox_cablediam + 1,
         str(n, " gland holes of ", junctionbox_cablediam, " mm don't fit along a ", span,
             " mm wall: at most ", floor((span - 4 * R) / (junctionbox_cablediam + 1))));
  for (i = [1:1:n]) {
    p = at + dir * (2 * R + (span - 4 * R) * (i - 0.5) / n);
    translate([p[0], p[1], SKIN + (T - SKIN) / 2])
      rotate(normal) rotate([0, 90, 0]) cylinder(d = junctionbox_cablediam, h = 4 * SKIN, center = true);
  }
}

module junctionbox() {
  difference() {
    union() {
      difference() {
        linear_extrude(T) outline();
        translate([0, 0, SKIN]) linear_extrude(T) outline(SKIN);
      }
      pillars();
    }
    // Pilot holes for the lid screws, down the pillars.
    for (c = CORNERS) translate([c[0], c[1], SKIN]) cylinder(d = junctionbox_lidscrewdiam * 0.8, h = T);
    // Gland holes: north and south run along x, east and west along y.
    if (nh > 0) wall_holes(nh, [0, H - SKIN / 2], [1, 0], W, 90);
    if (sh > 0) wall_holes(sh, [0, SKIN / 2], [1, 0], W, 90);
    if (wh > 0) wall_holes(wh, [SKIN / 2, 0], [0, 1], H, 0);
    if (eh > 0) wall_holes(eh, [W - SKIN / 2, 0], [0, 1], H, 0);
    // Floor holes, junctionbox_mountoffset in from each edge.
    o = junctionbox_mountoffset;
    for (x = [o, W - o], y = [o, H - o]) translate([x, y, -1]) cylinder(d = junctionbox_mountscrewdiam, h = SKIN + 2);
  }
}

module lid() {
  difference() {
    linear_extrude(SKIN) outline();
    for (c = CORNERS) translate([c[0], c[1], -1]) cylinder(d = junctionbox_lidscrewdiam + 0.4, h = SKIN + 2);
  }
}

// A sleeve with a slit along it, so it closes around a thin cable inside a gland.
module bushing() {
  difference() {
    cylinder(d = bushing_od, h = bushing_length);
    translate([0, 0, -1]) cylinder(d = bushing_id, h = bushing_length + 2);
    translate([0, 0, -1]) linear_extrude(bushing_length + 2)
      polygon([[0, 0], [bushing_od * cos(bushing_slitangle / 2), bushing_od * sin(bushing_slitangle / 2)],
               [bushing_od * cos(bushing_slitangle / 2), -bushing_od * sin(bushing_slitangle / 2)]]);
  }
}

// A plug for an unused gland hole: a cap outside the wall, and a stem that fills the
// hole through the wall with a little room to push it in.
module blocker() {
  cap = 2;
  cylinder(d = junctionbox_cablediam + 6, h = cap);
  translate([0, 0, cap - 0.01]) cylinder(d1 = junctionbox_cablediam - 0.2, d2 = junctionbox_cablediam - 0.6, h = SKIN + 1.01);
}

if (part == "box") junctionbox();
else if (part == "lid") lid();
else if (part == "bushing") bushing();
else if (part == "blocker") blocker();
else assert(part == "none", str("part must be box, lid, bushing, blocker or none, not \"", part, "\""));
