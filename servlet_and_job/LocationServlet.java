import java.io.*;
import java.util.*;
import javax.servlet.*;
import javax.servlet.http.*;

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
import org.apache.hive.*;
import org.apache.hive.service.*;
import org.apache.http.*;
import org.apache.hive.service.cli.thrift.*;
import org.apache.hive.service.server.*;
import org.apache.hadoop.hive.conf.*;
import org.apache.hadoop.hive.conf.HiveConf;
import org.apache.hive.service.CompositeService;


/*

sslab01: 
web server

sslab02:
spark master

sslab03:
spark worker #1

sslab04:
spark worder #2

sslab05:
mysql
ingestor

move source to apache/webapps/ROOT/WEB-INF/classes and compile
javac -cp ".:/homes/bpastene/cs490/apache-tomcat-7.0.59/lib/*:/homes/bpastene/spark/spark-1.2.0-bin-hadoop2.4/lib/*" LocationServlet.java

*/

public class LocationServlet extends HttpServlet {

	public static mymapper.classes.MovingActorsQueryJob job = null;
	public static Connection con = null;
	
	@Override
	public void init(ServletConfig config) throws ServletException {	
	
		job = new mymapper.classes.MovingActorsQueryJob();
		
		try {
			String driverName = "org.apache.hive.jdbc.HiveDriver";
			Class.forName(driverName);

			con = DriverManager.getConnection("jdbc:hive2://sslab02.cs.purdue.edu:10000", "bpastene", "");
		} catch (Exception e) {
			e.printStackTrace();
			System.exit(1);
		}
		
	}
	
	
	@Override
	public void doGet(HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException {
		// Set the response message's MIME type.
		response.setContentType("text/html;charset=UTF-8");
		// Allocate a output writer to write the response message into the network socket.
		PrintWriter out = response.getWriter();
				
			
		String typeChoicesString = request.getParameter("TypeChoice");
		String rangeChoicesString = request.getParameter("RangeChoice");
		
		String userLatString = request.getParameter("userLat");
		String userLonString = request.getParameter("userLon");
		
		Double userLat = null;
		Double userLon = null;
		if (userLatString != null && userLonString != null) {
			userLat = Double.valueOf(userLatString);
			userLon = Double.valueOf(userLonString);
		}
		
		if (typeChoicesString != null && rangeChoicesString != null) {
			
			String[] typeChoices = typeChoicesString.split(",");
			String[] rangeChoices = rangeChoicesString.split(",");
			String relevantStaticLocations = "";
			boolean wantPolice = false;
			boolean wantBus = false;
			boolean wantTaxi = false;
			
			if (typeChoices.length == rangeChoices.length) {
				for (int i = 0; i < typeChoices.length; i++) {
					String typeChoice = typeChoices[i];
					String rangeChoice = rangeChoices[i];
					
					if (typeChoice.equals("police") || typeChoice.equals("bus") || typeChoice.equals("taxi")) {
					
						double dist = Double.valueOf(rangeChoice);
						List<String> list = job.getActors(userLat, userLon, dist);
						for (String fieldString: list) {
							if (fieldString != null) {
								String fields[] = fieldString.split("\\s+");					
								int actorType = Integer.parseInt(fields[1]);
								
								double poiLat = Double.parseDouble(fields[3]);
								double poiLon = Double.parseDouble(fields[2]);
								
								if ((actorType == 0 && typeChoice.equals("police")) || (actorType == 1 && typeChoice.equals("bus")) || (actorType == 2 && typeChoice.equals("taxi"))) {
									out.print(String.format("%d~%f~%f<br />\n", actorType, poiLat, poiLon));
								}
							}
						}
						
					} else {
						ResultSet rs = null;
						try {
							
							double dist = Double.valueOf(rangeChoice);
							String query;
							if (typeChoice.compareTo("hotel") == 0) {
								query = String.format("select * from locations as loc where (loc.type = \"hotel\" or loc.type = \"motel\") and (ACOS(SIN(PI()*(%f)/180.0)*SIN(PI()*(loc.lat)/180.0)+COS(PI()*(%f)/180.0)*COS(PI()*(loc.lat)/180.0)*COS(PI()*(loc.lon)/180.0-PI()*(%f)/180.0))*6371) <= %f", userLat, userLat, userLon, dist);
							} else {
								query = String.format("select * from locations as loc where (loc.type = \"%s\") and (ACOS(SIN(PI()*(%f)/180.0)*SIN(PI()*(loc.lat)/180.0)+COS(PI()*(%f)/180.0)*COS(PI()*(loc.lat)/180.0)*COS(PI()*(loc.lon)/180.0-PI()*(%f)/180.0))*6371) <= %f", typeChoice, userLat, userLat, userLon, dist);
							}
					
							
							Statement ps = con.createStatement();
							long start = System.currentTimeMillis();
							rs = ps.executeQuery(query);
							long end = System.currentTimeMillis();
						
						
						
							while (rs.next()) {
								String name = rs.getString("name");
								double poiLat = rs.getDouble("lat");
								double poiLon = rs.getDouble("lon");
								if (name.length() != 0) {
									//out.print(String.format("%s<br />", name));
								}
								
								out.print(String.format("%s~%s~%f~%f<br />\n", name, typeChoice, poiLat, poiLon));
							}
						
						} catch (Exception e) {
							e.printStackTrace();
						}
					}
				}
			}
			
		}
		
	}
	
	
	@Override
	public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException {
		doGet(request, response);
	}
	
	/*
	public static void main (String[] args) throws Exception {
		ServletTest st = new ServletTest();
		st.init(null);
		
		List<String> list = st.javaRDD.map(new Function<Object[], String>() {
			@Override
			public String call(final Object[] record) throws Exception {
				return "" + record[4];
			}
		}).collect();
		
		System.out.printf("\n\n%s\n\n", list.size());
	}
	*/
}
