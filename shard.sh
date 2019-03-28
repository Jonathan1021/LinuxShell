set -e #error stop exit.

#Config variables
mongodb_path="/Users/n.diazgranados/mongodb-osx-x86_64-enterprise-4.0.2/script/SHARD"
company_name="koghi"
mongodb_initial_port=25001
mongodb_replica_names=("repl1" "repl2")
mongodb_csvr_names=( "c1" "c2" "c3" )
mongodb_node_names=( "n1" "n2" "n3" )

#Script variables
log_name="${company_name}.log"
keyfile_name="${company_name}-keyfile"
consvr_initial_port=$((mongodb_initial_port + 100))

#Create file structure for config servers by csvr
for csvr in "${mongodb_csvr_names[@]}"; do 
  mkdir -p  ${mongodb_path}/csvr/${csvr}/db/{path,log}
  touch ${mongodb_path}/csvr/${csvr}/db/log/csrv-${log_name}
done

# Create keyfile and give permission 400
mkdir ${mongodb_path}/keyfile
openssl rand -base64 742 > ${mongodb_path}/keyfile/${keyfile_name}
chmod 400 ${mongodb_path}/keyfile/${keyfile_name}

#Create config file
cport=${consvr_initial_port}
for csvr in "${mongodb_csvr_names[@]}"; do
 echo "Generating config file for $csvr"
cat >> ${mongodb_path}/csvr/${csvr}.cfg <<EOF
systemLog:
  destination: file
  path: "${mongodb_path}/csvr/${csvr}/db/log/csvr-${log_name}"
  logAppend: true
storage:
  dbPath: "${mongodb_path}/csvr/${csvr}/db/path"
processManagement:
  fork: true
net:
  bindIp: localhost
  port: ${cport}
security:
  keyFile: "${mongodb_path}/keyfile/${keyfile_name}"
replication:
  replSetName: ${company_name}-csvrs
sharding:
  clusterRole: configsvr
EOF
	echo "Starting $csvr from configuration file."
	mongod -f ${mongodb_path}/csvr/${csvr}.cfg
	let "cport++"
done

all_csrv_port=""
for i in "${!mongodb_csvr_names[@]}"; do
  if [ $i -eq 0 ]
    then
      all_csrv_port=localhost:${consvr_initial_port[0]}
    else
      all_csrv_port=${all_csrv_port},localhost:$((consvr_initial_port + i))
  fi
done

echo "Configuration ports: ${all_csrv_port}"

echo "Generating mongos config"
mkdir -p  ${mongodb_path}/mongos/log/
touch ${mongodb_path}/mongos/log/mongos-${log_name}
#Create mongos
cat >> ${mongodb_path}/mongos/mongos.cfg <<EOF 
sharding:
  configDB: ${company_name}-csvrs/${all_csrv_port}
security:
  keyFile: "${mongodb_path}/keyfile/${keyfile_name}"
net:
  bindIp: localhost
  port: $((consvr_initial_port - 1))
systemLog:
  destination: file
  path: "${mongodb_path}/mongos/log/mongos-${log_name}"
  logAppend: true
processManagement:
  fork: true
EOF

echo "Launch mongos"
mongos -f ${mongodb_path}/mongos/mongos.cfg

mport=${mongodb_initial_port}

for replica in "${mongodb_replica_names[@]}"; do
echo "Generating replica ${replica} file structure for one Shard:"

for node in "${mongodb_node_names[@]}"; do 
  mkdir -p  ${mongodb_path}/${replica}/${node}/db/{path,log}
  touch ${mongodb_path}/${replica}/${node}/db/log/${log_name}
done

#Create config file
for node in "${mongodb_node_names[@]}"; do
 echo "Generating config file for $node"
cat >> ${mongodb_path}/${replica}/${node}.cfg <<EOF
systemLog:
  destination: file
  path: "${mongodb_path}/${replica}/${node}/db/log/${log_name}"
  logAppend: true
storage:
  dbPath: "${mongodb_path}/${replica}/${node}/db/path"
  wiredTiger:
    engineConfig:
      cacheSizeGB: .1
  journal:
    enabled: true
processManagement:
  fork: true
net:
  bindIp: localhost
  port: ${mport}
security:
  keyFile: "${mongodb_path}/keyfile/${keyfile_name}"
replication:
  replSetName: ${company_name}-${replica}
sharding:
  clusterRole: shardsvr
EOF
  echo "Starting $node from configuration file."
  mongod -f ${mongodb_path}/${replica}/${node}.cfg
  let "mport++"
done
done
