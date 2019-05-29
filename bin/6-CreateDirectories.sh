#!/bin/bash
## Criação de diretorios e movimentação dos arquivos:

## Variaveis:
export DIR=/opt/cloudera/security2
export HOST=`hostname`

## Limpa anteriores
rm -rf $DIR

## Cria diretórios
mkdir -p $DIR/jks
mkdir -p $DIR/x509
mkdir -p $DIR/truststore
mkdir -p $DIR/CAcerts

## Movimenta arquivos:
mv ${HOST}.jks $DIR/jks/
mv ${HOST}.key $DIR/x509/
mv ${HOST}.pem $DIR/x509/
mv pkey.pass   $DIR/x509/
mv cdh.truststore jssecacerts $DIR/truststore/
mv cacerts rootca.pem intermediateca.pem $DIR/CAcerts/

## Muda os privilégios dos certificados
chmod 400 $DIR/x509/pkey.pass
chmod 400 $DIR/x509/${HOST}.key
chmod 444 $DIR/x509/${HOST}.pem
chmod 444 $DIR/jks/${HOST}.jks

## Criando links simbólicos:
ln -s $DIR/x509/${HOST}.key $DIR/x509/sslcert.key
ln -s $DIR/x509/${HOST}.pem $DIR/x509/sslcert.pem
ln -s $DIR/jks/${HOST}.jks $DIR/jks/cdh.keystore

## Mudando o owner da pasta security:
chown -R cloudera-scm:cloudera-scm $DIR
