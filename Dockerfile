FROM linuxserver/domoticz:version-2023.1

ARG LIB_PYTHON_BROADLINK_COMMIT=cbb1d67
ARG LIB_PYTHON_TUYA_COMMIT=23e375ff9f069752bb998b5089525fa9012da9d4
ARG PLUGIN_MQTT_DISCOVERY_COMMIT=ee96d074a2e2452c26db26f8bc0584b2a7dca7c9
ARG PLUGIN_ZIGBEE2MQTT_COMMIT=v.3.1.0
# v.3.0.0
ARG PLUGIN_TUYA_THERMOSTAT_COMMIT=5d245e381c7562af35224e7dcf7662b89c9049a1

LABEL build_version="version: ${VERSION}"
LABEL maintainer="iasmanis"

# environment settings
ENV HOME="/config" \
    WEBROOT=/

RUN \
    echo "****  install git  ****" && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    git && \
    echo "****  installing Broadlink-RM2-Universal-IR-Remote-Controller-Domoticz-plugin ****" && \
    git clone https://github.com/iasmanis/Domoticz-Broadlink-RM2-Plugin.git "${HOME}/plugins/Domoticz-Broadlink-RM2-Plugin" && \
    cd "${HOME}/plugins/Domoticz-Broadlink-RM2-Plugin" && \
    echo "TODO pin release" && \
    git rev-parse --short HEAD >> VERSION  && \
    rm -rf .git && \
    echo "**** install BroadlinkRM2 plugin dependencies ****" && \
    git clone https://github.com/mjg59/python-broadlink.git "${HOME}/plugins/Domoticz-Broadlink-RM2-Plugin/python-broadlink" && \
    cd "${HOME}/plugins/Domoticz-Broadlink-RM2-Plugin/python-broadlink" && \
    git checkout $LIB_PYTHON_BROADLINK_COMMIT && \
    # TODO: Use archive instead of plain checkout
    rm -rf .git && \
    pip3 install --no-cache-dir . && \
    pip3 install --no-cache-dir pyaes && \
    pip3 install --no-cache-dir python-miio && \
    ln -s "${HOME}/plugins/Domoticz-Broadlink-RM2-Plugin/python-broadlink/broadlink" "${HOME}/plugins/Domoticz-Broadlink-RM2-Plugin/broadlink" && \
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
    # git clone https://github.com/emontnemery/domoticz_mqtt_discovery "${HOME}/plugins/Domoticz-Mqtt-Discovery-Plugin" && \
    git clone https://github.com/iasmanis/Domoticz-MQTT-Discovery-Plugin.git "${HOME}/plugins/Domoticz-Mqtt-Discovery-Plugin" && \
    cd "${HOME}/plugins/Domoticz-Mqtt-Discovery-Plugin" && \
    git checkout $PLUGIN_MQTT_DISCOVERY_COMMIT && \
    rm -rf .git && \
    echo "****  cleanup  ****" && \
    apt-get purge -y git  && \
    apt-get clean && \
    rm -rf \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/* && \
    true
