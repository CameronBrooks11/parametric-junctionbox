// A 120 x 80 mm box with its lid beside it, set up from another file.
include <../junctionbox.scad>

part = "none";
junctionbox_width = 120;
junctionbox_height = 80;
nh = 3;
sh = 0;
wh = 1;
eh = 1;

junctionbox();
translate([0, -90, 0]) lid();
