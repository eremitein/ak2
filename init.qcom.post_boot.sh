#!/system/bin/sh

# Copyright (c) 2012-2013, 2016-2018, The Linux Foundation. All rights reserved.
#
# 2019 Mod for 'dragonheart@daisy' by Victor Bo <eremitein@xda/zerovoid@4pda>
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of The Linux Foundation nor
#       the names of its contributors may be used to endorse or promote
#       products derived from this software without specific prior written
#       permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NON-INFRINGEMENT ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

function global_func()
{
	target=`getprop ro.board.platform`

	if [ -f /sys/devices/soc0/soc_id ]; then
		soc_id=`cat /sys/devices/soc0/soc_id`
	else
		soc_id=`cat /sys/devices/system/soc/soc0/id`
	fi

	if [ -f /sys/devices/soc0/hw_platform ]; then
		hw_platform=`cat /sys/devices/soc0/hw_platform`
	else
		hw_platform=`cat /sys/devices/system/soc/soc0/hw_platform`
	fi

	if [ -f /sys/devices/soc0/platform_subtype_id ]; then
		platform_subtype_id=`cat /sys/devices/soc0/platform_subtype_id`
	fi

	ProductName=`getprop ro.product.name`
	low_ram=`getprop ro.config.low_ram`

	arch_type=`uname -m`
	MemTotalStr=`cat /proc/meminfo | grep MemTotal`
	MemTotal=${MemTotalStr:16:8}
}

function sched_dcvs_eas()
{
echo "sched_dcvs_eas"
	# Governor settings
	echo 1 > /sys/devices/system/cpu/cpu0/online
	echo "schedutil" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
	echo 0 > /sys/devices/system/cpu/cpufreq/schedutil/rate_limit_us
	# Set the hispeed_freq
	echo 1401600 > /sys/devices/system/cpu/cpufreq/schedutil/hispeed_freq
	# Default value for hispeed_load is 90, for 8953 and sdm450 it should be 85
	echo 85 > /sys/devices/system/cpu/cpufreq/schedutil/hispeed_load
}   

function sched_dcvs_hmp()
{
echo "sched_dcvs_hmp"
	# Scheduler settings
	echo 3 > /proc/sys/kernel/sched_window_stats_policy
	echo 3 > /proc/sys/kernel/sched_ravg_hist_size
	# Task packing settings
	echo 0 > /sys/devices/system/cpu/cpu0/sched_static_cpu_pwr_cost
	echo 0 > /sys/devices/system/cpu/cpu1/sched_static_cpu_pwr_cost
	echo 0 > /sys/devices/system/cpu/cpu2/sched_static_cpu_pwr_cost
	echo 0 > /sys/devices/system/cpu/cpu3/sched_static_cpu_pwr_cost
	echo 0 > /sys/devices/system/cpu/cpu4/sched_static_cpu_pwr_cost
	echo 0 > /sys/devices/system/cpu/cpu5/sched_static_cpu_pwr_cost
	echo 0 > /sys/devices/system/cpu/cpu6/sched_static_cpu_pwr_cost
	echo 0 > /sys/devices/system/cpu/cpu7/sched_static_cpu_pwr_cost
	# Spill load is set to 100% by default in the kernel
	echo 3 > /proc/sys/kernel/sched_spill_nr_run
	# Apply inter-cluster load balancer restrictions
	echo 0 > /proc/sys/kernel/sched_restrict_cluster_spill
	# Set sync wakee policy tunable
	echo 1 > /proc/sys/kernel/sched_prefer_sync_wakee_to_waker

	# Governor settings
	echo 1 > /sys/devices/system/cpu/cpu0/online
	echo "interactive" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
	#echo# "19000 1401600:39000" > /sys/devices/system/cpu/cpufreq/interactive/above_hispeed_delay
	echo 85 > /sys/devices/system/cpu/cpufreq/interactive/go_hispeed_load
	echo 20000 > /sys/devices/system/cpu/cpufreq/interactive/timer_rate
	#echo# 1401600 > /sys/devices/system/cpu/cpufreq/interactive/hispeed_freq
	echo 0 > /sys/devices/system/cpu/cpufreq/interactive/io_is_busy
	#echo# "85 1401600:80" > /sys/devices/system/cpu/cpufreq/interactive/target_loads
	echo 39000 > /sys/devices/system/cpu/cpufreq/interactive/min_sample_time
	#echo 40000 > /sys/devices/system/cpu/cpufreq/interactive/sampling_down_factor
	echo 19 > /proc/sys/kernel/sched_upmigrate_min_nice
	# Enable sched guided freq control
	echo 1 > /sys/devices/system/cpu/cpufreq/interactive/use_sched_load
	echo 1 > /sys/devices/system/cpu/cpufreq/interactive/use_migration_notif
	echo 200000 > /proc/sys/kernel/sched_freq_inc_notify
	echo 200000 > /proc/sys/kernel/sched_freq_dec_notify
}

function sched_dcvs_load()
{
echo "sched_dcvs_load"
	echo 1 > /sys/devices/system/cpu/cpu0/online
	echo "interactive" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
}

function configure_zram_parameters()
{
echo "configure_zram_parameters"
	if [ -f /sys/block/zram0/disksize ]; then
		echo 1610612736 > /sys/block/zram0/disksize
		mkswap /dev/block/zram0
		swapon /dev/block/zram0 -p 32758
	fi
}

function configure_read_ahead()
{
echo "configure_read_ahead"
global_func
	# Set 128 for <= 3GB &
	# set 512 for >= 4GB targets.
	if [ $MemTotal -le 3145728 ]; then
		echo 128 > /sys/block/mmcblk0/bdi/read_ahead_kb
		echo 128 > /sys/block/mmcblk0/queue/read_ahead_kb
		echo 128 > /sys/block/mmcblk0rpmb/bdi/read_ahead_kb
		echo 128 > /sys/block/mmcblk0rpmb/queue/read_ahead_kb
		echo 128 > /sys/block/dm-0/queue/read_ahead_kb
		echo 128 > /sys/block/dm-1/queue/read_ahead_kb
	else
		echo 512 > /sys/block/mmcblk0/bdi/read_ahead_kb
		echo 512 > /sys/block/mmcblk0/queue/read_ahead_kb
		echo 512 > /sys/block/mmcblk0rpmb/bdi/read_ahead_kb
		echo 512 > /sys/block/mmcblk0rpmb/queue/read_ahead_kb
		echo 512 > /sys/block/dm-0/queue/read_ahead_kb
		echo 512 > /sys/block/dm-1/queue/read_ahead_kb
	fi
}

function disable_core_ctl() {
echo "disable_core_ctl"
	if [ -f /sys/devices/system/cpu/cpu0/core_ctl/enable ]; then
		echo 0 > /sys/devices/system/cpu/cpu0/core_ctl/enable
	else
		echo 1 > /sys/devices/system/cpu/cpu0/core_ctl/disable
	fi
}

function configure_memory_parameters() {
echo "configure_memory_parameters"
global_func

	# Set Memory parameters.
	#
	# Set per_process_reclaim tuning parameters
	# All targets will use vmpressure range 50-70,
	# All targets will use 512 pages swap size.
	#
	# Set Low memory killer minfree parameters
	# 32 bit Non-Go, all memory configurations will use 15K series
	# 32 bit Go, all memory configurations will use uLMK + Memcg
	# 64 bit will use Google default LMK series.
	#
	# Set ALMK parameters (usually above the highest minfree values)
	# vmpressure_file_min threshold is always set slightly higher
	# than LMK minfree's last bin value for all targets. It is calculated as
	# vmpressure_file_min = (last bin - second last bin ) + last bin
	#
	# Set allocstall_threshold to 0 for all targets.

	# Set parameters for 32-bit Go targets.
	if [ $MemTotal -le 1048576 ] && [ "$low_ram" == "true" ]; then
		# Disable KLMK, ALMK, PPR & Core Control for Go devices
		echo 0 > /sys/module/lowmemorykiller/parameters/enable_lmk
		echo 0 > /sys/module/lowmemorykiller/parameters/enable_adaptive_lmk
		echo 0 > /sys/module/process_reclaim/parameters/enable_process_reclaim
		disable_core_ctl
	else
		# Read adj series and set adj threshold for PPR and ALMK.
		# This is required since adj values change from framework to framework.
		adj_series=`cat /sys/module/lowmemorykiller/parameters/adj`
		adj_1="${adj_series#*,}"
		set_almk_ppr_adj="${adj_1%%,*}"

		# PPR and ALMK should not act on HOME adj and below.
		# Normalized ADJ for HOME is 6. Hence multiply by 6
		# ADJ score represented as INT in LMK params, actual score can be in decimal
		# Hence add 6 considering a worst case of 0.9 conversion to INT (0.9*6).
		# For uLMK + Memcg, this will be set as 6 since adj is zero.
		set_almk_ppr_adj=$(((set_almk_ppr_adj * 6) + 6))
		echo $set_almk_ppr_adj > /sys/module/lowmemorykiller/parameters/adj_max_shift

		# Calculate vmpressure_file_min as below & set for 64 bit:
		# vmpressure_file_min = last_lmk_bin + (last_lmk_bin - last_but_one_lmk_bin)
		if [ "$arch_type" == "aarch64" ]; then
			minfree_series=`cat /sys/module/lowmemorykiller/parameters/minfree`
			minfree_1="${minfree_series#*,}" ; rem_minfree_1="${minfree_1%%,*}"
			minfree_2="${minfree_1#*,}" ; rem_minfree_2="${minfree_2%%,*}"
			minfree_3="${minfree_2#*,}" ; rem_minfree_3="${minfree_3%%,*}"
			minfree_4="${minfree_3#*,}" ; rem_minfree_4="${minfree_4%%,*}"
			minfree_5="${minfree_4#*,}"
			vmpres_file_min=$((minfree_5 + (minfree_5 - rem_minfree_4)))
			echo $vmpres_file_min > /sys/module/lowmemorykiller/parameters/vmpressure_file_min
		else
			# Set LMK series, vmpressure_file_min for 32 bit non-go targets.
			# Disable Core Control, enable KLMK for non-go 8909.
			if [ "$ProductName" == "msm8909" ]; then
				disable_core_ctl
				echo 1 > /sys/module/lowmemorykiller/parameters/enable_lmk
			fi
			echo "15360,19200,23040,26880,34415,43737" > /sys/module/lowmemorykiller/parameters/minfree
			echo 53059 > /sys/module/lowmemorykiller/parameters/vmpressure_file_min
		fi

		# Enable adaptive LMK for all targets &
		# use Google default LMK series for all 64-bit targets >=2GB.
		echo 1 > /sys/module/lowmemorykiller/parameters/enable_adaptive_lmk

		# Enable oom_reaper
		if [ -f /sys/module/lowmemorykiller/parameters/oom_reaper ]; then
			echo 1 > /sys/module/lowmemorykiller/parameters/oom_reaper
		fi

		# Set PPR parameters
		case "$soc_id" in
			# Do not set PPR parameters for premium targets
			# sdm845 - 321, 341
			# msm8998 - 292, 319
			# msm8996 - 246, 291, 305, 312
			"321" | "341" | "292" | "293" | "319" | "246" | "291" | "305" | "312")
				;;
			*)
				# Set PPR parameters for all other targets.
				echo $set_almk_ppr_adj > /sys/module/process_reclaim/parameters/min_score_adj
				echo 0 > /sys/module/process_reclaim/parameters/enable_process_reclaim
				echo 50 > /sys/module/process_reclaim/parameters/pressure_min
				echo 70 > /sys/module/process_reclaim/parameters/pressure_max
				echo 30 > /sys/module/process_reclaim/parameters/swap_opt_eff
				echo 512 > /sys/module/process_reclaim/parameters/per_swap_size
				;;
		esac
	fi

	# Set allocstall_threshold to 0 for all targets.
	# Set swappiness to 100 for all targets
	echo 0 > /sys/module/vmpressure/parameters/allocstall_threshold
	echo 100 > /proc/sys/vm/swappiness

	configure_zram_parameters
	#configure_read_ahead
}

function enable_memory_features()
{
echo "enable_memory_features"
global_func

	if [ $MemTotal -le 2097152 ]; then
		# Enable B service adj transition for 2GB or less memory
		setprop ro.vendor.qti.sys.fw.bservice_enable true
		setprop ro.vendor.qti.sys.fw.bservice_limit 5
		setprop ro.vendor.qti.sys.fw.bservice_age 5000

		# Enable Delay Service Restart
		setprop ro.vendor.qti.am.reschedule_service true
	fi
}

function start_hbtp()
{
echo "start_hbtp"
	# Start the Host based Touch processing but not in the power off mode.
	bootmode=`getprop ro.bootmode`
	if [ "charger" != $bootmode ]; then
		start vendor.hbtp
	fi
}

function msm8953_sched_boost()
{
echo "msm8953_soc: enable sched boosting"
	echo 1 > /proc/sys/kernel/sched_boost
}

function msm8953_hbtp()
{
echo "msm8953_soc: hbtp"
global_func
  # Start Host based Touch processing
  case "$hw_platform" in
    "MTP" | "Surf" | "RCM" )
      #if this directory is present, it means that a
      #1200p panel is connected to the device.
      dir="/sys/bus/i2c/devices/3-0038"
      if [ ! -d "$dir" ]; then
        start_hbtp
      fi
    ;;
  esac
}

function msm8953_mincpubw()
{
echo "msm8953_soc: cpufreq mincpubw"
  for devfreq_gov in /sys/class/devfreq/soc:qcom,mincpubw*/governor
  do
    echo "cpufreq" > $devfreq_gov
  done
}

function msm8953_bw_hwmon()
{
echo "msm8953_soc: bw_hwmon tune"
  for devfreq_gov in /sys/class/devfreq/soc:qcom,cpubw/governor
  do
    echo "bw_hwmon" > $devfreq_gov
    for cpu_io_percent in /sys/class/devfreq/soc:qcom,cpubw/bw_hwmon/io_percent
    do
      echo 34 > $cpu_io_percent
    done
    for cpu_guard_band in /sys/class/devfreq/soc:qcom,cpubw/bw_hwmon/guard_band_mbps
    do
      echo 0 > $cpu_guard_band
    done
    for cpu_hist_memory in /sys/class/devfreq/soc:qcom,cpubw/bw_hwmon/hist_memory
    do
      echo 20 > $cpu_hist_memory
    done
    for cpu_hyst_length in /sys/class/devfreq/soc:qcom,cpubw/bw_hwmon/hyst_length
    do
      echo 10 > $cpu_hyst_length
    done
    for cpu_idle_mbps in /sys/class/devfreq/soc:qcom,cpubw/bw_hwmon/idle_mbps
    do
      echo 1600 > $cpu_idle_mbps
    done
    for cpu_low_power_delay in /sys/class/devfreq/soc:qcom,cpubw/bw_hwmon/low_power_delay
    do
      echo 20 > $cpu_low_power_delay
    done
    for cpu_low_power_io_percent in /sys/class/devfreq/soc:qcom,cpubw/bw_hwmon/low_power_io_percent
    do
      echo 34 > $cpu_low_power_io_percent
    done
    for cpu_mbps_zones in /sys/class/devfreq/soc:qcom,cpubw/bw_hwmon/mbps_zones
    do
      echo "1611 3221 5859 6445 7104" > $cpu_mbps_zones
    done
    for cpu_sample_ms in /sys/class/devfreq/soc:qcom,cpubw/bw_hwmon/sample_ms
    do
      echo 4 > $cpu_sample_ms
    done
    for cpu_up_scale in /sys/class/devfreq/soc:qcom,cpubw/bw_hwmon/up_scale
    do
      echo 250 > $cpu_up_scale
    done
    for cpu_min_freq in /sys/class/devfreq/soc:qcom,cpubw/min_freq
    do
      echo 1611 > $cpu_min_freq
    done
  done
}

function msm8953_bimc()
{
echo "msm8953_soc: bimc"
  for gpu_bimc_io_percent in /sys/class/devfreq/soc:qcom,gpubw/bw_hwmon/io_percent
  do
    echo 40 > $gpu_bimc_io_percent
  done
}

function msm8953_disable_bcl()
{
echo "msm8953_soc: disable thermal & bcl"
  # Disable thermal & BCL core_control to update interactive gov settings
  echo 0 > /sys/module/msm_thermal/core_control/enabled
  for mode in /sys/devices/soc/soc:qcom,bcl*/mode
  do
    echo -n disable > $mode
  done
  for hotplug_mask in /sys/devices/soc/soc:qcom,bcl*/hotplug_mask
  do
    bcl_hotplug_mask=`cat $hotplug_mask`
    echo 0 > $hotplug_mask
  done
  for hotplug_soc_mask in /sys/devices/soc/soc:qcom,bcl*/hotplug_soc_mask
  do
    bcl_soc_hotplug_mask=`cat $hotplug_soc_mask`
    echo 0 > $hotplug_soc_mask
  done
  for mode in /sys/devices/soc/soc:qcom,bcl*/mode
  do
    echo -n enable > $mode
  done
}

function msm8953_apply_sched()
{
echo "msm8953_soc: apply sched"
  # If the kernel version >=4.9,use the schedutil governor
  KernelVersionStr=`cat /proc/sys/kernel/osrelease`
  KernelVersionS=${KernelVersionStr:2:2}
  KernelVersionA=${KernelVersionStr:0:1}
  KernelVersionB=${KernelVersionS%.*}
  if [ $KernelVersionA -ge 4 ] && [ $KernelVersionB -ge 9 ]; then
    sched_dcvs_eas
  else
    sched_dcvs_hmp
  fi
}

function msm8953_cores_on()
{
echo "msm8953_soc: set cores online"
  echo 1 > /sys/devices/system/cpu/cpu1/online
  echo 1 > /sys/devices/system/cpu/cpu2/online
  echo 1 > /sys/devices/system/cpu/cpu3/online
  echo 1 > /sys/devices/system/cpu/cpu4/online
  echo 1 > /sys/devices/system/cpu/cpu5/online
  echo 1 > /sys/devices/system/cpu/cpu6/online
  echo 1 > /sys/devices/system/cpu/cpu7/online
}

function msm8953_low_power()
{
echo "msm8953_soc: set low power mode"
  echo 0 > /sys/module/lpm_levels/parameters/sleep_disabled
}

function msm8953_enable_bcl()
{
echo "msm8953_soc: enable thermal & bcl"
  # Re-enable thermal & BCL core_control now
  echo 1 > /sys/module/msm_thermal/core_control/enabled
  for mode in /sys/devices/soc/soc:qcom,bcl*/mode
  do
    echo -n disable > $mode
  done
  for hotplug_soc_mask in /sys/devices/soc/soc:qcom,bcl*/hotplug_mask
  do
    echo $bcl_hotplug_mask > $hotplug_mask
  done
  for hotplug_soc_mask in /sys/devices/soc/soc:qcom,bcl*/hotplug_soc_mask
  do
    echo $bcl_soc_hotplug_mask > $hotplug_soc_mask
  done
  for mode in /sys/devices/soc/soc:qcom,bcl*/mode
  do
    echo -n enable > $mode
  done
}

function msm8953_smp_sched()
{
echo "msm8953_soc: apply smp sched"
  echo 100 > /proc/sys/kernel/sched_upmigrate
  echo 100 > /proc/sys/kernel/sched_downmigrate
}

function msm8953_hq_boost()
{
echo "msm8953_soc: apply hq boost"
  # HQ D1s-706 add for touch boost start
  echo 0:1401600 1:1401600 2:1401600 3:1401600 4:1401600 5:1401600 6:1401600 7:1401600 > /sys/module/cpu_boost/parameters/input_boost_freq
}

echo "apply rules for daisy"
configure_memory_parameters
start_hbtp
msm8953_hbtp

kversion=`cat /proc/sys/kernel/osrelease`
kversions=${kversion:27:4}
if [ "$kversions" = "zero" ]; then
	echo "apply dragonheart msm8953_soc"
	msm8953_sched_boost
	sched_dcvs_load
	msm8953_cores_on
else
	echo "apply stock msm8953_soc"
	disable_core_ctl
	msm8953_mincpubw
	msm8953_bw_hwmon
	msm8953_bimc
	msm8953_disable_bcl
	msm8953_apply_sched
	msm8953_cores_on
	msm8953_low_power
	msm8953_enable_bcl
	msm8953_smp_sched
	msm8953_hq_boost
	configure_read_ahead
fi

echo "apply ondemand chown"
chown -h system /sys/devices/system/cpu/cpufreq/ondemand/sampling_rate
chown -h system /sys/devices/system/cpu/cpufreq/ondemand/sampling_down_factor
chown -h system /sys/devices/system/cpu/cpufreq/ondemand/io_is_busy

echo "apply emmc boot"
emmc_boot=`getprop vendor.boot.emmc`
if [ "$emmc_boot" = "true" ]; then
	chown -h system /sys/devices/platform/rs300000a7.65536/force_sync
	chown -h system /sys/devices/platform/rs300000a7.65536/sync_sts
	chown -h system /sys/devices/platform/rs300100a7.65536/force_sync
	chown -h system /sys/devices/platform/rs300100a7.65536/sync_sts
fi

echo "apply post setup services"
# Post-setup services
setprop vendor.post_boot.parsed 1
low_ram_enable=`getprop ro.config.low_ram`
if [ "$low_ram_enable" != "true" ]; then
	start gamed
fi

echo "apply adrenotest apk"
# Install AdrenoTest.apk if not already installed
if [ -f /data/prebuilt/AdrenoTest.apk ]; then
	if [ ! -d /data/data/com.qualcomm.adrenotest ]; then
		pm install /data/prebuilt/AdrenoTest.apk
	fi
fi

echo "apply swebrowser apk"
# Install SWE_Browser.apk if not already installed
if [ -f /data/prebuilt/SWE_AndroidBrowser.apk ]; then
	if [ ! -d /data/data/com.android.swe.browser ]; then
		pm install /data/prebuilt/SWE_AndroidBrowser.apk
	fi
fi

echo "apply for kernel image version"
# Let kernel know our image version/variant/crm_version
if [ -f /sys/devices/soc0/select_image ]; then
	image_version="10:"
	image_version+=`getprop ro.build.id`
	image_version+=":"
	image_version+=`getprop ro.build.version.incremental`
	image_variant=`getprop ro.product.name`
	image_variant+="-"
	image_variant+=`getprop ro.build.type`
	oem_version=`getprop ro.build.version.codename`
	echo 10 > /sys/devices/soc0/select_image
	echo $image_version > /sys/devices/soc0/image_version
	echo $image_variant > /sys/devices/soc0/image_variant
	echo $oem_version > /sys/devices/soc0/image_crm_version
fi

echo "apply console log level"
# Change console log level as per console config property
console_config=`getprop persist.console.silent.config`
case "$console_config" in
	"1")
		echo "Enable console config to $console_config"
		echo 0 > /proc/sys/kernel/printk
	;;
	*)
		echo "Enable console config to $console_config"
	;;
esac

echo "apply misc paths"
# Parse misc partition path and set property
misc_link=$(ls -l /dev/block/bootdevice/by-name/misc)
real_path=${misc_link##*>}
setprop persist.vendor.mmi.misc_dev_path $real_path

echo "the end ;)"
# END #
