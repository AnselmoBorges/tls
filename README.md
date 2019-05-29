# Preparo e implantação de certificados SSL

Agora, para SSL / TLS, começaremos executando <a href="bin"> esses scripts </a> em um único nó na ordem. Você pode inspecionar cada um para ver o que eles fazem, mas em resumo, criamos nossa própria Autoridade de Certificação (autoridade de certificação raiz) junto com uma CA intermediária que emite os certificados assinados e criamos os formatos x509 e Java Keystore (JKS) para cada um, juntamente com em ambos os formatos. Uma vez criado, inspecione o conteúdo de cada usando **keytool -list -keystore keystore.jks-storepass** (para JKS) e **openssl x509 -in cert.pem -text -noout**. Você também pode verificar a validade do certificado x509 via openssl verify -CAfile cacerts cert.pem. Observe que os certificados criados devem ter as extensões:

```
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names
```

onde subjectAltName é o nome completo do nome do host. Se um balanceador de carga for usado para serviços em execução no host, você também deverá incluir o nome completo do balanceador de carga na lista de nomes alternativos. Por exemplo:

```
subjectAltName = node1.mydomain.com,loadbalancer.mydomain.com
```

A ordem na qual executar os scripts é a seguinte, mas antes disso, edite 0-SSLProps.sh para garantir que HOSTS seja a lista de nomes de domínio completos para os nós do cluster junto com os nomes do balanceador de carga, se a alta disponibilidade for ativada. O formato é "fqdn.host.1, fqdn.load.balancer fqdn.host.2, fqdn.load.balancer ... fqdn.host.n", embora seja possível omitir o nome do balanceador de carga para nós que não serão executados qualquer função de balanceamento de carga:

```
./1-Cleanup.sh
./2-RootCA.sh
./3-IntermediateCA.sh
./4-SignedCerts.sh
./5-CreateKeystore.sh
```

Outro script que deve ser alterado é o ultimo **5-CreateKeystore.sh** onde vem o parâmetro do JAVA_HOME, garanta que alem do JDK você tenha o JRE tambem.

Em seguida, em cada host, crie a estrutura de diretórios para os certificados e copie cada certificado para o host correspondente, e os CAcerts e cdh.truststore para todos os nós:

```
mkdir -p /opt/cloudera/security/jks
mkdir -p /opt/cloudera/security/x509
mkdir -p /opt/cloudera/security/truststore
mkdir -p /opt/cloudera/security/CAcerts

cp ${HOST}.jks /opt/cloudera/security/jks
cp ${HOST}.key /opt/cloudera/security/x509
cp ${HOST}.pem /opt/cloudera/security/x509
cp pkey.pass   /opt/cloudera/security/x509
cp cdh.truststore jssecacerts /opt/cloudera/security/truststore
cp cacerts rootca.pem intermediateca.pem /opt/cloudera/security/CAcerts

chmod 400 /opt/cloudera/security/x509/pkey.pass
chmod 400 /opt/cloudera/security/x509/${HOST}.key
chmod 444 /opt/cloudera/security/x509/${HOST}.pem
chmod 444 /opt/cloudera/security/jks/${HOST}.jks

ln -s /opt/cloudera/security/x509/${HOST}.key /opt/cloudera/security/x509/sslcert.key
ln -s /opt/cloudera/security/x509/${HOST}.pem /opt/cloudera/security/x509/sslcert.pem
ln -s /opt/cloudera/security/jks/${HOST}.jks /opt/cloudera/security/jks/cdh.keystore
```
