eval $(docker-machine env --swarm marcob-MDBW-swarm-master)
docker-compose stop; sleep 10;docker-compose rm -fv -a

/Users/marco/MDBWorld/docker-machine-cleanImage.sh
/Users/marco/MDBWorld/docker-machine-DataDir2.sh

docker-machine ssh marcob-MDB-swarm-node-1 'sudo docker ps'
docker-machine ssh marcob-MDB-swarm-node-2 'sudo docker ps'
docker-machine ssh marcob-MDB-swarm-node-3 'sudo docker ps'
echo "CLEAN CLOUD MANAGER GROUP"
#sleep 60

docker-compose --verbose up -d >> up.log
./sortedPs.sh
echo '----------------------' >> rs1.log
echo '----------------------' >> rs2.log
echo '----------------------' >> rs3.log
./sortedPs.sh | grep rs1 >> rs1.log
./sortedPs.sh | grep rs2 >> rs2.log
./sortedPs.sh | grep rs3 >> rs3.log

echo "Getting ready to configure Replica set via Cloud Manager API"

sleep 30

echo "Ready to deploy to Cloud Manager group  = marcob1"
cd ./mms-api-examples/automation/api_usage_example/


echo "Cleaning config"

python test_automation_api.py https://mms.mongodb.com automationrs1 $YOUR_MMS_GROUP_ID $MMS_USER $MMS_API_KEY --clean
python test_automation_api.py https://mms.mongodb.com automationrs1 $YOUR_MMS_GROUP_ID $MMS_USER $MMS_API_KEY
