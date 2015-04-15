import java.io.*;
import java.util.*;
import java.sql.*;
import java.text.SimpleDateFormat;
import java.net.*;

/*
	0 - .5:		police
	.5 - .75:	bus
	.75 - 1:		taxi
	
	create table moving_points(id int, type int, lon double, lat double, timestamp bigint, index(timestamp), key(id));
	create table tweets(id int, lon double, lat double, timestamp bigint, message varchar(141), index(timestamp), foreign key(id) references moving_points(id));
*/
public class Ingestor {
	public static class Point {
		int type;
		double lon;
		double lat;
		int id;
		Point(int type, int id, double lat, double lon) {
			this.type = type;
			this.id = id;
			this.lat = lat;
			this.lon = lon;
		}
	}
	public static void main (String[] args) throws Exception {
		LinkedList<LinkedList> timestamps = new LinkedList<LinkedList>();
		LinkedList<Point> newPoints = null;
		HashMap<Integer, Integer> types = new HashMap<Integer, Integer>();

		// load data from file
		String file = "points.txt";
		BufferedReader br = new BufferedReader(new FileReader(file));
		String line;
		int prevTimestamp = -1;
		while ((line = br.readLine()) != null) {
			String fields[] = line.split("\\s+");
			String action = fields[2];
			int timestamp = Integer.parseInt(fields[1]);
			int id = Integer.parseInt(fields[0]);
			double lat = Double.parseDouble(fields[3]);
			double lon = Double.parseDouble(fields[4]);
			int type;
			if (action.equals("newpoint")) {
				double rand = Math.random();
				type = 0;
				if (rand < .5) {
					type = 0;
				} else if (rand < .75) {
					type = 1;
				} else if (rand < 1) {
					type = 2;
				}
				types.put(id, type);
			} else {
				type = types.get(id);
			}
			
			Point point = new Point(type, id, lat, lon);
			
			if (prevTimestamp != timestamp) {
				prevTimestamp = timestamp;
				if (newPoints != null) {
					timestamps.add(newPoints);
					newPoints = new LinkedList<Point>();
				} else {
					newPoints = new LinkedList<Point>();
				}
				newPoints.add(point);
			} else {
				newPoints.add(point);
			}
			
		}
		br.close();
		timestamps.add(newPoints);
		
		System.out.printf("timestamps: %d\n\n", timestamps.size());
		
		// connect to mysql db and clear the tables
		String dbUrl = "jdbc:mysql://sslab05.cs.purdue.edu:3306/cs490";
		String username = "mymapper";
		String password = "password";
		Connection con = DriverManager.getConnection( dbUrl, username, password);
		
		Statement statement = con.createStatement();
		statement.executeUpdate("delete from tweets");	
		statement.executeUpdate("delete from moving_points");	
		statement.close();
		
		
		SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
		
		// connect to the twitter server
		String serverAddress = "ibnalhaytham.cs.purdue.edu";
		Socket s = new Socket(serverAddress, 11222);
		BufferedReader input = new BufferedReader(new InputStreamReader(s.getInputStream()));		
		
		while (true) {
			for (LinkedList<Point> list: timestamps) {
				System.out.printf("inserting...\n");
				long currentTime = System.currentTimeMillis();
				int tweetCount = 0;
				for (Point point: list) {
					statement = con.createStatement();
					statement.executeUpdate(String.format("insert into moving_points values(%d, %d, %f, %f, %d)", point.id, point.type, point.lon, point.lat, currentTime));	
					statement.close();
					
					double rand = Math.random();
					
					if (rand < .15) {
						tweetCount++;
						line = input.readLine();
						int ind = 0;
						int count = 0;
						for (ind = 0; ind < line.length(); ind++) {
							if (line.charAt(ind) == ',') {
								count++;
							}
							if (count == 5) {
								break;
							}
						}
						String message = "";
						rand = Math.random();
						if (rand < .05) {
							message = "OMG, just passed massive car crash on my way to class";
						} else if (rand < .10) {
							message = "stuck behind another car accident, people need to learn how to drive!!!";
						} else if (rand < .15) {
							message = "stuck in traffic and huge gridlock, this sucks";
						} else {
							message = line.substring(ind+1, line.length());						
						}
						PreparedStatement ps = con.prepareStatement("insert into tweets values(?, ?, ?, ?, ?)");
						ps.setInt(1, point.id);
						ps.setDouble(2, point.lon);
						ps.setDouble(3, point.lat);
						ps.setLong(4, currentTime);
						ps.setString(5, message);
						ps.execute();
						ps.close();
					}
					
				}
				
				System.out.printf("inserted in %d ms, %d of %d possible tweets inserted\n", System.currentTimeMillis() - currentTime, tweetCount, list.size());
				Thread.sleep(1000);
			}
		}
		
	}
}
