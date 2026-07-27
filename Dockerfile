FROM domoticz/domoticz:2026.2 AS builder

ARG LIB_PYTHON_BROADLINK_COMMIT=cbb1d67
ARG LIB_PYTHON_TUYA_COMMIT=23e375ff9f069752bb998b5089525fa9012da9d4
ARG PLUGIN_MQTT_DISCOVERY_COMMIT=f876e9d6fbb3bf233a3a860dc9fc67dc9ddcfcc0
ARG PLUGIN_ZIGBEE2MQTT_COMMIT=v.3.1.0
ARG PLUGIN_TUYA_THERMOSTAT_COMMIT=5d245e381c7562af35224e7dcf7662b89c9049a1
ARG PLUGIN_BROADLINK_RM2_COMMIT=cd65a14a94fc3e70982359e2b356fece86f29df8

# environment settings
ENV HOME="/config" \
    WEBROOT=/

# Install build dependencies
RUN echo "****  builder: install build deps ****" && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    git \
    build-essential \
    gcc \
    g++ \
    make \
    pkg-config \
    python3-dev \
    libssl-dev \
    libffi-dev \
    libyaml-dev \
    cargo \
    rustc

# Upgrade pip tooling
RUN echo "****  builder: upgrade pip tooling ****" && \
    pip3 install --no-cache-dir --upgrade pip setuptools wheel

# Install Broadlink-RM2 plugin
RUN echo "****  builder: installing Broadlink-RM2-Universal-IR-Remote-Controller-Domoticz-plugin ****" && \
    git clone https://github.com/iasmanis/Domoticz-Broadlink-RM2-Plugin.git /tmp/Domoticz-Broadlink-RM2-Plugin && \
    cd /tmp/Domoticz-Broadlink-RM2-Plugin && \
    mkdir -p "${HOME}/plugins/Domoticz-Broadlink-RM2-Plugin" && \
    git rev-parse --short HEAD >> "${HOME}/plugins/Domoticz-Broadlink-RM2-Plugin/VERSION"  && \
    git archive $PLUGIN_BROADLINK_RM2_COMMIT | tar -x -C "${HOME}/plugins/Domoticz-Broadlink-RM2-Plugin" && \
    cd /tmp && \
    rm -rf /tmp/Domoticz-Broadlink-RM2-Plugin && \
    echo "**** builder: install BroadlinkRM2 plugin dependencies ****" && \
    git clone https://github.com/mjg59/python-broadlink.git /tmp/python-broadlink && \
    cd /tmp/python-broadlink && \
    mkdir -p "${HOME}/plugins/Domoticz-Broadlink-RM2-Plugin/python-broadlink" && \
    git archive $LIB_PYTHON_BROADLINK_COMMIT | tar -x -C "${HOME}/plugins/Domoticz-Broadlink-RM2-Plugin/python-broadlink" && \
    cd /tmp && \
    rm -rf /tmp/python-broadlink && \
    cd "${HOME}/plugins/Domoticz-Broadlink-RM2-Plugin/python-broadlink" && \
    pip3 install --no-cache-dir . && \
    pip3 install --no-cache-dir pyaes && \
    pip3 install --no-cache-dir python-miio && \
    mv "${HOME}/plugins/Domoticz-Broadlink-RM2-Plugin/python-broadlink/broadlink" "${HOME}/plugins/Domoticz-Broadlink-RM2-Plugin/broadlink"

# Install Tuya Thermostat plugin
RUN echo "****  builder: installing Domoticz-Tuya-Thermostat-Plugin ****" && \
    git clone https://github.com/iasmanis/Domoticz-Tuya-Thermostat-Plugin.git /tmp/Domoticz-Tuya-Thermostat-Plugin && \
    cd /tmp/Domoticz-Tuya-Thermostat-Plugin && \
    mkdir -p "${HOME}/plugins/Domoticz-Tuya-Thermostat-Plugin" && \
    git rev-parse --short $PLUGIN_TUYA_THERMOSTAT_COMMIT >> "${HOME}/plugins/Domoticz-Tuya-Thermostat-Plugin/VERSION" && \
    git archive $PLUGIN_TUYA_THERMOSTAT_COMMIT | tar -x -C "${HOME}/plugins/Domoticz-Tuya-Thermostat-Plugin" && \
    cd /tmp && \
    rm -rf /tmp/Domoticz-Tuya-Thermostat-Plugin && \
    git clone https://github.com/clach04/python-tuya.git /tmp/python-tuya && \
    cd /tmp/python-tuya && \
    mkdir -p "${HOME}/plugins/Domoticz-Tuya-Thermostat-Plugin/python-tuya" && \
    git archive $LIB_PYTHON_TUYA_COMMIT | tar -x -C "${HOME}/plugins/Domoticz-Tuya-Thermostat-Plugin/python-tuya" && \
    cd /tmp && \
    rm -rf /tmp/python-tuya && \
    mv "${HOME}/plugins/Domoticz-Tuya-Thermostat-Plugin/python-tuya/pytuya" "${HOME}/plugins/Domoticz-Tuya-Thermostat-Plugin/pytuya"

# Install Zigbee2MQTT plugin
RUN echo "****  builder: installing domoticz-zigbee2mqtt-plugin ****" && \
    git clone https://github.com/stas-demydiuk/domoticz-zigbee2mqtt-plugin.git /tmp/Domoticz-Zigbee2Mqtt-Plugin && \
    cd /tmp/Domoticz-Zigbee2Mqtt-Plugin && \
    mkdir -p "${HOME}/plugins/Domoticz-Zigbee2Mqtt-Plugin" && \
    git archive $PLUGIN_ZIGBEE2MQTT_COMMIT | tar -x -C "${HOME}/plugins/Domoticz-Zigbee2Mqtt-Plugin" && \
    cd /tmp && \
    rm -rf /tmp/Domoticz-Zigbee2Mqtt-Plugin

# Install MQTT Discovery plugin
RUN echo "****  builder: installing domoticz_mqtt_discovery ****" && \
    # git clone https://github.com/emontnemery/domoticz_mqtt_discovery "${HOME}/plugins/Domoticz-Mqtt-Discovery-Plugin" && \
    git clone https://github.com/iasmanis/Domoticz-MQTT-Discovery-Plugin.git /tmp/Domoticz-Mqtt-Discovery-Plugin && \
    cd /tmp/Domoticz-Mqtt-Discovery-Plugin && \
    mkdir -p "${HOME}/plugins/Domoticz-Mqtt-Discovery-Plugin" && \
    git archive $PLUGIN_MQTT_DISCOVERY_COMMIT | tar -x -C "${HOME}/plugins/Domoticz-Mqtt-Discovery-Plugin" && \
    cd /tmp && \
    rm -rf /tmp/Domoticz-Mqtt-Discovery-Plugin

# Cleanup
RUN echo "**** builder: cleanup ****" && \
    rm -rf "${HOME}/.cache" && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

FROM domoticz/domoticz:2026.2

# environment settings
ENV HOME="/config" \
    WEBROOT=/

LABEL build_version="version: 2025.2, commit: $(git rev-parse --short HEAD)" \
    description="Domoticz with Broadlink RM2, Tuya Thermostat, Zigbee2MQTT and MQTT Discovery plugins" \
    url="https://github.com/iasmanis/docker-domoticz" \
    maintainer="iasmanis"

# Copy only the built Python dependencies and plugins from the builder image
COPY --from=builder /opt/venv/lib/python3.13/site-packages /opt/venv/lib/python3.13/site-packages
COPY --from=builder /config/plugins /opt/domoticz/userdata/plugins
