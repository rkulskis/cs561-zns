#!/bin/bash

# ZNS configurations
SU_ZONE=("1" "1")
MU4_ZONE=("4" "1")
MU8_ZONE=("8" "1")
FU_ZONE=("8" "2")
CONFIGS=(SU_ZONE MU4_ZONE MU8_ZONE FU_ZONE)

# First arg is the test ID
BASE_FIO_TEMPLATE=$1
PREFIX=$2

if [[ -z "$BASE_FIO_TEMPLATE" || -z "$PREFIX" ]]; then
    echo "Usage: $0 <base_fio_template> <prefix>"
    exit 1
fi

# Timestamp
date_time=$(date +"%Y%m%d-%H%M%S")

# Prep femu environment
pushd ../confznsplusplus/femu-scripts || exit 1
sudo ./pkgdep.sh
cp -f ../../scripts/femu-compile.sh .

ps aux | grep '[q]emu' | awk '{print $2}' | xargs sudo kill -9 # ensure clean state

for config_name in "${CONFIGS[@]}"; do
    # Extract channel and way from config
    config=("${!config_name}")
    chnls_per_zone=${config[0]}
    ways_per_zone=${config[1]}

    echo "=== Running test for config: $config_name ($chnls_per_zone channels, $ways_per_zone ways) ==="

    # Compile with current config
    ./femu-compile.sh "$chnls_per_zone" "$ways_per_zone"

    # Run femu
    ./run-zns.sh &

    echo "[INFO] Waiting for FEMU VM SSH to become available..."
    for i in {1..30}; do
        if sshpass -p femu ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 8080 femu@127.0.0.1 "echo '[INFO] SSH is ready'"; then
            break
        else
            echo "[INFO] Attempt $i: SSH not ready yet..."
            sleep 2
        fi
    done

    popd || exit 1

    # Run the actual test
    pushd ../tests || exit 1
    sshpass -p femu ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 8080 femu@127.0.0.1 "echo femu | sudo -S nvme zns reset-zone /dev/nvme0n1 -a"
    sshpass -p femu ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 8080 femu@127.0.0.1 "echo femu | sudo -S bash -c 'fio /home/femu/write.fio'"
    mkdir -p "../results/csv/${config_name}-${PREFIX}"
    for qd in 1 2 4 8 16 32 64; do
        FIO_JOB_NAME="${PREFIX}_${qd}"                   # Used for result naming
        FIO_FILE="${FIO_JOB_NAME}.fio"                   # The actual fio file
        sed "s/_IODEPTH_/${qd}/" "$BASE_FIO_TEMPLATE" > "$FIO_FILE"
        sync
        echo "[DEBUG] Local FIO file content:"
        cat "$FIO_FILE"
        
        sshpass -p femu scp -P 8080 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$(pwd)/$FIO_FILE" femu@127.0.0.1:/home/femu/
        sshpass -p femu ssh -p 8080 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null femu@127.0.0.1 "echo '[DEBUG] VM FIO file: $FIO_FILE' >> ~/fio_debug.log && cat /home/femu/$FIO_FILE >> ~/fio_debug.log"
        sshpass -p femu ssh -p 8080 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null femu@127.0.0.1 "echo femu | sudo -S fio --output-format=json --output=${FIO_JOB_NAME}.json /home/femu/${FIO_FILE}"
        sshpass -p femu scp -P 8080 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null femu@127.0.0.1:/home/femu/${FIO_JOB_NAME}.json "../results/csv/${config_name}-${PREFIX}/${FIO_JOB_NAME}-${date_time}.json"
    done
    popd || exit 1

    # Kill femu
    ps aux | grep '[q]emu' | awk '{print $2}' | xargs sudo kill -9

    # Return to femu dir for next iteration
    pushd ../confznsplusplus/femu-scripts || exit 1
done

popd || exit 1
