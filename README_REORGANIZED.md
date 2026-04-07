This export was reorganized so all VHDL source files live in `src/`.

What moved:
- Core source files are now in `src/`
- Testbenches remain in `sim_testbenches/`
- Memory init files remain in `mem_files/` and at the export root
- Original assembler/listing artifacts remain in `Test FIles/`

Important:
- `ECE449 Project Refactored.xpr` still exists, but its old source paths no longer match this layout.
- The cleanest next step is to create a new Vivado project and add:
  - `src/*.vhd`
  - `sim_testbenches/*.vhd`
  - the needed `.mem` files

Suggested folder usage:
- `src/` for design files
- `sim_testbenches/` for simulation benches
- `mem_files/` for ROM images
- `Test FIles/` for `.asm`, `.lst`, `.hex`, `.coe`
