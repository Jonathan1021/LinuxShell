set -e #error stop exit.

#Config variables
mongodb_path="/home/jvega/Documents/ReplicaSet/example"
company_name="koghi"
mongodb_initial_port=24001

#Script variables
log_name="${company_name}.log"
keyfile_name="${company_name}-keyfile"
mongodb_node_names=( "nodo1" "nodo2" "nodo3" )

#Create file structure by node
for node in "${mongodb_node_names[@]}"; do 
  mkdir -p  ${mongodb_path}/repl/${node}/db/{path,log}
  touch ${mongodb_path}/repl/${node}/db/log/${log_name}
done

# Create keyfile and give permission 400
mkdir ${mongodb_path}/repl/keyfile
openssl rand -base64 742 > ${mongodb_path}/repl/keyfile/${keyfile_name}
chmod 400 ${mongodb_path}/repl/keyfile/${keyfile_name}

#Create config file
mport=${mongodb_initial_port}
for node in "${mongodb_node_names[@]}"; do
	echo "Generating config file for $node"
cat >> ${mongodb_path}/${node}.cfg <<EOF
systemLog:
  destination: file
  path: "${mongodb_path}/repl/${node}/db/log/${log_name}"
  logAppend: true
storage:
  dbPath: "${mongodb_path}/repl/${node}/db/path"
  journal:
    enabled: true
processManagement:
  fork: true
net:
  bindIp: localhost
  port: ${mport}
security:
  keyFile: "${mongodb_path}/repl/keyfile/${keyfile_name}"
replication:
  replSetName: ${company_name}
# oplogSizeMB: <5% by default>
EOF
	echo "Starting $node from configuration file."
	mongod -f ${mongodb_path}/${node}.cfg
	let "mport++"
done

