# Debian-Turing-RK1
#### *Stock Debian ARM64 Linux for the Turing RK1*

This Debian ARM64 Linux image is built directly from official packages using the Debian [Debootstrap](https://wiki.debian.org/Debootstrap) utility, see: https://github.com/gregordinary/debian-nanopi-r6s/blob/main/debian/make_debian_img.sh#L128

Patches are directly available from the Debian repos using the built-in apt package manager, see: https://github.com/gregordinary/debian-nanopi-r6s/blob/main/debian/make_debian_img.sh#L355-L362

* Note: The kernel in this bundle is from kernel.org and will not get updates from debian.

---
### debian bookworm setup

<br/>

**1. download the appropriate image**
```
wget #
```

<br/>

**2. determine the location of the target micro sd card**

 * before plugging-in device
```
ls -l /dev/sd*
ls: cannot access '/dev/sd*': No such file or directory
```

 * after plugging-in device
```
ls -l /dev/sd*
brw-rw---- 1 root disk 8, 0 Mar 19 21:08 /dev/sda
```
* note: for mac, the device is ```/dev/rdiskX```

<br/>

**3. in the case above, substitute 'a' for 'X' in the command below (for /dev/sda)**
```
sudo su
xzcat nanopi-r6s_bookworm-v12-6.7-rc5.img.xz > /dev/sdX
sync
```

#### when the micro sd has finished imaging, eject and use it to boot the nanopi r6s to finish setup

<br/>

**4. login account**
```
user: debian
pass: debian
```

<br/>

**5. take updates**
```
sudo apt update
sudo apt upgrade
```

<br/>

**6. create new admin account**
```
sudo adduser <youruserid>
echo '<youruserid> ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/<youruserid>
sudo chmod 440 /etc/sudoers.d/<youruserid>
```

<br/>

**7. lockout and/or delete debian account**
```
sudo passwd -l debian
sudo chsh -s /usr/sbin/nologin debian
```

```
sudo deluser --remove-home debian
sudo rm /etc/sudoers.d/debian
```

<br/>

**8. change hostname (optional)**
```
sudo nano /etc/hostname
sudo nano /etc/hosts
```

<br/>


---
### booting from internal eMMC

<br/>

Imaging the internal eMMC device involves booting from a removable MMC card and imaging the internal eMMC device. When booted, the removable MMC device is seen as ```/dev/mmcblk0``` and the internal eMMC device is seen as ```/dev/mmcblk1```

<br/>

**1. boot from removable MMC**

Using the steps in the first section above, create a removable MMC card and boot using it. Note: If the internal eMMC device already has a bootable image on it, it will prefer to boot from that. To force the nanopi5 to boot from the removable MMC card you just made, hold the ```mask``` button down before applying power. Once successfully booted to the removable MMC, you will be able to see this by using the ```df``` command which will show /dev/mmcblk0p1 as the booted partition.

<br/>

**2. download the appropriate image to the booted MMC card and image the internal eMMC**
```
wget #
sudo su
xzcat nanopi-r6s_bookworm-v12-6.7-rc5.img.xz > /dev/mmcblk1
sync
```

<br/>

Once imaging completes, shutdown, remove the MMC card and it will then boot using the internal eMMC device.

Note: Once booted, ```sudo apt update``` then ```sudo apt upgrade``` to get the latest updates from the debian repositories.

<br/>

---
### booting from internal NVMe

<br/>

Imaging the internal NVMe device involves booting from a removable MMC card and imaging the internal NVMe device. When booted, the internal NVMe device is seen as ```/dev/nvme0n1```

<br/>

**1. boot from removable MMC**

Using the steps in the first section above, create a removable MMC card and boot using it. Note: If the internal eMMC device already has a bootable image on it, it will prefer to boot from that. To force the nanopi5 to boot from the removable MMC card you just made, hold the ```mask``` button down before applying power. Once successfully booted to the removable MMC, you will be able to see this by using the ```df``` command which will show /dev/mmcblk0p1 as the booted partition.

<br/>

**2. download the image to the booted MMC card and image the internal NVMe**
```
wget #
sudo su
xzcat nanopi-r6s_bookworm-v12-6.7-rc5.img.xz > /dev/nvme0n1
sync
```

<br/>

**3. install u-boot to internal eMMC**

The last step is to prepare the internal eMMC to host u-boot. The eMMC must not contain a bootable partition or it will be preferred for boot over the internal NVMe. Start by downloading the two u-boot files:
```
wget #
wget #
```

Erase the internal eMMC (the device is actually ```/dev/mmcblk1``` but X is placed where 1 belongs to prevent a copy paste mistake)
```
sudo dd if=/dev/zero of=/dev/mmcblkX bs=1M count=1024
```

The internal eMMC is now erased, install u-boot (again, change X to 1):
```
sudo dd bs=4K seek=8 if=idbloader.img of=/dev/mmcblkX
sudo dd bs=4K seek=2048 if=u-boot.itb of=/dev/mmcblkX
```

**4. setup is now complete and the system is ready for use**

shutdown the device, remove the external mmc card, and restart the device

Note: Once booted, ```sudo apt update``` then ```sudo apt upgrade``` to get the latest updates from the debian repositories.

<br/>

---
### building debian bookworm arm64 for the nanopi r6s from scratch

<br/>

The build script builds native arm64 binaries and thus needs to be run from an arm64 device such as a raspberry pi4 running a 64 bit arm linux. The initial build of this project used a debian arm64 odroid m1, but now uses a rock 5b running stock debian bookworm arm64.

<br/>

**1. clone the repo**
```
git clone https://github.com/gregordinary/debian-nanopi-r6s.git
cd debian-nanopi-r6s
```

<br/>

**2. run the debian build script**
```
cd debian
sudo sh make_debian_img.sh
```
* note: edit the build script to change various options: ```nano make_debian_img.sh```

<br/>

**3. the output if the build completes successfully**
```
mmc_2g.img.xz
```

<br/>
