from cdtfiji01.calix.local:5000/centos/dev

MAINTAINER Tao.H the@calix.com

RUN wget -q http://cdtfiji01.calix.local/hadoop-2.7.1.tar.gz ;\
tar xzf hadoop-2.7.1.tar.gz -C /opt ; \
rm -f hadoop-2.7.1.tar.gz ;\
cd hadoop-2.7.1/share/hadoop/common/lib;\
export http_proxy=http://172.29.1.8:3128;\
export HTTP_PROXY=http://172.29.1.8:3128;\
export https_proxy=http://172.29.1.8:3128;\
export HTTPS_PROXY=http://172.29.1.8:3128;\
wget http://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/2.7.1/hadoop-aws-2.7.1.jar;\
wget http://central.maven.org/maven2/com/amazonaws/aws-java-sdk/1.7.4/aws-java-sdk-1.7.4.jar;\
wget http://central.maven.org/maven2/com/fasterxml/jackson/core/jackson-databind/2.2.3/jackson-databind-2.2.3.jar;\
wget http://central.maven.org/maven2/com/fasterxml/jackson/core/jackson-annotations/2.2.3/jackson-annotations-2.2.3.jar;\
wget http://central.maven.org/maven2/com/fasterxml/jackson/core/jackson-core/2.1.3/jackson-core-2.1.3.jar;\
echo "export PATH=$PATH:/opt/hadoop-2.7.1/bin" >> /etc/bashrc;

expose 22

CMD /usr/sbin/sshd -D
