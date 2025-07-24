
# Big parts of this script are inspired by:
# https://github.com/9ary/yosys-spartan6-example/blob/master/synthesize.sh

# XST developer reference, very useful for figuring out what the arguments are for the XST CLI tooling
# https://www.rose-hulman.edu/class/cs/csse232/xilinx/devref.pdf

# The project name, should match the name of your top level module
PROJECT_NAME = TopLevel
# The file containing your toplevel
SRC_DIR      = src
# The FPGA board constraints file
UCF          = mimasv2.ucf
# The FPGA chip itself
FPGA         = xc6slx9-csg324
# FPGA Speed
SPEED 	     = 2
# The SPI flash memory chip name
SPI_PART     = m25p16
# The SPI flash memory amount, in bytes
SPI_SIZE     = 16384
# The Xilinix-ISE root directory, we comment it out here as it is passed via environment variable
XILINX_ISE   = ${shell echo $$(dirname $$(which xilinx-ise))/..}
# The directory containing the `src` directory
BASE_DIR     = ${shell pwd}
# The directory containing all the output artifacts
OUTPUT_DIR   = $(BASE_DIR)/build

## DO NOT MODIFY ##
SYNTH_DIR    := ${OUTPUT_DIR}/synth
CLASH_DIR    := ${OUTPUT_DIR}/clash
HDL_DIR      := ${OUTPUT_DIR}/hdl
XST_DIR      := ${SYNTH_DIR}/xst
XST_TMP_DIR  := ${XST_DIR}/projnav.tmp
PART 	     := ${FPGA}-${SPEED}

## Rules ##

.PHONE: flash bin synth pnr timing clean valid_install

flash: valid_install ${SYNTH_DIR}/${PROJECT_NAME}.bin
	programmer.py --filename ${SYNTH_DIR}/${PROJECT_NAME}.bin --verify

bin: valid_install ${SYNTH_DIR}/${PROJECT_NAME}.bin


synth: valid_install ${SYNTH_DIR}/${PROJECT_NAME}.ngc
	@echo "Bitstream binary finished, can be found at: ${SYNTH_DIR}/${PROJECT_NAME}.bin"

pnr: valid_install ${SYNTH_DIR}/${PROJECT_NAME}.ncd
	@echo "Finished place and route"

timing: valid_install ${SYNTH_DIR}/${PROJECT_NAME}.twr
	@echo "Generated TWR file, can be found at: ${SYNTH_DIR}/${PROJECT_NAME}.twr"

hdl: valid_install ${HDL_DIR}/topEntity.v
	@echo "Compiled Clash into Verilog"

clean:
	rm -r ${OUTPUT_DIR}
	rm -r dist-newstyle
	rm -r .ghc.environment.x86_64-linux-9.10.1

# Verify that ISE is installed
valid_install:
	@if [ ! -x "${XILINX_ISE}/xst" ]; then \
		echo "Please point XILINX_ISE to your ISE installation"; \
		exit 1; \
	fi

# Compilation
${HDL_DIR}/topEntity.v: ${SRC_DIR}/*
	cabal build --write-ghc-environment-files always
	mkdir -p ${CLASH_DIR}
	cabal run clash -- -package-env ".ghc.environment.x86_64-linux-9.10.1" -outputdir ${CLASH_DIR} --verilog $<
	rm -rf ${HDL_DIR}
	mv ${CLASH_DIR}/${PROJECT_NAME}.topEntity ${HDL_DIR}

# Synthesis
${SYNTH_DIR}/${PROJECT_NAME}.prj: ${HDL_DIR}/topEntity.v
	mkdir -p ${SYNTH_DIR}
	echo "" > "${SYNTH_DIR}/${PROJECT_NAME}.prj"
	for HDL in $^; do \
		echo "verilog work $$HDL" >> "${SYNTH_DIR}/${PROJECT_NAME}.prj"; \
	done

${SYNTH_DIR}/${PROJECT_NAME}.xst: ${SYNTH_DIR}/${PROJECT_NAME}.prj
	mkdir -p ${XST_DIR}
	mkdir -p ${XST_TMP_DIR}
	echo "set -tmpdir \"${XST_TMP_DIR}\"" > ${SYNTH_DIR}/${PROJECT_NAME}.xst
	echo "set -xsthdpdir \"${XST_DIR}\"" >> ${SYNTH_DIR}/${PROJECT_NAME}.xst
	echo "run" >> ${SYNTH_DIR}/${PROJECT_NAME}.xst
	echo "-ifn ${SYNTH_DIR}/${PROJECT_NAME}.prj" >> ${SYNTH_DIR}/${PROJECT_NAME}.xst
	echo "-ofn ${SYNTH_DIR}/${PROJECT_NAME}.ngc" >> ${SYNTH_DIR}/${PROJECT_NAME}.xst
	echo "-ofmt NGC" >> ${SYNTH_DIR}/${PROJECT_NAME}.xst
	echo "-p ${PART}" >> ${SYNTH_DIR}/${PROJECT_NAME}.xst
	echo "-top topEntity" >> ${SYNTH_DIR}/${PROJECT_NAME}.xst

${SYNTH_DIR}/${PROJECT_NAME}.ngc: ${SYNTH_DIR}/${PROJECT_NAME}.xst
	cd ${SYNTH_DIR} && ${XILINX_ISE}/xst -ifn ${SYNTH_DIR}/${PROJECT_NAME}.xst

# Place & route
${SYNTH_DIR}/${PROJECT_NAME}.ngd: ${SYNTH_DIR}/${PROJECT_NAME}.ngc
	cd ${SYNTH_DIR} && ${XILINX_ISE}/ngdbuild -uc "${BASE_DIR}/${UCF}" -p "${PART}" "${PROJECT_NAME}.ngc" "${PROJECT_NAME}.ngd"

${SYNTH_DIR}/${PROJECT_NAME}_map.ncd: ${SYNTH_DIR}/${PROJECT_NAME}.ngd
	cd ${SYNTH_DIR} && ${XILINX_ISE}/map -ol high -p "${PART}" -w -mt 2 -o "${PROJECT_NAME}_map.ncd" "${PROJECT_NAME}.ngd"

${SYNTH_DIR}/${PROJECT_NAME}_map.pcf ${SYNTH_DIR}/${PROJECT_NAME}.par ${SYNTH_DIR}/${PROJECT_NAME}.ncd: ${SYNTH_DIR}/${PROJECT_NAME}_map.ncd
	cd ${SYNTH_DIR} && ${XILINX_ISE}/par -w -ol high -mt 4 "${PROJECT_NAME}_map.ncd" "${PROJECT_NAME}.ncd"

# Timing report & bitstream generation
${SYNTH_DIR}/${PROJECT_NAME}.twr: ${SYNTH_DIR}/${PROJECT_NAME}_map.pcf ${SYNTH_DIR}/${PROJECT_NAME}.par
	cd ${SYNTH_DIR} && ${XILINX_ISE}/trce -v -n -fastpaths "${PROJECT_NAME}.ncd" -o "${PROJECT_NAME}.twr" "${PROJECT_NAME}_map.pcf"

${SYNTH_DIR}/${PROJECT_NAME}.bin: ${SYNTH_DIR}/${PROJECT_NAME}.ncd
	cd ${SYNTH_DIR} && ${XILINX_ISE}/bitgen -w -g Binary:Yes -g Compress -g UnusedPin:PullNone "${PROJECT_NAME}.ncd"

