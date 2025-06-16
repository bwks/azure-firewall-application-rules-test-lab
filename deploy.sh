#! /usr/bin/bash

# Call with:
#  FIREWALL_PIP="x.x.x.x" ./deploy.sh

CERT_DIR="./cert";
mkdir $CERT_DIR;

if [ -z "${FIREWALL_PIP}" ]; then
  echo "Environment variable FIREWALL_PIP is not set. Exiting."
  exit 1
fi
if [ -z "${CF_API_KEY}" ]; then
  echo "Environment variable CF_API_KEY is not set. Exiting."
  exit 1
fi

declare -A HOSTS;

HOSTS["client"]=2290
HOSTS["webserver1"]=2291 # no inspect
HOSTS["webserver2"]=2292 # inspect
HOSTS["webserver3"]=2293 # lets encrypt inspect

declare -A WEBSERVERS;

WEBSERVERS["webserver1"]=2291
WEBSERVERS["webserver2"]=2292

for server in ${!HOSTS[@]}; do
  echo "${server} port ${HOSTS[$server]}"
  scp -P ${HOSTS[$server]} ${CERT_DIR}/rootCA.crt ${CERT_DIR}/interCA.crt ${FIREWALL_PIP}:/tmp/

  ssh $FIREWALL_PIP -p ${HOSTS[$server]} "sudo mv /tmp/*.crt /usr/local/share/ca-certificates/ && \
    echo 10.255.255.10 idontexist.intheether | sudo tee --append /etc/hosts && \
    sudo update-ca-certificates --fresh"
done

for server in ${!WEBSERVERS[@]}; do
  echo "${server} port ${WEBSERVERS[$server]}"
  scp -P ${WEBSERVERS[$server]} ${CERT_DIR}/${server}.key ${CERT_DIR}/${server}.crt ${FIREWALL_PIP}:/tmp/

  ssh $FIREWALL_PIP -p ${WEBSERVERS[$server]} "sudo mv /tmp/${server}.* /etc/nginx/ssl/ && \
    echo \"<h1>Hello from ${server}</h1>\" | sudo tee /var/www/html/index.html && \
    sudo systemctl restart nginx"
done

echo "webserver3 port 2293"
WEBSERVER3="webserver3"
WEBSERVER3_PORT=${HOSTS[$WEBSERVER3]}

ssh $FIREWALL_PIP -p $WEBSERVER3_PORT "echo '<h1>Hello from ${WEBSERVER3}</h1>' | sudo tee /var/www/html/index.html && \
  sudo mkdir /root/.secrets && sudo touch /root/.secrets/cloudflare.ini && \
  sudo chmod 0700 /root/.secrets && sudo chmod 0400 /root/.secrets/cloudflare.ini && \
  echo 'dns_cloudflare_api_token=${CF_API_KEY}' | sudo tee /root/.secrets/cloudflare.ini && \
  sudo certbot certonly --agree-tos --no-eff-email -m bradleysearle@gmail.com --dns-cloudflare --dns-cloudflare-credentials /root/.secrets/cloudflare.ini -d 'webserver3.stratuslabs.net' && \
  sudo systemctl restart nginx"
