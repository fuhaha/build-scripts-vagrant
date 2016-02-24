set -x
echo $*
export config_name="$1"
if [ -z $1 ] ; then
	config_name="test1"
fi
export mdbci_dir="$HOME/mdbci"

export curr_dir=`pwd`

cd $mdbci_dir/$config_name

# Number of nodes
export galera_N=`vagrant status | grep galera | wc -l`
export repl_N=`vagrant status | grep node | wc -l`
cd $curr_dir
export new_dirs="yes"

export maxscale_binlog_dir="/var/lib/maxscale/Binlog_Service"
export maxdir="/usr/bin/"
export maxdir_bin="/usr/bin/"
export maxscale_cnf="/etc/maxscale.cnf"
export maxscale_log_dir="/var/log/maxscale/"

cd $mdbci_dir

# IP Of MaxScale machine
maxscale_IP=`./mdbci show network $config_name/maxscale --silent 2> /dev/null`
                # HACK : second attempt to bring node up
                if [ $? != 0 ] ; then
                        cd $config_name
                        vagrant destroy maxscale -f
                        vagrant up maxscale 
			cd ..
                        ip=`./mdbci show network $config_name/maxscale --silent 2> /dev/null`
                fi
export maxscale_IP
export maxscale_sshkey=`./mdbci show keyfile $config_name/maxscale --silent | sed 's/"//g'`

# User name and Password for Master/Slave replication setup (should have all PRIVILEGES)
export repl_user="skysql"
export repl_password="skysql"

# User name and Password for Galera setup (should have all PRIVILEGES)
export galera_user="skysql"
export galera_password="skysql"

export maxscale_user="skysql"
export maxscale_password="skysql"

export maxadmin_password="mariadb"

for prefix in "repl" "galera"
do
	N_var="$prefix"_N
	Nx=${!N_var}
	N=`expr $Nx - 1`
	for i in $(seq 0 $N)
	do
		num=`printf "%03d" $i`
		if [ $prefix == "repl" ] ; then
			node_n="node"
		else
			node_n="$prefix"
		fi
		ip_var="$prefix"_"$num"
		private_ip_var="$prefix"_private_"$num"

		# get IP
		ip=`./mdbci show network $config_name/$node_n$i --silent 2> /dev/null`
		# HACK : second attempt to bring node up
		if [ $? != 0 ] ; then
			cd $config_name
			vagrant destroy $node_n$i -f
		        vagrant up $node_n$i 
			cd ..
			ip=`./mdbci show network $config_name/$node_n$i --silent 2> /dev/null`
		fi
		# get ssh key
   		key=`./mdbci show keyfile $config_name/$node_n$i --silent 2> /dev/null | sed 's/"//g'`

		eval 'export "$prefix"_"$num"=$ip'
		eval 'export "$prefix"_sshkey_"$num"=$key'
		eval 'export "$prefix"_port_"$num"=3306'
	
		# trying to get private IP (for AWS)
#		cd $config_name
		private_ip=`./mdbci show private_ip $config_name/$node_n$i --silent 2> /dev/null`

		eval 'export "$prefix"_private_"$num"="$private_ip"'

		au=`./mdbci ssh --command 'whoami' $config_name/$node_n$i --silent 2> /dev/null | tr -cd "[:print:]" `
		eval 'export "$prefix"_access_user_"$num"="$au"'
		eval 'export "$prefix"_access_sudo_"$num"=sudo'

		server_num=`expr $i + 1`
		start_cmd_var="$prefix"_start_db_command_"$num"
		stop_cmd_var="$prefix"_stop_db_command_"$num"
		mysql_exe=`./mdbci ssh --command 'ls /etc/init.d/mysql* 2> /dev/null | tr -cd "[:print:]"' $config_name/$node_n$i  --silent 2> /dev/null`
		echo $mysql_exe | grep -i "mysql"
		if [ $? != 0 ] ; then
			#./mdbci ssh --command 'echo \"/usr/sbin/mysqld \$* 2> stderr.log > stdout.log &\" > mysql_start.sh; echo \"sleep 20\" >> mysql_start.sh; echo \"disown\" >> mysql_start.sh; chmod a+x mysql_start.sh' $config_name/$node_n$i  --silent
                        # eval 'export $start_cmd_var="/home/$au/mysql_start.sh "'
			service_name=`./mdbci ssh --command 'systemctl list-unit-files | grep mysql' $config_name/$node_n$i  --silent`
			echo $service_name | grep mysql
			if [ $? == 0 ] ; then
				echo $service_name | grep mysqld
				if [ $? == 0 ] ; then
		                        eval 'export $start_cmd_var="service mysqld start "'
	        	                eval 'export $stop_cmd_var="service mysqdl stop  "'
				else
	                        	eval 'export $start_cmd_var="service mysql start "'
	        	                eval 'export $stop_cmd_var="service mysql stop  "'
				fi
			else
	                        ./mdbci ssh --command 'echo \"/usr/sbin/mysqld \$* 2> stderr.log > stdout.log &\" > mysql_start.sh; echo \"sleep 20\" >> mysql_start.sh; echo \"disown\" >> mysql_start.sh; chmod a+x mysql_start.sh' $config_name/$node_n$i  --silent
        	                eval 'export $start_cmd_var="/home/$au/mysql_start.sh "'
				eval 'export $start_cmd_var="killall mysqld "'
			fi
		else
			eval 'export $start_cmd_var="$mysql_exe start "'
			eval 'export $stop_cmd_var="$mysql_exe stop "'
		fi

		eval 'export "$prefix"_start_vm_command_"$num"="\"cd $mdbci_dir/$config_name;vagrant up $node_n$i --provider=$provider; cd $curr_dir\""'
		eval 'export "$prefix"_kill_vm_command_"$num"="\"cd $mdbci_dir/$config_name;vagrant halt $node_n$i --provider=$provider; cd $curr_dir\""'
#		cd ..
	done
done

cd $mdbci_dir
export maxscale_access_user=`./mdbci ssh --command 'whoami' $config_name/maxscale --silent 2> /dev/null | tr -cd "[:print:]" `
export maxscale_access_sudo="sudo "
export maxscale_hostname=`./mdbci ssh --command 'hostname' $config_name/maxscale --silent 2> /dev/null | tr -cd "[:print:]" `
#cd ..

# Sysbench directory (should be sysbench >= 0.5)
export sysbench_dir="$HOME/sysbench_deb7/sysbench/"

export ssl=true
cd $curr_dir
set +x
