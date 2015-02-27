<%@ page import="java.sql.Connection" %>
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
<title>CS490 My Mapper</title>



<script src="js/bootstrap.min.js"></script>
<script src="js/jquery-2.1.1.min.js"></script>
<script src="js/bootstrap-select.js"></script>




</head>


<script>
	
	var fromProjection = new OpenLayers.Projection("EPSG:4326");   // Transform from WGS 1984
	var toProjection   = new OpenLayers.Projection("EPSG:900913"); // to Spherical Mercator Projection
	

	var poiLayer = new OpenLayers.Layer.Vector("POIs");
	



</script>

<body onload="initialize()">


	<%
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
				if (name.length() != 0) {
					//out.print(String.format("%s<br />", name));
				}
				
				out.print(String.format("var tempLoc = new OpenLayers.LonLat( %f , %f ).transform( fromProjection, toProjection);\n", poiLon, poiLat));
				out.print("var tempPoint = new OpenLayers.Geometry.Point( tempLoc.lon, tempLoc.lat );\n");
				out.print(String.format("var poiFeature = new OpenLayers.Feature.Vector(tempPoint, {userFeature: false, Name:\"%s\", Type:'%s'}, {externalGraphic: 'img/marker2.png', graphicHeight: 25, graphicWidth: 16});\n", name, rs.getString("type")));
					
				out.print("poiLayer.addFeatures(poiFeature);\n");
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
                            <option value="defaultopts" selected>--Type of interests--</option>
                            <option value="restaurant">Restaurant</option>
                            <option value="fast_food">Fast Food</option>
                            <option value="library">Library</option>
                            <option value="school">School</option>
                            <option value="supermarket">Grocery Store</option>
                            <option value="hotel">Hotel</option>
                            <option value="fuel">Gas Station</option>
                            <option value="parking">Parking Lot</option>
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
					function search() {
					
						var type = document.getElementById("TypeChoice");
						var typeSelect = document.getElementById("TypeSelect");
						type.value = typeSelect.options[typeSelect.selectedIndex].value;
						
						
						var range = document.getElementById("RangeChoice");
						var rangeSelect = document.getElementById("RangeSelect");
						range.value = rangeSelect.options[rangeSelect.selectedIndex].value;
						
						var tempPos = new OpenLayers.LonLat( position.lon , position.lat ).transform( toProjection, fromProjection);
						
						var userLatInput = document.getElementById("userLat");
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
						
						var prevZoom = document.getElementById("prevZoom");
						prevZoom.value = map.zoom;
						
						var prevCentLon = document.getElementById("prevCentLon");
						prevCentLon.value = map.center.lon;
						var prevCentLat = document.getElementById("prevCentLat");
						prevCentLat.value = map.center.lat;
						
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
			if (navigator.geolocation) {
				navigator.geolocation.getCurrentPosition(showPosition);
			}				
			function showPosition(position) {
				userLat = position.coords.latitude;
				userLon = position.coords.longitude;
				console.log("(" + userLat + ", " + userLon + ")\n");
			}
			
			
			var position = new OpenLayers.LonLat( userLon , userLat ).transform( fromProjection, toProjection);

			
			
			map = new OpenLayers.Map("map");
			map.addLayer(new OpenLayers.Layer.OSM());
	
	
			if (prevCenterLat == 0 || prevCenterLon == 0) {
				map.setCenter( position, zoom );
			} else {
				map.setCenter( new OpenLayers.LonLat( prevCenterLon , prevCenterLat ), zoom );
			}

	
			var userLayer = new OpenLayers.Layer.Vector("Overlay");
			var point = new OpenLayers.Geometry.Point( position.lon, position.lat );
			var userLoc = new OpenLayers.Feature.Vector(point, {userFeature: true}, {externalGraphic: 'img/marker.png', graphicHeight: 25, graphicWidth: 16});
			poiLayer.addFeatures(userLoc);
			
			
			map.addLayer(poiLayer);
			//map.addLayer(userLayer);
			
			
			var drag=new OpenLayers.Control.DragFeature(poiLayer,{    
				 'onDrag':function(feature, pixel){
						if (feature.attributes.userFeature == true) {
							position       = new OpenLayers.LonLat( feature.geometry.x  , feature.geometry.y ).transform( toProjection, fromProjection);
						}
				 }
			});
			
			
			var selectControl  = new OpenLayers.Control.SelectFeature(poiLayer,{				
				onSelect: onPopupFeatureSelect,
				onUnselect: onPopupFeatureUnselect,
				hover: true
			});
			
			
			map.addControl(drag);
			drag.activate();
			
			
			map.addControl(selectControl );
			selectControl.activate();
			
			
			function onPopupFeatureSelect(feature) {
				if (feature.attributes.userFeature == false) {
					drag.deactivate();
					
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
			
				if (feature.attributes.userFeature == false) {
					map.removePopup(feature.popup);
					feature.popup.destroy();
					feature.popup = null;
					drag.activate();
				}
			}

			
</script>

</body>


