################################################################################
# select base image.
################################################################################
FROM debian:9.9-slim

################################################################################
# define ARG and ENV
################################################################################
ARG PACKAGES_FOR_ESP_TOOLCHAIN="gcc git wget make libncurses-dev flex bison gperf python python-pip python-setuptools python-serial python-cryptography python-future python-pyparsing python-pyelftools"
ARG PACKAGES_FOR_ESP_IDF="cmake ninja-build"
ARG PACKAGES_FOR_DEBUG="vim"
ARG ESP_TOOLCHAIN_ARCHIVE="xtensa-esp32-elf-linux64-1.22.0-80-g6c4433a-5.2.0.tar.gz"
ARG ESP_IDF_VERSION="v3.3-beta3"

ENV DIR_ESP_BASE /opt/local/esp
ENV IDF_PATH ${DIR_ESP_BASE}/esp-idf
ENV PATH ${DIR_ESP_BASE}/xtensa-esp32-elf/bin:${IDF_PATH}/tools:${PATH}
ENV DIR_ESP_PROJECT /esp/project

################################################################################
# Install the packages needed for building and the packages needed for debugging.
################################################################################
RUN apt-get update \
	&& apt-get install -y ${PACKAGES_FOR_ESP_TOOLCHAIN}\
	&& apt-get install -y ${PACKAGES_FOR_ESP_IDF}\
	&& apt-get install -y ${PACKAGES_FOR_DEBUG}\
	&& apt-get clean \
	&& rm -fr /var/lib/apt/lists/* /tmp/* /var/tmp/*

################################################################################
# setup ESP Toolchain environment.
################################################################################
RUN mkdir -p ${DIR_ESP_BASE} \
	&& wget -O /tmp/${ESP_TOOLCHAIN_ARCHIVE} https://dl.espressif.com/dl/${ESP_TOOLCHAIN_ARCHIVE} \
	&& tar -xzf /tmp/${ESP_TOOLCHAIN_ARCHIVE} -C ${DIR_ESP_BASE} \
	&& rm /tmp/${ESP_TOOLCHAIN_ARCHIVE}

################################################################################
# setup ESP IDF environment.
################################################################################
RUN cd ${DIR_ESP_BASE} \
	&& : "clone specific release version" \
	&& git clone -b ${ESP_IDF_VERSION} --recursive https://github.com/espressif/esp-idf.git

RUN python -m pip install --user -r ${IDF_PATH}/requirements.txt

################################################################################
# setup ESP project environment.
################################################################################
RUN mkdir -p ${DIR_ESP_PROJECT}
WORKDIR ${DIR_ESP_PROJECT}
CMD /bin/bash
