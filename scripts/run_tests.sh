#!/bin/bash
# /* ************************ CONFIGS ************************ */
SU_ZONE=("1" "1"); MU4_ZONE=("4" "1") ;MU8_ZONE=("8" "1"); FU_ZONE=("8" "2");
CONFIGS=(SU_ZONE MU4_ZONE MU8_ZONE FU_ZONE)
date_time=$(date +"%Y%m%d-%H%M%S")
# /* ************************** INIT ************************** */
pushd ../confznsplusplus/femu-scripts 
sudo ./pkgdep.sh
cp -f ../../scripts/femu-compile.sh .
# /* ************************ HELPERS ************************ */
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 8080"
SSH_USER="femu"
SSH_HOST="127.0.0.1"
SSH_ADDR="${SSH_USER}@${SSH_HOST}"
SSHPASS="sshpass -p femu"
REMOTE_DIR="/home/femu"
ssh_vm() {
    $SSHPASS ssh $SSH_OPTS $SSH_ADDR "echo \"femu\" | sudo -S -k $@"
}

scp_to_vm() {
    $SSHPASS scp -P 8080 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$1" "${SSH_ADDR}:$2"
}

scp_from_vm() {
    $SSHPASS scp -P 8080 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "${SSH_ADDR}:$1" "$2"
}
# /* ********************** COMPILATION ********************** */
for config_name in "${CONFIGS[@]}"; do # Compilation
    chnls_per_zone=${config[0]}
    ways_per_zone=${config[1]}
		if [ -f x86_64-softmmu/${config_name}-qemu-system-x86_64 ]; then
				continue								# config already compiled
		fi
    ./femu-compile.sh "$chnls_per_zone" "$ways_per_zone" # compile
		cp -L x86_64-softmmu/qemu-system-x86_64 \
			 x86_64-softmmu/${config_name}-qemu-system-x86_64 # save binary with name
done
# /* *********************** RUN TESTS *********************** */
for config_name in "${CONFIGS[@]}"; do # tests
		cp -f x86_64-softmmu/${config_name}-qemu-system-x86_64 ../qemu-system-x86_64

    ./run-zns.sh &							# run FEMU
    echo "[INFO] Waiting for FEMU VM SSH to become available..."
    for i in {1..30}; do
        if ssh_vm "echo '[INFO] SSH is ready'"; then
            break
        else
            echo "[INFO] Attempt $i: SSH not ready yet..."
            sleep 2
        fi
    done

    popd 												# from ../confznsplusplus/femu-scripts

    pushd ../tests
    for j in {1..64}; do
				i=$((j))
				# if [ "$j" -ge 20 ]; then
						# i=$(((j - 18) * 10)) # [20,30,...,300]
				# else
						# i=$((j))				# [1,2,...20)
				# fi
        FIO_JOB_NAME="${i}"                   # Used for result naming
				for rw in read write; do
						for zone in intra inter; do
								TEST_NAME="${zone}_${rw}"
								ssh_vm "nvme zns reset-zone /dev/nvme0n1 -a"
								mkdir -p "../results/json/${TEST_NAME}/${config_name}"

								if [ "$zone" = "intra" ]; then
										ssh_vm "fio --output-format=json \
                --output=${FIO_JOB_NAME}.json \
                --name=${FIO_JOB_NAME} \
                --filename=/dev/nvme0n1 \
                --zonemode=zbd \
                --ioengine=io_uring \
                --direct=1 \
                --rw=${rw} \
                --bs=128k \
                --zonesize=64M \
                --size=64M \
                --iodepth=${i} \
                --group_reporting=1"
								else # inter
										ssh_vm "fio --output-format=json \
                --output=${FIO_JOB_NAME}.json \
                --name=${FIO_JOB_NAME} \
                --filename=/dev/nvme0n1 \
                --zonemode=zbd \
                --ioengine=psync \
                --direct=1 \
                --rw=${rw} \
                --bs=64k \
                --offset_increment=64M \
                --zonesize=64M \
                --size=64M \
                --numjobs=${i} \
                --group_reporting=1"
								fi

								out_json="../results/json/${TEST_NAME}/${config_name}/${FIO_JOB_NAME}-${date_time}.json"
								scp_from_vm "${REMOTE_DIR}/${FIO_JOB_NAME}.json" "$out_json"
														
								python3 trim_fio_json.py "$out_json" "$out_json" "$rw"
						done
				done
    done
    ps aux | grep '[q]emu' | awk '{print $2}' | xargs sudo kill -9 # kill FEMU
		sleep 1
    popd 
    pushd ../confznsplusplus/femu-scripts 
done

popd 
