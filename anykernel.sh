# AnyKernel2 Ramdisk Mod Script
# osm0sis @ xda-developers

## AnyKernel setup
# begin properties
properties() { '
kernel.string=DragonHeart kernel for Xiaomi Mi A2 Lite
do.devicecheck=1
do.modules=1
do.cleanup=1
do.cleanuponabort=0
device.name1=daisy
device.name2=
device.name3=
device.name4=
device.name5=
'; } # end properties

# shell variables
block=/dev/block/bootdevice/by-name/boot;
is_slot_device=0;
ramdisk_compression=auto;


## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. /tmp/anykernel/tools/ak2-core.sh;


## AnyKernel file attributes
# set permissions/ownership for included ramdisk files
chmod -R 750 $ramdisk/*;
chmod -R 755 $ramdisk/sbin;
chown -R root:root $ramdisk/*;


## AnyKernel install
dump_boot;

# begin ramdisk changes

# make schedutil default governor
#insert_line init.rc '# set governor' 'before' '# scheduler tunables' '# set governor'
#insert_line init.rc 'write /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor "schedutil"' 'after' '# set governor' 'write /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor "schedutil"'

#if [ -d $ramdisk/.subackup -o -d $ramdisk/.backup ]; then
if [ -d $ramdisk/.backup ]; then
  # Force kernel to load rootfs (preserve magisk by eremitein@xda)
  # skip_initramfs -> want_initramfs
	#ls -R /tmp/anykernel/
  #echo "magiskboot hexpatch";
	#ls -l /tmp/anykernel/*Image*;
  #$bin/magiskboot decompress /tmp/anykernel/zImage /tmp/anykernel/Image;
  #$bin/magiskboot hexpatch /tmp/anykernel/zImage 736B69705F696E697472616D667300 77616E745F696E697472616D667300;
	#$bin/magiskboot compress=gzip /tmp/anykernel/Image /tmp/anykernel/zImage;
  # Add skip_override parameter to cmdline so user doesn't have to reflash Magisk
  patch_cmdline "skip_override" "skip_override";
  ui_print " ";
  ui_print "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@";
  ui_print "Magisk detected! If you want continue using it";
  ui_print "    just reflash Magisk right after kernel    ";
  #ui_print "Please DO NOT reflash Magisk AFTER the kernel!";
  #ui_print "   The kernel preserves Magisk already :)";
  ui_print "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@";
  #ui_print " ";
	#ls -l /tmp/anykernel/*Image*;
	#ls -R /tmp/anykernel/;
else
  patch_cmdline "skip_override" "";
fi;

# Remove recovery service so that TWRP isn't overwritten
#remove_section init.rc "service flash_recovery" ""

# end ramdisk changes

write_boot;

## end install

