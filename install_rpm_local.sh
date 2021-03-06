#!/bin/bash 

# do the real building work
# this script is executed on build VM

set -x

cd $work_dir

sudo yum install -y rpmdevtools git
sudo yum install -y wget
sudo yum install -y tcl
sudo yum install -y libuuid-devel
sudo yum install -y xz-devel
sudo zypper -n install rpmdevtools
sudo zypper -n install git
sudo zypper -n install wget
sudo zypper -n install tcl
sudo zypper -n install libuuid-devel
sudo zypper -n install xz-devel


#wget http://pkgs.repoforge.org/flex/flex-2.5.35-0.8.el5.rfb.x86_64.rpm
wget http://maxscale-jenkins.mariadb.com/x/flex-2.5.35-0.8.el5.rfb.x86_64.rpm
#sudo yum install -
sudo yum install flex-2.5.35-0.8.el5.rfb.x86_64.rpm -y --nogpgcheck 
rm flex-2.5.35-0.8.el5.rfb.x86_64*
. ~/check_arch.sh

yum --version
if [ $? != 0 ] ; then
	sudo zypper -n install rpm-build
	zy=1
else
	sudo yum install -y rpm-build createrepo yum-utils
	zy=0
fi

if [ "$use_mariadbd" == "yes" ] ; then
	rm $mariadbd_file
	wget  --retry-connrefused $mariadbd_link
	sudo tar xzvf $mariadbd_file -C /usr/ --strip-components=1
	cmake_flags+=" -DERRMSG=/usr/share/english/errmsg.sys -DMYSQL_EMBEDDED_LIBRARIES=/usr/lib/ "
fi


if [ $zy != 0 ] ; then
  sudo zypper -n install gcc gcc-c++ ncurses-devel bison glibc-devel libgcc_s1 perl make libtool libopenssl-devel libaio libaio-devel 
  sudo zypper -n install flex
#  sudo zypper -n install librabbitmq-devel
  sudo zypper -n install libcurl-devel
  sudo zypper -n install pcre-devel
  cat /etc/*-release | grep "SUSE Linux Enterprise Server 11"
  if [ $? != 0 ] ; then 
    sudo zypper -n install libedit-devel
  fi

  sudo zypper -n install systemtap-sdt-devel

else
  sudo yum clean all 
  sudo yum install -y --nogpgcheck gcc gcc-c++ ncurses-devel bison glibc-devel libgcc perl make libtool openssl-devel libaio libaio-devel libedit-devel
  sudo yum install -y --nogpgcheck libedit-devel
  sudo yum install -y --nogpgcheck libcurl-devel
  sudo yum install -y --nogpgcheck curl-devel
  sudo yum install -y --nogpgcheck systemtap-sdt-devel
  sudo yum install -y --nogpgcheck rpm-sign
  sudo yum install -y --nogpgcheck gnupg
  sudo yum install -y --nogpgcheck pcre-devel
  sudo yum install -y --nogpgcheck flex
# sudo yum install -y libaio 

  cat /etc/redhat-release | grep "release 5"
  if [[ $? == 0 ]] ; then
      sudo yum remove -y libedit-devel libedit
  fi
fi

mkdir rabbit
cd rabbit
git clone https://github.com/alanxz/rabbitmq-c.git
if [ $? != 0 ] ; then
        echo "Error cloning rabbitmq-c"
        exit 1
fi
cd rabbitmq-c
git checkout v0.7.1
cmake .  -DCMAKE_C_FLAGS=-fPIC -DBUILD_SHARED_LIBS=N  -DCMAKE_INSTALL_PREFIX=/usr
sudo make install
cd ../../

mkdir tcl
cd tcl
wget --no-check-certificate http://prdownloads.sourceforge.net/tcl/tcl8.6.5-src.tar.gz
if [ $? != 0 ] ; then
        echo "Error getting tcl"
        exit 1
fi
tar xzvf tcl8.6.5-src.tar.gz
cd tcl8.6.5/unix
./configure
sudo make install
cd ../../..


# SQLite3
sudo yum install -y sqlite sqlite-devel pkgconfig
sudo zypper install -y sqlite3 sqlite3-devel pkg-config

# Jansson
git clone https://github.com/akheron/jansson.git
if [ $? != 0 ] ; then
    echo "Error cloning jansson"
    exit 1
fi

mkdir -p jansson/build
pushd jansson/build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_C_FLAGS=-fPIC -DJANSSON_INSTALL_LIB_DIR=/usr/lib64
make
sudo make install
popd

# Avro C API
wget http://mirror.netinch.com/pub/apache/avro/avro-1.8.0/c/avro-c-1.8.0.tar.gz
if [ $? != 0 ] ; then
    echo "Error getting avro-c"
    exit 1
fi

tar -axf avro-c-1.8.0.tar.gz
mkdir avro-c-1.8.0/build
pushd avro-c-1.8.0/build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_C_FLAGS=-fPIC -DCMAKE_CXX_FLAGS=-fPIC
make
sudo make install
popd

# Install Lua packages
sudo yum -y install lua lua-devel
sudo zypper -y install lua lua-devel

