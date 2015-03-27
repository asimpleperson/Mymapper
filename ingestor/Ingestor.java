import java.io.*;
import java.util.*;
import java.sql.*;

/*
	0 - .5:		police
	.5 - .75:	bus
	.75 - 1:		taxi
	
	create table moving_points(id int, type int, lon double, lat double, timestamp bigint, index(timestamp));
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
		
		String dbUrl = "jdbc:mysql://sslab05.cs.purdue.edu:3306/cs490";
		String username = "mymapper";
		String password = "password";
		Connection con = DriverManager.getConnection( dbUrl, username, password);
		
		Statement statement = con.createStatement();
		statement.executeUpdate("delete from moving_points");	
		statement.close();
		
		while (true) {
			int i = 0;
			for (LinkedList<Point> list: timestamps) {
				System.out.printf("inserting...\n");
				long currentTime = System.currentTimeMillis();
				for (Point point: list) {
					statement = con.createStatement();
					statement.executeUpdate(String.format("insert into moving_points values(%d, %d, %f, %f, %d)", point.id, point.type, point.lon, point.lat, currentTime));	
					statement.close();
				}
				System.out.printf("inserted in %d ms\n", System.currentTimeMillis() - currentTime);
				Thread.sleep(1000);
			}
		}
	}
}
