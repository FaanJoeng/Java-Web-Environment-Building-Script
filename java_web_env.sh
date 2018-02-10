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
		  for $decompressed_package in `ls ${PACKAGES_DIRECTORY}`
		  do
        if [[ $decompressed_package =~ "jdk" ]] && [[ ! $decompressed_package =~ ".tar.gz" ]]; then
           cp -r  "${PACKAGES_DIRECTORY}""${decompressed_package}" /usr/local/ 
           JAVA_HOME="/usr/local/""${decompressed_package}"
        fi  
		  done	
		fi  
	done	
  
  # 配置JDK环境变量并使之生效
  echo "export JAVA_HOME=${JAVA_HOME} \nexport JRE_HOME=${JAVA_HOME}/jre \nexport PATH=$JAVA_HOME/bin:$PATH \nexport CLASSPATH=$JAVA_HOME/jre/lib/ext:$JAVA_HOME/lib/tools.jar" >> /etc/profile
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
	echo "TODO"
}

# 编译安装Redis
function install_redis() {
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
             # TODO redis服务化

             cd -
            fi  
		     done	
		  fi  
	  done	
  printf "Redis installed successfully!\n\n"
}

# Oracle数据库安装
function install_oracle_db() {
  echo "TODO"
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
