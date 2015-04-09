package mymapper.classes;

import java.io.*;
import java.util.*;

import org.apache.spark.*;
import org.apache.spark.api.java.function.*;
import org.apache.spark.streaming.*;
import org.apache.spark.streaming.api.java.*;
import org.apache.spark.api.java.*;
import org.apache.spark.sql.api.java.*;
import org.apache.spark.rdd.*;
import org.apache.spark.storage.*;

import scala.Tuple2;
import scala.*;
import scala.runtime.AbstractFunction0;
import scala.runtime.AbstractFunction1;
import scala.runtime.*;
import scala.reflect.*;

import org.apache.spark.SparkConf;
import org.apache.spark.api.java.JavaRDD;
import org.apache.spark.api.java.JavaSparkContext;
import org.apache.spark.api.java.function.Function;

import java.sql.*;

/*

put source file in mymapper/classes

compile
javac -cp ".:/homes/bpastene/spark/spark-1.2.0-bin-hadoop2.4/lib/*" MovingActorsQueryJob.java

mkjar
jar cvf moving_actors_job.jar mymapper/

move jar to apache lib

*/


public class MovingActorsQueryJob implements java.io.Serializable {
	
	int numOfWorkers = 1;
	JavaRDD<Object[]> javaRDD = null;
	
	public static class DbConnection extends AbstractFunction0<Connection> implements java.io.Serializable {
	
		//private static final long serialVersionUID = 2L;
		
		private String driverClassName;
		private String connectionUrl;
		private String userName;
		private String password;
	 
		public DbConnection(String driverClassName, String connectionUrl, String userName, String password) {
				this.driverClassName = driverClassName;
				this.connectionUrl = connectionUrl;
				this.userName = userName;
				this.password = password;
		}
	 
		@Override
		public Connection apply() {
			try {
				Class.forName(driverClassName);
			} catch (ClassNotFoundException e) {
				e.printStackTrace();
				System.exit(1);
			}
	 
			Properties properties = new Properties();
			properties.setProperty("user", userName);
			properties.setProperty("password", password);
	 
			Connection connection = null;
			try {
				connection = DriverManager.getConnection(connectionUrl, properties);
			} catch (SQLException e) {
				e.printStackTrace();
				System.exit(1);
			}
	 
			return connection;
		}
	}
	

	public static class MapResult extends AbstractFunction1<ResultSet, Object[]> implements java.io.Serializable {
	
		private static final long serialVersionUID = 2L;
	
		//static final long serialVersionUID = 1L;
	 
		public Object[] apply(ResultSet row) {
			return JdbcRDD.resultSetToObjectArray(row);
		}
	}
	

	public MovingActorsQueryJob() {
		
		SparkConf conf = new SparkConf().setMaster("spark://sslab02.cs.purdue.edu:7077").setAppName("MovingActors Query Service");
		
		//conf.setJars(new String[]{"/u/data/u88/bpastene/cs490/mysql-connector-java-5.1.15-bin.jar", "/homes/bpastene/cs490/mysql-connector-java-5.1.15-bin.jar"});
		JavaSparkContext jssc = new JavaSparkContext(conf);
	
		jssc.addJar("/homes/bpastene/cs490/apache-tomcat-7.0.59/lib/moving_actors_job.jar");
		/*
		jssc.addFile("/homes/bpastene/cs490/apache-tomcat-7.0.59/webapps/ROOT/WEB-INF/classes/test/classes/Job.class");
		jssc.addFile("/homes/bpastene/cs490/apache-tomcat-7.0.59/webapps/ROOT/WEB-INF/classes/test/classes/Job$1.class");
		jssc.addFile("/homes/bpastene/cs490/apache-tomcat-7.0.59/webapps/ROOT/WEB-INF/classes/test/classes/Job$DbConnection.class");
		jssc.addFile("/homes/bpastene/cs490/apache-tomcat-7.0.59/webapps/ROOT/WEB-INF/classes/test/classes/Job$MapResult.class");
		*/
		
		
		/*
		jssc.addFile("/u/u88/bpastene/cs490/Job.class");
		jssc.addFile("/u/u88/bpastene/cs490/Job$1.class");
		//jssc.addFile("/u/u88/bpastene/cs490/Job$2.class");
		jssc.addFile("/u/u88/bpastene/cs490/Job$DbConnection.class");
		jssc.addFile("/u/u88/bpastene/cs490/Job$MapResult.class");
		*/
		
		

		DbConnection dbConnection = new DbConnection("com.mysql.jdbc.Driver", "jdbc:mysql://sslab05.cs.purdue.edu:3306/cs490", "mymapper", "password");
		

		
		JdbcRDD<Object[]> jdbcRDD = new JdbcRDD<>(jssc.sc(), dbConnection, "select * from moving_points where id >= ? and id <= ? and timestamp = (select max(timestamp) from moving_points)",
                              0, 10000, numOfWorkers, new MapResult(), ClassManifestFactory$.MODULE$.fromClass(Object[].class));
			

		
		javaRDD = JavaRDD.fromRDD(jdbcRDD, ClassManifestFactory$.MODULE$.fromClass(Object[].class));

		
	}
	

	public List<String> getActors(double lat, double lon, double range) {
		
		
		List<String> list = javaRDD.map(new Function<Object[], String>() {
			private static final long serialVersionUID = 2L;
			@Override
			public String call(final Object[] record) throws Exception {
				double pointLon = java.lang.Double.parseDouble("" + record[2]);
				double pointLat = java.lang.Double.parseDouble("" + record[3]);
				
				double dist = (Math.acos(Math.sin(Math.PI*(lat)/180.0)*Math.sin(Math.PI*(pointLat)/180.0)+Math.cos(Math.PI*(lat)/180.0)*Math.cos(Math.PI*(pointLat)/180.0)*Math.cos(Math.PI*(pointLon)/180.0-Math.PI*(lon)/180.0))*6371);
				
				if (dist <= range) {
					return record[0] + " " + record[1] + " " + record[2] + " " + record[3];
				} else {
					return null;
				}
				
			}
		}).collect();
		 
		return list;
	}
	
	/*
	public static void main (String[] args) throws Exception {
		Job j = new Job();
		List<String> list = j.getActors(40.426545, -86.910348, 1.60934);
	
	}
	*/
	
}
