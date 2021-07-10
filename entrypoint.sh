if [[ -n "${TZ}" ]]; then
  echo "Setting timezone to ${TZ}"
  ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
fi

cd /thyme-blockchain

. ./activate

thyme init

if [[ ${keys} == "generate" ]]; then
  echo "to use your own keys pass them as a text file -v /path/to/keyfile:/path/in/container and -e keys=\"/path/in/container\""
  thyme keys generate
elif [[ ${keys} == "copy" ]]; then
  if [[ -z ${ca} ]]; then
    echo "A path to a copy of the farmer peer's ssl/ca required."
	exit
  else
  thyme init -c ${ca}
  fi
else
  thyme keys add -f ${keys}
fi

for p in ${plots_dir//:/ }; do
    mkdir -p ${p}
    if [[ ! "$(ls -A $p)" ]]; then
        echo "Plots directory '${p}' appears to be empty, try mounting a plot directory with the docker -v command"
    fi
    thyme plots add -d ${p}
done

sed -i 's/localhost/127.0.0.1/g' ~/.thyme/mainnet/config/config.yaml

if [[ ${farmer} == 'true' ]]; then
  thyme start farmer-only
elif [[ ${harvester} == 'true' ]]; then
  if [[ -z ${farmer_address} || -z ${farmer_port} || -z ${ca} ]]; then
    echo "A farmer peer address, port, and ca path are required."
    exit
  else
    thyme configure --set-farmer-peer ${farmer_address}:${farmer_port}
    thyme start harvester
  fi
else
  thyme start farmer
fi

if [[ ${testnet} == "true" ]]; then
  if [[ -z $full_node_port || $full_node_port == "null" ]]; then
    thyme configure --set-fullnode-port 58444
  else
    thyme configure --set-fullnode-port ${var.full_node_port}
  fi
fi

while true; do sleep 30; done;
