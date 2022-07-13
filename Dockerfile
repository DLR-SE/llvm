FROM ubuntu

RUN apt-get update && apt-get -y --no-install-recommends install\
   software-properties-common build-essential g++ git apt-utils gawk cmake texinfo expat zlib1g-dev flex bison clang python3-dev lld bash diffutils python3-psutil python3-distutils wget

COPY [ "entrypoint.sh", "/opt/" ]

RUN chmod a+rwx /opt/entrypoint.sh

ENTRYPOINT ["/opt/entrypoint.sh"]
