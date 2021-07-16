if [[ -n "${TZ}" ]]; then
  echo "Setting timezone to ${TZ}"
  ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
fi

cd /cactus-blockchain

. ./activate

cactus init

if [[ ${keys} == "generate" ]]; then
  echo "to use your own keys pass them as a text file -v /path/to/keyfile:/path/in/container and -e keys=\"/path/in/container\""
  cactus keys generate
elif [[ ${keys} == "copy" ]]; then
  if [[ -z ${ca} ]]; then
    echo "A path to a copy of the farmer peer's ssl/ca required."
	exit
  else
  cactus init -c ${ca}
  fi
else
  cactus keys add -f ${keys}
fi

for p in ${plots_dir//:/ }; do
    mkdir -p ${p}
    if [[ ! "$(ls -A $p)" ]]; then
        echo "Plots directory '${p}' appears to be empty, try mounting a plot directory with the docker -v command"
    fi
    cactus plots add -d ${p}
done

sed -i 's/localhost/127.0.0.1/g' ~/.cactus/mainnet/config/config.yaml

if [[ ${farmer} == 'true' ]]; then
  cactus start farmer-only
elif [[ ${harvester} == 'true' ]]; then
  if [[ -z ${farmer_address} || -z ${farmer_port} || -z ${ca} ]]; then
    echo "A farmer peer address, port, and ca path are required."
    exit
  else
    cactus configure --set-farmer-peer ${farmer_address}:${farmer_port}
    cactus start harvester
  fi
else
  cactus start farmer
fi

if [[ ${testnet} == "true" ]]; then
  if [[ -z $full_node_port || $full_node_port == "null" ]]; then
    cactus configure --set-fullnode-port 58444
  else
    cactus configure --set-fullnode-port ${var.full_node_port}
  fi
fi

while true; do sleep 30; done;
