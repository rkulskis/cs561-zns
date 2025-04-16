all:
	echo "USAGE: "
init:
	git submodule update --init
# to get VM image fill out google form: https://forms.gle/nEZaEe2fkj5B1bxt9
compile-femu:
	sudo ./confznsplusplus/femu-scripts/pkgdep.sh
	cp -f ./scripts/femu-compile.sh ./confznsplusplus/femu-scripts/
	cd ./confznsplusplus/femu-scripts/ && ./femu-compile.sh # 999 888
