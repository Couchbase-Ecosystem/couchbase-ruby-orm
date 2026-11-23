set -x
set -e

VERSION=$1
BUCKET=$2
USER=$3
PASSWORD=$4


# Couchbase Server 7.6+ only publishes a generic "linux" package; older
# releases also ship distro-specific ones. Try the distro one first.
PACKAGE=""
for FLAVOR in ubuntu20.04 linux; do
  CANDIDATE=couchbase-server-enterprise_$VERSION-${FLAVOR}_amd64.deb
  if wget -q https://packages.couchbase.com/releases/$VERSION/$CANDIDATE; then
    PACKAGE=$CANDIDATE
    break
  fi
done
if [ -z "$PACKAGE" ]; then
  echo "No Couchbase Server package found for version $VERSION" >&2
  exit 1
fi
dpkg -i $PACKAGE
sleep 8
sudo service couchbase-server status
/opt/couchbase/bin/couchbase-cli cluster-init -c 127.0.0.1:8091 --cluster-username=admin --cluster-password=password --cluster-ramsize=320 --cluster-index-ramsize=256 --cluster-fts-ramsize=256 --services=data,index,query,fts
sleep 5
/opt/couchbase/bin/couchbase-cli server-info   -c 127.0.0.1:8091 -u admin -p password
/opt/couchbase/bin/couchbase-cli bucket-create -c 127.0.0.1:8091 -u admin -p password --bucket=$BUCKET --bucket-type=couchbase --bucket-ramsize=160 --bucket-replica=0 --wait
sleep 1
/opt/couchbase/bin/couchbase-cli user-manage   -c 127.0.0.1:8091 -u admin -p password --set --rbac-username $USER --rbac-password $PASSWORD --rbac-name "Auto Tester" --roles admin --auth-domain local
curl http://admin:password@localhost:8093/query/service -d "statement=CREATE INDEX \`default_type\` ON \`$BUCKET\`(\`type\`)"
curl http://admin:password@localhost:8093/query/service -d "statement=CREATE INDEX \`default_rating\` ON \`$BUCKET\`(\`rating\`)"
curl http://admin:password@localhost:8093/query/service -d "statement=CREATE INDEX \`default_name\` ON \`$BUCKET\`(\`name\`)"
