Steps to build docker images for p4 dev.
================================
## Prerequisites
### BF SDE Package
Get BF SDE tarball from intel.
### Linux Kernel Headers
Get correct Linux kernel tarball for OS. (e.g., ONL or SONiC)

NOTE: refer to
    https://github.com/stratum/stratum/blob/main/stratum/hal/bin/barefoot/README.build.md

----------

## Build steps

1. Modify build.env to specify correct SDE version and Linux kernel tarball.

2. Put BF SDE tarball and Linux kernel tarball into pkg-src/.

3.
```
make all
```

4. Get docker images under docker/.
