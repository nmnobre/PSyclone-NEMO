# 🌊 ♥️ 🌀 Treating NEMO to the PSyclone whirl

NEMO, the Nucleus for European Modelling of the Ocean, is a state-of-the-art modelling framework for research and forecasting activities in ocean and climate sciences, developed since 2008 by a European consortium formed by CMCC 🇮🇹, CNRS and MOi 🇫🇷, and the Met Office and NERC 🇬🇧.

## Installation

`get_nemo.sh` is an installation script for GNU/Linux machines which prepares a building environment around the NVIDIA HPC SDK. It tries to minimise the amount of external, globally installed packages by compiling a large part of NEMO's dependences from source.

## Building and running NEMO

`run_nemo.sh` will build and run a simple configuration with OpenMP GPU offloading support.
