# Concurrency-aware Algorithm Design for ZNS SSDs

## Repository Structure

## Setup instructions
1. Clone the repository including its submodules/dependencies

    ```bash
    git clone --recurse-submodules https://github.com/rkulskis/cs561-zns.git
    ```
2. Compile FEMU with custom femu scripts
   ```bash
   # only Debian/Ubuntu based distributions supported
   cd cs561-zns/
   make compile-femu
   ```
   ```bash
   # If on BU's SCC, follow below instructions
   cd cs562-zns/
   module load pixman ninja
   make compile-femu-scc
   ```
3. Get the [VM image](https://forms.gle/nEZaEe2fkj5B1bxt9) and unzip into desired directory
- In `/confznsplusplus/femu-scripts/run-zns.sh` change the below line to the location of your vm image in relation to the `run-zns.sh` file
  ```bash
  IMGDIR=$HOME/images --> IMGDIR=[IMAGE_DIR]
  ```
   
