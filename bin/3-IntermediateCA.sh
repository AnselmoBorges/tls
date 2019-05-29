#!/bin/sh

. ./0-SSLProps.sh

WORKDIR=$PWD/ca

mkdir $WORKDIR/intermediate
pushd $WORKDIR/intermediate
mkdir -p certs crl csr newcerts private
chmod 700 private
touch index.txt
echo 1002 > serial
echo 1002 > $WORKDIR/intermediate/crlnumber

cat > openssl.cnf << EOF
[ ca ]
# \`man ca\`
default_ca = CA_default

[ CA_default ]
# Directory and file locations.
dir               = $WORKDIR/intermediate
certs             = \$dir/certs
crl_dir           = \$dir/crl
new_certs_dir     = \$dir/newcerts
database          = \$dir/index.txt
serial            = \$dir/serial
RANDFILE          = \$dir/private/.rand

# The root key and root certificate.
private_key       = \$dir/private/intermediateca.key.pem
certificate       = \$dir/certs/intermediateca.cert.pem

# For certificate revocation lists.
crlnumber         = \$dir/crlnumber
crl               = \$dir/crl/intermediate.crl.pem
crl_extensions    = crl_ext
default_crl_days  = 30
default_md        = sha256

name_opt          = ca_default
cert_opt          = ca_default
default_days      = 365
preserve          = no
policy            = policy_loose

[ policy_loose ]
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ req ]
# Options for the \`req\` tool (\`man req\`).
default_bits        = 2048
distinguished_name  = req_distinguished_name
string_mask         = utf8only
default_md          = sha256
x509_extensions     = v3_ca

[ req_distinguished_name ]
countryName                     = Country Name (2 letter code)
stateOrProvinceName             = State or Province Name
localityName                    = Locality Name
0.organizationName              = Organization Name
organizationalUnitName          = Organizational Unit Name
commonName                      = Common Name
emailAddress                    = Email Address

countryName_default             = ${COUNTRY}
stateOrProvinceName_default     = ${STATE}
localityName_default            = ${LOCALITY}
0.organizationName_default      = ${ORGNAME}
organizationalUnitName_default  = ${ORGUNIT}
emailAddress_default            = ${EMAIL}

[ v3_ca ]
# Extensions for a typical CA (\`man x509v3_config\`).
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ server_cert ]
# Extensions for server certificates (\`man x509v3_config\`).
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names

EOF

# Generate IntermediateCA Key and Cert
NAME=intermediateca

openssl req -config openssl.cnf -new -newkey rsa:2048 -sha256 -keyout private/${NAME}.key -out csr/${NAME}.csr -nodes -subj "/C=${COUNTRY}/ST=${STATE}/L=${LOCALITY}/O=${ORGNAME}/OU=${ORGUNIT}/CN=${NAME}"

pushd  ..
openssl ca -config openssl.cnf -extensions v3_intermediate_ca -days 3650 -notext -md sha256 -in intermediate/csr/${NAME}.csr -out intermediate/certs/${NAME}.pem -batch
popd

pushd private; ln -s ${NAME}.key intermediateca.key.pem;  popd
pushd certs;   ln -s ${NAME}.pem intermediateca.cert.pem; popd

openssl x509 -noout -text -in certs/${NAME}.pem
openssl verify -CAfile ../certs/ca.cert.pem certs/${NAME}.pem

popd

cp ca/intermediate/certs/${NAME}.pem ./${NAME}.pem
