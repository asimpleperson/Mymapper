To run the ingestor and start creating moving points:

From any machine that's not sslab05.cs.purdue.edu, run the commands:

cd <local git repo path>/ingestor
javac -cp ".:./*" Ingestor.java
java -cp ".:./*" Ingestor

The ingestor will run and insert new data points into the database every 1 second.
