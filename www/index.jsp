<%@ page import="java.sql.Connection" %>
<%@ page import="java.util.*" %>
<%@ page import="org.apache.hadoop.hive.jdbc.*" %>
<%@ page import="java.sql.DriverManager" %>
<%@ page import="java.sql.ResultSet" %>
<%@ page import="java.sql.SQLException" %>
<%@ page import="java.sql.Statement" %>
<%@ page import="java.sql.*" %>
<%@ page import="javax.swing.JTable" %>
<%@ page import="java.sql.ResultSet" %>
<%@ page import="java.sql.ResultSetMetaData" %>
<%@ page import="java.util.Vector" %>
<%@ page import="javax.swing.table.DefaultTableModel" %>
<%@ page import="javax.swing.table.TableModel" %>
<%@ page import="java.awt.Cursor" %>
<%@ page import="javax.swing.*" %>

<!-- need to download apache hive @ https://hive.apache.org/downloads.html and add all of its jars, along with spark's jars, to Tomcat's class loader (in conf/cataline.properties)
	example:
		shared.loader=/homes/bpastene/cs490/apache_hive/lib/*.jar, /homes/bpastene/spark/spark-1.2.0-bin-hadoop2.4/lib/*.jar
-->

<%@ page import="org.apache.hive.jdbc.*" %>
<%@ page import="org.apache.hive.*" %>
<%@ page import="org.apache.hive.service.*" %>
<%@ page import="org.apache.http.*" %>
<%@ page import="org.apache.hive.service.cli.thrift.*" %>
<%@ page import="org.apache.hive.service.server.*" %>
<%@ page import="org.apache.hadoop.hive.conf.*" %>
<%@ page import="org.apache.hadoop.hive.conf.HiveConf" %>
<%@ page import="org.apache.hive.service.CompositeService" %>

<head>
<meta name="CS490" content="width=device-width, initial-scale=1.0">
<!-- Bootstrap -->
<link href="css/bootstrap.css" rel="stylesheet" media="screen">
<link rel="stylesheet" href="http://openlayers.org/en/v3.2.1/css/ol.css" type="text/css">

<style>
  .map {
    height: 400px;
    width: 100%;
  }


  .vertical-offset-100{
    padding-top:100px;
  }

</style>


<script src="http://www.openlayers.org/api/OpenLayers.js"  type="text/javascript"></script>
<script src="http://openlayers.org/en/v3.2.1/build/ol.js" type="text/javascript"></script>
<script type="text/javascript" src="http://maplib.khtml.org/khtml.maplib/khtml_all.js"> </script>
<title>Hi!CS490 My Mapper</title>

<script src="js/bootstrap.min.js"></script>
<script src="js/jquery-2.1.1.min.js"></script>
<script src="js/bootstrap-select.js"></script>


</head>

<%!

	static test.classes.Job job = new test.classes.Job();
	// test test
	Connection con = null;
	
	public void jspInit() {
		if (job == null) {
			//job = new test.classes.Job();
		}
		
		if (con == null) {
			try {
				// make sure the jdbc driver for hive is present in the classpath
				String driverName = "org.apache.hive.jdbc.HiveDriver";
				Class.forName(driverName);			
				// connect to database
				con = DriverManager.getConnection("jdbc:hive2://sslab02.cs.purdue.edu:10000", "bpastene", "");
			} catch (Exception e) {
				e.printStackTrace();
				System.exit(1);
			}
		}
	}
%>

<script>
	
	// declare different types of coordinate projections, the browser uses EPSG:4326 but OpenLayers uses ESPG:900913
	var fromProjection = new OpenLayers.Projection("EPSG:4326");   // Transform from WGS 1984
	var toProjection   = new OpenLayers.Projection("EPSG:900913"); // to Spherical Mercator Projection
	
	// declare the map layer used to store the markers for points of interest 
	var poiLayer = new OpenLayers.Layer.Vector("POIs");
	

</script>

<body onload="initialize()">


	<%
		
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
		
		// begin defining javascript variables by printing javascript lines to the html doc
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
							out.print(String.format("var tempLoc = new OpenLayers.LonLat( %f , %f ).transform( fromProjection, toProjection);\n", poiLon, poiLat));
							out.print("var tempPoint = new OpenLayers.Geometry.Point( tempLoc.lon, tempLoc.lat );\n");
							out.print(String.format("var poiFeature = new OpenLayers.Feature.Vector(tempPoint, {userFeature: false, Name:\"%s\", Type:'%s'}, {externalGraphic: 'img/marker2.png', graphicHeight: 25, graphicWidth: 16});\n", "", typeChoice));			
							out.print("poiLayer.addFeatures(poiFeature);\n");
						}
					}
				}
			} else {
		
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
		}
		
		
		out.print(String.format("</script>\n"));
		
	
	%>


    <div class="container-fluid">
        <!-- Brand and toggle get grouped for better mobile display -->
            
        <div class="navbar-header">
            <button type="button" class="navbar-toggle collapsed" data-toggle="collapse" data-target="#bs-example-navbar-collapse-1">
                <span class="sr-only">Toggle navigation</span>
                <span class="icon-bar"></span>
                <span class="icon-bar"></span>
                <span class="icon-bar"></span>
            </button>
            <a class="navbar-brand">CS490</a>
        </div>

        <!-- Collect the search options -->
        <div class="collapse navbar-collapse" id="bs-example-navbar-collapse-1">
  
            <form id = "SearchForm" class="navbar-form navbar-left" method="post">
                <div class="form-group">
                    <input type="hidden" id="TypeChoice" name="TypeChoice" value="" />

                        <select id = "TypeSelect" class="form-control" name="select-type-of-interest" onchange="dropdownTest(this.value)">
                            <option value="defaultopts" id="defaultopts">--Type of interests--</option>
                            <option value="restaurant" id="restaurant">Restaurant</option>
                            <option value="fast_food" id="fast_food">Fast Food</option>
                            <option value="library" id="library">Library</option>
                            <option value="school" id="school">School</option>
                            <option value="supermarket" id="supermarket">Grocery Store</option>
                            <option value="hotel" id="hotel">Hotel</option>
                            <option value="fuel" id="fuel">Gas Station</option>
                            <option value="parking" id="parking">Parking Lot</option>
							<option value="police" id="police">Police Car</option>
							<option value="bus" id="bus">Bus</option>
							<option value="taxi" id="taxi">Taxi</option>
                        </select>
                </div>
    
				
        
            
                <div class="form-group">
                    <input type="hidden" id="RangeChoice" name="RangeChoice" value=" " />

                            <select id = "RangeSelect" class="form-control" name="select-range" onchange="dropdownTest(this.value)">
                            <option value="defaultopts" selected>--Range--</option>
                            <option value="0.804672">Within half a Mile</option>
                            <option value="1.60934">Within 1 Mile</option>
                            <option value="3.21869">Within 2 Miles</option>
                        </select>
                </div>
    
				<!--Search Button-->
				<button type="button" class="btn btn-default btn-lg" onclick="search()">Search</button>
				
				<input type="hidden" name="userLat" id="userLat" />
				<input type="hidden" name="userLon" id="userLon" />
				
				<input type="hidden" name="prevZoom" id ="prevZoom" value="" />
				
				<input type="hidden" name="prevCenterLon" id="prevCentLon" value="" />
				
				<input type="hidden" name="prevCenterLat" id="prevCentLat" value="" />
				
				<script>
				
					<%
						if (typeChoice != null) {
							out.print("			var selectOption1 = document.getElementById(\"TypeSelect\");\n");
							out.print("			selectOption1.value = \"" + typeChoice + "\";\n");
						} else {
							out.print("			var selectOption1 = document.getElementById(\"TypeSelect\");\n");
							out.print("			selectOption1.value = \"defaultopts\";\n");
						}
						
						if (rangeChoice != null) {
							out.print("			var selectOption2 = document.getElementById(\"RangeSelect\");\n");
							out.print("			selectOption2.value = \"" + rangeChoice + "\";\n");
						} else {
							out.print("			var selectOption2 = document.getElementById(\"RangeSelect\");\n");
							out.print("			selectOption2.value = \"defaultopts\";\n");
						}
					%>
				
					function search() {
						// this function is called when the user hits submit
					
						// assign the type of location the user chose to the hidden input "TypeChoice"
						var type = document.getElementById("TypeChoice");
						var typeSelect = document.getElementById("TypeSelect");
						type.value = typeSelect.options[typeSelect.selectedIndex].value;
						
						// assign the range the user chose to the hidden input "RangeChoice"
						var range = document.getElementById("RangeChoice");
						var rangeSelect = document.getElementById("RangeSelect");
						range.value = rangeSelect.options[rangeSelect.selectedIndex].value;
						
						// get the user's current location
						var tempPos = new OpenLayers.LonLat( position.lon , position.lat ).transform( toProjection, fromProjection);
						
						// assign the user's location (the blue marker) to the hidden inputs userLat and userLon
						var userLatInput = document.getElementById("userLat");
						// the following if condition makes sure that the coordinates of the position are in the right projection (EPSG:4326, not EPSG:900913), it's not the best way of doing it, but it works
						if (position.lat > 10000 || position.lon < -10000) {
							userLatInput.value = tempPos.lat;
						} else {
							userLatInput.value = position.lat;
						}						
						var userLonInput = document.getElementById("userLon");
						if (position.lat > 10000 || position.lon < -10000) {
							userLonInput.value = tempPos.lon;
						} else {
							userLonInput.value = position.lon;
						}
						
						// assign the map's zoom level to the hidden input prevZoom
						var prevZoom = document.getElementById("prevZoom");
						prevZoom.value = map.zoom;
						
						// assign the map's center to the hidden input prevCent
						var prevCentLon = document.getElementById("prevCentLon");
						prevCentLon.value = map.center.lon;
						var prevCentLat = document.getElementById("prevCentLat");
						prevCentLat.value = map.center.lat;
						
						// submit the form, which reloads the page and queries the database based on the information saved to the hidden parameters
						// the user's location, map's zoom, and map's center is saved and restored on submission
						var form = document.getElementById("SearchForm");
						form.submit();
					}
				</script>
			</form> 
        
            <!--
            <button type="button" class="btn btn-default btn-lg" onclick="testloc()">Loc test 1</button>
            <button type="button" class="btn btn-default brn-lg" onclick="hideMarkers()">Hide test</button>
            <button type="button" class="btn btn-default brn-lg" onclick="eventTest()">Event test</button>    
            -->
       
        </div><!--end of collapse navbar-collapse-->   
    </div><!-- end of container-fluid -->

    <div id="map"></div>


<script type="text/javascript">
			
			// coords = (lat, lon) = (40, -86)
			//var userLat = 40.4258333;
			//var userLon = -86.9080556;
			
			// if it's possible and the user's browser supports it, grab the user's actual location
			if (navigator.geolocation) {
				navigator.geolocation.getCurrentPosition(showPosition);
			}				
			function showPosition(position) {
				userLat = position.coords.latitude;
				userLon = position.coords.longitude;
			}			
			var position = new OpenLayers.LonLat( userLon , userLat ).transform( fromProjection, toProjection);

			// create the map
			map = new OpenLayers.Map("map");
			// add the base layer to the map, using OpenLayer's map images
			// this can be changed to use GoogleMap's images, or MapQuest images, etc
			map.addLayer(new OpenLayers.Layer.OSM());
			
	
			// set the center and zoom of the map
			if (prevCenterLat == 0 || prevCenterLon == 0) {
				map.setCenter( position, zoom );
			} else {
				map.setCenter( new OpenLayers.LonLat( prevCenterLon , prevCenterLat ), zoom );
			}

			
			// create a point for the user's location and add it to the poiLayer
			var point = new OpenLayers.Geometry.Point( position.lon, position.lat );
			var userLoc = new OpenLayers.Feature.Vector(point, {userFeature: true}, {externalGraphic: 'img/marker.png', graphicHeight: 25, graphicWidth: 16});
			poiLayer.addFeatures(userLoc);
			
			// add the poiLayer to the map on top of the base layer
			map.addLayer(poiLayer);
			
			// define a drag listener for poiLayer
			var drag=new OpenLayers.Control.DragFeature(poiLayer,{    
				 'onDrag':function(feature, pixel){
						// if the feature that's being dragged is the user (the blue marker, not a red marker)
						if (feature.attributes.userFeature == true) {
							// drag the user's position
							position = new OpenLayers.LonLat( feature.geometry.x  , feature.geometry.y ).transform( toProjection, fromProjection);
						}
				 }
			});
			
			// define a select listener for poiLayer, if a feature is hovered over, call onPopupFeatureSelect(), if it's un-hovered-over, call onPopupFeatureUnselect()
			var selectControl  = new OpenLayers.Control.SelectFeature(poiLayer,{				
				onSelect: onPopupFeatureSelect,
				onUnselect: onPopupFeatureUnselect,
				hover: true
			});
			
			// add the drag listener to the map
			map.addControl(drag);
			drag.activate();
			
			// add the select listener to the map
			map.addControl(selectControl );
			selectControl.activate();
			
			
			function onPopupFeatureSelect(feature) {
				// if the feature being hovered-over is not the user
				if (feature.attributes.userFeature == false) {
					// don't let static markers be dragged by disabling the drag listener when a static marker is selected
					drag.deactivate();
					
					// display a pop-up that lists the location's name and type
					var popup = new OpenLayers.Popup.FramedCloud("popup",
						OpenLayers.LonLat.fromString(feature.geometry.toShortString()),
						null,
						"Name: " + feature.attributes.Name + "<br>Type: " + feature.attributes.Type,
						null,
						true,
						null
					);
					popup.autoSize = true;
					popup.maxSize = new OpenLayers.Size(400,800);
					popup.fixedRelativePosition = true;
					feature.popup = popup;
					map.addPopup(popup);
				}
			}
			function onPopupFeatureUnselect(feature) {
				// if the feature being un-hovered-over is not the user
				if (feature.attributes.userFeature == false) {
					// remove the popup
					map.removePopup(feature.popup);
					feature.popup.destroy();
					feature.popup = null;
					
					// reactivate the drag listener so the user marker (the blue marker) can be dragged
					drag.activate();
				} else {
					console.log("unselected user loc\n");
				}
			}

			
</script>

</body>


