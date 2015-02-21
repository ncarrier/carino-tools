                      shell tools for the carino project

 ° arm-linux-gnueabihf-pkg-config : Wrapper around pkg-config, calling it with
the needed environment variables for arm cross-compilation.

 ° autoconnect.sh : Script for auto-(re-)connecting the wifi of the host to the
target's "carino" network, or the a network whose name is passed as an argument.
It will check periodically if the connection is ok and try to re-establish it if
not. Relies on network-manager and the nmcli tool.

 ° bau : Wrapper around build.sh which Builds And Updates the packages given
passed as arguments. During the build process, the final dir is monitored with
inotify and all the created or modified files are installed on the target, iif
they are not already present with the same md5sum. Symbolic links are also
(poorly) handled.

 ° build.sh : Build script for the carino project. Loads the content of
config/build_config, then builds all the packages passed as arguments, if any,
or build the packages listed in config/packages if none.
Build of tools needed for the cross compilation is also supported, in a staging
directory dedicated to host tools. The packages are built in order (no
dependency support). They are built by calling their build script in the
build_scripts directory, with the relevant variables added to their environment.
The following environment variables are set:
For all packages (default values in parenthesis):
 * OUT_DIR (out) : where are placed the files produced during the build
 * BUILD_DIR (out/build) : where are created the directories where each package
   must place it's intermediate build files
 * BOOT_DIR (out/boot) : where the files necessary to the first boot steps must
   be placed, for now: the kernel (uImage), the u-boot config (uEnv.txt) and the
   device tree (sun7i-a20-pcduino3.dtb)
 * U_BOOT_DIR (out/u-boot) : where the u-boot bootloader will be installed after
   compilation, useful only for the u-boot build script and the script
   responsible for the creation of a SD card image (gen_sd.sh)
 * CONFIG_DIR (config) : where the configuration files are located, it includes
   build configs, skeletton...
 * PACKAGES_DIR (packages) : where are located the packages sources
 * BUILD_SCRIPTS_DIR (build_scripts) : where are located the build scripts for
   the packages
 * PATH : the bin/ directory in the host staging dir is appended to the PATH
   environment variable
 * PACKAGE_BUILD_DIR (out/build/package_name) : directory a build script must
   use to put it's intermediate build files
 * the compilation variables CFLAGS, CPPFLAGS, LDFLAGS, CC, CXX, PACKAGE_NAME
   and PKG_CONFIG_PATH are also set to meaningful values and must be used by
   each build script if relevant
For host builds:
 * STAGING_HOST_DIR (out/staging.host) : where packages must install the files
   relevant for others host packages' build, e.g. headers, .a or .so files
For cross-compilation builds:
 * STAGING_DIR (out/staging) : where packages must install the files relevant
   for others packages' build, e.g. headers, .a or .so files
 * FINAL_DIR (out/final) : where the packages must install the files needed on
   the target
 * TOOLCHAIN_PREFIX (arm-linux-gnueabihf) : prefix of the toolchain used for the
   cross-compilation 

All the previoulsy mentionned directories are created prior to each build
script's execution.
After each build has finished, the skel in config/skel is merged into the final
dir, this means that if one has modified something in the skel, he only has to
build and update a fast building package to get it's modifications pushed on
target.
After each package has been built, a file
${BUILD_DIR}/${target}/${target}.staging_files is created, which contains all
the files which have been installed in the staging dir during the build process.
This is to ease the writing of build scripts so that the "integrator" can know
among which files he is supposed to choose the candidates for installation in
the final dir.
For each package PACKAGE, a target PACKAGE-dirclean is supported, which removes
the PACKAGE_BUILD_DIR directory.
Environment variables of influence are :
 * V : if set to 1, the build will be (much) more verbose
 * CARINO_VERSION_TYPE : if set to "release", the executables in the final
   directory will be stripped and the build will be optimised for size

 ° cb : example of some command lines able to build automatically a package if
one of it's source files have been modified, then push the result on the target
and finally execute a command on target. This can be particularly useful for the
development of a library which uses automated unit tests.

 ° gen_sd.sh : script responsible of generating a bootable sd card with two
partitions, one for the boot, containing what has been placed in BOOT_DIR, the
other for the rootfs, containing what is in the final dir. This script needs
root permissions because it has to mount the partitions. The size of each
partition is controlled in build_config.

 ° setenv : should be sourced when developing for the carino project. Defines
the following aliases :
 * bb packages_list : builds the listed packages
 * bau packages_list : builds the listed packages and updates them on target
 * sd : calls the gen_sd.sh script
 * purple : make the console print in purple
 * normal : make the console print in it's default style
 * st : issues a git status command in each of the git repositories
 * romnt, rwmnt : remounts read-only (resp read/write) the / and /boot
   partitions on the target
Also configures automatic bash completion for the bb, bau and ./build.sh
commands.

 ° useful_commands : set of commands, mainly one-liners I found usefull at least
once, potential candidates for having an alias defined in setenv in the future.
