if [[ -n "${TZ}" ]]; then
  echo "Setting timezone to ${TZ}"
  ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
fi

cd /chialite-blockchain

. ./activate

chialite init

if [[ ${keys} == "generate" ]]; then
  echo "to use your own keys pass them as a text file -v /path/to/keyfile:/path/in/container and -e keys=\"/path/in/container\""
  chialite keys generate
elif [[ ${keys} == "copy" ]]; then
  if [[ -z ${ca} ]]; then
    echo "A path to a copy of the farmer peer's ssl/ca required."
	exit
  else
  chialite init -c ${ca}
  fi
else
  chialite keys add -f ${keys}
fi

for p in ${plots_dir//:/ }; do
    mkdir -p ${p}
    if [[ ! "$(ls -A $p)" ]]; then
        echo "Plots directory '${p}' appears to be empty, try mounting a plot directory with the docker -v command"
    fi
    chialite plots add -d ${p}
done

sed -i 's/localhost/127.0.0.1/g' ~/.chialite/mainnet/config/config.yaml

if [[ ${farmer} == 'true' ]]; then
  chialite start farmer-only
elif [[ ${harvester} == 'true' ]]; then
  if [[ -z ${farmer_address} || -z ${farmer_port} || -z ${ca} ]]; then
    echo "A farmer peer address, port, and ca path are required."
    exit
  else
    chialite configure --set-farmer-peer ${farmer_address}:${farmer_port}
    chialite start harvester
  fi
else
  chialite start farmer
fi

if [[ ${testnet} == "true" ]]; then
  if [[ -z $full_node_port || $full_node_port == "null" ]]; then
    chialite configure --set-fullnode-port 58444
  else
    chialite configure --set-fullnode-port ${var.full_node_port}
  fi
fi

while true; do sleep 30; done;
