<html>
<head>
<title>useBean Example</title>
</head>
<body>
   <%
      response.setIntHeader("Refresh", 1);
		String typeChoice = request.getParameter("TypeChoice");
		String rangeChoice = request.getParameter("RangeChoice");
		
		String userLatString = request.getParameter("userLat");
		String userLonString = request.getParameter("userLon");
		
		String prevZoom = request.getParameter("prevZoom");
		String prevCenterLat = request.getParameter("prevCenterLat");
		String prevCenterLon = request.getParameter("prevCenterLon");
		
		Double userLat;
		Double userLon;
		if (userLatString == null || userLonString == null) {
			userLat = 40.4258333;
			userLon = -86.9080556;
		} else {
			userLat = Double.valueOf(userLatString);
			userLon = Double.valueOf(userLonString);
		}
		out.print(String.format("<script>\n"));
		out.print(String.format("var userLat = %f;\n", userLat));
		out.print(String.format("var userLon = %f;\n", userLon));
		
		if (prevZoom != null && prevZoom.length() > 0) {
			out.print(String.format("var zoom = %s;\n", prevZoom));
		} else {
			out.print("var zoom = 15;\n");
		}
		
		if (prevCenterLat != null && prevCenterLat.length() > 0 && prevCenterLon != null && prevCenterLon.length() > 0) {
			out.print(String.format("var prevCenterLat = %s;\n", prevCenterLat));
			out.print(String.format("var prevCenterLon = %s;\n", prevCenterLon));
		} else {
			out.print("var prevCenterLat = 0;\n");
			out.print("var prevCenterLon = 0;\n");
		}
		
		if (typeChoice != null && typeChoice.compareTo("defaultopts") != 0 && rangeChoice != null && rangeChoice.compareTo("defaultopts") != 0) {
		
			String driverName = "org.apache.hive.jdbc.HiveDriver";
			Class.forName(driverName);
			
			Connection con = DriverManager.getConnection("jdbc:hive2://sslab02.cs.purdue.edu:10000", "bpastene", "");
			
			
			double dist = Double.valueOf(rangeChoice);
			String query;
			if (typeChoice.compareTo("hotel") == 0) {
				query = String.format("select * from locations as loc where (loc.type = \"hotel\" or loc.type = \"motel\") and (ACOS(SIN(PI()*(%f)/180.0)*SIN(PI()*(loc.lat)/180.0)+COS(PI()*(%f)/180.0)*COS(PI()*(loc.lat)/180.0)*COS(PI()*(loc.lon)/180.0-PI()*(%f)/180.0))*6371) <= %f", userLat, userLat, userLon, dist);
			} else {
				query = String.format("select * from locations as loc where (loc.type = \"%s\") and (ACOS(SIN(PI()*(%f)/180.0)*SIN(PI()*(loc.lat)/180.0)+COS(PI()*(%f)/180.0)*COS(PI()*(loc.lat)/180.0)*COS(PI()*(loc.lon)/180.0-PI()*(%f)/180.0))*6371) <= %f", typeChoice, userLat, userLat, userLon, dist);
			}
	
			Statement ps = con.createStatement();
			long start = System.currentTimeMillis();
			ResultSet rs = ps.executeQuery(query);
			long end = System.currentTimeMillis();
			
			while (rs.next()) {
				String name = rs.getString("name");
				double poiLat = rs.getDouble("lat");
				double poiLon = rs.getDouble("lon");
				
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
