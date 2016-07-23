FROM ubuntu:14.04

# JAVA 1.8
RUN apt-get update && apt-get install -y software-properties-common && add-apt-repository -y ppa:webupd8team/java &&  apt-get update &&  echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections && \
    apt-get install -y git oracle-java8-installer && apt-get clean autoclean && apt-get autoremove -y && rm -rf /var/lib/{apt,dpkg,cache,log}/ && rm -rf /var/cache/oracle-jdk8-installer
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle/

# SCALA 2.11.8
RUN wget http://downloads.lightbend.com/scala/2.11.8/scala-2.11.8.deb && sudo dpkg -i scala-2.11.8.deb && rm scala-2.11.8.deb  && apt-get clean autoclean && apt-get autoremove -y && rm -rf /var/lib/{apt,dpkg,cache,log}/

# MAVEN 3.3.9
RUN wget http://mirror.olnevhost.net/pub/apache/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz && sudo tar -zxf apache-maven-3.3.9-bin.tar.gz -C /usr/local/ && rm apache-maven-3.3.9-bin.tar.gz && \
    sudo ln -s /usr/local/apache-maven-3.3.9/bin/mvn /usr/bin/mvn
ENV M2_HOME /usr/local/apache-maven-3.3.9

# SPARK 1.6.1
ENV MAVEN_OPTS "-Xmx2g -XX:ReservedCodeCacheSize=512m"
RUN git clone https://github.com/ElfoLiNk/spark.git --depth=1 --branch=branch-1.6 && \
    cd spark && ./dev/change-scala-version.sh 2.11 && \
	sed -i '170s{.*{BUILD_COMMAND=("$MVN" -T 1C clean package -DskipTests --quiet $@){' make-distribution.sh && \
    ./make-distribution.sh --name docker --tgz -Pyarn -Phadoop-2.6 -Dhadoop.version=2.7.2 -Dscala-2.11 -Dmaven.test.skip=true && \
    sudo tar -xf spark-*.tgz -C /usr/local/ && sudo mv /usr/local/spark-* /usr/local/spark && \
    cd .. && rm -rf spark && \
    echo 'spark.eventLog.enabled true' >> /usr/local/spark/conf/spark-defaults.conf && mv /usr/local/spark/conf/log4j.properties.template /usr/local/spark/conf/log4j.properties && \
	mkdir -p /usr/local/spark/assembly/target/scala-2.11
	ln -s /usr/local/spark/lib/* /usr/local/spark/assembly/target/scala-2.11/
ENV SPARK_HOME /usr/local/spark
ENV PATH $PATH:$SPARK_HOME/bin

# Clean
RUN rm -rf /root/.m2/repository && rm -rf /usr/local/apache-maven-3.3.9 && find /usr/share/doc -depth -type f ! -name copyright|xargs rm || true && find /usr/share/doc -empty|xargs rmdir || true && rm -rf /usr/share/man/* /usr/share/groff/* /usr/share/info/* && rm -rf /usr/share/lintian/* /usr/share/linda/* /var/cache/man/*
