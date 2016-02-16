yum install -y wget
#wget -Uvh http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm
#rpm -Uvh epel-release-6-8.noarch.rpm

yum install -y gcc gcc-c++ make
wget --tries=10 http://www.cmake.org/files/v2.8/cmake-2.8.12.2.tar.gz --no-check-certificate
tar xzvf cmake-2.8.12.2.tar.gz
cd cmake-2.8.12.2
./bootstrap
gmake
make install
