#!/bin/sh

. ./0-SSLProps.sh

WORKDIR=$PWD

mkdir $WORKDIR/ca
pushd $WORKDIR/ca
mkdir -p certs crl newcerts private
chmod 700 private
touch index.txt
echo 1001 > serial

cat > openssl.cnf << EOF
[ ca ]
# \`man ca\`
default_ca = CA_default

[ CA_default ]
# Directory and file locations.
dir               = $WORKDIR/ca
certs             = \$dir/certs
crl_dir           = \$dir/crl
new_certs_dir     = \$dir/newcerts
database          = \$dir/index.txt
serial            = \$dir/serial
RANDFILE          = \$dir/private/.rand

# The root key and root certificate.
private_key       = \$dir/private/ca.key.pem
certificate       = \$dir/certs/ca.cert.pem

# For certificate revocation lists.
crlnumber         = \$dir/crlnumber
crl               = \$dir/crl/ca.crl.pem
crl_extensions    = crl_ext
default_crl_days  = 30
default_md        = sha256

name_opt          = ca_default
cert_opt          = ca_default
default_days      = 365
preserve          = no
policy            = policy_strict

[ policy_strict ]
# The root CA should only sign intermediate certificates that match.
# See the POLICY FORMAT section of \`man ca\`.
countryName             = match
stateOrProvinceName     = match
organizationName        = match
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

[ v3_intermediate_ca ]
# Extensions for a typical intermediate CA (\`man x509v3_config\`).
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true, pathlen:0
keyUsage = critical, digitalSignature, cRLSign, keyCertSign
EOF

# Generate RootCA Key and Cert
NAME=rootca

openssl req -config openssl.cnf -new -newkey rsa:4096 -days 7300 -sha256 -extensions v3_ca -nodes -x509 -subj "/C=${COUNTRY}/ST=${STATE}/L=${LOCALITY}/O=${ORGNAME}/OU=${ORGUNIT}/CN=${NAME}" -keyout private/${NAME}.key -out certs/${NAME}.pem

# Verify RootCA certificate
openssl x509 -noout -text -in certs/${NAME}.pem

pushd certs;   ln -s ${NAME}.pem ca.cert.pem; popd
pushd private; ln -s ${NAME}.key ca.key.pem;  popd

popd

cp ca/certs/${NAME}.pem ./${NAME}.pem
