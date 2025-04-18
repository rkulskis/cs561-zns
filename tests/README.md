# tests/

1. Zones must be cleared before running any write test
```bash
# Device name should be /dev/nvme0n1
sudo nvme zns reset-zone [DEVICE_NAME] -a
```
2. To run a test:
```bash
sudo fio [TEST_FILE] 
```
3. To output the fio results to a csv file:
```bash
sudo fio --output-format=csv --output=[OUTPUT_FILE].csv [TEST_FILE]
```

Table of test id:int to description of test

- 1: Ross example test, not testing anything specific
- 2: Basic write test w/ iodepth=16 | zonesize = 33554432
- 3: Basic read test w/ sequential reads. Global is the same.
- 4: Random read test
- 5: Write and read with iodepth=1, low queue depth
- 6: Write and read with iodepth=32, high queue depth