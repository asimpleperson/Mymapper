import java.sql.Connection;
import org.apache.hadoop.hive.jdbc.*;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.*;
import javax.swing.JTable;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.util.Vector;
import javax.swing.table.DefaultTableModel;
import javax.swing.table.TableModel;
import java.awt.Cursor;
import javax.swing.*;

import org.apache.hive.jdbc.*;
import org.apache.hive.jdbc.Utils;
import org.apache.hive.*;
import org.apache.hive.service.*;
import org.apache.http.*;
import org.apache.hive.service.CompositeService;
import org.apache.hive.service.cli.CLIService;
import org.apache.hive.service.cli.thrift.*;
import org.apache.hive.service.server.*;
import org.apache.hadoop.hive.conf.HiveConf;


/*

launch cluster:
./spark/spark-1.2.0-bin-hadoop2.4/sbin/start-master.sh

cluster url:
UI:			machine_url:8080
master: 	machine_url:7077

launch worker:
./spark/spark-1.2.0-bin-hadoop2.4/bin/spark-class org.apache.spark.deploy.worker.Worker spark://master_url

launch JDBC server:
./spark/spark-1.2.0-bin-hadoop2.4/sbin/start-thriftserver.sh --master spark://cluster_url:7077 --conf hive.metastore.warehouse.dir=/u/u88/bpastene/hive_warehouse

fill database with locations:
./spark/spark-1.2.0-bin-hadoop2.4/bin/beeline
!connect jdbc:hive2://localhost:10000
create table locations(id BIGINT, name STRING, type STRING, lon DOUBLE, lat DOUBLE) row format delimited fields terminated by '~' stored as textfile;
load data local inpath '/u/u88/bpastene/cs490/out.txt' into table locations;

compile test:
javac -cp ".:/homes/bpastene/cs490/lib/*:/homes/bpastene/spark/spark-1.2.0-bin-hadoop2.4/lib/*" SQLTest.java

run test:
java -cp ".:/homes/bpastene/cs490/lib/*:/homes/bpastene/spark/spark-1.2.0-bin-hadoop2.4/lib/*" SQLTest


*/


public class SQLTest {

	public static void main (String[] args) throws Exception {
		
		String driverName = "org.apache.hive.jdbc.HiveDriver";
		Class.forName(driverName);
		
		Connection con = DriverManager.getConnection("jdbc:hive2://sslab05.cs.purdue.edu:10000", "bpastene", "");
		
		long start = System.currentTimeMillis();
		Statement ps = con.createStatement();
		ResultSet rs = ps.executeQuery("select * from locations");
		long end = System.currentTimeMillis();
		
		while (rs.next()) {
			String name = rs.getString("name");
			if (name.length() != 0) {
				System.out.printf("%s\n", name);
			}
		}
		
		System.out.printf("\n\nqueried in %d ms\n", end-start);
		
		con.close();
		
	}
	
}
