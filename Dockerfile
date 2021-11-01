# SPDX-License-Identifier: Apache-2.0
# Copyright Contributors to the Egeria project

FROM maven:3.8.3-openjdk-8 AS build

# Overrideable parks
ARG DOWNLOAD_SERVER="https://archive.apache.org/dist"
ARG ATLAS_VERSION=2.2.0
ARG REGISTRY=registry-1.docker.io
ARG REPO=odpi


ENV ATLAS_URL="${DOWNLOAD_SERVER}/atlas/${ATLAS_VERSION}/apache-atlas-${ATLAS_VERSION}-sources.tar.gz" \
    ATLAS_KEYS="${DOWNLOAD_SERVER}/atlas/KEYS" \
    JAVA_TOOL_OPTIONS="-Xmx1024m" \
    MAVEN_OPTS="-Xms2g -Xmx2g"

WORKDIR /opt

# Some base additinos
RUN apt-get update && apt-get install patch

# Pull down Apache Atlas and build it into /root/atlas-bin.
RUN set -e; \
  wget -nv "$ATLAS_URL" -O "apache-atlas-$ATLAS_VERSION.tar.gz" && \
  wget -nv "$ATLAS_URL.asc" -O "apache-atlas-$ATLAS_VERSION.tar.gz.asc" && \
  wget -nv "$ATLAS_KEYS" -O "atlas-KEYS" && \
  gpg --import atlas-KEYS && \
  gpg --verify apache-atlas-$ATLAS_VERSION.tar.gz.asc apache-atlas-$ATLAS_VERSION.tar.gz && \
  tar zxf apache-atlas-$ATLAS_VERSION.tar.gz

WORKDIR /opt/apache-atlas-sources-$ATLAS_VERSION

# A few patches for the build
COPY patches/0001-Update-buildtools-to-project-version.patch .
RUN patch < 0001-Update-buildtools-to-project-version.patch

# Remove -DskipTests if unit tests are to be included
RUN mvn clean -DskipCheck=true -DskipTests=true install && \
    mvn clean -DskipCheck=true -DskipTests=true package -Pdist,embedded-hbase-solr && \
    mkdir -p /opt/atlas-bin && \
    tar zxf /opt/apache-atlas-sources-$ATLAS_VERSION/distro/target/*server.tar.gz --strip-components 1 -C /opt/atlas-bin

FROM openjdk:16-jdk-alpine

LABEL org.label-schema.schema-version = "1.0"
LABEL org.label-schema.vendor = "ODPi"
LABEL org.label-schema.name = "apache-atlas"
LABEL org.label-schema.description = "Apache Atlas image to support LF AI & Data Egeria demonstrations."
LABEL org.label-schema.url = "https://egeria.odpi.org/open-metadata-resources/open-metadata-deployment/"
LABEL org.label-schema.vcs-url = "https://planetf1/atlas-docker"
LABEL org.label-schema.docker.cmd = "docker run -d -p 21000:21000 planetf1/docker-atlas"
LABEL org.label-schema.docker.debug = "docker exec -it $CONTAINER /bin/sh"

ENV JAVA_TOOL_OPTIONS="-Xmx1024m" \
    HBASE_CONF_DIR="/opt/apache/atlas/hbase/conf" \
    ATLAS_OPTS="-Dkafka.advertised.hostname=localhost"

RUN apk --no-cache add python bash shadow && \
    apk --no-cache update && \
    apk --no-cache upgrade && \
    groupadd -r atlas -g 21000 && \
    useradd --no-log-init -r -g atlas -u 21000 -d /opt/apache/atlas atlas

COPY --from=build --chown=atlas:atlas /opt/atlas-bin/ /opt/apache/atlas/

# Must use numeric userid here to meet k8s security checks
USER 21000:21000

WORKDIR /opt/apache/atlas
RUN sed -i "s|^atlas.graph.storage.lock.wait-time=10000|atlas.graph.storage.lock.wait-time=200|g" conf/atlas-application.properties && \
    echo "atlas.notification.relationships.enabled=true" >> conf/atlas-application.properties && \
    echo "atlas.kafka.listeners=PLAINTEXT://:9027" >> conf/atlas-application.properties && \
    echo "atlas.kafka.advertised.listeners=PLAINTEXT://\${sys:kafka.advertised.hostname}:9027" >> conf/atlas-application.properties

EXPOSE 9026 9027 21000
ENTRYPOINT ["/bin/bash", "-c", "/opt/apache/atlas/bin/atlas_start.py; tail -fF /opt/apache/atlas/logs/atlas*.out"]
