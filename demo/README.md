MongoDB World Demo (mongo-swarm)
===========

Below there is a brief description of each compose files used and how to use the Python automation scripts to deploy our cluster into Cloud Manager using its API.

===========

Compose files
-----
**`mdb_base.yaml`**

This is the base and starting file where we define the service for each shard (as a replica set). 

		i.e. mongodb_replset_1

This file contains the following definitions:

**image**: Docker image for the Cloud Manager automation agent from the Docker HUB 

		image: marcob/mongodb-automation:latest

**security_opt**: Security options to run this service (the Cloud Manager automation requires to be run with seccomp:unconfined so that it can execute all required system calls)

		security_opt:
      		- seccomp:unconfined

**labels**: Labels added to each container for this service. These will be used to map the role of each container (mongod, cfgsvr, mongos) and the replica set it belongs to

    	labels:
      		- "role=mongod"
      		- "replset=rs1"

**command**: Command to be run by the container, in this case, the automation agent for Cloud Manager. Details required:
	    	- Cloud Manager group ID
	    	- Cloud Manager api Key

	   command: --mmsBaseUrl=https://cloud.mongodb.com --mmsGroupId=XXXX --mmsApiKey=XXXXX
	
**`mdb_repl.yaml`**

This file extends *mdb_base.yaml* and expands each service previously defined into 3 containers for each service. Here we address individual container options for each replica set / shard.

	i.e.  rs1a: extends mongodb_replset_1

This file contains the following definitions:

**ports**: ports mapping HOST:CONTAINER for the automation agent and the mongod process. The ports on the host should be all different to avoid multiple containers trying to map on the same port on a single host.

    ports:
      - 27001:27000
      - 27027:27027

 **volumes**: Data volume mapping HOST:container. Each container will use the /data/ directory for its mongod process. This directory will then be mounted on the host as the /mnt/data/rs1. The mount directory on the host should ideally:
 
* Be a different volume for each container (provisioned from different disks)
* Have enough space and performance

This allow us for instance to access the datafiles for normal operations or just tail the mongod.log file

    volumes:
      - /mnt/data/rs1:/data

**hostname**: hostname associated to this container. This will be used by Swarm multi-host networking for hostname resolution between multiple swarm nodes

    hostname: rs1a

**container_name**: Name of the container to refer to it with Docker tools / logs
    	
    container_name: rs1a

**labels**: Additional label to tag a container with its initial state. This is then use with a soft constraint to try to prevent having multiple primary mongod processes on the same worker node.

    labels:
      - "initialstate=primary"

**`mdb_cgroup.yaml`**

This file extends *mdb_repl.yaml* to add the cgroups limits associated to each container. 

This file contains the following definitions:

**cpuset**: Core (or set of cores) where this container will be executed from

    cpuset: "0"

**mem_limit**: Memory (resident only) limit associated to this container

    mem_limit: "6442450944"
    	
**memswap_limit**: Memory (resident + swap) limit associated to this container

    memswap_limit: "6442450944"

**`docker-compose.yml`**

This file extends mdb_cgroup.yaml and the services for each container to glue them all together and add constraint and affinity filters:

This file contains the following definitions:

**image**: Docker image for the Cloud Manager automation agent from the Docker HUB 

	image: marcob/mongodb-automation:latest
    
**environment** variables: Here we will define our filters based on the labels defined in mdb_repl.yaml

    environment:
      - "affinity:replset!=rs1" 

Affinity filter to avoid deploying a new container for replset rs1 if there is already on on that node
      
      - "affinity:initialstate!=~primary" 

Affinity soft filter to avoid deploying a new container with a primary initial state if there is already on on that node
      
      - "constraint:node!=marcob-MDBW-swarm-master"

Constraint filter to avoid or force the deployment of a container to a specific swarm node

Cloud Manager API examples
---------

The Cloud Manager API examples and scripts are available at the following repo:

[https://github.com/10gen-labs/mms-api-examples/](https://github.com/10gen-labs/mms-api-examples/)

During the demo, I ran a modified version of test_automation_api.py to deploy to multiple nodes that contains the following changes:

Number of steps used from the original test_automation_api.py

	Step("configs/api_0_clean.json",
         "Start with empty automation config"),

    Step("configs/api_1_define_versions.json",
         "Setup desired MongoDB versions"),

    Step("configs/api_2_install_other_agents.json",
         "Install Backup and Monitoring agents"),

    Step("configs/shardedCluster3.2.json",
         "Create a Sharded Cluster"),

The last step uses the automation configuration defined in [shardedCluster3.2.json] (shardedCluster3.2.json)


First step:

	python test_automation_api.py https://mms.mongodb.com HOSTNAME GROUP_ID MMS_USERNAME MMS_API_KEY --clean
	
Second step:

	python test_automation_api.py https://mms.mongodb.com HOSTNAME GROUP_ID MMS_USERNAME MMS_API_KEY 
	
	
Steps to deploy the example sharded cluster 
-----
Once we have a Swarm cluster deployed using Docker Machine (and after having all pre-required binaries installed), we can deploy it with the following commands:

**Move to demo directory**

	cd MDBW-demo

**Source the Docker environment variables to connect to the Swarm master**	

	eval $(docker-machine env --swarm marcob-MDBW-swarm-master)
	docker-compose up -d

**Move to the mms-api-examples directory**

	cd mms-api-examples/automation/api_usage_example
	
**Clean the automation configuration for the current group**

	python test_automation_api.py https://mms.mongodb.com HOSTNAME GROUP_ID MMS_USERNAME MMS_API_KEY --clean

**Deploy our sharded cluster on Cloud Manager based on the
configuration defined in shardedCluster3.2.json**

	python test_automation_api.py https://mms.mongodb.com HOSTNAME GROUP_ID MMS_USERNAME MMS_API_KEY 