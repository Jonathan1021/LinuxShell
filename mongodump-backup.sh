 #!/bin/sh

echo "Start - Scripts Mongo Backup Connection"

TIMESTAMP=`date +%F-%H%M`

echo "-----> Variable declaration"

NUMBER_CONNECTIONS=1

echo "-----> Number Connections $NUMBER_CONNECTIONS"


# Conecction Daniela
CONNECTIONS_NAME[0]=""
CONNECTIONS_HOST[0]=
CONNECTIONS_PORT[0]=
CONNECTIONS_USERNAME[0]=""
CONNECTIONS_PASS[0]=""

MONGODUMP_PATH="/usr/bin/mongodump"
BACKUPS_DIR=""

echo Execute - Backup

a=0

while [ $a -lt $NUMBER_CONNECTIONS ]
do
   	echo "-----> $a Connection: ${CONNECTIONS_NAME[$a]}"
	echo "----->    Host: ${CONNECTIONS_HOST[$a]}"
	echo "----->    Port: ${CONNECTIONS_PORT[$a]}"
   	$MONGODUMP_PATH --host ${CONNECTIONS_HOST[$a]} --port ${CONNECTIONS_PORT[$a]} --username ${CONNECTIONS_USERNAME[$a]} --password ${CONNECTIONS_PASS[$a]} --out $BACKUPS_DIR/${CONNECTIONS_NAME[$a]}_$TIMESTAMP
	a=`expr $a + 1`
done
echo "---> Done!"