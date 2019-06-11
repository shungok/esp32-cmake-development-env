# esp32-cmake-development-env

[![Docker build status](https://img.shields.io/docker/cloud/build/shungok/esp32-cmake-development-env.svg)](https://hub.docker.com/r/shungok/esp32-cmake-development-env/builds) ![Docker automated](https://img.shields.io/docker/cloud/automated/shungok/esp32-cmake-development-env.svg) ![Docker layers](https://img.shields.io/microbadger/layers/shungok/esp32-cmake-development-env.svg) ![Docker image-size](https://img.shields.io/microbadger/image-size/shungok/esp32-cmake-development-env.svg) ![Docker pulls](https://img.shields.io/docker/pulls/shungok/esp32-cmake-development-env.svg) ![Docker stars](https://img.shields.io/docker/stars/shungok/esp32-cmake-development-env.svg)

## Purpose

This project provide a build and flash environment for ESP32 using docker container.

## Dependencies

- Docker
- VirtualBox (Case of non native linux environment.)

## How to use

### Overview

The steps in this section assume that the Docker host OS has recognized ESP32 (USB device).
If your development environment is not native linux, you have to prepare a docker host that recognized USB that follows [this step](#preparation-for-non-native-linux-os).

Please, follow the steps below.

1. Prepare docker image.
    - Case of using latest image which is managed DockerHub.
    - Case of using manual building image.
2. Start up docker container and connect the container.
3. Build and flash esp32 project.
4. Monitor output from usb serial port.

### Steps

#### 1. Prepare docker image.

Please select a way what you like.

##### Case of using latest image which is managed DockerHub.

```shell
% docker pull shungok/esp32-cmake-development-env
% docker images
REPOSITORY                            TAG                 IMAGE ID            CREATED             SIZE
shungok/esp32-cmake-development-env   latest              cb09e767768e        3 hours ago         1.16GB
debian                                9.9-slim            92d2f0789514        4 weeks ago         55.3MB
```

##### Case of using manual building image.

```shell
% cat Dockerfile | docker build - -t esp32-idfv3.3-beta3
Sending build context to Docker daemon  4.096kB
Step 1/17 : FROM debian:9.9-slim
 ---> 92d2f0789514
…
Successfully built 0e56d713dcdc
Successfully tagged esp32-idfv3.3-beta3:latest

% docker images
REPOSITORY            TAG                 IMAGE ID            CREATED             SIZE
esp32-idfv3.3-beta3   latest              0e56d713dcdc        21 seconds ago      1.16GB
debian                9.9-slim            92d2f0789514        4 weeks ago         55.3MB
```

※ If you want to change esp-idf version, you can set ESP_IDF_VERSION as following.
(available version tags: [Tags · espressif/esp-idf · GitHub](https://github.com/espressif/esp-idf/tags) )

```shell
% cat Dockerfile | docker build - -t esp32-idfv4.0-dev --build-arg ESP_IDF_VERSION=v4.0-dev
Sending build context to Docker daemon  3.072kB
```

#### 2. Start up docker container and connect the container.

To start up docker container for building and flashing esp32 project, you have to specify three things.

1. Usb device filepath which was detected in docker host OS. (with --device option)
2. Project directory (/path/to/esp32_project_directory) you want to use in docker container. (with -v option)
3. Docker image. (ex: shungok/esp32-cmake-development-env:latest)

```shell
% cd /path/to/esp32_project_directory; pwd
/path/to/esp32_project_directory

% docker run --rm --device /dev/ttyUSB0 -v `pwd`:/esp/project -it shungok/esp32-cmake-development-env:latest
※ into docker container
root@eccd3cbaaae6:/esp/project#
```

#### 3. Build and flash esp32 project.

First, If nesessary, you should clean up build cache.

```shell
root@eccd3cbaaae6:/esp/project# idf.py fullclean
Checking Python dependencies...
Python requirements from /opt/local/esp/esp-idf/requirements.txt are satisfied.
```

Build.

※ Public document: [Get Started (CMake) — ESP-IDF Programming Guide v3.2 documentation (build-the-project)](https://docs.espressif.com/projects/esp-idf/en/stable/get-started-cmake/index.html#build-the-project)


```shell
root@eccd3cbaaae6:/esp/project# idf.py build
Checking Python dependencies...
Python requirements from /opt/local/esp/esp-idf/requirements.txt are satisfied.
Running cmake in directory /esp/project/build
Executing "cmake -G Ninja -DPYTHON_DESP_CHECKED=1 -DESP_PLATFORM=1 --warn-uninitialized /esp/project"...
```

If your environment is not supported automatic bootloader, you have to change ESP32 bootloader mode to download flashing mode (ROM serial bootloader for esptool.py) manually.

[ESP32 Boot Mode Selection · espressif/esptool Wiki · GitHub](https://github.com/espressif/esptool/wiki/ESP32-Boot-Mode-Selection)

※ If you change to download flashing mode (GPIO0 is held low on reset), monitoring console will output message like below.

```shell
root@eccd3cbaaae6:/esp/project# idf.py monitor -p /dev/ttyUSB0
ets Jun  8 2016 00:22:57

rst:0x1 (POWERON_RESET),boot:0x3 (DOWNLOAD_BOOT(UART0/UART1/SDIO_REI_REO_V2))
waiting for download
```

After that flash the built image.

※ Public document: [Get Started (CMake) — ESP-IDF Programming Guide v3.2 documentation (flash-to-a-device)](https://docs.espressif.com/projects/esp-idf/en/stable/get-started-cmake/index.html#flash-to-a-device)

```shell
root@eccd3cbaaae6:/esp/project# idf.py flash -p /dev/ttyUSB0
Checking Python dependencies...
Python requirements from /opt/local/esp/esp-idf/requirements.txt are satisfied.
Running ninja in directory /esp/project/build
Executing "ninja all"...
…
Leaving...
Hard resetting via RTS pin...
Done
```

#### 4. Monitor output from usb serial port.

Start to monitor usb serial port.

※ Public document: [Get Started (CMake) — ESP-IDF Programming Guide v3.2 documentation (monitor)](https://docs.espressif.com/projects/esp-idf/en/stable/get-started-cmake/index.html#monitor)

```shell
root@eccd3cbaaae6:/esp/project# idf.py monitor -p /dev/ttyUSB0
Checking Python dependencies...
Python requirements from /opt/local/esp/esp-idf/requirements.txt are satisfied.
Running idf_monitor in directory /esp/project
Executing "/usr/bin/python /opt/local/esp/esp-idf/tools/idf_monitor.py -p /dev/ttyUSB0 -b 115200 /esp/project/build/<project name>.elf -m '/usr/bin/python' '/opt/local/esp/esp-idf/tools/idf.py'"...
--- idf_monitor on /dev/ttyUSB0 115200 ---
--- Quit: Ctrl+] | Menu: Ctrl+T | Help: Ctrl+T followed by Ctrl+H ---
```

Next, hard resetting via RTS pin (if you use ESP32 DevkitC, just push reset button.)

If flashed application can boot, monitoring console will output the messages like below.

```shell
ets Jun  8 2016 00:22:57

rst:0x1 (POWERON_RESET),boot:0x13 (SPI_FAST_FLASH_BOOT)
configsip: 0, SPIWP:0xee
clk_drv:0x00,q_drv:0x00,d_drv:0x00,cs0_drv:0x00,hd_drv:0x00,wp_drv:0x00
mode:DIO, clock div:1
load:0x3fff0018,len:4
load:0x3fff001c,len:6688
ho 0 tail 12 room 4
load:0x40078000,len:12116
load:0x40080400,len:7372
entry 0x40080780
I (30) boot: ESP-IDF v3.3-beta1-694-g6b3da6b18 2nd stage bootloader
I (30) boot: compile time 04:12:23
I (31) boot: Enabling RNG early entropy source...
I (37) qio_mode: Enabling default flash chip QIO
I (42) boot: SPI Speed      : 80MHz
I (46) boot: SPI Mode       : QIO
I (50) boot: SPI Flash Size : 4MB
I (54) boot: Partition Table:
I (58) boot: ## Label            Usage          Type ST Offset   Length
I (65) boot:  0 nvs              WiFi data        01 02 00009000 00006000
I (72) boot:  1 phy_init         RF data          01 01 0000f000 00001000
I (80) boot:  2 factory          factory app      00 00 00010000 00200000
I (87) boot:  3 spiffs           Unknown data     01 82 00210000 00100000
I (95) boot: End of partition table
I (99) esp_image: segment 0: paddr=0x00010020 vaddr=0x3f400020 size=0x3ba84 (244356) map
I (173) esp_image: segment 1: paddr=0x0004baac vaddr=0x3ffb0000 size=0x03178 ( 12664) load
I (177) esp_image: segment 2: paddr=0x0004ec2c vaddr=0x40080000 size=0x00400 (  1024) load
0x40080000: _WindowOverflow4 at /opt/local/esp/esp-idf/components/freertos/xtensa_vectors.S:1779

I (180) esp_image: segment 3: paddr=0x0004f034 vaddr=0x40080400 size=0x00fdc (  4060) load
I (190) esp_image: segment 4: paddr=0x00050018 vaddr=0x400d0018 size=0xcc10c (835852) map
0x400d0018: _flash_cache_start at ??:?

I (418) esp_image: segment 5: paddr=0x0011c12c vaddr=0x400813dc size=0x11f2c ( 73516) load
0x400813dc: call_start_cpu0 at /opt/local/esp/esp-idf/components/esp32/cpu_start.c:157

I (454) boot: Loaded app from partition at offset 0x10000
I (454) boot: Disabling RNG early entropy source...
I (454) cpu_start: Pro cpu up.
I (458) cpu_start: Application information:
I (463) cpu_start: Project name:     <project name>
I (469) cpu_start: App version:      v2.0.0-12-g9e3ff7a
I (475) cpu_start: Compile time:     Jun  7 2019 04:12:08
I (481) cpu_start: ELF file SHA256:  a6b23737f180c2df...
I (487) cpu_start: ESP-IDF:          v3.3-beta1-694-g6b3da6b18
I (494) cpu_start: Starting app cpu, entry point is 0x40081340
0x40081340: call_start_cpu1 at /opt/local/esp/esp-idf/components/esp32/cpu_start.c:267

I (0) cpu_start: App cpu up.
I (504) heap_init: Initializing. RAM available for dynamic allocation:
I (511) heap_init: At 3FFAE6E0 len 00001920 (6 KiB): DRAM
I (517) heap_init: At 3FFBA6F0 len 00025910 (150 KiB): DRAM
I (523) heap_init: At 3FFE0440 len 00003AE0 (14 KiB): D/IRAM
I (530) heap_init: At 3FFE4350 len 0001BCB0 (111 KiB): D/IRAM
I (536) heap_init: At 40093308 len 0000CCF8 (51 KiB): IRAM
I (542) cpu_start: Pro cpu start user code
I (560) pm_esp32: Frequency switching config: CPU_MAX: 80, APB_MAX: 80, APB_MIN: 40, Light sleep: DISABLED
I (561) cpu_start: Starting scheduler on PRO CPU.
I (0) cpu_start: Starting scheduler on APP CPU.
I (706) SD: Using SDMMC peripheral
I (707) gpio: GPIO[13]| InputEn: 0| OutputEn: 1| OpenDrain: 0| Pullup: 0| Pulldown: 0| Intr:0
E (1710) sdmmc_req: sdmmc_host_wait_for_event returned 0x107
Name: SA32G
Type: SDHC/SDXC
Speed: 20 MHz
Size: 29520MB
…
```

If you want to disconnect this serial connection, you should input ctrl + ].

##  Preparation for non-native Linux OS
### macOS

#### Verification conditions

I verified under following conditions.

* macOS: 10.14.4 (Mojave)
* Docker Desktop community: 2.0.0.3/31259 (channel:stable)
  * Engine: 18.09.02
  * Machine: 0.16.1
* Virtualbox: Version 6.0.8 r130520 (Qt5.6.3) + Extention Pack 6.0.8
  * [Dowonloads – Oracle VM VirtualBox](https://www.virtualbox.org/wiki/Downloads)
    * https://download.virtualbox.org/virtualbox/6.0.8/VirtualBox-6.0.8-130520-OSX.dmg
    * https://download.virtualbox.org/virtualbox/6.0.8/Oracle_VM_VirtualBox_Extension_Pack-6.0.8.vbox-extpack

#### Overview

Please install Virtualbox and extensions in advance.

1. Create Docker host machine on Virtualbox.
2. Set USB Device Filter of Virtualbox VM.
3. Confirme to detect ESP32 on Virtualbox VM.
4. Change Docker host machine in current shell.

#### Steps

##### 1. Create Docker host machine on Virtualbox.

Create Docker host machine with docker-machine comannd.

```shell
% docker-machine create -d virtualbox docker-host-default
Creating CA: /Users/<username>/.docker/machine/certs/ca.pem
Creating client certificate: /Users/<username>/.docker/machine/certs/cert.pem
Running pre-create checks...
(docker-host-default) Image cache directory does not exist, creating it at /Users/<username>/.docker/machine/cache...
(docker-host-default) No default Boot2Docker ISO found locally, downloading the latest release...
(docker-host-default) Latest release for github.com/boot2docker/boot2docker is v18.09.6
(docker-host-default) Downloading /Users/<username>/.docker/machine/cache/boot2docker.iso from https://github.com/boot2docker/boot2docker/releases/download/v18.09.6/boot2docker.iso...
(docker-host-default) 0%....10%....20%....30%....40%....50%....60%....70%....80%....90%....100%
Creating machine...
(docker-host-default) Copying /Users/<username>/.docker/machine/cache/boot2docker.iso to /Users/<username>/.docker/machine/machines/docker-host-default/boot2docker.iso...
(docker-host-default) Creating VirtualBox VM...
(docker-host-default) Creating SSH key...
(docker-host-default) Starting the VM...
(docker-host-default) Check network to re-create if needed...
(docker-host-default) Found a new host-only adapter: "vboxnet2"
(docker-host-default) Waiting for an IP...
Waiting for machine to be running, this may take a few minutes...
Detecting operating system of created instance...
Waiting for SSH to be available...
Detecting the provisioner...
Provisioning with boot2docker...
Copying certs to the local machine directory...
Copying certs to the remote machine...
Setting Docker configuration on the remote daemon...
Checking connection to Docker...
Docker is up and running!
To see how to connect your Docker Client to the Docker Engine running on this virtual machine, run: docker-machine env docker-host-default

% docker-machine ls
NAME                  ACTIVE   DRIVER       STATE     URL                         SWARM   DOCKER     ERRORS
docker-host-default   *        virtualbox   Running   tcp://192.168.99.100:2376           v18.09.6
```

##### 2. Set USB Device Filter of Virtualbox VM.

First, stop Docker host machine.

```shell
% docker-machine stop docker-host-default
Stopping "docker-host-default"...
Machine "docker-host-default" was stopped.

% docker-machine ls
NAME                  ACTIVE   DRIVER       STATE     URL   SWARM   DOCKER    ERRORS
docker-host-default   -        virtualbox   Stopped                 Unknown
```
Second, connect ESP32 to PC and make sure that macOS detects the device.

```shell
% ls -l /dev/*.usbserial*
crw-rw-rw-  1 root  wheel   18,  35  6 10 18:04 /dev/cu.usbserial-DM01OY8T
crw-rw-rw-  1 root  wheel   18,  34  6 10 18:02 /dev/tty.usbserial-DM01OY8T

% system_profiler SPUSBDataType
USB:

    USB 3.0 Bus:

      Host Controller Driver: AppleUSBXHCILPT
      PCI Device ID: 0x9c31
      PCI Revision ID: 0x0004
      PCI Vendor ID: 0x8086

…

        FT230X Basic UART:

          Product ID: 0x6015
          Vendor ID: 0x0403  (Future Technology Devices International Limited)
          Version: 10.00
          Serial Number: DM01OY8T
          Speed: Up to 12 Mb/sec
          Manufacturer: FTDI
          Location ID: 0x14100000 / 26
          Current Available (mA): 500
          Current Required (mA): 90
          Extra Operating Current (mA): 0
```

Third, set USB Device Filter of Virtualbox VM.

```shell
% vboxmanage modifyvm docker-host-default --usbehci on
(need VirtualBox Extention Pack)

or

% vboxmanage modifyvm docker-host-default --usb on

% vboxmanage usbfilter add 0 --target docker-host-default --name 'FTDI FT230X Basic UART' --vendorid 0x0403 --productid 0x6015 --manufacturer FTDI
```

Finaly, start Docker host machine.

```shell
% docker-machine start docker-host-default
Starting "docker-host-default"...
(docker-host-default) Check network to re-create if needed...
(docker-host-default) Waiting for an IP...
Machine "docker-host-default" was started.
Waiting for SSH to be available...
Detecting the provisioner...
Started machines may have new IP addresses. You may need to re-run the `docker-machine env` command.

% docker-machine ls
NAME                  ACTIVE   DRIVER       STATE     URL                         SWARM   DOCKER     ERRORS
docker-host-default   -        virtualbox   Running   tcp://192.168.99.100:2376           v18.09.6
```

##### 3. Confirme to detect ESP32 on Virtualbox VM.

When the virtual machine recognizes the device, the device file in macOS disappears.

```shell
% ls -l /dev/*.usbserial*
zsh: no matches found: /dev/*.usbserial*
```

Login Docker host OS and confirme to detect ESP32 Virtualbox VM.

```shell
% docker-machine ssh docker-host-default
   ( '>')
  /) TC (\   Core is distributed with ABSOLUTELY NO WARRANTY.
 (/-_--_-\)           www.tinycorelinux.net

docker@docker-host-default:~$ cat /etc/release
TinyCoreLinux 8.2.1

docker@docker-host-default:~$ udevadm monitor
monitor will print the received events for:
UDEV - the event which udev sends out after rule processing
KERNEL - the kernel uevent
```

When ESP32 disconnect, the console output messages like below.

```shell
KERNEL[104.995021] remove   /devices/pci0000:00/0000:00:06.0/usb2/2-1/2-1:1.0/ttyUSB0/tty/ttyUSB0 (tty)
UDEV  [104.995467] remove   /devices/pci0000:00/0000:00:06.0/usb2/2-1/2-1:1.0/ttyUSB0/tty/ttyUSB0 (tty)
KERNEL[104.995525] unbind   /devices/pci0000:00/0000:00:06.0/usb2/2-1/2-1:1.0/ttyUSB0 (usb-serial)
UDEV  [104.995621] unbind   /devices/pci0000:00/0000:00:06.0/usb2/2-1/2-1:1.0/ttyUSB0 (usb-serial)
KERNEL[104.995693] remove   /devices/pci0000:00/0000:00:06.0/usb2/2-1/2-1:1.0/ttyUSB0 (usb-serial)
UDEV  [104.995774] remove   /devices/pci0000:00/0000:00:06.0/usb2/2-1/2-1:1.0/ttyUSB0 (usb-serial)
KERNEL[104.995855] unbind   /devices/pci0000:00/0000:00:06.0/usb2/2-1/2-1:1.0 (usb)
UDEV  [104.995995] unbind   /devices/pci0000:00/0000:00:06.0/usb2/2-1/2-1:1.0 (usb)
KERNEL[104.996130] remove   /devices/pci0000:00/0000:00:06.0/usb2/2-1/2-1:1.0 (usb)
UDEV  [104.996214] remove   /devices/pci0000:00/0000:00:06.0/usb2/2-1/2-1:1.0 (usb)
KERNEL[104.996356] unbind   /devices/pci0000:00/0000:00:06.0/usb2/2-1 (usb)
UDEV  [104.996550] unbind   /devices/pci0000:00/0000:00:06.0/usb2/2-1 (usb)
KERNEL[104.996830] remove   /devices/pci0000:00/0000:00:06.0/usb2/2-1 (usb)
UDEV  [104.997001] remove   /devices/pci0000:00/0000:00:06.0/usb2/2-1 (usb)
```

When ESP32 connect, the console output messages like below.

```shell
KERNEL[113.278724] add      /devices/pci0000:00/0000:00:06.0/usb2/2-1 (usb)
UDEV  [113.295275] add      /devices/pci0000:00/0000:00:06.0/usb2/2-1 (usb)
KERNEL[113.315879] add      /devices/pci0000:00/0000:00:06.0/usb2/2-1/2-1:1.0 (usb)
KERNEL[113.315908] add      /devices/pci0000:00/0000:00:06.0/usb2/2-1/2-1:1.0/ttyUSB0 (usb-serial)
UDEV  [113.317307] add      /devices/pci0000:00/0000:00:06.0/usb2/2-1/2-1:1.0 (usb)
UDEV  [113.318658] add      /devices/pci0000:00/0000:00:06.0/usb2/2-1/2-1:1.0/ttyUSB0 (usb-serial)
KERNEL[113.324747] add      /devices/pci0000:00/0000:00:06.0/usb2/2-1/2-1:1.0/ttyUSB0/tty/ttyUSB0 (tty)
KERNEL[113.324778] bind     /devices/pci0000:00/0000:00:06.0/usb2/2-1/2-1:1.0/ttyUSB0 (usb-serial)
KERNEL[113.324798] bind     /devices/pci0000:00/0000:00:06.0/usb2/2-1/2-1:1.0 (usb)
KERNEL[113.324819] bind     /devices/pci0000:00/0000:00:06.0/usb2/2-1 (usb)
UDEV  [113.327703] add      /devices/pci0000:00/0000:00:06.0/usb2/2-1/2-1:1.0/ttyUSB0/tty/ttyUSB0 (tty)
UDEV  [113.330129] bind     /devices/pci0000:00/0000:00:06.0/usb2/2-1/2-1:1.0/ttyUSB0 (usb-serial)
UDEV  [113.345175] bind     /devices/pci0000:00/0000:00:06.0/usb2/2-1/2-1:1.0 (usb)
UDEV  [113.349786] bind     /devices/pci0000:00/0000:00:06.0/usb2/2-1 (usb)
```

There is the device file(/dev/ttyUSB0) to communicate ESP32.


```shell
docker@docker-host-default:~$ ls -ltr /dev/tty* | tail -5
crw--w----    1 root     staff       4,  10 Jun  4 07:12 /dev/tty10
crw-------    1 docker   staff       4,   1 Jun  4 07:12 /dev/tty1
crw--w----    1 root     staff       4,   0 Jun  4 07:12 /dev/tty0
crw-rw-rw-    1 root     staff       5,   0 Jun  4 07:12 /dev/tty
crw-rw----    1 root     staff     188,   0 Jun  4 08:00 /dev/ttyUSB0 <--- recognized
```

The device file is created according to setting of the naming rule file as following.

```shell
docker@docker-host-default:~$ grep -ri usb  /etc/udev/rules.d/ | grep -i tty
/etc/udev/rules.d/60-persistent-serial.rules:KERNEL!="ttyUSB[0-9]*|ttyACM[0-9]*", GOTO="persistent_serial_end"
```

If multiple devices are connected, device files will be created with "ttyUSB1,2,3 ..." according to this naming . In that case, you need to provide the appropriate device file to the docker command.

##### 4. Change Docker host machine in current shell.

Logout from Docker host OS.

```shell
docker@docker-host-default:~$ exit
logout
```

And change the Docker host machine that recognizes Docker commands on the current shell.

```shell
% docker-machine env docker-host-default
export DOCKER_TLS_VERIFY="1"
export DOCKER_HOST="tcp://192.168.99.100:2376"
export DOCKER_CERT_PATH="/Users/<username>/.docker/machine/machines/docker-host-default"
export DOCKER_MACHINE_NAME="docker-host-default"
# Run this command to configure your shell:
# eval $(docker-machine env docker-host-default)

% eval $(docker-machine env docker-host-default)

% docker ps -a
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES

% docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
```

Go to [main steps](#how-to-use).

### Windows
Unverified.

## References

- ESP32
  - [Get Started (CMake) — ESP-IDF Programming Guide v4.0-dev-728-g826ff7186 documentation](https://docs.espressif.com/projects/esp-idf/en/latest/get-started-cmake/)
  - [ESP32 Boot Mode Selection · espressif/esptool Wiki · GitHub](https://github.com/espressif/esptool/wiki/ESP32-Boot-Mode-Selection)
- Docker
  - [Reference documentation \| Docker Documentation](https://docs.docker.com/reference/)
- Project
  - [GitHub - bschwind/esp-32-build: A Dockerfile for building and flashing ESP32 applications](https://github.com/bschwind/esp-32-build)
