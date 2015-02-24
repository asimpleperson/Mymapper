# Mymapper
1. To Use a Spark application, the first step is to download and install a thing called maven.
2. Install Maven require a path to the jdk scource folder, if don't know the folder need to download a new jdk use the path for that folder.
3. then to build Mave need following steps:
		assume mave is in usr/lock
		/usr/local/apache-maven
		export PATH=$PATH:/usr/local/apache-maven/apache-maven-3.2.5/bin
		export JAVA_HOME=/usr/java/jdk1.7.0_51

		then run mvn --version
4. To run a spark application, first need to start running the spark:
		./sbin/start-master.sh
5. To kill the current running project:
		./bin/spark-class org.apache.spark.deploy.Client kill <master url> <driver ID>
6. To run an application need to build a jar file and then run do following:
	in path of the application file build files in order:
		$ find .
		./pom.xml
		./src
		./src/main
		./src/main/java
		./src/main/java/SimpleApp.java

		run:
		$ mvn package

	in the path of the spark directory:
		./bin/spark-submit \
		--class <main-class>
		--master <master-url> \
		--deploy-mode <deploy-mode> \
		--conf <key>=<value> \
		... # other options
		<application-jar> \
		[application-arguments]

		Or:

		./bin/spark-submit \
		--class org.apache.spark.examples.SparkPi \
		--master yarn-cluster \  # can also be `yarn-client` for client mode
		--executor-memory 20G \
		--num-executors 50 \
		/path/to/examples.jar \
		100
7. master url IP:7077, but the web ui is in url IP:8080
8. need work then the submit job will works to add a worker:
		./bin/spark-class org.apache.spark.deploy.worker.Worker spark://IP:PORT
	

