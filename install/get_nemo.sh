#!/bin/bash
set -e

###########
########### Software versions
###########
NVHPC_VERSION=24.5
CUDA_VERSION=12.4
HDF5_VERSION=1.14.4-3
NETCDF_C_VERSION=4.9.2
NETCDF_F_VERSION=4.6.1
PERL_VERSION=5.40.0
PYTHON_VERSION=3.12.4
PARALLEL_VERSION=20240522
PSYCLONE_VERSION=master
NEMO_VERSION=4.0_mirror_SI3_GPU

###########
########### Installation environment
###########
export TOPLEVEL=$PWD
export DEP_DIR=$TOPLEVEL/dev
export BUILD_DIR=$TOPLEVEL/build
export PARCOMP=$(nproc)

mkdir -p $BUILD_DIR

###########
########### NVIDIA HPC SDK
###########
TARGET_ARCH=Linux_x86_64

NVHPC_VSTR=$(sed 's/\.//' <<< $NVHPC_VERSION)
NVHPC_YEAR=20$(sed 's/\..*//' <<< $NVHPC_VERSION)
NVHPC_DIR=$DEP_DIR/nvhpc_sdk-$NVHPC_VERSION

cd $BUILD_DIR
wget https://developer.download.nvidia.com/hpc-sdk/${NVHPC_VERSION}/nvhpc_${NVHPC_YEAR}_${NVHPC_VSTR}_${TARGET_ARCH}_cuda_${CUDA_VERSION}.tar.gz
tar xpzf nvhpc_${NVHPC_YEAR}_${NVHPC_VSTR}_${TARGET_ARCH}_cuda_${CUDA_VERSION}.tar.gz
NVHPC_SILENT=true NVHPC_INSTALL_DIR=$NVHPC_DIR NVHPC_INSTALL_TYPE=single ./nvhpc_${NVHPC_YEAR}_${NVHPC_VSTR}_${TARGET_ARCH}_cuda_${CUDA_VERSION}/install

nvcudadir=$NVHPC_DIR/$TARGET_ARCH/$NVHPC_VERSION/cuda
nvcompdir=$NVHPC_DIR/$TARGET_ARCH/$NVHPC_VERSION/compilers
nvmathdir=$NVHPC_DIR/$TARGET_ARCH/$NVHPC_VERSION/math_libs
nvcommdir=$NVHPC_DIR/$TARGET_ARCH/$NVHPC_VERSION/comm_libs

export PATH=$nvcudadir/bin${PATH:+:${PATH}}
export PATH=$nvcompdir/bin:$PATH
export PATH=$nvcommdir/openmpi/openmpi-3.1.5/bin:$PATH
export PATH=$nvcompdir/extras/qd/bin:$PATH
export LD_LIBRARY_PATH=$nvcudadir/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
export LD_LIBRARY_PATH=$nvcudadir/extras/CUPTI/lib64:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$nvcompdir/extras/qd/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$nvcompdir/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$nvmathdir/lib64:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$nvcommdir/openmpi/openmpi-3.1.5/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$nvcommdir/nccl/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$nvcommdir/nvshmem/lib:$LD_LIBRARY_PATH
export CPATH=$nvmathdir/include${CPATH:+:${CPATH}}
export CPATH=$nvcommdir/openmpi/openmpi-3.1.5/include:$CPATH
export CPATH=$nvcommdir/nccl/include:$CPATH
export CPATH=$nvcommdir/nvshmem/include:$CPATH
export CPATH=$nvcompdir/extras/qd/include/qd:$CPATH
export MANPATH=$nvcompdir/man${MANPATH:+:${MANPATH}}
export OPAL_PREFIX=$nvcommdir/openmpi/openmpi-3.1.5

###########
########### HDF5
###########
HDF5_DIR=$DEP_DIR/hdf5-$HDF5_VERSION

HDF5_DVERSION=$(sed 's/-/./' <<< $HDF5_VERSION)

cd $BUILD_DIR
wget https://github.com/HDFGroup/hdf5/releases/download/hdf5_$HDF5_DVERSION/hdf5-$HDF5_VERSION.tar.gz
tar -xzf hdf5-$HDF5_VERSION.tar.gz
mkdir hdf5-${HDF5_VERSION}_build
cd hdf5-${HDF5_VERSION}_build
wget 'https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD' -O $BUILD_DIR/hdf5-$HDF5_VERSION/bin/config.guess
wget 'https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD'  -O $BUILD_DIR/hdf5-$HDF5_VERSION/bin/config.sub
CC=mpicc CFLAGS=-fPIC CXX=mpicxx FC=mpif90 FCFLAGS=-fPIC CPP=cpp $BUILD_DIR/hdf5-$HDF5_VERSION/configure --prefix=$HDF5_DIR --enable-shared --enable-fortran --enable-parallel
make -j$PARCOMP
make install

export PATH=$HDF5_DIR/bin:$PATH
export LD_LIBRARY_PATH=$HDF5_DIR/lib:$LD_LIBRARY_PATH
export CPATH=$HDF5_DIR/include:$CPATH
export LIBRARY_PATH=$HDF5_DIR/lib:$LIBRARY_PATH

###########
########### netCDF-C
###########
NETCDF_C_DIR=$DEP_DIR/netcdf-c-$NETCDF_C_VERSION

cd $BUILD_DIR
wget https://github.com/Unidata/netcdf-c/archive/refs/tags/v$NETCDF_C_VERSION.zip
unzip v$NETCDF_C_VERSION.zip
mkdir netcdf-c-${NETCDF_C_VERSION}_build
cd netcdf-c-${NETCDF_C_VERSION}_build
wget 'https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD' -O $BUILD_DIR/netcdf-c-$NETCDF_C_VERSION/config.guess
wget 'https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD'  -O $BUILD_DIR/netcdf-c-$NETCDF_C_VERSION/config.sub
CC=mpicc CFLAGS=-fPIC CXX=mpicxx FC=mpif90 FCFLAGS=-fPIC CPP=cpp $BUILD_DIR/netcdf-c-$NETCDF_C_VERSION/configure --prefix=$NETCDF_C_DIR --disable-dap --disable-libxml2
make -j$PARCOMP
make install

export PATH=$NETCDF_C_DIR/bin:$PATH
export LD_LIBRARY_PATH=$NETCDF_C_DIR/lib:$LD_LIBRARY_PATH
export CPATH=$NETCDF_C_DIR/include:$CPATH
export LIBRARY_PATH=$NETCDF_C_DIR/lib:$LIBRARY_PATH

###########
########### netCDF-Fortran
###########
NETCDF_F_DIR=$DEP_DIR/netcdf-fortran-$NETCDF_F_VERSION

cd $BUILD_DIR
wget https://github.com/Unidata/netcdf-fortran/archive/refs/tags/v$NETCDF_F_VERSION.zip
unzip v$NETCDF_F_VERSION.zip
mkdir netcdf-fortran-${NETCDF_F_VERSION}_build
cd netcdf-fortran-${NETCDF_F_VERSION}_build
wget 'https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD' -O $BUILD_DIR/netcdf-fortran-$NETCDF_F_VERSION/config.guess
wget 'https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD'  -O $BUILD_DIR/netcdf-fortran-$NETCDF_F_VERSION/config.sub
CC=mpicc CFLAGS=-fPIC CXX=mpicxx FC=mpif90 FCFLAGS=-fPIC CPP=cpp $BUILD_DIR/netcdf-fortran-$NETCDF_F_VERSION/configure --prefix=$NETCDF_F_DIR
make -j$PARCOMP
make install

export PATH=$NETCDF_F_DIR/bin:$PATH
export LD_LIBRARY_PATH=$NETCDF_F_DIR/lib:$LD_LIBRARY_PATH
export CPATH=$NETCDF_F_DIR/include:$CPATH
export LIBRARY_PATH=$NETCDF_F_DIR/lib:$LIBRARY_PATH

###########
########### Perl
###########
PERL_DIR=$DEP_DIR/perl-$PERL_VERSION

cd $BUILD_DIR
wget https://www.cpan.org/src/5.0/perl-$PERL_VERSION.tar.gz
tar -xzf perl-$PERL_VERSION.tar.gz
mkdir perl-${PERL_VERSION}_build
cd perl-${PERL_VERSION}_build
$BUILD_DIR/perl-$PERL_VERSION/Configure -des -Dprefix=$PERL_DIR -Dmksymlinks
make -j$PARCOMP
make install

export PATH=$PERL_DIR/bin:$PATH
export MANPATH=$PERL_DIR/man:$MANPATH
export PERL_CPANM_HOME=$PERL_DIR/cpanm

wget -O - https://cpanmin.us | perl - --self-upgrade
cpanm URI

###########
########### Python
###########
PYTHON_DIR=$DEP_DIR/python-$PYTHON_VERSION

cd $BUILD_DIR
wget https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tgz
tar -xzf Python-$PYTHON_VERSION.tgz
mkdir Python-${PYTHON_VERSION}_build
cd Python-${PYTHON_VERSION}_build
CC=gcc CXX=g++ FF=gfortran FC=gfortran $BUILD_DIR/Python-$PYTHON_VERSION/configure --enable-optimizations --with-lto --with-ensurepip=install --prefix=$PYTHON_DIR
make -j$PARCOMP
make install

export PATH=$PYTHON_DIR/bin:$PATH
export LD_LIBRARY_PATH=$PYTHON_DIR/lib:$LD_LIBRARY_PATH
export CPATH=$PYTHON_DIR/include:$CPATH
export LIBRARY_PATH=$PYTHON_DIR/lib:$LIBRARY_PATH

###########
########### Parallel
###########
PARALLEL_DIR=$DEP_DIR/parallel-$PARALLEL_VERSION

cd $BUILD_DIR
wget https://ftp.gnu.org/gnu/parallel/parallel-$PARALLEL_VERSION.tar.bz2
tar -xf parallel-$PARALLEL_VERSION.tar.bz2
mkdir parallel-${PARALLEL_VERSION}_build
cd parallel-${PARALLEL_VERSION}_build
CC=gcc CXX=g++ FF=gfortran FC=gfortran $BUILD_DIR/parallel-$PARALLEL_VERSION/configure --prefix=$PARALLEL_DIR
make -j$PARCOMP
make install

export PATH=$PARALLEL_DIR/bin:$PATH

###########
########### PSyclone
###########
PSYCLONE_DIR=$DEP_DIR/psyclone-$PSYCLONE_VERSION

git clone https://github.com/stfc/PSyclone.git $PSYCLONE_DIR
cd $PSYCLONE_DIR
git checkout $PSYCLONE_VERSION
pip3 install -e .
cd $PSYCLONE_DIR/lib/profiling/nvidia
F90=mpif90 make

export PSYCLONE_DIR
export PSYCLONE_CONFIG=$PSYCLONE_DIR/config/psyclone.cfg
export CPATH=$PSYCLONE_DIR/lib/profiling/nvidia:$CPATH
export LIBRARY_PATH=$PSYCLONE_DIR/lib/profiling/nvidia:$LIBRARY_PATH

###########
########### NEMO
###########
NEMO_DIR=$TOPLEVEL/nemo-$NEMO_VERSION

svn co https://forge.ipsl.jussieu.fr/nemo/svn/NEMO/branches/UKMO/NEMO_$NEMO_VERSION $NEMO_DIR --non-interactive --trust-server-cert-failures="unknown-ca,cn-mismatch,expired,not-yet-valid,other"
cd $NEMO_DIR
patch -p0 < $TOPLEVEL/patch/nemo.patch

###########
########### Clean-up
###########
rm -rf $BUILD_DIR

###########
########### Setup script
###########
SETUP_SCRIPT=env_nemo.sh

cd $TOPLEVEL
rm -f $SETUP_SCRIPT

echo "export PATH='$PATH'" >> $SETUP_SCRIPT
echo "export LD_LIBRARY_PATH='$LD_LIBRARY_PATH'" >> $SETUP_SCRIPT
echo "export CPATH='$CPATH'" >> $SETUP_SCRIPT
echo "export CPPFLAGS='$(echo -I$CPATH | sed 's/:/ -I/g')'" >> $SETUP_SCRIPT
echo "export LIBRARY_PATH='$LIBRARY_PATH'" >> $SETUP_SCRIPT
echo "export MANPATH='$MANPATH'" >> $SETUP_SCRIPT
echo "export OPAL_PREFIX='$OPAL_PREFIX'" >> $SETUP_SCRIPT
echo "export PSYCLONE_DIR='$PSYCLONE_DIR'" >> $SETUP_SCRIPT
echo "export PSYCLONE_CONFIG='$PSYCLONE_CONFIG'" >> $SETUP_SCRIPT
