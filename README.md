# Shell tools for the carino project

## arm-linux-gnueabihf-pkg-config

Wrapper around pkg-config, calling it with the needed environment variables for
arm cross-compilation.

## autoconnect.sh

Script for auto-(re-)connecting the wifi of the host to the target's "carino"
network, or a network whose name is passed as an argument.  
It will check periodically if the connection is ok and try to re-establish it if
not. Relies on network-manager and the nmcli tool.

## bau

Wrapper around  [build.sh](#build.sh) which Builds And Updates the packages
given passed as arguments. During the build process, the final dir is monitored
with inotify and all the created or modified files are installed on the target,
iif they are not already present with the same md5sum. Symbolic links are also
(poorly) handled.

## <a name="build_sh"></a>build.sh

Build script for the carino project. Loads the content of config/build\_config,
then builds all the packages passed as arguments, if any, or build the packages
listed in config/packages if none.

Build of tools needed for the cross compilation is also supported, in a staging
directory dedicated to host tools. The packages are built in order (no
dependency support). They are built by calling their build script in the
build\_scripts directory, with the relevant variables added to their
environment.

The following environment variables are set:

* For all packages (with _default values_):
 * **OUT\_DIR** _out_: where are placed the files produced during the build
 * **BUILD\_DIR** _out/build_: where are created the directories where each
   package must place it's intermediate build files
 * <a name="BOOT\_DIR"></a>**BOOT\_DIR** _out/boot_: where the files necessary
   to the first boot steps must be placed, for now: the kernel (uImage), the
   u-boot config (uEnv.txt) and the device tree (sun7i-a20-pcduino3.dtb)
 * **U\_BOOT\_DIR** _out/u-boot_: where the u-boot bootloader will be installed
   after compilation, useful only for the u-boot build script and the script
   responsible for the creation of a SD card image with [gen\_sd.sh](#gen\_sd.sh)
 * **CONFIG\_DIR** _config_: where the configuration files are located, it
   includes build configs, skeletton...
 * **PACKAGES\_DIR** _packages_: where are located the packages sources
 * **BUILD\_SCRIPTS\_DIR** _build\_scripts_: where are located the build scripts
   for the packages
 * **PATH** : the bin/ directory in the host staging dir is appended to the PATH
   environment variable
 * <a name="PACKAGE\_BUILD\_DIR"></a>**PACKAGE\_BUILD\_DIR**
   _out/build/package\_name_: directory a build script must use to put it's
   intermediate build files
 * the compilation variables CFLAGS, CPPFLAGS, LDFLAGS, CC, CXX, PACKAGE\_NAME
   and PKG\_CONFIG\_PATH are also set to meaningful values and must be used by
   each build script if relevant
* For host builds:
 * **STAGING\_HOST\_DIR** _out/staging.host_: where packages must install the
   files relevant for others host packages' build, e.g. headers, .a or .so files
* For cross-compilation builds:
 * **STAGING\_DIR** _out/staging_: where packages must install the files
   relevant for others packages' build, e.g. headers, .a or .so files
 * **FINAL\_DIR** _out/final_: where the packages must install the files needed
   on the target
 * **TOOLCHAIN\_PREFIX** _arm-linux-gnueabihf_: prefix of the toolchain used for
   the cross-compilatio

All the previoulsy mentionned directories are created prior to each build
script's execution.  
After each package has been built, a file
BUILD\_DIR/target/target.staging\_files is created, which contains all the files
which have been installed in the staging dir during the build process. This is
to ease the writing of build scripts so that the "integrator" can know among
which files he is supposed to choose the candidates for installation in the
final dir.  
Just before build.sh exits, the skeleton in config/skel is merged into the
final dir, this means that if one has modified something in the skel, he only
has to build and update a fast building package to get it's modifications pushed
on target.  
For each package PACKAGE, a **PACKAGE-dirclean** target is supported, which
removes the [PACKAGE\_BUILD\_DIR](#PACKAGE\_BUILD\_DIR) directory.

Environment variables of influence are :

* **V** : if set to 1, the build will be (much) more verbose
* **CARINO\_VERSION\_TYPE** : if set to "release", the executables in the final
  directory will be stripped and the build will be optimised for size

## cb

Example of some command lines able to build automatically a package if one of
it's source files have been modified, then push the result on the target and
finally execute a command on target. This can be particularly useful for the
development of a library which uses automated unit tests.

## gen\_sd.sh

Script responsible of generating a bootable sd card with two partitions, one for
the boot, containing what has been placed in [BOOT\_DIR](#BOOT\_DIR), the other
for the rootfs, containing what is in the final dir. This script needs root
permissions because it has to mount the partitions. The size of each partition
is controlled in build\_config.

## setenv

Should be sourced when developing for the carino project. Defines the
following aliases:

* **bb** packages\_list: builds the listed packages
* **bau** packages\_list: builds the listed packages and updates them on target
* **sd**: calls the gen\_sd.sh script
* **purple**: make the console print in purple
* **normal**: make the console print in it's default style
* **st**: issues a git status command in each of the git repositories
* **romnt**, **rwmnt**: remounts read-only (resp read/write) the / and /boot
  partitions on the target

Also configures automatic bash completion for the bb, bau and ./build.sh
commands.

## useful\_commands

Set of commands, mainly one-liners I found usefull at least once, potential
candidates for having an alias defined in setenv in the future.

## License

    This is part of the Carino project documentation.
    Copyright (C) 2015
      Nicolas CARRIER
    See the file doc/README.md for copying conditions
