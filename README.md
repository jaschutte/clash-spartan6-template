## A Nix template created to kickstart projects wanting to use Clash for a Spartan-6 FPGA.

You can use this template yourself by creating an empty directory and then typing in the following command:

`nix flake init -t github:jaschutte/clash-spartan6-template#defaultTemplate`

By default the template is configured to run a simple LED counter for a Mimas V2 board.
Although it's simple enough to target different devices using the makefile!
Do be aware that this project aims to give a template for OLDER fpgas! It uses the old Xilinx-ISE tooling for synthesis and routing.

## Caveats
The programmer included only works for the Mimas V2 with modified firmware! How to flash this firmware can be found here:
https://github.com/jimmo/numato-mimasv2-pic-firmware

## Credits
jimno, for their awesome custom PIC firmware which makes uploading to the Mimas V2 much faster:
https://github.com/jimmo/numato-mimasv2-pic-firmware

9ary, who served as a great reference for the included makefile:
https://github.com/9ary/yosys-spartan6-example/blob/master/synthesize.sh
