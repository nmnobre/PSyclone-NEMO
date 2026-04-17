#!/bin/bash
set -e

###########
########### Setup runtime environment
###########
source env_nemo.sh

###########
########### Run NEMO
###########
export TEST_NAME=BENCH_OMP_OFFLOAD_NVHPC
export FCFLAGS="-i4 -Mr8 -O3 -mp=gpu -gpu=mem:managed $CPPFLAGS"
export PROFILING_DIR=/dummy
export HDF5_HOME=/dummy
export NCDF_C_HOME=/dummy
export NCDF_F_HOME=/dummy
export ENABLE_PROFILING=
export REPRODUCIBLE=
export PSYCLONE_COMPILER=mpif90
export MPIF90=psyclonefc
export PSYCLONE_OPTS="--enable-cache -l output -s $PSYCLONE_DIR/examples/nemo/scripts/omp_gpu_trans.py"

cd $NEMO_DIR
./makenemo -r BENCH -m linux_spack_profile -n $TEST_NAME -j 4

cd $NEMO_DIR/tests/$TEST_NAME/EXP00
cp $PSYCLONE_DIR/examples/nemo/scripts/KGOs/namelist_cfg_bench_small namelist_cfg
mpirun -np 1 ./nemo
head -25 timing.output
