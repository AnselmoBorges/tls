#!/bin/bash

## Script central da criação dos arquivos de SSL/TLS:

## Variaveis:
export DIR_HOME=$HOME/tls/bin

## Execução dos scripts:
cd $DIR_HOME
sh 0-SSLProps.sh
sh 1-Cleanup.sh
sh 2-RootCA.sh
sh 3-IntermediateCA.sh
sh 4-SignedCerts.sh
sh 5-CreateKeystore.sh
sh 6-CreateDirectories.sh


