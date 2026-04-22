#!/bin/bash
set -e

###########
########### Software versions
###########
NVHPC_VERSION=26.3
CUDA_VERSION=13.1
HDF5_VERSION=2.1.1
NETCDF_C_VERSION=4.10.0
NETCDF_F_VERSION=4.6.2
PERL_VERSION=5.42.2
PYTHON_VERSION=3.14.4
PSYCLONE_VERSION=master
NEMO_VERSION=5.0-RC

###########
########### Installation environment
###########
TOPLEVEL=$PWD
DEP_DIR=$TOPLEVEL/dev
BUILD_DIR=$TOPLEVEL/build
PARCOMP=$(nproc)

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

module use $NVHPC_DIR/modulefiles
module load nvhpc/$NVHPC_VERSION

module use $NVHPC_ROOT/comm_libs/$CUDA_VERSION/hpcx/latest/modulefiles
module load hpcx

###########
########### HDF5
###########
HDF5_DIR=$DEP_DIR/hdf5-$HDF5_VERSION

HDF5_DVERSION=$(sed 's/-/./' <<< $HDF5_VERSION)

cd $BUILD_DIR
wget https://github.com/HDFGroup/hdf5/releases/download/$HDF5_DVERSION/hdf5-$HDF5_VERSION.tar.gz
tar -xzf hdf5-$HDF5_VERSION.tar.gz
mkdir hdf5-${HDF5_VERSION}_build
cd hdf5-${HDF5_VERSION}_build
CC=mpicc CXX=mpicxx FC=mpif90 cmake ../hdf5-$HDF5_VERSION -DHDF5_BUILD_FORTRAN=ON -DHDF5_ENABLE_PARALLEL=ON -DHDF5_ENABLE_NONSTANDARD_FEATURE_FLOAT16=ON -DHDF5_ENABLE_ZLIB_SUPPORT=ON -DCMAKE_INSTALL_PREFIX=$HDF5_DIR
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

sed -i 's/\/libmpi.la//g' $NETCDF_C_DIR/lib/libnetcdf.la

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

git clone --branch $NEMO_VERSION https://forge.nemo-ocean.eu/nemo/nemo.git $NEMO_DIR
cd $NEMO_DIR
cp $PSYCLONE_DIR/examples/nemo/scripts/KGOs/arch-linux_spack.fcm arch/arch-linux_spack.fcm
cp $PSYCLONE_DIR/examples/nemo/scripts/KGOs/arch-linux_spack_profile.fcm arch/arch-linux_spack_profile.fcm
patch -p0 <<'EOF'
--- mk/bld.cfg
+++ mk/bld.cfg
@@ -67,6 +67,7 @@
 bld::excl_dep        use::mkl_dfti
 bld::excl_dep        use::cudafor
 bld::excl_dep        use::openacc
+bld::excl_dep        use::profile_psy_data_mod

 # Don't generate interface files
 bld::tool::geninterface none
EOF

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
echo "export PSYCLONE_DIR='$PSYCLONE_DIR'" >> $SETUP_SCRIPT
echo "export PSYCLONE_CONFIG='$PSYCLONE_CONFIG'" >> $SETUP_SCRIPT
echo "export NEMO_DIR='$NEMO_DIR'" >> $SETUP_SCRIPT
