#!/bin/bash

set -e

CONTAINER_NAME=cpprestsdk_example_1


echo " - Check for correct user rights ..."
if [ "$EUID" -ne 0 ]; then
	echo "Please run this script as root!"
	exit 1
fi

echo " - Check if old container is running"
CONTAINER=$(docker ps -a | grep "${CONTAINER_NAME}" || [[ $? == 1 ]])

if [ ! -z "$CONTAINER" ]; then
	CONT_ID=$(echo "$CONTAINER" | awk ' { print $1 }')
	echo " - Found old container with id '${CONT_ID}'."

	docker rm -f "${CONT_ID}"
else
	echo " - No old container. Nothing to do here."
fi

echo " - Start centos container"

docker run -it -d --name "${CONTAINER_NAME}" -p 22 centos:latest sleep inf

#
# make update
#

docker exec -it "${CONTAINER_NAME}" bash -c "yum update -y"

#
# install relevant development tools
#

# install wget and all GNU compiler stuff
docker exec -it "${CONTAINER_NAME}" bash -c "yum groupinstall -y \"Development Tools\" && yum install -y wget"
docker exec -it "${CONTAINER_NAME}" bash -c "yum install openssl-devel"
docker exec -it "${CONTAINER_NAME}" bash -c "yum install -y centos-release-scl && yum update -y && yum install -y devtoolset-7"
# download cmake and build it
docker exec -it "${CONTAINER_NAME}" bash -c "cd /root && git clone https://github.com/Kitware/cmake"
docker exec -it "${CONTAINER_NAME}" bash -c "cd /root/cmake && ./bootstrap && make && make install"
docker exec -it "${CONTAINER_NAME}" bash -c "cmake --version"
# download boost 1.68 and compile
docker exec -it "${CONTAINER_NAME}" bash -c "cd /root && wget https://dl.bintray.com/boostorg/release/1.68.0/source/boost_1_68_0.tar.gz"
docker exec -it "${CONTAINER_NAME}" bash -c "cd /root && tar xvf boost_1_68_0.tar.gz"
docker exec -it "${CONTAINER_NAME}" bash -c "cd /root/boost_1_68_0 && ./bootstrap.sh --prefix=/root/boost && ./b2 install"
# download cpprestsdk and compile it
docker exec -it "${CONTAINER_NAME}" bash -c "cd /root && git clone https://github.com/microsoft/cpprestsdk"
docker exec -it "${CONTAINER_NAME}" bash -c "cd /root/cpprestsdk && git submodule update --init"
docker exec -it "${CONTAINER_NAME}" bash -c "cd /root/cpprestsdk && cmake -G \"Unix Makefiles\" . && make "

