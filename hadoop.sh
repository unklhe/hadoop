#!/bin/bash


if [ $# -gt 0 ] && [ "$1" == "-h" ] ; then
  echo "Usage: hadoop.sh [cluster quantity [cluster-name]]"
  exit 0
fi

which sshpass 1>/dev/null
if [ $? != 0 ] ; then
  echo "Install sshpass first"
  echo "  yum install -y epel-release"
  echo "  yum --enablerepo=epel -y install sshpass"
  exit 1
fi


password=itsme
cluster=hadoop-node
if [ $# -gt 1 ] ; then
  cluster=$2
fi

registry=
docker ps -a --filter name=${cluster} | grep ${cluster} 1>/dev/null

if [ $? == 0 ] ; then
  echo "[Warning] Cluster already exists, remove it fist!"
  docker ps -a --filter name=${cluster}
  exit 1
fi
echo "1. Run containers ..."
docker run -d --name ${cluster}1 -h ${cluster}1 -p 50070:50070 -p 8088:8088 -p 19888:19888 ${registry}hadoop
#docker run --name ${cluster}1 -h ${cluster}1 -p 50070:50070 -p 8088:8088 -p 9000 -p 8032 centos:hadoop >/dev/null 2>&1 &
count=1
if [ $# -gt 0 ] ; then
  count=$1
  for i in $(seq 2 $1) ; do
    docker run -d --name ${cluster}$i -h ${cluster}$i ${registry}hadoop
    sleep 1
  done
fi

sleep 5

echo "2. Configure hosts name ..."
rm -f /tmp/.hosts
for i in $(seq 1 $count); do
  sed -i "/${cluster}${i}/d" /etc/hosts 2>/dev/null
  ip=`docker inspect ${cluster}$i |grep "\"IPAddress\""| awk '{print substr($2,2, length($2)-3)}'|uniq`
  if [ "${ip}" != "" ] ; then
    ssh-keygen -R ${ip} 2>/dev/null
    ssh-keygen -R ${cluster}$i 2>/dev/null
    echo "${ip}    ${cluster}$i"
    echo "${ip}    ${cluster}$i">>/tmp/.hosts
  fi
done

for i in $(seq 1 $count); do
  ip=`docker inspect ${cluster}$i |grep "\"IPAddress\""| awk '{print substr($2,2, length($2)-3)}'|uniq`
  if [ "${ip}" != "" ] ; then
    sshpass -p ${password} scp -o StrictHostKeychecking=no /tmp/.hosts root@${ip}:/tmp 2>/dev/null
    sshpass -p ${password} ssh -o StrictHostKeychecking=no root@${ip} "echo ''>>/etc/hosts; cat /tmp/.hosts >>/etc/hosts; rm -f /tmp/.hosts" 2>/dev/null
  fi
done

cat /tmp/.hosts >> /etc/hosts
rm -f /tmp/.hosts

echo "3. Start Hadoop ..."
#ip=`docker inspect ${cluster}1 |grep "\"IPAddress\""| awk '{print substr($2,2, length($2)-3)}'`
#sshpass -p ${password} ssh root@${ip} /opt/hadoop-2.7.1/bin/startmaster.sh
cp etc/core-site.xml.template core-site.xml
cp etc/yarn-site.xml.template yarn-site.xml
cp etc/mapred-site.xml.template mapred-site.xml
sed -i s/0.0.0.0/${cluster}1/g /usr/local/hadoop/etc/hadoop/core-site.xml
sed -i s/0.0.0.0/${cluster}1/g /usr/local/hadoop/etc/hadoop/yarn-site.xml
sed -i s/0.0.0.0/${cluster}1/g /usr/local/hadoop/etc/hadoop/mapred-site.xml
for i in $(seq 1 $count); do
  ip=`docker inspect ${cluster}$i |grep "\"IPAddress\""| awk '{print substr($2,2, length($2)-3)}'|uniq`
  sshpass -p ${password} scp *.xml root@${ip}:/usr/local/hadoop/etc/hadoop
  if [ $i == 1 ] ; then
    sshpass -p ${password} ssh root@${ip} hdfs namenode -format -force -nonInteractive
    sshpass -p ${password} ssh root@${ip} "nohup hdfs namenode >/tmp/namenode.log 2>&1 &"
    sshpass -p ${password} ssh root@${ip} "nohup yarn resourcemanager >/tmp/resourcemanager.log 2>&1 &"
    if [ $count == 1 ] ; then
      sshpass -p ${password} ssh root@${ip} "nohup hdfs datanode >/tmp/datanode.log 2>&1 &"
      sshpass -p ${password} ssh root@${ip} "nohup yarn nodemanager >/tmp/nodemanager.log 2>&1 &"
    fi
  else
    sshpass -p ${password} ssh -o StrictHostKeychecking=no root@${ip} "nohup hdfs datanode >/tmp/datanode.log 2>&1 &"
    sshpass -p ${password} ssh -o StrictHostKeychecking=no root@${ip} "nohup yarn nodemanager >/tmp/nodemanager.log 2>&1 &"
  fi
done

rm -f *.xml

echo -e "\nDone"