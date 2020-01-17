FROM lsiobase/alpine:3.10

# set version label and commit to check out
ARG DOMOTICZ_VERSION=4.10693
ARG DOMOTICZ_COMMIT=649306c4de2371177e186384874206c18e861f7c

# docker hub should also set this
ARG SOURCE_COMMIT=
ARG PYTHON_BROADLINK_COMMIT=8bc67af6
ENV BUILD_TOOLS_COMMIT $SOURCE_COMMIT
ENV DOMOTICZ_VERSION $DOMOTICZ_VERSION
ENV DOMOTICZ_COMMIT $DOMOTICZ_COMMIT
LABEL build_version="version: ${DOMOTICZ_VERSION}"
LABEL maintainer="iasmanis"

# environment settings
ENV HOME="/config"

# copy prebuilds
COPY patches/ /

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
    cmake \
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
    libftdi1-dev \
    libressl-dev \
    libusb-compat-dev \
    libusb-dev \
    linux-headers \
    make \
    mosquitto-dev \
    musl-dev \
    pkgconf \
    sqlite-dev \
    tar \
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
    libffi \
    libssl1.1 \
    python3-dev && \
    echo "**** link libftdi libs ****" && \
    ln -s /usr/lib/libftdi1.so /usr/lib/libftdi.so && \
    ln -s /usr/lib/libftdi1.a /usr/lib/libftdi.a && \
    ln -s /usr/include/libftdi1/ftdi.h /usr/include/ftdi.h && \
    echo "**** build telldus-core ****" && \
    mkdir -p \
    /tmp/telldus-core && \
    tar xf /tmp/patches/telldus-core-2.1.2.tar.gz -C \
    /tmp/telldus-core --strip-components=1 && \
    curl -o /tmp/telldus-core/Doxyfile.in -L \
    https://raw.githubusercontent.com/telldus/telldus/master/telldus-core/Doxyfile.in && \
    cp /tmp/patches/Socket_unix.cpp /tmp/telldus-core/common/Socket_unix.cpp && \
    cp /tmp/patches/ConnectionListener_unix.cpp /tmp/telldus-core/service/ConnectionListener_unix.cpp && \
    cp /tmp/patches/CMakeLists.txt /tmp/telldus-core/CMakeLists.txt && \
    cd /tmp/telldus-core && \
    cmake -DBUILD_TDADMIN=false -DCMAKE_INSTALL_PREFIX=/tmp/telldus-core . && \
    make && \
    echo "**** configure telldus core ****" && \
    mv /tmp/telldus-core/client/libtelldus-core.so.2.1.2 /usr/lib/libtelldus-core.so.2.1.2 && \
    mv /tmp/telldus-core/client/telldus-core.h /usr/include/telldus-core.h && \
    ln -s /usr/lib/libtelldus-core.so.2.1.2 /usr/lib/libtelldus-core.so.2 && \
    ln -s /usr/lib/libtelldus-core.so.2 /usr/lib/libtelldus-core.so && \
    echo "**** build domoticz ****" && \
    git clone https://github.com/domoticz/domoticz.git /tmp/domoticz && \
    cd /tmp/domoticz && \
    git checkout ${DOMOTICZ_COMMIT} && \
    cmake \
    -DBUILD_SHARED_LIBS=True \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/var/lib/domoticz \
    -DUSE_BUILTIN_LUA=ON \
    -DUSE_BUILTIN_MQTT=ON \
    -DUSE_BUILTIN_SQLITE=OFF \
    -DUSE_STATIC_BOOST=OFF \
    -DUSE_STATIC_LIBSTDCXX=OFF \
    -DUSE_STATIC_OPENZWAVE=OFF \
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
    git rev-parse --short HEAD >> VERSION  && \
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
    git rev-parse --short HEAD >> VERSION && \
    rm -rf .git && \
    echo "TODO pin release" && \
    git clone https://github.com/clach04/python-tuya.git "${HOME}/plugins/Domoticz-Tuya-Thermostat-Plugin/python-tuya" && \
    cd "${HOME}/plugins/Domoticz-Tuya-Thermostat-Plugin/python-tuya" && \
    git rev-parse --short HEAD >> VERSION && \
    ln -s "${HOME}/plugins/Domoticz-Tuya-Thermostat-Plugin/python-tuya/pytuya" "${HOME}/plugins/Domoticz-Tuya-Thermostat-Plugin/pytuya" && \
    rm -rf .git && \
    echo "****  installing domoticz-zigbee2mqtt-plugin ****" && \
    git clone https://github.com/stas-demydiuk/domoticz-zigbee2mqtt-plugin.git "${HOME}/plugins/Domoticz-Zigbee2Mqtt-Plugin" && \
    cd "${HOME}/plugins/Domoticz-Zigbee2Mqtt-Plugin" && \
    git rev-parse --short HEAD >> VERSION && \
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
    echo " **** cleanup ****" && \
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
