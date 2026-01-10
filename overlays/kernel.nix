_final: prev:
if (prev ? linuxPackages_lqx) && prev.stdenv.hostPlatform.isx86_64 then
  {
    linuxPackages_lqx_v4 = prev.linuxPackagesFor (
      prev.linuxPackages_lqx.kernel.override {
        extraConfig = ''
          # CPU ISA baseline
          X86_64_VERSION 4

          # Obsolete buses
          EISA n
          FIREWIRE n
          FIREWIRE_OHCI n
          FIREWIRE_SBP2 n
          ISA_BUS n
          MCA n
          PCCARD n
          PCI_LEGACY n
          PCMCIA n

          # Obsolete devices
          FLOPPY n
          IEEE1284 n
          JOYSTICK_GAMECON n
          PARPORT n
          PRINTER n

          # Obsolete storage stacks
          ATA_OVER_ETH n
          BLK_DEV_FD n
          IDE n

          # Obsolete / special-purpose filesystems
          9P_FS n
          ADFS_FS n
          AFFS_FS n
          AFS_FS n
          BEFS_FS n
          CEPH_FS n
          CIFS n
          GFS2_FS n
          HFSPLUS_FS n
          HFS_FS n
          MINIX_FS n
          NFS_FS n
          NFS_V2 n
          NFS_V3 n
          NFS_V4 n
          OCFS2_FS n
          OMFS_FS n
          ORANGEFS_FS n
          QNX4FS_FS n
          SMBFS n
          SYSV_FS n
          UFS_FS n

          # Unused filesystems
          APFS_FS n
          BTRFS_FS n
          EROFS_FS n
          F2FS_FS n
          JFS_FS n
          XFS_FS n

          # Obsolete networking
          ARCNET n
          ATM n
          DECNET n
          FDDI n
          HIPPI n
          LAPB n
          TOKENRING n
          X25 n

          # Unused networking
          INFINIBAND n

          # Unused GPU
          DRM_AMDGPU n
          DRM_I915 n
          DRM_NOUVEAU n
          DRM_QXL n
          DRM_RADEON n
          DRM_VIRTIO_GPU n
          DRM_VMWGFX n

          # Unused CPU
          HOTPLUG_CPU n
          INTEL_IDLE n
          INTEL_PSTATE n
          INTEL_RAPL n
          INTEL_RAPL_CORE n
          INTEL_THERMAL n
          INTEL_TURBO_MAX_3 n
          M386 n
          M486 n
          M586 n
          M586TSC n 
          M686 n

          # Unused memory
          BLK_DEV_PMEM n

          # Unused sound
          SND_FIREWIRE n
          SND_PCI n
          SND_SOC n
          SND_USB_CAIAQ n
          SND_USB_UA101 n

          # Unused input
          INPUT_JOYSTICK n
          INPUT_TABLET n
          INPUT_TOUCHSCREEN n

          # X870E Taichi Wi-Fi
          IWLWIFI m
          WLAN y

          # Unused Wi-Fi
          ATH10K n
          ATH9K n
          ATH_COMMON n
          BRCMFMAC n
          RTLWIFI n

          # USB Gadget mode
          USB_CONFIGFS n
          USB_GADGET n

          # Unused hardware monitoring
          HWMON_VID n
          SENSORS_ADT7410 n
          SENSORS_ADT7475 n
          SENSORS_LM75 n
          SENSORS_MAX6650 n

          # Unused encryption
          FS_ENCRYPTION n
          FS_VERITY n

          # Unused quota
          QUOTA n
          QUOTACTL n

          # Unused multipath
          DM_MULTIPATH n
          DM_RAID n

          # Unused RAID
          BLK_DEV_MD n
          MD_RAID0 n
          MD_RAID1 n
          MD_RAID10 n
          MD_RAID456 n

          # Disable kernel debug noise
          DEBUG_INFO n
          DEBUG_KERNEL n
          DEBUG_MISC n
          SCHED_DEBUG n

          # Scheduling behavior
          HZ_1000 y
          PREEMPT_DYNAMIC y
        '';
        ignoreConfigErrors = true;
      }
    );
  }
else
  { }
