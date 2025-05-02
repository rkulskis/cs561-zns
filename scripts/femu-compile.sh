#!/bin/bash

# confznsplusplus/hw/femu/femu.c:694 defines femu config
# which includes ZNS config

# ARGS
chnls_per_zone=$1
ways_per_zone=$2

FEMU_CONFIG_FILE="../hw/femu/femu.c"

set_chnls_per_zone() {
		prop_name="zns_channels_per_zone"
		mem_name="chnls_per_zone"
		val=${1:-"8"}								# 8 is default value
		echo "Setting ${mem_name} to ${val}"

		sed -i "/^[[:space:]]*DEFINE_PROP_UINT64(\"${prop_name}\"/c\\
		DEFINE_PROP_UINT64(\"${prop_name}\", FemuCtrl, zns_params.${mem_name}, ${val}),
" "$FEMU_CONFIG_FILE"
}

set_ways_per_zone() {
		prop_name="zns_ways_per_zone"
		mem_name="ways_per_zone"
		val=${1:-"1U"}							# 1 is default value
		echo "Setting ${mem_name} to ${val}"

		sed -i "/^[[:space:]]*DEFINE_PROP_UINT64(\"${prop_name}\"/c\\
		DEFINE_PROP_UINT64(\"${prop_name}\", FemuCtrl, zns_params.${mem_name}, ${val}),
" "$FEMU_CONFIG_FILE"
}

set_chnls_per_zone $chnls_per_zone
set_ways_per_zone $ways_per_zone

NRCPUS="$(cat /proc/cpuinfo | grep "vendor_id" | wc -l)"

make clean
#  --extra-cflags=-w --disable-git-update
../configure --enable-kvm --target-list=x86_64-softmmu --disable-werror
make -j $NRCPUS

echo ""
echo "===> FEMU compilation done ..."
echo ""
exit
