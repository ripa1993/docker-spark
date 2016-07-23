FROM ubuntu:14.04

# JAVA 1.8 AND GIT 
RUN echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu precise main" | tee -a /etc/apt/sources.list && \
    echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu precise main" | tee -a /etc/apt/sources.list && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys EEA14886 && \
    apt-get update && \
    echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && \
    apt-get install -y git oracle-java8-installer ca-certificates && \
    apt-get clean autoclean && apt-get autoremove -y && \
    rm -rf /var/lib/{apt,dpkg,cache,log}/ && rm -rf /var/cache/oracle-jdk8-installer
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle/

# MAVEN & SPARK 1.6
RUN wget http://mirror.olnevhost.net/pub/apache/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz && sudo tar -zxf apache-maven-3.3.9-bin.tar.gz -C /usr/local/ && rm apache-maven-3.3.9-bin.tar.gz && \
    sudo ln -s /usr/local/apache-maven-3.3.9/bin/mvn /usr/bin/mvn && \
    git clone https://github.com/ElfoLiNk/spark.git --depth=1 --branch=branch-1.6 && \
    cd spark && ./dev/change-scala-version.sh 2.11 && \
    sed -i '170s{.*{BUILD_COMMAND=("$MVN" -T 1C clean package -DskipTests --quiet $@){' make-distribution.sh && \
    ./make-distribution.sh --name docker --tgz -Pyarn -Phadoop-2.6 -Dhadoop.version=2.7.2 -Dscala-2.11 -Dmaven.test.skip=true && \
    sudo tar -xf spark-*.tgz -C /usr/local/ && sudo mv /usr/local/spark-* /usr/local/spark && \
    cd .. && rm -rf spark && \
    echo 'spark.eventLog.enabled true' >> /usr/local/spark/conf/spark-defaults.conf && mv /usr/local/spark/conf/log4j.properties.template /usr/local/spark/conf/log4j.properties && \
    mkdir -p /usr/local/spark/assembly/target/scala-2.11 && \
    ln -s /usr/local/spark/lib/* /usr/local/spark/assembly/target/scala-2.11/ && \
    rm -rf /root/.m2/repository && rm -rf /usr/local/apache-maven-3.3.9 && find /usr/share/doc -depth -type f ! -name copyright|xargs rm || true && find /usr/share/doc -empty|xargs rmdir || true && rm -rf /usr/share/man/* /usr/share/groff/* /usr/share/info/* && rm -rf /usr/share/lintian/* /usr/share/linda/* /var/cache/man/*
ENV SPARK_HOME /usr/local/spark
ENV PATH $PATH:$SPARK_HOME/bin

