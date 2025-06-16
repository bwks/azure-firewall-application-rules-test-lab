#!/bin/bash
# https://learn.microsoft.com/en-us/azure/firewall/premium-certificates

CERT_DIR="./cert";
mkdir $CERT_DIR;

# Create root CA
openssl req -x509 -new -nodes -newkey rsa:4096 -keyout $CERT_DIR/rootCA.key -sha256 -days 1024 -out $CERT_DIR/rootCA.crt -subj "/C=AU/ST=Queensland/O=StuffandThings/CN=StuffandThings Root CA" -config openssl.cnf -extensions rootCA_ext

openssl pkcs12 -export -out $CERT_DIR/rootCA.pfx -inkey $CERT_DIR/rootCA.key -in $CERT_DIR/rootCA.crt -password "pass:"

# Create intermediate CA request
openssl req -new -nodes -newkey rsa:4096 -keyout $CERT_DIR/interCA.key -sha256 -out $CERT_DIR/interCA.csr -subj "/C=AU/ST=Queensland/O=StuffandThings/CN=StuffandThings Intermediate CA"

# Sign on the intermediate CA
openssl x509 -req -in $CERT_DIR/interCA.csr -CA $CERT_DIR/rootCA.crt -CAkey $CERT_DIR/rootCA.key -CAcreateserial -out $CERT_DIR/interCA.crt -days 1024 -sha256 -extfile openssl.cnf -extensions interCA_ext

# Export the intermediate CA into PFX
openssl pkcs12 -export -out $CERT_DIR/interCA.pfx -inkey $CERT_DIR/interCA.key -in $CERT_DIR/interCA.crt -password "pass:"

# webservers
for i in {1..2}
do
  openssl genrsa -out $CERT_DIR/webserver$i.key 2048

  openssl req -new -key $CERT_DIR/webserver$i.key -out $CERT_DIR/webserver$i.csr \
    -subj "/C=AU/ST=Queensland/L=Brisbane/O=StuffandThings/CN=webserver$i.stuffandthings.internal" \
    -addext "subjectAltName=DNS:webserver$i.stuffandthings.internal"

  openssl x509 -req -in $CERT_DIR/webserver$i.csr -CA $CERT_DIR/interCA.crt -CAkey $CERT_DIR/interCA.key -CAcreateserial \
    -out $CERT_DIR/webserver$i-alone.crt -days 365 -sha256 -extfile <(printf "subjectAltName=DNS:webserver$i.stuffandthings.internal")

  cat $CERT_DIR/webserver$i-alone.crt $CERT_DIR/interCA.crt $CERT_DIR/rootCA.crt > $CERT_DIR/webserver$i.crt
done

echo ""
echo "================"
echo "Successfully generated root and intermediate CA certificates"
echo "   - rootCA.crt/rootCA.key - Root CA public certificate and private key"
echo "   - interCA.crt/interCA.key - Intermediate CA public certificate and private key"
echo "   - interCA.pfx - Intermediate CA pkcs12 package which could be uploaded to Key Vault"
echo "================"
