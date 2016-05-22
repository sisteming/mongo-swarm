eval $(docker-machine env --swarm marcob-MDBW-swarm-master)
docker-compose stop; sleep 10;docker-compose rm -fv -a

docker-machine ssh marcob-MDB-swarm-node-1 'sudo docker ps'
docker-machine ssh marcob-MDB-swarm-node-2 'sudo docker ps'
docker-machine ssh marcob-MDB-swarm-node-3 'sudo docker ps'
echo "CLEAN CLOUD MANAGER GROUP"
#sleep 60

docker-compose --verbose up -d >> up.log

echo "Getting ready to configure Replica set via Cloud Manager API"

sleep 30

echo "Ready to deploy to Cloud Manager group $YOURMMSGROUPID"
cd ~/mms-api-examples/automation/api_usage_example/

echo "Cleaning config"
python test_automation_api.py https://mms.mongodb.com automationrs1 $YOURMMSGROUPID $MMS_USER MMSAPIKEY --clean
echo "Deploying cluster config"
python test_automation_api.py https://mms.mongodb.com automationrs1 $YOURMMSGROUPID $MMS_USER MMSAPIKEY
