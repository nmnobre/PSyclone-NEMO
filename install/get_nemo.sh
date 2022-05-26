#!/bin/bash
set -e

###########
########### PREPARE INSTALLATION ENVIRONMENT
###########
export TOPLEVEL=$PWD
export DEP_DIR=$TOPLEVEL/dev
export BUILD_DIR=$TOPLEVEL/build
export PARCOMP=$(nproc)

mkdir -p $BUILD_DIR

###########
########### NVIDIA HPC SDK
###########
NVHPC_VERSION=22.5
CUDA_VERSION=11.7
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
export PATH=$nvcommdir/mpi/bin:$PATH
export PATH=$nvcompdir/extras/qd/bin:$PATH
export LD_LIBRARY_PATH=$nvcudadir/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
export LD_LIBRARY_PATH=$nvcudadir/extras/CUPTI/lib64:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$nvcompdir/extras/qd/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$nvcompdir/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$nvmathdir/lib64:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$nvcommdir/mpi/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$nvcommdir/nccl/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$nvcommdir/nvshmem/lib:$LD_LIBRARY_PATH
export CPPFLAGS="$CPPFLAGS -I$nvmathdir/include"
export CPPFLAGS="$CPPFLAGS -I$nvcommdir/mpi/include"
export CPPFLAGS="$CPPFLAGS -I$nvcommdir/nccl/include"
export CPPFLAGS="$CPPFLAGS -I$nvcommdir/nvshmem/include"
export CPPFLAGS="$CPPFLAGS -I$nvcompdir/extras/qd/include/qd"
export LDFLAGS="$LDFLAGS -L$nvcudadir/lib64"
export LDFLAGS="$LDFLAGS -L$nvcudadir/extras/CUPTI/lib64"
export LDFLAGS="$LDFLAGS -L$nvcompdir/extras/qd/lib"
export LDFLAGS="$LDFLAGS -L$nvcompdir/lib"
export LDFLAGS="$LDFLAGS -L$nvmathdir/lib64"
export LDFLAGS="$LDFLAGS -L$nvcommdir/mpi/lib"
export LDFLAGS="$LDFLAGS -L$nvcommdir/nccl/lib"
export LDFLAGS="$LDFLAGS -L$nvcommdir/nvshmem/lib"
export MANPATH=$nvcompdir/man${MANPATH:+:${MANPATH}}
export OPAL_PREFIX=$nvcommdir/mpi

###########
########### HDF5
###########
HDF5_VERSION=1.12.2
HDF5_DIR=$DEP_DIR/hdf5-$HDF5_VERSION

HDF5_MVERSION=$(sed 's/\.[0-9]*$//' <<< $HDF5_VERSION)

cd $BUILD_DIR
wget http://www.hdfgroup.org/ftp/HDF5/prev-releases/hdf5-$HDF5_MVERSION/hdf5-$HDF5_VERSION/src/hdf5-$HDF5_VERSION.tar.gz
tar -xzf hdf5-$HDF5_VERSION.tar.gz
mkdir hdf5-${HDF5_VERSION}_build
cd hdf5-${HDF5_VERSION}_build
wget 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD' -O $BUILD_DIR/hdf5-$HDF5_VERSION/bin/config.guess
wget 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD'  -O $BUILD_DIR/hdf5-$HDF5_VERSION/bin/config.sub
CC=mpicc CFLAGS=-fPIC CXX=mpicxx FC=mpif90 FCFLAGS=-fPIC CPP=cpp $BUILD_DIR/hdf5-$HDF5_VERSION/configure --prefix=$HDF5_DIR --enable-shared --enable-fortran --enable-parallel
make -j$PARCOMP
make install

export PATH=$HDF5_DIR/bin:$PATH
export LD_LIBRARY_PATH=$HDF5_DIR/lib:$LD_LIBRARY_PATH
export CPPFLAGS="$CPPFLAGS -I$HDF5_DIR/include"
export LDFLAGS="$LDFLAGS -L$HDF5_DIR/lib"

###########
########### NETCDF-C
###########
NETCDF_C_VERSION=4.8.1
NETCDF_C_DIR=$DEP_DIR/netcdf-c-$NETCDF_C_VERSION

cd $BUILD_DIR
wget https://github.com/Unidata/netcdf-c/archive/refs/tags/v$NETCDF_C_VERSION.zip
unzip v$NETCDF_C_VERSION.zip
mkdir netcdf-c-${NETCDF_C_VERSION}_build
cd netcdf-c-${NETCDF_C_VERSION}_build
wget 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD' -O $BUILD_DIR/netcdf-c-$NETCDF_C_VERSION/config.guess
wget 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD'  -O $BUILD_DIR/netcdf-c-$NETCDF_C_VERSION/config.sub
CC=mpicc CFLAGS=-fPIC CXX=mpicxx FC=mpif90 FCFLAGS=-fPIC CPP=cpp $BUILD_DIR/netcdf-c-$NETCDF_C_VERSION/configure --prefix=$NETCDF_C_DIR --disable-dap
make -j$PARCOMP
make install

export PATH=$NETCDF_C_DIR/bin:$PATH
export LD_LIBRARY_PATH=$NETCDF_C_DIR/lib:$LD_LIBRARY_PATH
export CPPFLAGS="$CPPFLAGS -I$NETCDF_C_DIR/include"
export LDFLAGS="$LDFLAGS -L$NETCDF_C_DIR/lib"

###########
########### NETCDF-Fortran
###########
NETCDF_F_VERSION=4.5.4
NETCDF_F_DIR=$DEP_DIR/netcdf-fortran-$NETCDF_F_VERSION

cd $BUILD_DIR
wget https://github.com/Unidata/netcdf-fortran/archive/refs/tags/v$NETCDF_F_VERSION.zip
unzip v$NETCDF_F_VERSION.zip
mkdir netcdf-fortran-${NETCDF_F_VERSION}_build
cd netcdf-fortran-${NETCDF_F_VERSION}_build
wget 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD' -O $BUILD_DIR/netcdf-fortran-$NETCDF_F_VERSION/config.guess
wget 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD'  -O $BUILD_DIR/netcdf-fortran-$NETCDF_F_VERSION/config.sub
CC=mpicc CFLAGS=-fPIC CXX=mpicxx FC=mpif90 FCFLAGS=-fPIC CPP=cpp $BUILD_DIR/netcdf-fortran-$NETCDF_F_VERSION/configure --prefix=$NETCDF_F_DIR
make -j$PARCOMP
make install

export PATH=$NETCDF_F_DIR/bin:$PATH
export LD_LIBRARY_PATH=$NETCDF_F_DIR/lib:$LD_LIBRARY_PATH
export CPPFLAGS="$CPPFLAGS -I$NETCDF_F_DIR/include"
export LDFLAGS="$LDFLAGS -L$NETCDF_F_DIR/lib"

###########
########### PERL
###########
PERL_VERSION=5.34.1
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

wget -O - http://cpanmin.us | perl - --self-upgrade
cpanm URI

###########
########### PYTHON
###########
PYTHON_VERSION=3.10.4
PYTHON_DIR=$DEP_DIR/python-$PYTHON_VERSION

cd $BUILD_DIR
wget https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tgz
tar -xzf Python-$PYTHON_VERSION.tgz
mkdir Python-${PYTHON_VERSION}_build
cd Python-${PYTHON_VERSION}_build
CC=gcc CXX=g++ FF=gfortran FC=gfortran $BUILD_DIR/Python-$PYTHON_VERSION/configure --enable-optimizations --with-ensurepip=install --prefix=$PYTHON_DIR
make -j$PARCOMP
make install

export PATH=$PYTHON_DIR/bin:$PATH
export LD_LIBRARY_PATH=$PYTHON_DIR/lib:$LD_LIBRARY_PATH
export CPPFLAGS="$CPPFLAGS -I$PYTHON_DIR/include"
export LDFLAGS="$LDFLAGS -L$PYTHON_DIR/lib"

###########
########### PSyclone
###########
PSYCLONE_VERSION=310_enter_data
PSYCLONE_DIR=$DEP_DIR/psyclone-$PSYCLONE_VERSION

git clone https://github.com/stfc/PSyclone.git $PSYCLONE_DIR
cd $PSYCLONE_DIR
git checkout $PSYCLONE_VERSION
pip3 install -e .
cd $PSYCLONE_DIR/lib/profiling/nvidia
F90=mpif90 make

export PSYCLONE_DIR
export PSYCLONE_CONFIG=$PSYCLONE_DIR/config/psyclone.cfg
export CPPFLAGS="$CPPFLAGS -I$PSYCLONE_DIR/lib/profiling/nvidia"
export LDFLAGS="$LDFLAGS -L$PSYCLONE_DIR/lib/profiling/nvidia"

###########
########### NEMO
###########
NEMO_VERSION=4.0_mirror_SI3_GPU
NEMO_DIR=$TOPLEVEL/nemo-$NEMO_VERSION

svn co https://forge.ipsl.jussieu.fr/nemo/svn/NEMO/branches/UKMO/NEMO_$NEMO_VERSION $NEMO_DIR
cd $NEMO_DIR
patch -p0 < $TOPLEVEL/patch/nemo.patch

###########
########### CLEAN-UP
###########
rm -rf $BUILD_DIR

###########
########### SETUP SCRIPT
###########
SETUP_SCRIPT=env_nemo.sh

cd $TOPLEVEL
rm -f $SETUP_SCRIPT

echo "export PATH='$PATH'" >> $SETUP_SCRIPT
echo "export LD_LIBRARY_PATH='$LD_LIBRARY_PATH'" >> $SETUP_SCRIPT
echo "export CPPFLAGS='$CPPFLAGS'" >> $SETUP_SCRIPT
echo "export LDFLAGS='$LDFLAGS'" >> $SETUP_SCRIPT
echo "export MANPATH='$MANPATH'" >> $SETUP_SCRIPT
echo "export OPAL_PREFIX='$OPAL_PREFIX'" >> $SETUP_SCRIPT
echo "export PSYCLONE_DIR='$PSYCLONE_DIR'" >> $SETUP_SCRIPT
echo "export PSYCLONE_CONFIG='$PSYCLONE_CONFIG'" >> $SETUP_SCRIPT
