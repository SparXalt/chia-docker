if [[ -n "${TZ}" ]]; then
  echo "Setting timezone to ${TZ}"
  ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
fi

cd /taco-blockchain

. ./activate

taco init

if [[ ${keys} == "generate" ]]; then
  echo "to use your own keys pass them as a text file -v /path/to/keyfile:/path/in/container and -e keys=\"/path/in/container\""
  taco keys generate
elif [[ ${keys} == "copy" ]]; then
  if [[ -z ${ca} ]]; then
    echo "A path to a copy of the farmer peer's ssl/ca required."
	exit
  else
  taco init -c ${ca}
  fi
else
  taco keys add -f ${keys}
fi

for p in ${plots_dir//:/ }; do
    mkdir -p ${p}
    if [[ ! "$(ls -A $p)" ]]; then
        echo "Plots directory '${p}' appears to be empty, try mounting a plot directory with the docker -v command"
    fi
    taco plots add -d ${p}
done

sed -i 's/localhost/127.0.0.1/g' ~/.taco/mainnet/config/config.yaml

if [[ ${farmer} == 'true' ]]; then
  taco start farmer-only
elif [[ ${harvester} == 'true' ]]; then
  if [[ -z ${farmer_address} || -z ${farmer_port} || -z ${ca} ]]; then
    echo "A farmer peer address, port, and ca path are required."
    exit
  else
    taco configure --set-farmer-peer ${farmer_address}:${farmer_port}
    taco start harvester
  fi
else
  taco start farmer
fi

if [[ ${testnet} == "true" ]]; then
  if [[ -z $full_node_port || $full_node_port == "null" ]]; then
    taco configure --set-fullnode-port 58444
  else
    taco configure --set-fullnode-port ${var.full_node_port}
  fi
fi

while true; do sleep 30; done;
