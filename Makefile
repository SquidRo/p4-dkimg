#
# Makefile for building docker images for p4 develement on tofino switch.
#

include build.env

TARGETS := sde-install sde-dkimg stratum-bf stratum-bf-no-skip tm-sim

SDE_VERSION=9.9.0
KERNEL_TAR=linux-4.14.49-OpenNetworkLinux.tar.xz
SDE_DK_TAG=sq/bf-sde:${SDE_VERSION}
TM_DK_TAG=sq/tofino-model:${SDE_VERSION}


STRATUM_ROOT=${PWD}/stratum

# put needed packages (ex: sde, kernel headers)  into PKG_SRC_PATH
PKG_SRC_PATH= ${PWD}/pkg_src

OUTPUT_DIR  = ${PWD}/build

SDE_TAR=${PKG_SRC_PATH}/bf-sde-${SDE_VERSION}.tgz

all: $(TARGETS)

.PHONY: clean sde-install sde-dkimg stratum-bf stratum-bf-no-skip tm-sim _no-skip-patch

clean:
	@find ${OUTPUT_DIR} ! -name '.gitignore' -type f -exec rm {} \;

# build docker images
sde-install:
	export SDE_TAR=${SDE_TAR}; cd ${STRATUM_ROOT} && \
	stratum/hal/bin/barefoot/build-bf-sde.sh \
	    -t ${SDE_TAR} -k ${PKG_SRC_PATH}/${KERNEL_TAR}

sde-dkimg:
	cd ${PKG_SRC_PATH}; \
	docker build -f ${PKG_SRC_PATH}/Dockerfile-sde990 -t ${SDE_DK_TAG} .
	docker save ${SDE_DK_TAG} | gzip > ${OUTPUT_DIR}/sq-sde-${SDE_VERSION}-docker.tar.gz

stratum-bf:
	cd ${STRATUM_ROOT}; \
	export SDE_INSTALL_TAR=${PKG_SRC_PATH}/bf-sde-${SDE_VERSION}-install.tgz; \
	stratum/hal/bin/barefoot/docker/build-stratum-bf-container.sh; \
	mv stratum-bfrt-${SDE_VERSION}-docker.tar.gz ${OUTPUT_DIR}/${NEWNAME}

_no-skip-patch:
	cd ${STRATUM_ROOT}; \
	git am ../patch/0001-Patch-to-display-p4-symbol-info-on-tofino-model.patch;

stratum-bf-no-skip: _no-skip-patch stratum-bf
	$(eval NEWNAME := stratum-bfrt-${SDE_VERSION}-no-skip-docker.tar.gz)

tm-sim:
	export SDE_TAR=${SDE_TAR}; cd ${STRATUM_ROOT} && \
	stratum/hal/bin/barefoot/docker/build-tofino-model-container.sh ${SDE_TAR}

	cd ${PKG_SRC_PATH}; \
	docker build -f ${PKG_SRC_PATH}/Dockerfile-tm -t ${TM_DK_TAG} .
	docker save ${TM_DK_TAG} | gzip > ${OUTPUT_DIR}/sq-tofino-model-${SDE_VERSION}-docker.tar.gz

# not to remove...
.PRECIOUS:

