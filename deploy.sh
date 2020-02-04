#!/bin/bash

contract="dapp.jar"
tools="Tools.jar"
rpc="127.0.0.1:8545"

bytes="$(java -cp ./Tools.jar cli.PackageJarAsHex ./dapp.jar)"

echo $bytes