# Java-Web-Environment-Building-Script
## Introduction

  Bulid basic Java web running environment on linux, tested on CentOS-7-x86_64-1708 minimal only.
  
## Useage
First of all, you must add your packages to be installed to a directory, `PACKAGES_DIRECTORY` in the following. I will add more flexible ways later.
1. Copy this script to your machine
2. Switch to an account with root permission
3. `chmod +x java_web_env.sh`
4. `. PATH_TO_SCRIPT/java_web_env.sh PACKAGES_DIRECTORY`

## Pakcage download links
1. **Jdk** [jdk-8u161-linux-x64.tar.gz](http://download.oracle.com/otn-pub/java/jdk/8u161-b12/2f38c3b165be4555a1fa6e98c45e0808/jdk-8u161-linux-x64.tar.gz)
2. **Tomcat** [apache-tomcat-8.5.27.tar.gz](http://mirrors.hust.edu.cn/apache/tomcat/tomcat-8/v8.5.27/bin/apache-tomcat-8.5.27.tar.gz)
3. **Redis** [redis-4.0.8.tar.gz](http://download.redis.io/releases/redis-4.0.8.tar.gz)

## TODO
1. Mysql|Oracle DB  
2. Security related issues
