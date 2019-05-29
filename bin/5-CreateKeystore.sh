#!/bin/sh

. ./0-SSLProps.sh

JAVA_HOME=/usr/java/jdk1.8.0_211
JAVA_SEC_LIB=$JAVA_HOME/jre/lib/security/
PATH=$JAVA_HOME/bin:$PATH

for i in ${HOSTS}
do
    HOST=$(echo ${i} | awk -F',' '{print $1}')
    CN=${HOST}
    openssl pkcs12 -export -inkey ${HOST}.key -in ${HOST}.pem -passin pass:${PASSWORD} -out ${HOST}.p12 -passout pass:${PASSWORD} -name ${CN}
    keytool -importkeystore -alias ${CN} -srckeystore ${HOST}.p12 -srcstoretype PKCS12 -srcstorepass ${PASSWORD} -destkeystore ${HOST}.jks -deststoretype JKS -deststorepass ${PASSWORD}
done

cp $JAVA_SEC_LIB/cacerts ./jssecacerts

keytool -import -trustcacerts -keystore jssecacerts -alias rootca -storepass changeit -file rootca.pem -noprompt
keytool -importcert -keystore cdh.truststore -alias rootca -file rootca.pem -storepass ${PASSWORD} -noprompt
