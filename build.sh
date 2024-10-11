#!/bin/bash
################
# WHERE WE ARE #
################
DITEHOME=$(pwd)
#############
## VERSION ##
#############
echo "Please, select what to do:"
OPTIONS="build clean exit"
select opt in $OPTIONS; do
	if [ "$opt" = "build" ]; then
		CC="gcc"
		F77="gfortran"
		CPP="g++"
		COMPOPT="-O2 -funroll-loops"
		break
	elif [ "$opt" = "clean" ]; then
		echo "This operation cleans all libraries and executables leaving only the source code. Continue? [yes | no] "
		read answer
		if [ "$answer" == "yes" ]; then
			cd ${DITEHOME}/src
			make clean

			cd ${DITEHOME}/lib/zmatlib
			make clean

			cd ${DITEHOME}/lib/armadillo-8.500.0
			rm -rf ./build

			cd ${DITEHOME}/lib/dite2lib
			make clean

			cd ${DITEHOME}
			rm -rf ./build_zmatrix ./dite2_run ./Makefile.in

			echo ""
			echo "DITE2 build dir completely clean."
			echo ""
			exit
		else
			echo ""
			echo "Nothing to be done. Build script stopped."
			echo ""
			exit
		fi
		break
	elif [ "$opt" = "exit" ]; then
		echo "Build script interrupted"
		exit
		break
	else
		echo "Bad option - please answer 1 to build, 2 to clean the package, or 3 to exit"
	fi
done
###########################################
# PREPARATION OF THE make.COMPILERS FILE ##
###########################################
cat > ./Makefile.in << EOF
CC      = ${CC}
CPP     = ${CPP}
F77     = ${F77}
COMPOPT = ${COMPOPT}
LL=-L$(pwd)/lib/zmatlib/ -L$(pwd)/lib/armadillo-8.500.0/build/ -L$(pwd)/lib/dite2lib/
II=-I$(pwd)/lib/zmatlib/include/ -I$(pwd)/lib/armadillo-8.500.0/include -I$(pwd)/lib/dite2lib/
LIBS=-std=c++11 -ldite2 -lzmat -larmadillo -D_ARMA_USE_LAPACK -llapack -lblas
EOF
#############################
# BUILD THE ZMATLIB LIBRARY #
#############################
cd ${DITEHOME}/lib/
tar zxf ./zmatlib.tgz
cd zmatlib/
make -j4
ZMATPATH=$(pwd)
# Check if ZMAT has been built
log=`find -name "libzmat.a"`
if [ -z "$log" ]; then
	echo ""
	echo "ERROR: it was not possible to build the ZMAT library (lib/zmatlib/). Please, check the Makefile therein."
	echo ""
	echo "Build script stopped"
	exit
fi
###############################
# BUILD THE ARMADILLO LIBRARY #
###############################
cd ${DITEHOME}/lib/
tar zxf armadillo-8.500.0.tgz
cd armadillo-8.500.0/
mkdir build
cd build
cmake ../ -DCMAKE_INSTALL_PREFIX:PATH=${DITEHOME}/lib/armadillo-8.500.0/build
make -j4
# Check if ARMADILLO has been built
log=`find -name "libarmadillo.so"`
if [ -z "$log" ]; then
	echo ""
	echo "ERROR: it was not possible to build the ARMADILLO library (lib/armadillo-8.500.0/). Please, check the Makefile therein."
	echo ""
	echo "Build script stopped"
	exit
fi
###########################
# BUILD THE DITE2 LIBRARY #
###########################
cd ${DITEHOME}/lib/
tar zxf dite2lib.tgz
cd dite2lib/
make -j2
# Check if DITE2 has been built
log=`find -name "libdite2.a"`
if [ -z "$log" ]; then
	echo ""
	echo "ERROR: it was not possible to build the DiTe2 library (lib/dite2lib/). Please, check the Makefile therein."
	echo ""
	echo "Build script stopped"
	exit
fi
###############
# BUILD DITE2 #
###############
cd ${DITEHOME}/src/
make
# Check if DiTe2 has been built
log=`find -name "dite2"`
if [ -z "$log" ]; then
	echo ""
	echo "ERROR: it was not possible to build the DITE2 stand alone (src/). Please, check the Makefile therein."
	echo ""
	echo "Build script stopped"
	exit
fi
cd ../
cat > ./dite2_run << EOF
#!/bin/bash
###########################################################
# Use this script to run DITE2                            #
#                                                         #
# Please, note that if the DITE2 build directory is       #
# moved to a different path after the program has been    #
# compiled, the paths in the following commands must      #
# be changed accordingly to the new location of the files #
###########################################################
export LD_LIBRARY_PATH=${DITEHOME}/lib/armadillo-8.500.0/build:${LD_LIBRARY_PATH}
export DITE2HOME=${DITEHOME}/lib/dite2lib
${DITEHOME}/src/dite2 \$1
EOF
chmod u+x ./dite2_run
######################
# BUILD ZMATRIX TOOL #
######################
cat > ./build_zmatrix << EOF
#!/bin/bash
###########################################################
# Use this script to run DITE2                            #
#                                                         #
# Please, note that if the DITE2 build directory is       #
# moved to a different path after the program has been    #
# compiled, the paths in the following commands must      #
# be changed accordingly to the new location of the files #
###########################################################
export LD_LIBRARY_PATH=${DITEHOME}/lib/armadillo-8.500.0/build:${LD_LIBRARY_PATH}
export DITE2HOME=${DITEHOME}/lib/dite2lib
${DITEHOME}/src/dite2 \$1 1
EOF
chmod u+x ./build_zmatrix
#######
# END #
#######
echo ""
echo "====================================================================================================================="
echo "DITE2 succesfully compiled. A calculation should be done in 3 steps"
echo ""
echo "Step 1: build the Z-Matrix from the PDB with the command:"
echo ""
echo "        ./build_zmatrix mol.inp"
echo ""
echo "Step 2: add to mol.inp the information on the internal coordinates based on the information in the Z-Matrix"
echo "        Refer to the README.TXT file about writing the input file"
echo ""
echo "Step 3: run the diffusion tensor calculation with the command:"
echo ""
echo "        ./dite2_run mol.inp"
echo ""
echo "Please note that 'build_zmatrix' and 'dite2_run' are bash scripts pointing to the actual position of this directory:"
echo ""
echo $(pwd)
echo ""
echo "If this directory is moved to another location, the scripts should be modified accordingly."
echo "====================================================================================================================="
echo ""

