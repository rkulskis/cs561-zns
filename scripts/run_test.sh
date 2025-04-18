#!/bin/bash

# ZNS configurations
SU_ZONE=("1" "1")
MU4_ZONE=("4" "1")
MU8_ZONE=("8" "1")
FU_ZONE=("8" "2")
CONFIGS=(SU_ZONE MU4_ZONE MU8_ZONE FU_ZONE)

# First arg is the test ID
test_id=$1

if [[ -z "$test_id" ]]; then
    echo "Usage: $0 <test_id>"
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
    sleep 12  # Give time for boot

    popd || exit 1

    # Run the actual test
    pushd ../tests || exit 1
		sshpass -p femu scp -P 8080 "./$test_id.fio" femu@127.0.0.1:~/
		sshpass -p femu ssh -p 8080 femu@127.0.0.1 "echo femu | sudo -S nvme zns reset-zone /dev/nvme0n1 -a"
		sshpass -p femu ssh -p 8080 femu@127.0.0.1 "echo femu | sudo -S fio --output-format=csv --output=${test_id}.csv ~/${test_id}.fio"
		sshpass -p femu scp -P 8080 femu@127.0.0.1:~/"${test_id}.csv" ../results/csv/"${test_id}-${config_name}-${date_time}.csv"
    popd || exit 1

		# Kill femu		
		ps aux | grep '[q]emu' | awk '{print $2}' | xargs sudo kill -9

    # Return to femu dir for next iteration
    pushd ../confznsplusplus/femu-scripts || exit 1
done

popd || exit 1
