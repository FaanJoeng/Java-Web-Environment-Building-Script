#!/bin/bash
#Author: Yang Fan fan.yang04<AT>hand-china.com
#Date: Jan 10, 2018
#Build basic java web running environment on Linux, only tested on CentOS-7-x86_64-1708 minimal.
#You can revise this script freely depending on your demand.

# TODO 1. 完成mysql,oracle,jenkins安装函数编写 2.redis服务化 3.权限优化

# 获取软件存放目录
PACKAGES_DIRECTORY=$1

# 检查是否为Root用户
[ $(id -u) != "0" ] && { echo -e "\033[31mError: Please make sure you own root permission to run this script!\033[0m"; exit 1; }

export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin


# 安装git（源码方式）

#tar -zxf git-2.9.5.tar.gz
#cd ./git-2.9.5 
#./configure --prefix=/usr/local
#ls -s  /usr/local/bin/git /usr/bin/git

# 开放端口
#iptables -A INPUT -p tcp --dport 80 -j ACCEPT

# 安装编译及权限控制相关包
function install_common_tools() {
  for package in make gcc gcc-c++ iptables iptables-service
  do
	  yum -y install $package
  done
}

# 安装jdk
function install_jdk() {
	for package in `ls ${PACKAGES_DIRECTORY}`
	do
		if [[ $package =~ "jdk" ]] && [[ "$package" =~ ".tar.gz" ]]; then
		  tar -zxf "${PACKAGES_DIRECTORY}""${package}" -C "${PACKAGES_DIRECTORY}"
		  # 将解压后的安装包移进安装目录
		  for decompressed_package in `ls ${PACKAGES_DIRECTORY}`
		  do
        if [[ $decompressed_package =~ "jdk" ]] && [[ ! $decompressed_package =~ ".tar.gz" ]]; then
           cp -r  "${PACKAGES_DIRECTORY}""${decompressed_package}" /usr/local/ 
           JAVA_HOME="/usr/local/""${decompressed_package}"
        fi  
		  done	
		fi  
	done	
  
  # 配置JDK环境变量并使之生效
  echo "export JAVA_HOME=${JAVA_HOME} 
  export JRE_HOME=${JAVA_HOME}/jre 
  export PATH=$JAVA_HOME/bin:$PATH 
  export CLASSPATH=$JAVA_HOME/jre/lib/ext:$JAVA_HOME/lib/tools.jar" >> /etc/profile
  source /etc/profile

  printf "Jdk installed successfully!\n\n"

  java -version

  printf "\n"
}

# 安装git
function install_git() {
	yum -y install git-core
	git --version
}

# 安装Tomcat
function install_tomcat() {
	for package in `ls ${PACKAGES_DIRECTORY}`
	do
		if [[ $package =~ "tomcat" ]] && [[ $package =~ ".tar.gz" ]]; then
		  tar -zxf "${PACKAGES_DIRECTORY}""${package}" -C "${PACKAGES_DIRECTORY}"
		  # 将解压后的安装包移进安装目录
		  for decompressed_package in `ls ${PACKAGES_DIRECTORY}`
		  do
        if [[ $decompressed_package =~ "apache-tomcat" ]] && [[ ! $decompressed_package =~ ".tar.gz" ]]; then
           cp -r  "${PACKAGES_DIRECTORY}""${decompressed_package}" /usr/local/ 
           CATALINA_HOME="/usr/local/""${decompressed_package}/"
        fi  
		  done	
		fi  
	done	
  
  # 如tomcat正在运行 则杀死进程
  # ps -ef | grep tomcat | awk 'NR==1{print $2}' | kill -9
  # 启动Tomcat
  "${CATALINA_HOME}""bin/startup.sh"

  printf "Tomcat installed and langching successfully!\n\n"
}

# 安装Jenkins TODO
function install_jenkins() {
	for package in `ls ${PACKAGES_DIRECTORY}`
  do
    if [[ $package =~ "jenkins" ]] && [[ $package =~ ".rpm" ]]; then
      rpm -ivh "${PACKAGES_DIRECTORY}""${package}"
      
      sed -i -e "/^\/usr\/bin\/java*/a\\${JAVA_HOME}\/bin\/java" /etc/init.d/jenkins
      
      systemctl enable jenkins
      systemctl start jenkins
    fi  
  done
}

# 编译安装Redis
function install_redis() {
  yum -y install gcc gcc-c++
  for package in `ls ${PACKAGES_DIRECTORY}`
	  do
		  if [[ $package =~ "redis" ]] && [[ "$package" =~ ".tar.gz" ]]; then
		    tar -zxf "${PACKAGES_DIRECTORY}""${package}" -C "${PACKAGES_DIRECTORY}"
		    # 进入解压后的目录编译安装
		    for decompressed_package in `ls ${PACKAGES_DIRECTORY}`
		      do
            if [[ $decompressed_package =~ "redis" ]] && [[ ! $decompressed_package =~ ".tar.gz" ]]; then
              cd "${PACKAGES_DIRECTORY}"$decompressed_package
              make && make PREFIX=/usr/local/redis install 
              mkdir -p /usr/local/redis/etc/
              cp redis.conf /usr/local/redis/etc/redis.conf 
              
              # redis服务化
              cp "${PACKAGES_DIRECTORY}"$decompressed_package/utils/redis_init_script /etc/init.d/redis 
              
              sed -i "1i # description:  Redis is a persistent key-value database" /etc/init.d/redis
              sed -i "1i # chkconfig:   2345 90 10" /etc/init.d/redis
              chkconfig redis on
              systemctl start redis
            fi  
		     done	
		  fi  
	  done	
  printf "Redis installed successfully!\n\n"
}

# Oracle数据库安装
function install_oracle_db() {
  # 安装依赖
  yum -y install binutils compat-libcap1 compat-libstdc++-33 gcc gcc-c++ glibc glibc-devel ksh libgcc libstdc++ libstdc++-devel libaio libaio-devel libXext libXtst libX11 libXau libxcb libXi make sysstat unixODBC unixODBC-devel net-tools smartmontools
   
  chmod u+w /etc/sudoers

  sed -i -e '/^root*$/a\oracle    ALL=(ALL)       ALL' /etc/sudoers

  chmod u-w /etc/sudoers

  # 设置内核参数
  echo "fs.aio-max-nr=1048576 
fs.file-max=6815744 
kernel.shmall=2097152 
kernel.shmmax=976003072 
kernel.shmmni=4096 
kernel.sem=250 32000 100 128 
net.ipv4.ip_local_port_range=9000 65500 
net.core.rmem_default=262144 
net.core.rmem_max=4194304 
net.core.wmem_default=262144 
net.core.wmem_max=1048586" >> /etc/sysctl.conf
  
  # 使设置生效
  /sbin/sysctl -p 

  # 配置用户限制
  echo "oracle   soft   nofile    1024  
oracle   hard   nofile    65536  
oracle   soft   nproc    16384  
oracle   hard   nproc    16384  
oracle   soft   stack    10240  
oracle   hard   stack    32768  
oracle   hard   memlock    134217728  
oracle   soft   memlock    134217728 " >> /etc/security/limits.conf

  # 关闭防火墙
  sed -i "/^SELINUX=enforcing*/c\SELINUX=disabled" /etc/selinux/config
  systemctl stop firewalld   
  systemctl disable firewalld   


  # 创建相关用户和组
  groupadd oinstall
  groupadd dba
  groupadd oper
  useradd -g oinstall -G dba,oper oracle
  
  echo "oracle"  | passwd --stdin oracle 
   
  # 安装目录
  mkdir -p /opt/app/oracle/product/12/db_1 

  # 数据目录 
  mkdir -p /opt/app/oracle/oradata

  # 数据恢复目录
  mkdir -p /opt/app/oracle/fast_recovery_area

  # 创建及使用过程日志目录
  mkdir -p /opt/app/oracle/archlog

  chown -R oracle:oinstall /opt/app/oracle

  echo "# Oracle Settings
export TMP=/tmp  
export TMPDIR=$TMP  
  
export ORACLE_HOSTNAME=oracle12 
export ORACLE_UNQNAME=cdb  
export ORACLE_BASE=/opt/app/oracle  
export ORACLE_HOME=/opt/app/oracle/product/12/db_1  
export ORACLE_SID=cdb  
  
export PATH=/usr/sbin:$PATH  
export PATH=/opt/app/oracle/product/12/db_1/bin:$PATH  
  
export LD_LIBRARY_PATH=/opt/app/oracle/product/12/db_1/lib:/lib:/usr/lib  
export CLASSPATH=/opt/app/oracle/product/12/db_1/jlib:/opt/app/oracle/product/12/db_1/rdbms/jlib  
" >> /home/oracle/.bash_profile
  
  source /home/oracle/.bash_profile
  
  # TODO
  sed -i '1c 127.0.0.1 oracle12 localhost localhost.localdomain localhost4 localhost4.localdomain4' /etc/hosts
  
  mkdir /opt/app/oraInventory
        
  chown -R oracle:oinstall /opt/app/oraInventory

  yum -y install zip unzip 

  for package in `ls ${PACKAGES_DIRECTORY}`
    do
      if [[ $package =~ "database" ]] && [[ "$package" =~ ".zip" ]]; then
        mkdir -p "${PACKAGES_DIRECTORY}oracle"
        unzip "${PACKAGES_DIRECTORY}""${package}" -d "${PACKAGES_DIRECTORY}oracle"

        sed -i "/^UNIX_GROUP_NAME*/c\UNIX_GROUP_NAME=oinstall" "${PACKAGES_DIRECTORY}oracle/database/response/db_install.rsp"
        sed -i "/^INVENTORY_LOCATION*/c\INVENTORY_LOCATION=/opt/app/oraInventory" "${PACKAGES_DIRECTORY}oracle/database/response/db_install.rsp"
        sed -i "/^oracle.install.option*/c\oracle.install.option=INSTALL_DB_SWONLY" "${PACKAGES_DIRECTORY}oracle/database/response/db_install.rsp"
        sed -i "/^SELECTED_LANGUAGES*/c\SELECTED_LANGUAGES=en" "${PACKAGES_DIRECTORY}oracle/database/response/db_install.rsp"
        sed -i "/^ORACLE_HOME*/c\ORACLE_HOME=/opt/app/oracle/product/12/db_1" "${PACKAGES_DIRECTORY}oracle/database/response/db_install.rsp"
        sed -i "/^ORACLE_BASE*/c\ORACLE_BASE=/opt/app/oracle" "${PACKAGES_DIRECTORY}oracle/database/response/db_install.rsp"
        sed -i "/^oracle.install.db.InstallEdition*/c\oracle.install.db.InstallEdition=EE" "${PACKAGES_DIRECTORY}oracle/database/response/db_install.rsp"
        sed -i "/^oracle.install.db.OSDBA_GROUP*/c\oracle.install.db.OSDBA_GROUP=dba" "${PACKAGES_DIRECTORY}oracle/database/response/db_install.rsp"
        sed -i "/^oracle.install.db.OSOPER_GROUP*/c\oracle.install.db.OSOPER_GROUP=oper" "${PACKAGES_DIRECTORY}oracle/database/response/db_install.rsp"
        sed -i "/^oracle.install.db.OSBACKUPDBA_GROUP*/c\oracle.install.db.OSBACKUPDBA_GROUP=dba" "${PACKAGES_DIRECTORY}oracle/database/response/db_install.rsp"
        sed -i "/^oracle.install.db.OSDGDBA_GROUP*/c\oracle.install.db.OSDGDBA_GROUP=dba" "${PACKAGES_DIRECTORY}oracle/database/response/db_install.rsp"
        sed -i "/^oracle.install.db.OSKMDBA_GROUP*/c\oracle.install.db.OSKMDBA_GROUP=dba" "${PACKAGES_DIRECTORY}oracle/database/response/db_install.rsp"
        sed -i "/^oracle.install.db.OSRACDBA_GROUP*/c\oracle.install.db.OSRACDBA_GROUP=dba " "${PACKAGES_DIRECTORY}oracle/database/response/db_install.rsp"
       
        sed -i "/^DECLINE_SECURITY_UPDATES*/c\DECLINE_SECURITY_UPDATES=true" "${PACKAGES_DIRECTORY}oracle/database/response/db_install.rsp"

        sed -i "/^oracle.install.db.config.starterdb.type*/c\oracle.install.db.config.starterdb.type=GENERAL_PURPOSE" "${PACKAGES_DIRECTORY}oracle/database/response/db_install.rsp"
        sed -i "/^oracle.install.db.config.starterdb.globalDBName*/c\oracle.install.db.config.starterdb.globalDBName=cdb1" "${PACKAGES_DIRECTORY}oracle/database/response/db_install.rsp"
        sed -i "/^oracle.install.db.config.starterdb.SID*/c\oracle.install.db.config.starterdb.SID=cdb1" "${PACKAGES_DIRECTORY}oracle/database/response/db_install.rsp"
        sed -i "/^oracle.install.db.config.starterdb.characterSet*/c\oracle.install.db.config.starterdb.characterSet=AL32UTF8 " "${PACKAGES_DIRECTORY}oracle/database/response/db_install.rsp"
        sed -i "/^SECURITY_UPDATES_VIA_MYORACLESUPPORT*/c\SECURITY_UPDATES_VIA_MYORACLESUPPORT=false" "${PACKAGES_DIRECTORY}oracle/database/response/db_install.rsp"


        # FIXME 怎么实现同步？？？？
        su oracle -c "${PACKAGES_DIRECTORY}oracle/database/runInstaller"" -silent -force -noconfig -responseFile ""${PACKAGES_DIRECTORY}oracle/database/response/db_install.rsp" 
        
        wait $!

        # 安装完成后执行两个脚本
        . /opt/app/oraInventory/orainstRoot.sh
        . /opt/app/oracle/product/12/db_1/root.sh
        
        # 添加监听
        su oracle -c "netca -silent -responsefile ""${PACKAGES_DIRECTORY}oracle/database/response/netca.rsp"

        # 数据库创建设置
        sed -i "/^gdbName*/c\gdbName=cdb1" "${PACKAGES_DIRECTORY}oracle/database/response/dbca.rsp"
        sed -i "/^sid*/c\sid=cdb1" "${PACKAGES_DIRECTORY}oracle/database/response/dbca.rsp"
        sed -i "/^databaseConfigType*/c\databaseConfigType=SI" "${PACKAGES_DIRECTORY}oracle/database/response/dbca.rsp"
        sed -i "/^createServerPool*/c\createServerPool=false" "${PACKAGES_DIRECTORY}oracle/database/response/dbca.rsp"
        sed -i "/^createAsContainerDatabase*/c\createAsContainerDatabase=true" "${PACKAGES_DIRECTORY}oracle/database/response/dbca.rsp"
        sed -i "/^numberOfPDBs*/c\numberOfPDBs=1" "${PACKAGES_DIRECTORY}oracle/database/response/dbca.rsp"
        sed -i "/^pdbName*/c\pdbName=cdb1" "${PACKAGES_DIRECTORY}oracle/database/response/dbca.rsp"
        sed -i "/^useLocalUndoForPDBs*/c\useLocalUndoForPDBs=true" "${PACKAGES_DIRECTORY}oracle/database/response/dbca.rsp"
        sed -i "/^templateName*/c\templateName=/app/oracle/product/12/db_1/assistants/dbca/templates/General_Purpose.dbc " "${PACKAGES_DIRECTORY}oracle/database/response/dbca.rsp"
        sed -i "/^emExpressPort*/c\emExpressPort=5500" "${PACKAGES_DIRECTORY}oracle/database/response/dbca.rsp"
        sed -i "/^runCVUChecks*/c\runCVUChecks=false" "${PACKAGES_DIRECTORY}oracle/database/response/dbca.rsp"
        sed -i "/^omsPort*/c\omsPort=0" "${PACKAGES_DIRECTORY}oracle/database/response/dbca.rsp"
        sed -i "/^dvConfiguration*/c\dvConfiguration=false" "${PACKAGES_DIRECTORY}oracle/database/response/dbca.rsp"
        sed -i "/^olsConfiguration*/c\olsConfiguration=false" "${PACKAGES_DIRECTORY}oracle/database/response/dbca.rsp"
        sed -i "/^datafileJarLocation*/c\datafileJarLocation={ORACLE_HOME}/assistants/dbca/templates/" "${PACKAGES_DIRECTORY}oracle/database/response/dbca.rsp"
        sed -i "/^datafileDestination*/c\datafileDestination={ORACLE_BASE}/oradata/{DB_UNIQUE_NAME}/" "${PACKAGES_DIRECTORY}oracle/database/response/dbca.rsp"
        sed -i "/^recoveryAreaDestination*/c\recoveryAreaDestination={ORACLE_BASE}/fast_recovery_area/{DB_UNIQUE_NAME}" "${PACKAGES_DIRECTORY}oracle/database/response/dbca.rsp"
        sed -i "/^storageType*/c\storageType=FS" "${PACKAGES_DIRECTORY}oracle/database/response/dbca.rsp"
        sed -i "/^characterSet*/c\characterSet=AL32UTF8" "${PACKAGES_DIRECTORY}oracle/database/response/dbca.rsp"
        sed -i "/^nationalCharacterSet*/c\nationalCharacterSet=AL16UTF16" "${PACKAGES_DIRECTORY}oracle/database/response/dbca.rsp"
        sed -i "/^registerWithDirService*/c\registerWithDirService=false " "${PACKAGES_DIRECTORY}oracle/database/response/dbca.rsp"
        sed -i "/^listeners*/c\listeners=LISTENER" "${PACKAGES_DIRECTORY}oracle/database/response/dbca.rsp"
        sed -i "/^variables=*/c\variables=DB_UNIQUE_NAME=cdb1,ORACLE_BASE=/opt/app/oracle,PDB_NAME=,DB_NAME=cdb1,ORACLE_HOME=/opt/app/oracle/product/12/db_1,SID=cdb1" "${PACKAGES_DIRECTORY}oracle/database/response/dbca.rsp"
        sed -i "/^initParams*/c\initParams=undo_tablespace=UNDOTBS1,memory_target=796MB,processes=300,db_recovery_file_dest_size=2780MB,nls_language=AMERICAN,dispatchers=(PROTOCOL=TCP) (SERVICE=cdb1XDB),db_recovery_file_dest={ORACLE_BASE}/fast_recovery_area/{DB_UNIQUE_NAME},db_block_size=8192BYTES,diagnostic_dest={ORACLE_BASE},audit_file_dest={ORACLE_BASE}/admin/{DB_UNIQUE_NAME}/adump,nls_territory=AMERICA,local_listener=LISTENER_CDB1,compatible=12.2.0,control_files=("{ORACLE_BASE}/oradata/{DB_UNIQUE_NAME}/control01.ctl", "{ORACLE_BASE}/fast_recovery_area/{DB_UNIQUE_NAME}/control02.ctl"),db_name=cdb1,audit_trail=db,remote_login_passwordfile=EXCLUSIVE,open_cursors=300" "${PACKAGES_DIRECTORY}oracle/database/response/dbca.rsp"
        sed -i "/^sampleSchema*/c\sampleSchema=false" "${PACKAGES_DIRECTORY}oracle/database/response/dbca.rsp"
        sed -i "/^memoryPercentage*/c\memoryPercentage=40" "${PACKAGES_DIRECTORY}oracle/database/response/dbca.rsp"
        sed -i "/^databaseType*/c\databaseType=MULTIPURPOSE" "${PACKAGES_DIRECTORY}oracle/database/response/dbca.rsp"
        sed -i "/^automaticMemoryManagement*/c\automaticMemoryManagement=true" "${PACKAGES_DIRECTORY}oracle/database/response/dbca.rsp"
        sed -i "/^totalMemory*/c\totalMemory=0" "${PACKAGES_DIRECTORY}oracle/database/response/dbca.rsp"
        
        # 创建数据库
        su oracle -c "dbca -silent -createDatabase  -responseFile  ""${PACKAGES_DIRECTORY}oracle/database/response/dbca.rsp"
      fi  
    done  
}

# Mysql数据库安装
function install_mysql_db() {
	echo "TODO"
}

# 安装提示
printf "Thanks for using this script to bulid a basic running enviorment for Java web(only tested on CentOS-7-x86_64-1708 minimal),
if you have any questions, please mail to fan.yang04<AT>hand-china.com.\n"
cat <<EOF
    0:[Install compile tools and other basic packages]
    1:[Install jdk(bin)]
    2:[Install tomcat(bin)]
    3:[Install git(from repo)]
    4:[Install jenkins]
    5:[Install oracle database]
    6:[Install mysql database]
    7:[Install redis(src)]
    q:[exit]
EOF
read -t 10 -p "Please choose the package you would like to install: " input
case ${input} in
 0)
 install_common_tools
 ;;
 1)
 install_jdk
 ;;
 2)
 install_tomcat
 ;;
 3)
 install_git
 ;;
 4)
 install_jenkins
 ;;
 5)
 install_oracle_db
 ;;
 6)
 install_mysql_db
 ;;
 7)
 install_redis
 ;;
 q)
 exit
 ;;
 *)
 printf "Opps! please confirm your choice!\n"
esac