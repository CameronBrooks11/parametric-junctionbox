default:
    @just --list

# Render each part and check its size, the holes on each side and in the floor
test:
    python3 tests/test_junctionbox.py

# Render the README picture into assets/
images:
    @mkdir -p assets
    montage -version >/dev/null
    openscad --render --camera=0,0,0,55,0,25,330 --viewall --autocenter --imgsize=450,400 --colorscheme=Tomorrow -D 'part="box"' -o assets/box.png junctionbox.scad
    openscad --render --camera=0,0,0,55,0,25,330 --viewall --autocenter --imgsize=450,400 --colorscheme=Tomorrow -D 'part="lid"' -o assets/lid.png junctionbox.scad
    montage assets/box.png assets/lid.png -tile 2x1 -geometry +4+4 assets/junctionbox.png
    rm assets/box.png assets/lid.png
