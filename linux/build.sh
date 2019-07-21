#!/bin/bash
set -e
##########################################
# This script is used to build RK3399 Linux.
# by: Qitas
# Date: 2019-03-12
##########################################
export ROOT=`pwd`
SCRIPTS=$ROOT/scripts
export BOOT_PATH
export ROOTFS_PATH
export UBOOT_PATH

root_check()
{
	if [ "$(id -u)" -ne "0" ]; then
		echo "This option requires root."
		echo "Pls use command: sudo ./build.sh"
		exit 0
	fi	
}

UBOOT_check()
{
	for ((i = 0; i < 5; i++)); do
		UBOOT_PATH=$(whiptail --title "RK3399 Build System" \
			--inputbox "Pls input device node of SDcard.(/dev/sdc)" \
			10 60 3>&1 1>&2 2>&3)
	
		if [ $i = "4" ]; then
			whiptail --title "RK3399 Build System" --msgbox "Error, Invalid Path" 10 40 0	
			exit 0
		fi


		if [ ! -b "$UBOOT_PATH" ]; then
			whiptail --title "RK3399 Build System" --msgbox \
				"The input path invalid! Pls input correct path!" \
				--ok-button Continue 10 40 0	
		else
			i=200 
		fi 
	done
}

BOOT_check()
{
	## Get mount path of u-disk
	for ((i = 0; i < 5; i++)); do
		BOOT_PATH=$(whiptail --title "RK3399 Build System" \
			--inputbox "Pls input mount path of BOOT.(/media/RK3399/BOOT)" \
			10 60 3>&1 1>&2 2>&3)
	
		if [ $i = "4" ]; then
			whiptail --title "RK3399 Build System" --msgbox "Error, Invalid Path" 10 40 0	
			exit 0
		fi


		if [ ! -d "$BOOT_PATH" ]; then
			whiptail --title "RK3399 Build System" --msgbox \
				"The input path invalid! Pls input correct path!" \
				--ok-button Continue 10 40 0	
		else
			i=200 
		fi 
	done
}

ROOTFS_check()
{
	for ((i = 0; i < 5; i++)); do
		ROOTFS_PATH=$(whiptail --title "RK3399 Build System" \
			--inputbox "Pls input mount path of rootfs.(/media/RK3399/rootfs)" \
			10 60 3>&1 1>&2 2>&3)
	
		if [ $i = "4" ]; then
			whiptail --title "RK3399 Build System" --msgbox "Error, Invalid Path" 10 40 0	
			exit 0
		fi


		if [ ! -d "$ROOTFS_PATH" ]; then
			whiptail --title "RK3399 Build System" --msgbox \
				"The input path invalid! Pls input correct path!" \
				--ok-button Continue 10 40 0	
		else
			i=200 
		fi 
	done
}
Update_check()
{
	MENUSTR="Pls choose SD or EMMC"
	##########################################
	VAR=$(whiptail --title "RK3399 RK3399 Build System" \
    	--menu "$MENUSTR" 10 60 3 --cancel-button Exit --ok-button Select \
    	"0"  "SD Card" \
    	"1"  "EMMC" \
    	3>&1 1>&2 2>&3)
}

if [ ! -d $ROOT/output ]; then
    mkdir -p $ROOT/output
fi

##########################################
## Root Password check
for ((i = 0; i < 5; i++)); do
	PASSWD=$(whiptail --title "RK3399 Build System" \
		--passwordbox "Enter your root password. Note! Don't use root to run this scripts" \
		10 60 3>&1 1>&2 2>&3)
	
	if [ $i = "4" ]; then
		whiptail --title "Note Box" --msgbox "Error, Invalid password" 10 40 0	
		exit 0
	fi

	sudo -k
	if sudo -lS &> /dev/null << EOF
$PASSWD
EOF
	then
		i=10
	else
		whiptail --title "RK3399 Build System" --msgbox "Invalid password, Pls input corrent password" \
			10 40 0	--cancel-button Exit --ok-button Retry
	fi
done

echo $PASSWD | sudo ls &> /dev/null 2>&1

## Check cross tools
function prepare_toolchain()
{ 
	sudo apt -y --no-install-recommends --fix-missing install \
	bsdtar mtools u-boot-tools pv bc \
	gcc automake make \
	lib32z1 lib32z1-dev qemu-user-static \
	dosfstools libncurses5-dev libssl-dev
}
function get_toolchain()
{ 
	if [ ! -d $ROOT/toolchain/gcc-linaro-aarch ]; then
		cd $ROOT
		git clone --depth=1 https://github.com/sochub/aarch-linux.git
		mv aarch-linux toolchain
    	fi
	if [ ! -d $ROOT/toolchain/gcc-linaro-aarch/gcc-linaro ]; then
		cd $ROOT/toolchain/gcc-linaro-aarch
		git clone --depth=1 https://github.com/sochub/arm-linux-eabi.git
		mv arm-linux-eabi gcc-linaro
    	fi
}

if [ ! -d $ROOT/output ]; then
    mkdir -p $ROOT/output
fi

MENUSTR="Pls select build option"

OPTION=$(whiptail --title "RK3399 Build System" \
	--menu "$MENUSTR" 20 60 12 --cancel-button Finish --ok-button Select \
	"0"   "Build Release Image" \
	"1"   "Build Uboot" \
	"2"   "Build Linux" \
	"3"   "Update kernel Image" \
	"4"   "Update Module" \
	"5"   "Update Uboot" \
	"6"   "Install Image into EMMC" \
	3>&1 1>&2 2>&3)

	#"0"   "Build Release Image" \
	#"7"   "Build system image" \

get_toolchain
prepare_toolchain


if [ $OPTION = "0" -o $OPTION = "0" ]; then
	sudo echo ""
	clear
	Update_check
	clear
	TMP=$OPTION
	TMP_DISTRO=""
	MENUSTR="Distro Options"
	OPTION=$(whiptail --title "RK3399 Build System" \
		--menu "$MENUSTR" 20 60 3 --cancel-button Finish --ok-button Select \
		"0"   "Ubuntu Xenial" \
		"1"   "Debian Jessie" \
		3>&1 1>&2 2>&3)

        TYPE=$(whiptail --title "RK3399 Build System" \
                --menu "$MENUSTR" 20 60 3 --cancel-button Finish --ok-button Select \
                "0"   "Server" \
                3>&1 1>&2 2>&3)
	if [ ! -f $ROOT/output/boot.img ]; then
		export BUILD_KERNEL=1
		cd $SCRIPTS
		./kernel_compile.sh
		cd -
	fi
	if [ ! -d $ROOT/output/lib ]; then
		if [ -f $ROOT/output/lib ]; then
			rm $ROOT/output/lib
		fi
		mkdir $ROOT/output/lib
		export BUILD_MODULE=1
		cd $SCRIPTS
		./kernel_compile.sh
		cd -
	fi
	if [ ! -f $ROOT/output/u-boot/idbloader.img -o ! -f $ROOT/output/u-boot/trust.img -o ! -f $ROOT/output/u-boot/uboot.img ]; then
	    cd $SCRIPTS
		./uboot_compile.sh
		cd -
	fi

	if [ $OPTION = "0" ]; then
		TMP_DISTRO="xenial"
        elif [ $OPTION = "1" ]; then
                TMP_DISTRO="jessie"
        fi

	if [ $TYPE = "0" ]; then
		TMP_TYPE="server"
	elif [ $TYPE = "1" ]; then
		TMP_TYPE="desktop"
	fi
	cd $SCRIPTS
	DISTRO=$TMP_DISTRO
        if [ -d $ROOT/output/${DISTRO}_rootfs_$TMP_TYPE ]; then
                if (whiptail --title "RK3399 Build System" --yesno \
                        "${DISTRO} rootfs has exist! Do you want use it?" 10 60) then
                        OP_ROOTFS=0
                else
                        OP_ROOTFS=1
                fi
                if [ $OP_ROOTFS = "0" ]; then
                        sudo cp -rf $ROOT/output/${DISTRO}_rootfs_$TMP_TYPE $ROOT/output/tmp
			if [ -d $ROOT/output/rootfs ]; then
				sudo rm -rf $ROOT/output/rootfs
			fi
			sudo mv $ROOT/output/tmp $ROOT/output/rootfs
			whiptail --title "RK3399 Build System" --msgbox "Rootfs has build" \
				10 40 0	--ok-button Continue
		else
			sudo rm -rf $ROOT/output/${DISTRO}_rootfs_$TMP_TYPE
			export DISTRO=$DISTRO
			export PLATFORM=$PLATFORM
                        sudo ./00_rootfs_build.sh $DISTRO $PLATFORM $TYPE
                        sudo ./01_rootfs_build.sh $DISTRO $TMP_TYPE
		fi
	else
		sudo rm -rf $ROOT/output/${DISTRO}_rootfs_$TMP_TYPE
		export DISTRO=$DISTRO
		export PLATFORM=$PLATFORM
                sudo ./00_rootfs_build.sh $DISTRO $PLATFORM $TYPE
                sudo ./01_rootfs_build.sh $DISTRO $TMP_TYPE
			
	fi
	if [ $TMP = "0" ]; then 
				echo -e "\nend it\n"
                sudo ./build_image.sh $DISTRO $PLATFORM $TYPE $VAR
                whiptail --title "RK3399 Build System" --msgbox "Succeed to build Image" \
                                10 40 0 --ok-button Continue
	fi
	exit 0
elif [ $OPTION = "1" ]; then
	cd $SCRIPTS
	./uboot_compile.sh
	clear
	exit 0
elif [ $OPTION = "2" ]; then
	export BUILD_KERNEL=1
	export BUILD_MODULE=1
	cd $SCRIPTS
	./kernel_compile.sh $PLATFORM
	clear
	exit 0
elif [ $OPTION = "10" ]; then
	export BUILD_KERNEL=1
	cd $SCRIPTS
	./kernel_compile.sh
	exit 0
elif [ $OPTION = "10" ]; then
	export BUILD_MODULE=1
	cd $SCRIPTS
	./kernel_compile.sh
	exit 0
elif [ $OPTION = "10" ]; then
	sudo echo ""
	clear
	UBOOT_check
	clear
	whiptail --title "RK3399 Build System" \
			 --msgbox "Burning Image to SDcard. Pls select Continue button" \
				10 40 0	--ok-button Continue
	pv "$ROOT/output/${PLATFORM}.img" | sudo dd bs=1M of=$UBOOT_PATH && sync
	clear
	whiptail --title "RK3399 Build System" --msgbox "Succeed to Download Image into SDcard" \
				10 40 0	--ok-button Continue
	exit 0
elif [ $OPTION = '3' ]; then
	clear 
	Update_check
	clear
	if [ $VAR = "0" ]; then
		UBOOT_check
	fi
	clear
	cd $SCRIPTS
	sudo ./kernel_update.sh $UBOOT_PATH  #$PLATFORM
	exit 0
elif [ $OPTION = '4' ]; then
	sudo echo ""
	clear 
	ROOTFS_check
	clear
	cd $SCRIPTS
	sudo ./modules_update.sh $ROOTFS_PATH
	exit 0
elif [ $OPTION = '5' ]; then
	clear
	Update_check
	clear
	if [ $VAR = "0" ]; then
		UBOOT_check
	fi
	clear
	cd $SCRIPTS
	sudo ./uboot_update.sh $UBOOT_PATH
	exit 0
elif [ $OPTION = '6' ]; then
	if [ ! -f $ROOT/output/system.img ]; then
		echo "Can not find system.img in ${ROOT}/output"
		exit 0
	fi
	cd $SCRIPTS
	sudo ./flash_tool.sh -c $PLATFORM -p system -i $ROOT/output/system.img
	exit 0
elif [ $OPTION = '7' ]; then
	clear 
	Update_check
	clear
	cd $SCRIPTS
	sudo ./build_system.sh $VAR
	exit 0
elif [ $OPTION = '10' ]; then
	clear
	echo -e "\e[1;31m Updating SDK to Github \e[0m"
	git push -u origin master
	exit 0
elif [ $OPTION = "11" ]; then
	clear
	echo -e "\e[1;31m Updating SDK from Github \e[0m"
	git push origin
	exit 0
else
	whiptail --title "RK3399 Build System" \
		--msgbox "Pls select correct option" 10 50 0
	exit 0
fi
