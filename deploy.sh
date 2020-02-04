#!/bin/bash
# -----------------------------------------------------------------------------
# This script can be used to deploy StakerRegistry and PoolRegistry contracts.
#
# Usage: ./deploy.sh
# Note: PRIVATE_KEY, NONCE, EXPECTED_STAKER_REGISTRY_ADDRESS should be set before running the script.
# -----------------------------------------------------------------------------

#Private key of the deployer account
PRIVATE_KEY="0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
#Nonce of the deployer account
NONCE=0
EXPECTED_STAKER_REGISTRY_ADDRESS="0xa056337bb14e818f3f53e13ab0d93b6539aa570cba91ce65c716058241989be9"
STAKER_JAR_PATH="dapp.jar"
POOL_JAR_PATH="poolRegistry.jar"
TOOLS_JAR=Tools.jar
NODE_ADDRESS="127.0.0.1:8545"

function require_success()
{
	if [ $1 -ne 0 ]
	then
		echo "Failed"
		exit 1
	fi
}

callPayload="$(java -cp $TOOLS_JAR cli.ComposeCallPayload "main")"
receipt=`./rpc.sh --deploy "$PRIVATE_KEY" "$NONCE" "$NODE_ADDRESS" "$STAKER_JAR_PATH" "$callPayload"`
require_success $?

echo "Deployment transaction hash: \"$receipt\".  Waiting for deployment to complete..."
address=""
while [ "" == "$address" ]
do
	echo " waiting..."
	sleep 1
	address=`./rpc.sh --get-receipt-address "$receipt" "$NODE_ADDRESS"`
	require_success $?
done
echo "dapp was deployed to address: \"$address\""
if [ "$EXPECTED_STAKER_REGISTRY_ADDRESS" != "$address" ]
then
	echo "Address was incorrect:  Expected $EXPECTED_STAKER_REGISTRY_ADDRESS"
	exit 1
fi