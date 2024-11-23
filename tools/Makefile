# SPITZ12 configuration w/ the OPA ocean dynamical core module (OCE) but
# w/o the SI3 sea ice module (ICE), XIOS support, nor MPI partitioning.
# Use key_noisnan instead of IEEE_IS_NAN=ieee_is_nan for NEMO 4.0.7 or above.

PARCOMP ?= $(shell nproc)

REF_CFG = SPITZ12
NEW_CFG = SPITZ12_OCE

FCFLAGS     = -i4 -r8 -O3 -fast -Mcray=pointer -Mpre -Mvect=fuse,prefetch,tile -Minline
FCFLAGS_SC  = $(FCFLAGS)
FCFLAGS_MC  = $(FCFLAGS) -acc=multicore
FCFLAGS_GPU = $(FCFLAGS) -acc=gpu -gpu=mem:managed

LDFLAGS_SC  =
LDFLAGS_MC  = -acc=multicore
LDFLAGS_GPU = -acc=gpu -gpu=mem:managed

OPT_SRC     = $(CURDIR)/cfgs/$(NEW_CFG)_PSY
OPT_SRC_SC  = none
OPT_SRC_MC  = $(OPT_SRC)
OPT_SRC_GPU = $(OPT_SRC)

PSY_SCR = $(PSYCLONE_DIR)/examples/nemo/scripts

.PHONY: all clean

all: SC MC GPU

SC MC GPU:
	FCFLAGS="$(FCFLAGS_$@)" LDFLAGS="$(LDFLAGS_$@)" \
		./makenemo -n $(NEW_CFG)_$@ -r $(REF_CFG) -m linux_nvhpc -j $(PARCOMP) -e $(OPT_SRC_$@) \
		add_key "IEEE_IS_NAN=ieee_is_nan key_nosignedzero" \
		del_key "key_iomput key_mpp_mpi key_si3"

MC GPU: PSY

PSY: SC
	mkdir -p $(OPT_SRC)
	parallel psyclone -s $(PSY_SCR)/acc_kernels_trans.py -I $(OPAL_PREFIX)/include -o $(OPT_SRC)/{/} \
		{} ::: cfgs/$(NEW_CFG)_$</BLD/ppsrc/nemo/*f90

clean:
	rm -rf cfgs/$(NEW_CFG)_*

sc mc gpu:
	@$(MAKE) `echo $@ | tr [:lower:] [:upper:]`
