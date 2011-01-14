#!/bin/bash

##########################################################################
#
# Final Proyect: 
# 		"Desarrollo de Sistemas Empotrados Basados en Linux."
#		Profesor: Diego Dompe. 2010
# 
# Setup Environment Develop	for Cross Compilation:
# 	- Compiler and toolchain (CodeSourcery)
#	- Emulator (QEMU From Maemo) 
#	- Cross-compilation Toolkit (Scratchbox2 from Maemo)
#	
# Authors:
#	- Rocio Briceño (R)
#	- Jose David Delgado (JD) 
#	- Stephan Salazar (S)
#	- Javier Tiá (J)
#
# @TODO
#	- Cross Compile Tarea 2
#
# Links:
# 	http://elinux.org/BeagleBoard
#
###########################################################################

set -e
set -o errexit
# for Debbuging
# set -x
# set -v

# Avoid use proxy
#unset http_proxy; unset ftp_proxy; unset all_proxy; unset ALL_PROXY \
#unset https_proxy; unset no_proxy

DIR_ROOT=/tmp/RJDSJ_$(date +%s) # /tmp/RJDSJ_1294785522
DIR_BUILDROOT=$DIR_ROOT/buildroot
NCPU=$(cat /proc/cpuinfo | grep processor | wc -l)
DIR_ROOTFS=$DIR_ROOT/target

mkdir -p $DIR_ROOT && mkdir -p $DIR_BUILDROOT $DIR_ROOTFS
DIR_COMPILER=/opt/arm-2009q1 # /tmp/arm-2009q3

# Minimize Locale generation
# LANG=C; LANGUAGE=en_US:en; LC_ALL=C; 
# GLIBC_GENERATE_LOCALES="en_US.UTF-8"
# ENABLE_BINARY_LOCALE_GENERATION="0"

# export LANG LANGUAGE LC_ALL GLIBC_GENERATE_LOCALES ENABLE_BINARY_LOCALE_GENERATION

# Fix Ubuntu libc upgrade
# sudo sysctl -w vm.mmap_min_addr=65536 # 0

URLs="https://source.ridgerun.net/packages/linux-2.6.32-bbxm-validation-20100805.tar.gz
http://busybox.net/downloads/busybox-1.17.4.tar.bz2
http://download.lighttpd.net/lighttpd/releases-1.4.x/lighttpd-1.4.28.tar.gz
http://beagleboard-validation.s3.amazonaws.com/deploy/201008201549/sd/beagleboard-validation-201008201549.img.gz"

MD5s="d90a7bca1bade8ab867366b0b85d69fe  linux-2.6.32-bbxm-validation-20100805.tar.gz
b3254232e9919007ca803d3a4fe81f3c  busybox-1.17.4.tar.bz2
202d36efc6324adb95a3600d2826ec6a  lighttpd-1.4.28.tar.gz
75ac3fb3bdc45dc17a6cfd27218652d1  beagleboard-validation-201008201549.img.gz"

#
# Check Start
#

# Check Necessary Tools
function check_soft() {
	cd $DIR_ROOT

    # Check QEMU with beaglexM Motherboard
	problem=$(eval qemu-system-arm -M beaglexM | grep 'beaglexm')
	if [ "" == "$problem" ]; then
		echo -n "No qemu-system-arm."
		exit 1
	else 
		echo -e "QEMU OK.\n"
	fi

	# Check CodeSourcery Toolchain
	find $DIR_COMPILER/* -path '*bin*' -executable -name gcc | grep arm-none-linux-gnueabi 1>o.tmp
	if [ ! -s o.tmp ]; then
		echo -n "No CodeSourcery."
		exit 1
		rm o.tmp
	else 
		echo -e "CodeSourcery Toolchain OK.\n"
		rm o.tmp
	fi

	# Check Git
	problem=$(eval which git)
	if [ "" == "$problem" ]; then
   		echo -n "No Git."
	 	exit 1
	else 
		echo -e "Git OK.\n"
	fi


	# Check mkimage
	problem=$(eval which mkimage)
	if [ "" == "$problem" ]; then
   		echo -n "No mkimage."
		sudo apt-get install uboot-mkimage
		exit 1
	else 
		echo -e "mkimage OK.\n"
	fi

	echo ''
	read -p 'Necessary Software OK. Process to Download Necessary Tools. ENTER';
}

# Download necessary Archives 
function setup_assets() {
	cd $DIR_ROOT

echo ''
echo "Proccess to Download Necessary Archives.

You can copy the Necessary Archives in $DIR_ROOT:

	* linux-2.6.32-bbxm-validation-20100805.tar.gz
	* busybox-1.17.4.tar.bz2
	* lighttpd-1.4.28.tar.gz
	* beagleboard-validation-201008201549.img.gz

"

read -p "Process to download necessary Archives Y/N[Y]: " download
download=${download:-Y} 
echo ''
echo $download

if [[ "Y" == $(echo "$download" | tr '[:lower:]' '[:upper:]') ]]; 
then 
	for url in $URLs
	do
		asset=$(echo $url | sed 's/.*\///')
		echo "$MD5s" | grep $asset | md5sum -c && { assetMD5=1; };

  		if [[ -e $asset && $assetMD5 -eq 1 ]]; then
			echo "$url exists, skiping..."
			echo ''
  		else
			wget -c -P $DIR_ROOT -O $asset --no-check-certificate $url || { echo 'Download failed.'; exit 1; }  
  		fi
	done

	echo "$MD5s" | md5sum -c || { echo 'File Corrupt'; exit 1; }
	exit 1;
else 
	echo ''
	read -p 'Necessary Files OK. Proccess Setup Compiler. ENTER'; 
	echo ''
fi
}


#
# Prepare Compiler
#
function setup_compiler() {
	# Avoid installation in mode graphic
	# ~/arm-2009q3-67-arm-none-linux-gnueabi.bin -i console

	#
	# Create links for compiler
	#
	cd $DIR_ROOT
	
	rm -rf $DIR_ROOT/bin
	mkdir -p $DIR_ROOT/bin

	cd $DIR_ROOT/bin
	toolchain=$DIR_COMPILER
	for x in $toolchain/bin/arm-none-linux-gnueabi-*
	do
		ln -s $x arm-linux-${x#$toolchain/bin/arm-none-linux-gnueabi-}
	done
	
	echo ''
	read -p 'Compiler OK. Proccess Install and Setup QEMU. ENTER'; 
	echo ''
	cd $DIR_ROOT
}

export PATH="$DIR_ROOT/bin:$PATH"

#
# Setup Emulator QEMU
#
function setup_emulator() {
	cd $DIR_ROOT

	rm -rf $DIR_ROOT/qemu*
	mkdir $DIR_ROOT/qemu
	git clone git://gitorious.org/qemu-maemo/qemu.git qemu-git
	cd qemu-git
	./configure --prefix=$DIR_ROOT/qemu --enable-system \
	--target-list=arm-linux-user,arm-softmmu 
	#--enable-sdl

	make -j$NCPU install

	# echo "export PATH=""$DIR_ROOT/qemu:$PATH""" >> ~/.bashrc && \

	echo ''
	read -p 'QEMU Emulator OK. Proccess Install and Setup Scratchbox2. ENTER'; 
	echo ''
	cd $DIR_ROOT
}

export PATH="$DIR_ROOT/qemu:$PATH"


#
# Setup Scratchbox2
#
function setup_sb2() {
	cd $DIR_ROOT
	
	rm -rf $DIR_ROOT/scratchbox2
	git clone git://gitorious.org/scratchbox2/scratchbox2.git scratchbox2 && \
	cd scratchbox2 && \
	git checkout -b stable 2.1 && \
	./autogen.sh --prefix=$DIR_ROOT/sb2 && \
	make -j$NCPU install prefix=$DIR_ROOT/sb2 && \

	# Add sb2 to the PATH:
	#echo "export PATH=""$DIR_ROOT/sb2/bin:$PATH""" >> ~/.bashrc && \
	export PATH="$DIR_ROOT/sb2/bin:$PATH" 

	cd $DIR_ROOT

	mkdir -p $DIR_BUILDROOT
	cd $DIR_BUILDROOT && \
	cp -a $DIR_COMPILER/arm-none-linux-gnueabi/libc/{lib,etc,usr} .

	# cd $DIR_COMPILER/arm-none-linux-gnueabi/libc/
	# Assume QEMU installed
	# $DIR_ROOT/sb2/bin/sb2-init BeaglexM arm-none-linux-gnueabi-gcc
	# sb2-init -c $HOME/qemu/bin/qemu-arm BeagleGeneric $HOME/bin/arm-linux-gcc

	# Optional Compiler -cpu cortex-a8 and compatible OMAPv3
	# sb2-init -c qemu-arm BeaglexM $DIR_ROOT/bin/arm-linux-gcc && \
	sb2-init -c $DIR_ROOT/qemu/bin/qemu-arm BeaglexM $DIR_ROOT/bin/arm-linux-gcc && \

	# Set default Target BeablexM
	sb2-config -d BeaglexM && \

	# Check Compiler
	echo 'ScratchBox2 Prepared Successfully'
	sb2 gcc --version

	echo ''
	read -p 'Scratchbox2 OK. Proccess Setup Kernel(uImage). ENTER'; 
	echo ''
	cd $DIR_ROOT
}

export PATH="$DIR_ROOT/sb2/bin:$PATH" 

#
# Make mkimage utility/tool
#
function setup_mkimage() {
	cd $DIR_ROOT

	rm -rf $DIR_ROOT/u-boot-arm
	# Get U-Boot source 
	git clone git://git.denx.de/u-boot-arm.git u-boot-arm

	cd $DIR_ROOT/u-boot-arm
	make -j$NCPU tools && \

	install tools/mkimage $DIR_ROOT/bin && \
	
	echo ''
	read -p 'Kernel(mkimage) OK. Proccess Install/Setup Kernel(uImage). ENTER'; 
	echo ''

	cd $DIR_ROOT
}


#
# Compile Kernel
#
function setup_kernel() {
	cd $DIR_ROOT

	# avoid auto generate mkimage
	#setup_mkimage
	rm -rf beagleboard-validation-linux
	tar xf linux-2.6.32-bbxm-validation-20100805.tar.gz && \
	cd beagleboard-validation-linux
#
# Avoid scratchbox2, problem with Ubuntu
#
#sb2 make -j$NCPU clean
#sb2 make -j$NCPU distclean
#sb2 make -j$NCPU omap3_beagle_defconfig && \
#sb2 make -j$NCPU uImage && \
	
make -j$NCPU ARCH=arm CROSS_COMPILE=$DIR_COMPILER/bin/arm-none-linux-gnueabi- clean
make -j$NCPU ARCH=arm CROSS_COMPILE=$DIR_COMPILER/bin/arm-none-linux-gnueabi- distclean
make -j$NCPU ARCH=arm CROSS_COMPILE=$DIR_COMPILER/bin/arm-none-linux-gnueabi- omap3_beagle_defconfig
make -j$NCPU ARCH=arm CROSS_COMPILE=$DIR_COMPILER/bin/arm-none-linux-gnueabi- uImage	
	
	cp -v arch/arm/boot/uImage $DIR_ROOT && \

#sb2 make modules && \
make -j$NCPU ARCH=arm CROSS_COMPILE=$DIR_COMPILER/bin/arm-none-linux-gnueabi- modules && \

	echo ''
	read -p 'Kernel(uImage) OK. Proccess Install/Setup Busybox. ENTER';
	echo ''
	cd $DIR_ROOT
}


# ----------------------------------------------------
# 	Make Root File System (ramdisk.gz)
# ----------------------------------------------------

#
# Make busybox
#

cp -v config_busybox-1.17.4 $DIR_ROOT

function setup_busybox() {
	cd $DIR_ROOT

	rm -rf $DIR_ROOTFS && mkdir $DIR_ROOTFS

	tar xf busybox-1.17.4.tar.bz2 && \
	cd busybox-1.17.4
	make -j$NCPU clean && make -j$NCPU distclean

	cp -v $DIR_ROOT/config_busybox-1.17.4 .config

	sb2 make -j$NCPU && \
	sb2 make -j$NCPU CONFIG_PREFIX=$DIR_ROOTFS install && \

	echo ''
	read -p 'Busybox OK. Proccess Setup Root File System. ENTER';
	echo ''
	cd $DIR_ROOT
}


#
# Setup Root File System
#
function setup_rootfs() {
	cd $DIR_ROOT
	rm -rf $DIR_ROOTFS/lib/modules/2.6.32/{source,build}

	cd $DIR_ROOT/beagleboard-validation-linux

	echo ''
	echo 'Installing modules kernel...'
	# Avoiding Scratchbox2, problem with Ubuntu
	# sb2 make -j$NCPU INSTALL_MOD_PATH=$DIR_ROOTFS modules_install
	make -j$NCPU ARCH=arm CROSS_COMPILE=$DIR_COMPILER/bin/arm-none-linux-gnueabi- \
	INSTALL_MOD_PATH=$DIR_ROOTFS modules_install

	cd $DIR_ROOTFS
	
	mkdir dev
	sudo mknod dev/console c 5 1
	sudo mknod dev/null c 1 3

	mkdir -p dev/pts etc etc/init.d lib mnt opt proc root sys tmp var var/log var/www/html var/log/lighttpd etc/lighttpd

echo -e 'rootfs       /            auto    defaults      1  1
proc         /proc        proc    defaults      0  0
sysfs        /sys         sysfs   defaults      0  0
devpts       /dev/pts     devpts  mode=0622     0  0' > $DIR_ROOTFS/etc/fstab

echo -e 'root:x:0:root
root:*:0:
daemon:*:1:
bin:*:2:
sys:*:3:
adm:*:4:
tty:*:5:
shadow:*:42:
lighttpd:*:100:
nogroup:*:65534:' > $DIR_ROOTFS/etc/group

echo -e 'root::0:0:root:/root:/bin/ash
daemon:*:1:1:daemon:/usr/sbin:/bin/sh
bin:*:2:2:bin:/bin:/bin/sh
sys:*:3:3:sys:/dev:/bin/sh
lighttpd:*:100:100:lighttpd:/var/www/html:/bin/nologin
nobody:*:65534:65534:nobody:/nonexistent:/bin/sh' > $DIR_ROOTFS/etc/passwd

echo -e '127.0.0.1       localhost' > $DIR_ROOTFS/etc/hosts

echo -e '::sysinit:/etc/init.d/rcS 

# /bin/ash
#
# Start an "askfirst" shell on the serial port
#ttyS0
::askfirst:-/bin/ash

# Stuff to do when restarting the init process
::restart:/sbin/init

# Stuff to do before rebooting
::ctrlaltdel:/sbin/reboot
::shutdown:/bin/umount -a -r
#::shutdown:/sbin/swapoff -a
' > $DIR_ROOTFS/etc/inittab

echo -e '#!/bin/sh
HOSTNAME=EMPOTRADO
VERSION=1.0.1

hostname $HOSTNAME

#   ---------------------------------------------
#   Prints execution status.
#
#   arg1 : Execution status
#   arg2 : Continue (0) or Abort (1) on error
#   ---------------------------------------------
status ()
{
	if [ $1 -eq 0 ] ; then
	   echo "[SUCCESS]"
	else
		echo "[FAILED]"
		if [ $2 -eq 1 ] ; then
		   echo "... System init aborted."
		   exit 1
		fi
	fi
}

#   ---------------------------------------------
#   Get verbose
#   ---------------------------------------------
echo ""
echo "    System for ""CURSO EMPOTRADO"" initialization..."
echo ""
echo "    Hostname       : $HOSTNAME"
#echo "    Hostname       : $HOSTNAME"
echo "    Filesystem     : v$VERSION"
echo "    Kernel release : `uname -v` `uname -s` `uname -r`"
#echo "    Kernel version : "
echo ""

#   ---------------------------------------------
#   MDEV Support
#   (Requires sysfs support in the kernel)
#   ---------------------------------------------
echo -n " Mounting /proc             : "
mount -n -t proc /proc /proc
status $? 1

echo -n " Mounting /sys              : "
mount -n -t sysfs sysfs /sys
status $? 1

echo -n " Mounting /dev              : "
mount -n -t tmpfs mdev /dev
status $? 1

echo -n " Mounting /dev/pts          : "
mkdir /dev/pts
mount -t devpts devpts /dev/pts
status $? 1

echo -n " Populating /dev            : "
mkdir /dev/input
mkdir /dev/snd

mdev -s
status $? 0

#   ---------------------------------------------
#   Mount the default file systems
#   ---------------------------------------------
echo -n " Mounting other filesystems : "
mount -a
status $? 0

#   ---------------------------------------------
#   Set PATH
#   ---------------------------------------------
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin


#   ---------------------------------------------
#   Start other daemons
#   ---------------------------------------------
echo -n " Starting syslogd           : "
/sbin/syslogd
status $? 0

#   ---------------------------------------------
#   Done!
#   ---------------------------------------------
echo ""
echo "System ""CURSO EMPOTRADO"" initialization complete."

#   ---------------------------------------------
# 	Show Banner SOFTTEK/HP
#   ---------------------------------------------
if [ -x /etc/motd ]; then
	cat /etc/motd
fi

#   ---------------------------------------------
# 	Show Start lighttpd
#   ---------------------------------------------
#if [ -x /sbin/lighttpd ]; then
#	echo -e "Starting Lighttpd with basic features\n...";
#	lighttpd -D -f /etc/lighttpd/lighttpd.conf
#fi

#   ---------------------------------------------
#   Start "TAREA 2"
#   ---------------------------------------------
#if [ -x /tarea_2 ]; then
#       echo " Starting ""TAREA 2""..."
#       /tarea2
#       #sleep 5
#fi

' > $DIR_ROOTFS/etc/init.d/rcS

sudo chmod -v +x $DIR_ROOTFS/etc/init.d/rcS

echo '
#
# lighttpd.conf for Curso Empotrado
#

server.document-root 	= "/var/www/html"
server.port 			= 30000
server.username 		= "lighttpd"
server.groupname 		= "lighttpd"
server.bind             = "127.0.0.1"
server.event-handler 	= "poll"
server.tag 				= "lighttpd"

server.errorlog         = "/var/log/lighttpd/error.log"
accesslog.filename      = "/var/log/lighttpd/access.log"

server.modules          = (
		"mod_access",
		"mod_accesslog",
	    "mod_fastcgi",
		"mod_rewrite"
	    ,"mod_auth"
)

# mimetype mapping
mimetype.assign  = (
  ".gif"          =>      "image/gif",
  ".jpg"          =>      "image/jpeg",
  ".jpeg"         =>      "image/jpeg",
  ".png"          =>      "image/png",
  ".css"          =>      "text/css",
  ".html"         =>      "text/html",
  ".htm"          =>      "text/html",
  ".js"           =>      "text/javascript",
  ".text"         =>      "text/plain",
  ".txt"          =>      "text/plain",
)

index-file.names = ( "index.html", "index.htm" )
' > $DIR_ROOTFS/etc/lighttpd/lighttpd.conf

# Test html
echo '<html><title>Curso Empotrado</title><body>
<h3>CURSO EMPOTRADO</h3>
</body></html>
' > $DIR_ROOTFS/var/www/html/index.html

#echo -e 'audio       0:5 0666
#console     0:5 0600
#control.*   0:0 0660 @/bin/mv /dev/$MDEV /dev/snd/
#dsp         0:5 0666
#event.*     0:0 0600 @/bin/mv /dev/$MDEV /dev/input/
#fb          0:5 0666
#nfs         0:5 0770
#null        0:0 0777
#pcm.*       0:0 0660 @/bin/mv /dev/$MDEV /dev/snd/
#rtc         0:0 0666
#tty         0:5 0660
#tty0*       0:5 0660
#tty1*       0:5 0660
#tty2*       0:5 0660
#tty3*       0:5 0660
#tty4*       0:5 0660
#tty5*       0:5 0660
#tty6*       0:5 0660
#ttyS*       0:5 0640
#urandom     0:0 0444
#zero        0:0 0666
#' > $DIR_ROOTFS/etc/mdev.conf

echo '
 ____         __ _   _       _         __  _   _ ____  
/ ___|  ___  / _| |_| |_ ___| | __    / / | | | |  _ \ 
\___ \ / _ \| |_| __| __/ _ \ |/ /   / /  | |_| | |_) |
 ___) | (_) |  _| |_| ||  __/   <   / /   |  _  |  __/ 
|____/ \___/|_|  \__|\__\___|_|\_\ /_/    |_| |_|_|    

' > $DIR_ROOTFS/etc/motd

cd $DIR_ROOTFS/lib
cp -ra $DIR_COMPILER/arm-none-linux-gnueabi/libc/lib/* . && \
cd modules && arm-none-linux-gnueabi-strip $(find . -name '*.ko')

echo ''
read -p 'Setup Root File System OK. Process install/setup Tarea 2. ENTER'; 
echo ''
cd $DIR_ROOT
}


#
# Compile Tarea 2
#
function setup_tarea2() {
	cd $DIR_ROOT

	cd tarea2
	sb2 make 
	sb2 make -j$NCPU DESTDIR=$DIR_ROOTFS install  

	read -p 'Tarea 2 OK. Process install/setup lighttpd. ENTER'; 

	cd $DIR_ROOT
}


#
# Setup lighttpd 
#
function setup_lighttpd() {
	cd $DIR_ROOT

	rm -rf lighttpd-1.4.28
	tar xf lighttpd-1.4.28.tar.gz
	cd lighttpd-1.4.28
	
	sb2 ./configure --prefix=$DIR_ROOTFS  \
	--disable-ipv6 --without-zlib --without-bzip2 \
	--without-pcre --disable-lfs

	sb2 make -j$NCPU 
	sb2 make -j$NCPU DESTDIR=$DIR_ROOTFS install  

	# Run lighttpd -f /etc/lighttpd/lighttpd.conf -D
	read -p 'Lighttpd Server OK. Process create <ramdisk.gz>. ENTER'; 

	cd $DIR_ROOT
}


#
# Setup ramdisk.gz
#
function setup_ramdisk() {
	cd $DIR_ROOT

	FILE_MOUNT=rd-ext2.bin
	# Make file system 46 MB
	dd if=/dev/zero of=$FILE_MOUNT bs=1k count=45056 && \
	mke2fs -F -m0 $FILE_MOUNT && \

	DIR_RD_EXT2=$DIR_ROOT/rd-ext2_$(date +%s)
	mkdir -p $DIR_RD_EXT2

	sudo mount -t ext2 $FILE_MOUNT $DIR_RD_EXT2 -o loop #|| \ 
#{ sync && sudo umount $DIR_RD_EXT2; rm $DIR_RD_EXT2; exit 1; }

	tar -C $DIR_ROOTFS -cf - . | sudo tar -C $DIR_RD_EXT2 -xf - && \
	
	sudo chown -R root:root $DIR_RD_EXT2 && \

	# Permission for Lighttpd Server
	sudo chown lighttpd:lighttpd $DIR_ROOTFS/var/log/lighttpd
	sudo chown lighttpd:root $DIR_ROOTFS/etc/lighttpd/lighttpd.conf

	sync && sudo umount $DIR_RD_EXT2 && \
	rm -rf $DIR_RD_EXT2

	rm $DIR_ROOT/ramdisk.gz
	gzip -c --best $FILE_MOUNT > $DIR_ROOT/ramdisk.gz

	echo ''
	read -p 'ramdisk.gz OK. Process copy uImage and ramdisk.gz to SD Card. ENTER'; 
	echo ''
	cd $DIR_ROOT
}


# Change OLD ramdisk to NEW ramdisk
function setup_sdcard() {
	cd $DIR_ROOT

	# Mount SD Card 
	DIR_SD_CARD=$DIR_ROOT/sdcard_$(date +%s)
	mkdir -p $DIR_SD_CARD
	# 41 MB image 
	fileSD=beagleboard-validation-201008201549.img.gz 
  
	if [ -e $fileSD ]; then
		gunzip $fileSD
  	fi

	sudo mount -o rw,loop,offset=32256 $DIR_ROOT/$(basename $fileSD .gz) $DIR_SD_CARD #|| \ 
#{ sync && sudo umount $DIR_SD_CARD; rm $DIR_SD_CARD; exit 1; }

	# Copy NEW ramdisk.gz
	sudo cp -vu $DIR_ROOT/ramdisk.gz $DIR_SD_CARD && \
	sudo cp -vu $DIR_ROOT/uImage $DIR_SD_CARD && \

	sync && sudo umount $DIR_SD_CARD
	rm -rf $DIR_SD_CARD

	echo ''
	read -p 'uImage and ramdisk.gz into SD Card OK. Process Run Emulator with new System. ENTER';
	echo ''
	cd $DIR_ROOT
}


#
# Run Emulator
#
function run_emulator() {
	cd $DIR_ROOT
	
	# $DIR_ROOT/qemu/bin/
	fileIMG=beagleboard-validation-201008201549.img
	
	$DIR_ROOT/qemu/bin/qemu-system-arm -M beaglexm -sd $fileIMG -serial stdio

	echo ''
	echo '-~--O--~ THE END -~--O--~'
	echo ''
	cd $DIR_ROOT
}

cd $DIR_ROOT

check_soft && \
setup_assets  && \
setup_compiler && \
setup_emulator && \
setup_sb2 && \
setup_kernel && \
setup_busybox && setup_rootfs && \
#setup_tarea2 && \
setup_lighttpd && \
setup_ramdisk && \
setup_sdcard && \
run_emulator

