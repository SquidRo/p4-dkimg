#
# Makefile for building docker images for p4 develement on tofino switch.
#

include build.env

TARGETS := sde-install sde-dkimg stratum-bf-no-skip tm-sim

# put needed packages (ex: sde, kernel headers)  into PKG_SRC_PATH
PKG_SRC_PATH= ${PWD}/pkg-src

DK_DIR      = ${PWD}/docker
STRATUM_ROOT= ${PWD}/stratum

SDE_TAR=${PKG_SRC_PATH}/bf-sde-${SDE_VERSION}.tgz

all: $(TARGETS)
	@echo "Output files:"
	@find ${DK_DIR} -name "*.gz"
	@find ${PKG_SRC_PATH} -name "*install.tgz"

.PHONY: clean test_req_tar _no-skip-patch sde-install sde-dkimg stratum-bf-no-skip tm-sim

clean:
	@find ${DK_DIR} ! -name 'Dockerfile*' -type f -exec rm {} \;
	@find ${PKG_SRC_PATH} -name "*install.tgz" -exec rm {} \;

test_req_tar:
	$(if $(wildcard $(SDE_TAR)),,\
         $(error Put sde tarball into ${PKG_SRC_PATH}, and try again... ***))

	$(if $(wildcard ${PKG_SRC_PATH}/${KERNEL_TAR}),,\
         $(error Put kernel tarball into ${PKG_SRC_PATH}, and try again... ***))

	# download stratum source for building process
	git submodule update -f --init

# build related files for docker images
${PKG_SRC_PATH}/bf-sde-${SDE_VERSION}-install.tgz:
	$(MAKE) test_req_tar
	export SDE_TAR=${SDE_TAR}; cd ${STRATUM_ROOT} && \
	stratum/hal/bin/barefoot/build-bf-sde.sh \
	    -t ${SDE_TAR} -k ${PKG_SRC_PATH}/${KERNEL_TAR}

${DK_DIR}/sq-sde-${SDE_VERSION}-docker.tar.gz: ${PKG_SRC_PATH}/bf-sde-${SDE_VERSION}-install.tgz
	cd ${PKG_SRC_PATH}; \
	docker build -f ${DK_DIR}/Dockerfile-sde990 -t ${SDE_DK_TAG} .
	docker save ${SDE_DK_TAG} | gzip > ${DK_DIR}/sq-sde-${SDE_VERSION}-docker.tar.gz

stratum-bf: ${PKG_SRC_PATH}/bf-sde-${SDE_VERSION}-install.tgz
	cd ${STRATUM_ROOT}; \
	export SDE_INSTALL_TAR=${PKG_SRC_PATH}/bf-sde-${SDE_VERSION}-install.tgz; \
	stratum/hal/bin/barefoot/docker/build-stratum-bf-container.sh; \
	mv stratum-bfrt-${SDE_VERSION}-docker.tar.gz ${DK_DIR}/${NEWNAME}

_no-skip-patch:
	git submodule update -f --init

	cd ${STRATUM_ROOT}; \
	git am ../patch/0001-Patch-to-display-p4-symbol-info-on-tofino-model.patch;
	$(MAKE) NEWNAME=stratum-bfrt-${SDE_VERSION}-no-skip-docker.tar.gz stratum-bf

${DK_DIR}/stratum-bfrt-${SDE_VERSION}-no-skip-docker.tar.gz:
	$(MAKE) _no-skip-patch

${DK_DIR}/sq-tofino-model-${SDE_VERSION}-docker.tar.gz:
	$(MAKE) test_req_tar
	export SDE_TAR=${SDE_TAR}; cd ${STRATUM_ROOT} && \
	stratum/hal/bin/barefoot/docker/build-tofino-model-container.sh ${SDE_TAR}

	cd ${PKG_SRC_PATH}; \
	docker build -f ${DK_DIR}/Dockerfile-tm -t ${TM_DK_TAG} .
	docker save ${TM_DK_TAG} | gzip > ${DK_DIR}/sq-tofino-model-${SDE_VERSION}-docker.tar.gz

# alias for targets above
sde-install: ${PKG_SRC_PATH}/bf-sde-${SDE_VERSION}-install.tgz

sde-dkimg: ${DK_DIR}/sq-sde-${SDE_VERSION}-docker.tar.gz

stratum-bf-no-skip: ${DK_DIR}/stratum-bfrt-${SDE_VERSION}-no-skip-docker.tar.gz

tm-sim: ${DK_DIR}/sq-tofino-model-${SDE_VERSION}-docker.tar.gz

.DEFAULT_GOAL := all

# not to remove...
.PRECIOUS:

