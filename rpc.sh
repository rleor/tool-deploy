#!/bin/bash

TOOLS_JAR=Tools.jar

function receipt_data() {
	header='{"jsonrpc":"2.0","id":1,"method":"eth_getTransactionReceipt","params":["'
	receipt="$1"
	footer='"]}'
	echo $header$receipt$footer
}

function get_seed() {
        header='{"jsonrpc":"2.0","id":1,"method":"getseed","params":['
        footer="]}"
        echo $header$footer
}

function submit_seed() {
        header='{"jsonrpc":"2.0","id":1,"method":"submitseed","params":["'
        seed="$1"
        comma='", "'
        pubkey="$2"
        footer='"]}'
        echo $header$seed$comma$pubkey$footer
}

function submit_signature() {
        header='{"jsonrpc":"2.0","id":1,"method":"submitsignature","params":["'
        signature="$1"
        comma='", "'
        sealinghash="$2"
        footer='"]}'
        echo $header$signature$comma$sealinghash$footer
}

function result_is_true() {
	if [[ "$1" =~ (\"result\":true) ]];
	then
		return 0
	else
		return 1
	fi
}

function extract_status() {
	if [[ "$1" =~ (\"status\".+\"id) ]];
	then
		result=${BASH_REMATCH[0]:10}
		echo ${result:0:3}
	fi
}

function extract_receipt_hash() {
	if [[ "$1" =~ (\"result\":\"0x[0-9a-f]{64}) ]];
	then
		echo ${BASH_REMATCH[0]:10:66}
	fi
}

function extract_receipt() {
	if [[ "$1" =~ (\"result\".+\"id) ]];
	then
		result=${BASH_REMATCH[0]:9}
		echo ${result:0:-4}
	fi
}

function extract_address_from_receipt() {
	if [[ "$1" =~ (\"contractAddress\".+\"id) ]];
	then
		result=${BASH_REMATCH[0]:19}
		echo ${result:0:66}
	fi
}

function extract_hash64() {
        if [[ "$1" =~ (\"result\": \"0x[0-9a-f]{64}) ]];
        then
                echo ${BASH_REMATCH[0]:11:67}
        fi
}

function extract_hash128() {
        if [[ "$1" =~ (\"result\": \"0x[0-9a-f]{128}) ]];
        then
                echo ${BASH_REMATCH[0]:11:131}
        fi
}

function bad_connection_msg() {
	echo ' '
	echo "Unable to establish a connection using "$1". "
	echo "Ensure that the kernel is running and that it is running on the specified host and port, and that the kernel rpc connection is enabled. "
	echo 'The kernel rpc connection details can be modified in the configuration file at: config/config.xml'
}

if [ $# -eq 0 ]
then
	print_help
	exit 1
fi

function send_raw_and_print_receipt() {
	# send the transaction.
	payload='{"jsonrpc":"2.0","method":"eth_sendRawTransaction","params":["'$1'"],"id":1}'
	response=$(curl -s -X POST -H "Content-Type: application/json" --data "$payload" "$2")
	if [ $? -eq 7 ]
	then
		bad_connection_msg "$2"
		exit 1
	fi

	receipt_hash=$(extract_receipt_hash "$response")
	echo $receipt_hash
}

if [ "$1" = '--get-receipt-address' ]
then
	# get receipt must have 3 arguments.
	if [ $# -ne 3 ]
	then
		echo 'Incorrect number of arguments given!'
		print_help
		exit 1
	fi

	# query the transaction receipt.
	response=$(curl -s -X POST -H "Content-Type: application/json" --data "$(receipt_data "$2")" "$3")
	if [ $? -eq 7 ]
	then
		bad_connection_msg
		exit 1
	fi

	status=$(extract_status "$response")

	if [ "0x0" == "$status" ]
	then
		exit 2
	fi
	address=$(extract_address_from_receipt "$response")
	echo "$address"

elif [ "$1" = '--check-receipt-status' ]
then
	# get receipt must have 3 arguments.
	if [ $# -ne 3 ]
	then
		echo 'Incorrect number of arguments given!'
		print_help
		exit 1
	fi

	# query the transaction receipt.
	response=$(curl -s -X POST -H "Content-Type: application/json" --data "$(receipt_data "$2")" "$3")
	if [ $? -eq 7 ]
	then
		bad_connection_msg
		exit 1
	fi

	status=$(extract_status "$response")

	if [ "0x0" == "$status" ]
	then
		exit 2
	elif [ "0x1" == "$status" ]
	then
		exit 0
	else
		exit 1
	fi

elif [ "$1" = '--deploy' ]
then
	# Deploy has 4 arguments:
	private_key="$2"
	nonce="$3"
	node_address="$4"
	jar_path="$5"
	jar_bytes=""
	
	# Grab the bytes of the deployment jar.
	if [ $# -eq 5 ]
	then
		jar_bytes="$(java -cp $TOOLS_JAR cli.PackageJarAsHex "$jar_path")"
	elif [ $# -eq 6 ]
	then
		argument="$6"
		jar_bytes="$(java -cp $TOOLS_JAR cli.PackageJarAsHex "$jar_path" "$argument")"
	else
		echo 'Incorrect number of arguments given!'
		print_help
		exit 1
	fi

	if [ $? -ne 0 ]
	then
		echo 'PackageJarAsHex failed.'
		exit 1
	fi
	# Package the entire transaction.
	signed_deployment="$(java -cp $TOOLS_JAR cli.SignTransaction --privateKey "$private_key" --nonce "$nonce" --deploy "$jar_bytes")"
	if [ $? -ne 0 ]
	then
		echo 'Signing deployment transaction failed.'
		exit 1
	fi

	send_raw_and_print_receipt "$signed_deployment" "$node_address"

elif [ "$1" = '--call' ]
then
	# Call has 7 arguments:
	private_key="$2"
	nonce="$3"
	target_address="$4"
	serialized_call="$5"
	value="$6"
	
	if [ $# -eq 7 ]
	then
		# Package the entire transaction.
		signed_call="$(java -cp $TOOLS_JAR cli.SignTransaction --privateKey "$private_key" --nonce "$nonce" --destination "$target_address" --call "$serialized_call" --value "$value")"
		if [ $? -ne 0 ]
		then
			exit 1
		fi

		send_raw_and_print_receipt "$signed_call" "$7"
	else
		echo 'Incorrect number of arguments given!'
		print_help
		exit 1
	fi

elif [ "$1" = '--getseed' ]
then
        
        if [ $# -ne 2 ]
        then
                echo 'Incorrect number of arguments given!'
                print_help
                exit 1
        fi

        # query the seed.
        response=$(curl -s -X POST -H "Content-Type: application/json" --data "$(get_seed)" "$2")
       
        echo "$(extract_hash128 "$response")"

elif [ "$1" = '--submitseed' ]
then
        # submit seed must have 4 arguments.
        if [ $# -ne 4 ]
        then
                echo 'Incorrect number of arguments given!'
                print_help
                exit 1
        fi

        # submit seed and the pubkey.
        response=$(curl -s -X POST -H "Content-Type: application/json" --data "$(submit_seed "$2" "$3")" "$4")
        if [ $? -eq 7 ]
        then
                bad_connection_msg
                exit 1
        fi

        echo "$(extract_hash64 "$response")"

elif [ "$1" = '--submitsignature' ]
then
        # submit signature must have 4 arguments.
        if [ $# -ne 4 ]
        then
                echo 'Incorrect number of arguments given!'
                print_help
                exit 1
        fi

        # submit signature and the sealinghash.
        response=$(curl -s -X POST -H "Content-Type: application/json" --data "$(submit_signature "$2" "$3")" "$4")
        if [ $? -eq 7 ]
        then
                bad_connection_msg
                exit 1
        fi


        echo "$(result_is_true "$responsse")"

else
	print_help
	exit 1
fi