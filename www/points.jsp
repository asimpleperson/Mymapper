<html>
<head>
<title>useBean Example</title>
</head>
<body>
   <%
      response.setIntHeader("Refresh", 1);
      		// get the user's choice for type of location, typeChoice = "fast_food", or "restaurant", or "library", etc.
		String typeChoice = request.getParameter("TypeChoice");
		// get the user's choice for range of locations, rangeChoice = ".804672" (.5 mile in km), or 1mi, or 2mi
		String rangeChoice = request.getParameter("RangeChoice");
		
		// userLatString = user's latitude
		String userLatString = request.getParameter("userLat");
		// userLonString = user's longitude
		String userLonString = request.getParameter("userLon");
		
		// prevZoom=  the map's zoom level before the user hit submit
		String prevZoom = request.getParameter("prevZoom");
		// prevCenter = the map's center before the user hit submit
		String prevCenterLat = request.getParameter("prevCenterLat");
		String prevCenterLon = request.getParameter("prevCenterLon");
		
		Double userLat;
		Double userLon;
		// if the prevCenter inputs were not set, the map's center defaults to just north of chauncey
		if (userLatString == null || userLonString == null) {
			userLat = 40.4258333;
			userLon = -86.9080556;
		} else {
			userLat = Double.valueOf(userLatString);
			userLon = Double.valueOf(userLonString);
		}
		
		// Acutally print points
      out.print(String.format("<script>\n"));
		out.print(String.format("var userLat = %f;\n", userLat));
		out.print(String.format("var userLon = %f;\n", userLon));
		
		// define zoom level
		if (prevZoom != null && prevZoom.length() > 0) {
			out.print(String.format("var zoom = %s;\n", prevZoom));
		} else {
			out.print("var zoom = 15;\n");
		}
		
		// define map center coords
		if (prevCenterLat != null && prevCenterLat.length() > 0 && prevCenterLon != null && prevCenterLon.length() > 0) {
			out.print(String.format("var prevCenterLat = %s;\n", prevCenterLat));
			out.print(String.format("var prevCenterLon = %s;\n", prevCenterLon));
		} else {
			out.print("var prevCenterLat = 0;\n");
			out.print("var prevCenterLon = 0;\n");
		}
		
		// if the user previously specified the type of location, the range, and then hit submit, find the relevant locations
		if (typeChoice != null && typeChoice.compareTo("defaultopts") != 0 && rangeChoice != null && rangeChoice.compareTo("defaultopts") != 0) {
		
			// make sure the jdbc driver for hive is present in the classpath
			String driverName = "org.apache.hive.jdbc.HiveDriver";
			Class.forName(driverName);
			
			// connect to database
			Connection con = DriverManager.getConnection("jdbc:hive2://sslab02.cs.purdue.edu:10000", "bpastene", "");
			
			
			double dist = Double.valueOf(rangeChoice);
			String query;
			// query the db for locations of the specified type within the specified range, the sql query uses trigonometry to calculate the distance between two geographic pair of coordinates
			if (typeChoice.compareTo("hotel") == 0) {
				// hotel can either be a hotel or motel, so query differently based on that
				query = String.format("select * from locations as loc where (loc.type = \"hotel\" or loc.type = \"motel\") and (ACOS(SIN(PI()*(%f)/180.0)*SIN(PI()*(loc.lat)/180.0)+COS(PI()*(%f)/180.0)*COS(PI()*(loc.lat)/180.0)*COS(PI()*(loc.lon)/180.0-PI()*(%f)/180.0))*6371) <= %f", userLat, userLat, userLon, dist);
			} else {
				query = String.format("select * from locations as loc where (loc.type = \"%s\") and (ACOS(SIN(PI()*(%f)/180.0)*SIN(PI()*(loc.lat)/180.0)+COS(PI()*(%f)/180.0)*COS(PI()*(loc.lat)/180.0)*COS(PI()*(loc.lon)/180.0-PI()*(%f)/180.0))*6371) <= %f", typeChoice, userLat, userLat, userLon, dist);
			}
	
			// query the db
			Statement ps = con.createStatement();
			long start = System.currentTimeMillis();
			ResultSet rs = ps.executeQuery(query);
			long end = System.currentTimeMillis();
			
			// iterate through the results
			while (rs.next()) {
				String name = rs.getString("name");
				double poiLat = rs.getDouble("lat");
				double poiLon = rs.getDouble("lon");
				
				// for each resulting location, create an OpenLayer feature for it and add it to the poiLayer
				out.print(String.format("var tempLoc = new OpenLayers.LonLat( %f , %f ).transform( fromProjection, toProjection);\n", poiLon, poiLat));
				out.print("var tempPoint = new OpenLayers.Geometry.Point( tempLoc.lon, tempLoc.lat );\n");
				out.print(String.format("var poiFeature = new OpenLayers.Feature.Vector(tempPoint, {userFeature: false, Name:\"%s\", Type:'%s'}, {externalGraphic: 'img/marker2.png', graphicHeight: 25, graphicWidth: 16});\n", name, rs.getString("type")));
					
				out.print("poiLayer.addFeatures(poiFeature);\n");
			}
			
		}
		
		
		out.print(String.format("</script>\n"));
	%>
</body>
</html>
