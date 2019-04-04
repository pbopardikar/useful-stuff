#!/usr/bin/env bash

set -e

# just set the values for your System & Apps domain & run the script
# the script will output a root certificate, domain certificate & domain key
# paste the contents of root cert into the Trusted Cert field under the Security tab of BOSH Director
# paste the contents of the domain cert, key in the PAS tile's Network tab under "certs & keys for HA Proxy & Router"
# Note: You may need to recreate all the VM's. Check the box "Recreate all VMs" under the Director Config, before you click "Apply Changes"

SYS_DOMAIN=system.mydomain.com
APPS_DOMAIN=apps.mydomain.com

SSL_FILE=sslconf-pas.conf
ROOT_CERT=rootCA
PAS_CERT=pasCA

#Generate SSL Config with SANs
if [ ! -f $SSL_FILE ]; then
cat > $SSL_FILE <<EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
[req_distinguished_name]
countryName_default = US
stateOrProvinceName_default = CA
localityName_default = SF
organizationalUnitName_default = Pivotal
[ v3_req ]
# Extensions to add to a certificate request
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = *.${SYS_DOMAIN}
DNS.2 = *.${APPS_DOMAIN}
DNS.3 = *.login.${SYS_DOMAIN}
DNS.4 = *.uaa.${SYS_DOMAIN}
EOF
fi

openssl genrsa -out ${ROOT_CERT}.key 2048
openssl req -x509 -new -nodes -key ${ROOT_CERT}.key -sha256 -days 1024 -subj "/C=US/ST=CA/O=Pivotal/L=SF/OU=PA/CN=pivotal.io" -out ${ROOT_CERT}.crt

openssl genrsa -out ${PAS_CERT}.key 2048
openssl req -new -out ${PAS_CERT}.csr -subj "/C=US/ST=CA/O=Pivotal/L=SF/OU=PA/CN=pivotal.io" -key ${PAS_CERT}.key -config ${SSL_FILE}
openssl x509 -req -days 3650 -sha256 -in ${PAS_CERT}.csr -CA ${ROOT_CERT}.crt -CAkey ${ROOT_CERT}.key -CAcreateserial -out ${PAS_CERT}.crt -extensions v3_req -extfile ${SSL_FILE}

rm ${ROOT_CERT}.key
rm ${ROOT_CERT}.srl
rm ${PAS_CERT}.csr

