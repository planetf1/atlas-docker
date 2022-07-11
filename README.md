<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright Contributors to the Egeria project. -->
# atlas-docker
Apache Atlas Dockerfile to support ongoing Egeria development work. It is not suitable as a general Atlas container as it needs to be much more configurable to integrate into the broader environment.

We may evolve this over time, and make use of it in a helm chart to deploy a more appropriate ecosystem to support development and testing of the Egeria Atlas connector

* Based on Apache Atlas 2.2.0
* Docker images based on those previously in https://github.com/odpi/egeria

# Running the image

Currently this image is only tested running on linux/macos podman.

## Launch

Podman or docker can be used, it
```
podman run -p 9026:9026 -p 9027:9027 -p 21000:21000 docker.io/planetf1/apache-atlas:latest
```

## Using Kafka

Integration via Kafka is interesting for egeria, in addition to the webui/endpoint

For example, using the tools provided in the 'kafka' package (add .sh to the commands when running on linux, whilst homebrew macOS users should use this version)

```
$ kafka-topics --bootstrap-server localhost:9027 --list                     [13:04:05]
ATLAS_HOOK
ATLAS_ENTITIES
__consumer_offsets

$ ./kafka-console-consumer.sh --bootstrap-server localhost:9027 --topic ATLAS_ENTITIES &
$ echo "test" | ./kafka-console-producer.sh --broker-list localhost:9027 --topic ATLAS_ENTITIES
test
```

Note that the ATLAS_ENTITIES topic is only created on first use


## Access WebUI

Go to http://localhost:21000

## Caveats

### MacOS

If running podman-machine locally on macOS, ensure the following line is present
in the containers section of ~/.config/containers/containers.conf

```
   rootless_networking = "cni"
```
Without this, and even after podman 3.4.0 (which should contain a fix) this seemed to be needed
to allow kafka etc to work

### Example output

```
podman run -p 9026:9026 -p 9027:9027 -p 21000:21000 docker.io/planetf1/apache-atlas:latest     [11:38:24]
Trying to pull docker.io/planetf1/apache-atlas:latest...
Getting image source signatures
Copying blob sha256:cd9d07e1a75170502baba5c385b3cf74c13ff0ff38e278b35914eaa1b8e601e6
Copying blob sha256:e7c96db7181be991f19a9fb6975cdbbd73c65f4a2681348e63a141a2192a5f10
Copying blob sha256:f910a506b6cb1dbec766725d70356f695ae2bf2bea6224dbe8c7c6ad4f3664a2
Copying blob sha256:c2274a1a0e2786ee9101b08f76111f9ab8019e368dce1e325d3c284a0ca33397
Copying blob sha256:449d525ac143897d5037e7c1ed5d116b7499d17cd537cf67deec2f9439c0d2f5
Copying blob sha256:e52f7f053805d49913d7e6b9b0a69be076dc38da8190fa719c89edd66603b902
Copying blob sha256:e52f7f053805d49913d7e6b9b0a69be076dc38da8190fa719c89edd66603b902
Copying blob sha256:e7c96db7181be991f19a9fb6975cdbbd73c65f4a2681348e63a141a2192a5f10
Copying blob sha256:449d525ac143897d5037e7c1ed5d116b7499d17cd537cf67deec2f9439c0d2f5
Copying blob sha256:cd9d07e1a75170502baba5c385b3cf74c13ff0ff38e278b35914eaa1b8e601e6
Copying blob sha256:c2274a1a0e2786ee9101b08f76111f9ab8019e368dce1e325d3c284a0ca33397
Copying blob sha256:f910a506b6cb1dbec766725d70356f695ae2bf2bea6224dbe8c7c6ad4f3664a2
Copying config sha256:d0d772d56b0bac2c89c477dc2bc931ee4e2858d941e172455c671a16a9630dc0
Writing manifest to image destination
Storing signatures
Picked up JAVA_TOOL_OPTIONS: -Xmx1024m

Configured for local HBase.
Starting local HBase...
Local HBase started!

Configured for local Solr.
Starting local Solr...
solr.xml doesn't exist in /opt/apache/atlas/data/solr, copying from /opt/apache/atlas/solr/server/solr/solr.xml
Local Solr started!

Creating Solr collections for Atlas using config: /opt/apache/atlas/conf/solr

Starting Atlas server on host: localhost
Starting Atlas server on port: 21000
.......................................................................................................................................................................................................
Apache Atlas Server started!!!

==> /opt/apache/atlas/logs/atlas.20211018-104104.out <==
running master, logging to /opt/apache/atlas/hbase/bin/../logs/hbase--master-f23e302384c0.out
Picked up JAVA_TOOL_OPTIONS: -Xmx1024m

==> /opt/apache/atlas/logs/atlas.20211018-104105.out <==
*** [WARN] ***  Your Max Processes Limit is currently 7543.
 It should be set to 65000 to avoid operational disruption.
 If you no longer wish to see this warning, set SOLR_ULIMIT_CHECKS to false in your profile or solr.in.sh
NOTE: Please install lsof as this script needs it to determine if Solr is listening on port 9838.

Started Solr server on port 9838 (pid=atlas). Happy searching!


==> /opt/apache/atlas/logs/atlas.20211018-104116.out <==
Created collection 'vertex_index' with 1 shard(s), 1 replica(s) with config-set 'vertex_index'

==> /opt/apache/atlas/logs/atlas.20211018-104143.out <==
Created collection 'edge_index' with 1 shard(s), 1 replica(s) with config-set 'edge_index'

==> /opt/apache/atlas/logs/atlas.20211018-104150.out <==
Created collection 'fulltext_index' with 1 shard(s), 1 replica(s) with config-set 'fulltext_index'

==> /opt/apache/atlas/logs/atlas.20211018-104154.out <==
```

