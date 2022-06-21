set -x
set -e
apt-get install libev-dev python-httplib2 libssl1.0.0
wget https://packages.couchbase.com/releases/5.1.0/couchbase-server-enterprise_5.1.0-ubuntu14.04_amd64.deb
dpkg -i couchbase-server-enterprise_5.1.0-ubuntu14.04_amd64.deb
sleep 8
sudo service couchbase-server status
/opt/couchbase/bin/couchbase-cli cluster-init -c 127.0.0.1:8091 --cluster-username=admin --cluster-password=password --cluster-ramsize=320 --cluster-index-ramsize=256 --cluster-fts-ramsize=256 --services=data,index,query,fts
sleep 5
/opt/couchbase/bin/couchbase-cli server-info   -c 127.0.0.1:8091 -u admin -p password
/opt/couchbase/bin/couchbase-cli bucket-create -c 127.0.0.1:8091 -u admin -p password --bucket=default --bucket-type=couchbase --bucket-ramsize=160 --bucket-replica=0 --wait
sleep 1
/opt/couchbase/bin/couchbase-cli user-manage   -c 127.0.0.1:8091 -u admin -p password --set --rbac-username tester --rbac-password password123 --rbac-name "Auto Tester" --roles admin --auth-domain local
curl http://admin:password@localhost:8093/query/service -d 'statement=CREATE INDEX `default_type` ON `default`(`type`)'
