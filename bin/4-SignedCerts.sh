#!/bin/sh

. ./0-SSLProps.sh

echo ${PASSWORD} > pkey.pass

for i in $HOSTS
do
    HOST=$(echo ${i} | awk -F',' '{print $1}')
    CN=${HOST}
    ENTRY=2
    cp ca/intermediate/openssl.cnf .
    cat >> openssl.cnf << EOF
[alt_names]
DNS.1 = ${CN}
EOF
    for SAN in $(echo ${i} | sed 's/,/ /g')
    do
        if [ "${HOST}" != "${SAN}" ]; then
            cat >> openssl.cnf << EOF
DNS.${ENTRY} = ${SAN}
EOF
            ENTRY=$((ENTRY + 1))
        fi
    done

    openssl req -config openssl.cnf -reqexts server_cert -new -newkey rsa:2048 -sha256 -keyout ${HOST}.key -out ${HOST}.csr -subj "/C=${COUNTRY}/ST=${STATE}/L=${LOCALITY}/O=${ORGNAME}/OU=${ORGUNIT}/CN=${CN}" -passin pass:${PASSWORD} -passout pass:${PASSWORD}

#   Create signed cert with intermediate CA and server_cert extensions (which include serverAuth and clientAuth for multiple use and TLS3)
    openssl ca -config openssl.cnf -extensions server_cert -days 365 -notext -md sha256 -in ${HOST}.csr -out ${HOST}.pem -batch

#   Append the intermediate CA cert to the cert itself (if self-signed), otherwise you need to only append the untrusted ones and leave trusted ones in CA chain
    cat intermediateca.pem rootca.pem >> ${HOST}.pem
done

cat intermediateca.pem rootca.pem > cacerts
