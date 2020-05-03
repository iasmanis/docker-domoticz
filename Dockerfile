FROM lsiobase/alpine:3.11

# set version label and commit to check out
# Minor version refrence table
# https://www.domoticz.com/wiki/Domoticz_versions_-_Commits#Database_versions
# Major version reference
# https://github.com/domoticz/domoticz/blob/development/main/appversion.h

ARG DOMOTICZ_VERSION=2020.1
ARG DOMOTICZ_COMMIT=2020.1

# ARG DOMOTICZ_VERSION=4.11807
# ARG DOMOTICZ_COMMIT=f7a465aeb

# docker hub should also set this
ARG SOURCE_COMMIT=
ARG LIB_PYTHON_BROADLINK_COMMIT=cbb1d67
ARG LIB_PYTHON_TUYA_COMMIT=23e375ff9f069752bb998b5089525fa9012da9d4
ARG PLUGIN_MQTT_DISCOVERY_COMMIT=a56bad5840afe84d6bca995e88ae49ff94bf0aa6
ARG PLUGIN_ZIGBEE2MQTT_COMMIT=423da5f
ARG PLUGIN_TUYA_THERMOSTAT_COMMIT=5d245e381c7562af35224e7dcf7662b89c9049a1
ENV BUILD_TOOLS_COMMIT $SOURCE_COMMIT
ENV DOMOTICZ_VERSION $DOMOTICZ_VERSION
ENV DOMOTICZ_COMMIT $DOMOTICZ_COMMIT
LABEL build_version="version: ${DOMOTICZ_VERSION}"
LABEL maintainer="iasmanis"

# environment settings
ENV HOME="/config"

# # copy prebuilds
# COPY patches/ /

# Using edge for dev deps as domoticz makefile requires cmake >= 3.16.5
# Remove http://dl-cdn.alpinelinux.org/alpine/edge/main after cmake is updated in current

RUN \
    echo "**** install build packages ****" && \
    apk add --no-cache --virtual=build-dependencies \
    libffi-dev \
    libc-dev \
    openssl-dev \
    argp-standalone \
    autoconf \
    automake \
    binutils \
    boost-dev \
    confuse-dev \
    curl-dev \
    doxygen \
    eudev-dev \
    g++ \
    gcc \
    git \
    gzip \
    jq \
    libcurl \
    libftdi1-dev  \
    rhash-dev \
    expat-dev \
    libarchive-dev \
    libuv-dev \
    libusb-compat-dev \
    libusb-dev \
    linux-headers \
    make \
    mosquitto-dev \
    musl-dev \
    pkgconf \
    sqlite-dev \
    tar \
    lua5.3-dev \
    zlib-dev \
    uthash-dev \
    zlib-dev && \
    echo "**** install runtime packages ****" && \
    apk add --no-cache \
    boost \
    boost-system \
    boost-thread \
    curl \
    eudev-libs \
    iputils \
    libressl \
    openssh \
    openssl \
    openssl-libs-static \
    libffi \
    libssl1.1 \
    lua5.3 \
    lua5.3-libs \
    python3-dev && \
    echo "**** install cmake ****" && \
    apk add cmake --repository=http://dl-cdn.alpinelinux.org/alpine/edge/main && \
    # echo "**** build cmake ****" && \
    # cd /tmp && \
    # wget https://cmake.org/files/v3.16/cmake-3.16.5.tar.gz && \
    # tar -xvvzf cmake-3.16.5.tar.gz && \
    # cd /tmp/cmake-3.16.5 && \
    # ./bootstrap \
    # --prefix=/usr \
    # --mandir=/share/man \
    # --datadir=/share/$pkgname \
    # --docdir=/share/doc/$pkgname \
    # --system-libs \
    # --no-system-jsoncpp && \
    # make && \
    # make install && \
    true
RUN true && \
    echo "**** build domoticz ****" && \
    git clone https://github.com/domoticz/domoticz.git /tmp/domoticz && \
    cd /tmp/domoticz && \
    git checkout ${DOMOTICZ_COMMIT} && \
    cmake \
    -S./ \
    -DBUILD_SHARED_LIBS=True \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/var/lib/domoticz \
    -DUSE_BUILTIN_LUA=ON \
    -DUSE_BUILTIN_MQTT=ON \
    -DUSE_BUILTIN_SQLITE=OFF \
    -DUSE_STATIC_BOOST=OFF \
    -DUSE_STATIC_LIBSTDCXX=OFF \
    -DUSE_STATIC_OPENZWAVE=OFF \
    -DWITH_UTILITIES=OFF \
    -DLUA_INCLUDE_DIR=/usr/include \
    -Wno-dev && \
    make && \
    make install && \
    echo "****  installing Broadlink-RM2-Universal-IR-Remote-Controller-Domoticz-plugin ****" && \
    git clone https://github.com/iasmanis/Domoticz-Broadlink-RM2-Plugin.git "${HOME}/plugins/Domoticz-Broadlink-RM2-Plugin" && \
    cd "${HOME}/plugins/Domoticz-Broadlink-RM2-Plugin" && \
    echo "TODO pin release" && \
    git rev-parse --short HEAD >> VERSION  && \
    rm -rf .git && \
    echo "**** install BroadlinkRM2 plugin dependencies ****" && \
    git clone https://github.com/mjg59/python-broadlink.git "${HOME}/plugins/Domoticz-Broadlink-RM2-Plugin/python-broadlink" && \
    cd "${HOME}/plugins/Domoticz-Broadlink-RM2-Plugin/python-broadlink" && \
    git checkout $LIB_PYTHON_BROADLINK_COMMIT  && \
    rm -rf .git && \
    pip3 install --no-cache-dir . && \
    pip3 install --no-cache-dir pyaes && \
    pip3 install --no-cache-dir python-miio && \
    ln -s "${HOME}/plugins/Domoticz-Broadlink-RM2-Plugin/python-broadlink/broadlink" "${HOME}/plugins/Domoticz-Broadlink-RM2-Plugin/broadlink" && \
    echo "****  installing Domoticz-AirPurifier-Plugin ****" && \
    git clone https://github.com/iasmanis/Domoticz-AirPurifier-Plugin.git "${HOME}/plugins/Domoticz-AirPurifier-Plugin" && \
    cd "${HOME}/plugins/Domoticz-AirPurifier-Plugin" && \
    git rev-parse --short HEAD >> VERSION  && \
    rm -rf .git && \
    echo "TODO pin release" && \
    echo "****  installing Domoticz-Tuya-Thermostat-Plugin ****" && \
    git clone https://github.com/iasmanis/Domoticz-Tuya-Thermostat-Plugin.git "${HOME}/plugins/Domoticz-Tuya-Thermostat-Plugin" && \
    cd "${HOME}/plugins/Domoticz-Tuya-Thermostat-Plugin" && \
    git checkout $PLUGIN_TUYA_THERMOSTAT_COMMIT && \
    git rev-parse --short HEAD >> VERSION && \
    rm -rf .git && \
    git clone https://github.com/clach04/python-tuya.git "${HOME}/plugins/Domoticz-Tuya-Thermostat-Plugin/python-tuya" && \
    cd "${HOME}/plugins/Domoticz-Tuya-Thermostat-Plugin/python-tuya" && \
    git checkout $LIB_PYTHON_TUYA_COMMIT  && \
    ln -s "${HOME}/plugins/Domoticz-Tuya-Thermostat-Plugin/python-tuya/pytuya" "${HOME}/plugins/Domoticz-Tuya-Thermostat-Plugin/pytuya" && \
    rm -rf .git && \
    echo "****  installing domoticz-zigbee2mqtt-plugin ****" && \
    git clone https://github.com/stas-demydiuk/domoticz-zigbee2mqtt-plugin.git "${HOME}/plugins/Domoticz-Zigbee2Mqtt-Plugin" && \
    cd "${HOME}/plugins/Domoticz-Zigbee2Mqtt-Plugin" && \
    git checkout $PLUGIN_ZIGBEE2MQTT_COMMIT  && \
    rm -rf .git && \
    echo "****  installing domoticz_mqtt_discovery ****" && \
    git clone 	https://github.com/iasmanis/Domoticz-MQTT-Discovery-Plugin.git "${HOME}/plugins/Domoticz-Mqtt-Discovery-Plugin" && \
    cd "${HOME}/plugins/Domoticz-Mqtt-Discovery-Plugin" && \
    git checkout $PLUGIN_MQTT_DISCOVERY_COMMIT && \
    rm -rf .git && \
    echo "**** determine runtime packages using scanelf ****" && \
    RUNTIME_PACKAGES="$( \
    scanelf --needed --nobanner /var/lib/domoticz/domoticz \
    | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
    | sort -u \
    | xargs -r apk info --installed \
    | sort -u \
    )" && \
    apk add --no-cache \
    $RUNTIME_PACKAGES && \
    echo "**** add abc to dialout and cron group ****" && \
    usermod -a -G 16,20 abc && \
    echo "**** cleanup ****" && \
    # cd /tmp/cmake-3.16.5 && \
    # make uninstall && \
    apk del --purge \
    build-dependencies && \
    rm -rf \
    /tmp/* \
    /usr/lib/libftdi* \
    /usr/include/ftdi.h


# copy local files
COPY root/ /

# ports and volumes
EXPOSE 8080 6144 1443
VOLUME /config
