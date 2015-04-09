LocationServlet.java
Java servlet that processes any and all queries from the web ui. If the web ui requests static locations, it queires spark's built in SQL data store. If the web ui requests moving objects, the servlet asks the MovingActorsQueryJob spark app, which queries MySQL and returns the relevant locations.

To change LocationServlet, follow these steps:
- edit the file /homes/bpastene/cs490/apache-tomcat-7.0.59/webapps/ROOT/WEB-INF/classes/LocationServlet.java
- compile it: "javac -cp ".:/homes/bpastene/cs490/apache-tomcat-7.0.59/lib/*:/homes/bpastene/spark/spark-1.2.0-bin-hadoop2.4/lib/*" LocationServlet.java"
- if it compiled without error, stop the server: "/homes/bpastene/cs490/apache-tomcat-7.0.59/bin/shutdown.sh"
- then start the server: "/homes/bpastene/cs490/apache-tomcat-7.0.59/bin/startup.sh"
- wait a minute for the server to start back up, and your changes should be live


MovingActorsQueryJob.java
A spark app that queries MySQL for moving objects.
