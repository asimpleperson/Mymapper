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

*/

public class ServletTest extends HttpServlet {

	Job job;
	
	@Override
	public void init(ServletConfig config) throws ServletException {	
	
		job = new Job();
		
	}
	
	
	@Override
	public void doGet(HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException {
		// Set the response message's MIME type.
		response.setContentType("text/html;charset=UTF-8");
		// Allocate a output writer to write the response message into the network socket.
		PrintWriter out = response.getWriter();
		
		
		out.print("<head>\n"
		+ "<meta name=\"CS490\" content=\"width=device-width, initial-scale=1.0\">\n"
		+ "<!-- Bootstrap -->\n"
		+ "<link href=\"css/bootstrap.css\" rel=\"stylesheet\" media=\"screen\">\n"
		+ "<link rel=\"stylesheet\" href=\"http://openlayers.org/en/v3.2.1/css/ol.css\" type=\"text/css\">\n"
		+ "<style>\n"
		+ "  .map {\n"
		+ "    height: 400px;\n"
		+ "    width: 100%;\n"
		+ "  }\n"
		+ "  .vertical-offset-100{\n"
		+ "    padding-top:100px;\n"
		+ "  }\n"
		+ "</style>\n"
		+ "<script src=\"http://www.openlayers.org/api/OpenLayers.js\"  type=\"text/javascript\"></script>\n"
		+ "<script src=\"http://openlayers.org/en/v3.2.1/build/ol.js\" type=\"text/javascript\"></script>\n"
		+ "<script type=\"text/javascript\" src=\"http://maplib.khtml.org/khtml.maplib/khtml_all.js\"> </script>\n"
		+ "<title>CS490 My Mapper</title>\n"
		+ "<script src=\"js/bootstrap.min.js\"></script>\n"
		+ "<script src=\"js/jquery-2.1.1.min.js\"></script>\n"
		+ "<script src=\"js/bootstrap-select.js\"></script>\n"
		+ "<script>\n"
		+ "	var fromProjection = new OpenLayers.Projection(\"EPSG:4326\");   // Transform from WGS 1984\n"
		+ "	var toProjection   = new OpenLayers.Projection(\"EPSG:900913\"); // to Spherical Mercator Projection\n"
		+ "	var poiLayer = new OpenLayers.Layer.Vector(\"POIs\");\n"
		+ "</script>\n"
		+ "</head>\n"
		+ "<body onload=\"initialize()\">\n");
		
		
		
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
				Connection con = null;
				ResultSet rs = null;
				try {
					String driverName = "org.apache.hive.jdbc.HiveDriver";
					Class.forName(driverName);
					
					con = DriverManager.getConnection("jdbc:hive2://sslab02.cs.purdue.edu:10000", "bpastene", "");

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
						
						out.print(String.format("var tempLoc = new OpenLayers.LonLat( %f , %f ).transform( fromProjection, toProjection);\n", poiLon, poiLat));
						out.print("var tempPoint = new OpenLayers.Geometry.Point( tempLoc.lon, tempLoc.lat );\n");
						out.print(String.format("var poiFeature = new OpenLayers.Feature.Vector(tempPoint, {userFeature: false, Name:\"%s\", Type:'%s'}, {externalGraphic: 'img/marker2.png', graphicHeight: 25, graphicWidth: 16});\n", name, rs.getString("type")));
							
						out.print("poiLayer.addFeatures(poiFeature);\n");
					}
				
				} catch (Exception e) {
					e.printStackTrace();
				}
			}
			
		}
		
		
		out.print(String.format("</script>\n"));
		
		out.print("<div class=\"container-fluid\">\n");
		out.print("        <!-- Brand and toggle get grouped for better mobile display -->   \n");
		out.print("        <div class=\"navbar-header\">\n");
		out.print("            <button type=\"button\" class=\"navbar-toggle collapsed\" data-toggle=\"collapse\" data-target=\"#bs-example-navbar-collapse-1\">\n");
		out.print("                <span class=\"sr-only\">Toggle navigation</span>\n");
		out.print("                <span class=\"icon-bar\"></span>\n");
		out.print("                <span class=\"icon-bar\"></span>\n");
		out.print("                <span class=\"icon-bar\"></span>\n");
		out.print("            </button>\n");
		out.print("            <a class=\"navbar-brand\">CS490</a>\n");
		out.print("        </div>\n");
		out.print("        <!-- Collect the search options -->\n");
		out.print("        <div class=\"collapse navbar-collapse\" id=\"bs-example-navbar-collapse-1\">\n");
		out.print("            <form id = \"SearchForm\" class=\"navbar-form navbar-left\" method=\"post\">\n");
		out.print("                <div class=\"form-group\">\n");
		out.print("                    <input type=\"hidden\" id=\"TypeChoice\" name=\"TypeChoice\" value=\"\" />\n");
		out.print("                        <select id = \"TypeSelect\" class=\"form-control\" name=\"select-type-of-interest\" onchange=\"dropdownTest(this.value)\">\n");
		out.print("                            <option value=\"defaultopts\" id=\"defaultopts\">--Type of interests--</option>\n");
		out.print("                            <option value=\"restaurant\" id=\"restaurant\">Restaurant</option>\n");
		out.print("                            <option value=\"fast_food\" id=\"fast_food\">Fast Food</option>\n");
		out.print("                            <option value=\"library\" id=\"library\">Library</option>\n");
		out.print("                            <option value=\"school\" id=\"school\">School</option>\n");
		out.print("                            <option value=\"supermarket\" id=\"supermarket\">Grocery Store</option>\n");
		out.print("                            <option value=\"hotel\" id=\"hotel\">Hotel</option>\n");
		out.print("                            <option value=\"fuel\" id=\"fuel\">Gas Station</option>\n");
		out.print("                            <option value=\"parking\" id=\"parking\">Parking Lot</option>\n");
		out.print("                            <option value=\"police\" id=\"police\">Police Car</option>\n");
		out.print("                            <option value=\"bus\" id=\"bus\">Bus</option>\n");
		out.print("                            <option value=\"taxi\" id=\"taxi\">Taxi</option>\n");
		out.print("                        </select>\n");
		out.print("                </div>\n");
		out.print("                <div class=\"form-group\">\n");
		out.print("                    <input type=\"hidden\" id=\"RangeChoice\" name=\"RangeChoice\" value=\" \" />\n");
		out.print("                            <select id = \"RangeSelect\" class=\"form-control\" name=\"select-range\" onchange=\"dropdownTest(this.value)\">\n");
		out.print("                            <option value=\"defaultopts\" selected>--Range--</option>\n");
		out.print("                            <option value=\"0.804672\">Within half a Mile</option>\n");
		out.print("                            <option value=\"1.60934\">Within 1 Mile</option>\n");
		out.print("                            <option value=\"3.21869\">Within 2 Miles</option>\n");
		out.print("                        </select>\n");
		out.print("                </div>\n");
		out.print("				<!--Search Button-->\n");
		out.print("				<button type=\"button\" class=\"btn btn-default btn-lg\" onclick=\"search()\">Search</button>\n");
		out.print("				<input type=\"hidden\" name=\"userLat\" id=\"userLat\" />\n");
		out.print("				<input type=\"hidden\" name=\"userLon\" id=\"userLon\" />\n");
		out.print("				<input type=\"hidden\" name=\"prevZoom\" id =\"prevZoom\" value=\"\" />\n");
		out.print("				<input type=\"hidden\" name=\"prevCenterLon\" id=\"prevCentLon\" value=\"\" />\n");
		out.print("				<input type=\"hidden\" name=\"prevCenterLat\" id=\"prevCentLat\" value=\"\" />\n");
		out.print("				<script>\n");
		out.print("					function search() {\n");
		out.print("						var type = document.getElementById(\"TypeChoice\");\n");
		out.print("						var typeSelect = document.getElementById(\"TypeSelect\");\n");
		out.print("						type.value = typeSelect.options[typeSelect.selectedIndex].value;\n");
		out.print("						var range = document.getElementById(\"RangeChoice\");\n");
		out.print("						var rangeSelect = document.getElementById(\"RangeSelect\");\n");
		out.print("						range.value = rangeSelect.options[rangeSelect.selectedIndex].value;\n");
		out.print("						var tempPos = new OpenLayers.LonLat( position.lon , position.lat ).transform( toProjection, fromProjection);\n");
		out.print("						var userLatInput = document.getElementById(\"userLat\");\n");
		out.print("						if (position.lat > 10000 || position.lon < -10000) {\n");
		out.print("							userLatInput.value = tempPos.lat;\n");
		out.print("						} else {\n");
		out.print("							userLatInput.value = position.lat;\n");
		out.print("						}\n");
		out.print("						var userLonInput = document.getElementById(\"userLon\");\n");
		out.print("						if (position.lat > 10000 || position.lon < -10000) {\n");
		out.print("							userLonInput.value = tempPos.lon;\n");
		out.print("						} else {\n");
		out.print("							userLonInput.value = position.lon;\n");
		out.print("						}\n");
		out.print("						var prevZoom = document.getElementById(\"prevZoom\");\n");
		out.print("						prevZoom.value = map.zoom;\n");
		out.print("						var prevCentLon = document.getElementById(\"prevCentLon\");\n");
		out.print("						prevCentLon.value = map.center.lon;\n");
		out.print("						var prevCentLat = document.getElementById(\"prevCentLat\");\n");
		out.print("						prevCentLat.value = map.center.lat;\n");
		out.print("						var form = document.getElementById(\"SearchForm\");\n");
		out.print("						form.submit();\n");
		out.print("					}\n");
		out.print("				</script>\n");
		out.print("			</form> \n");
		out.print("            <!--\n");
		out.print("            <button type=\"button\" class=\"btn btn-default btn-lg\" onclick=\"testloc()\">Loc test 1</button>\n");
		out.print("            <button type=\"button\" class=\"btn btn-default brn-lg\" onclick=\"hideMarkers()\">Hide test</button>\n");
		out.print("            <button type=\"button\" class=\"btn btn-default brn-lg\" onclick=\"eventTest()\">Event test</button>    \n");
		out.print("            -->\n");
		out.print("        </div><!--end of collapse navbar-collapse-->   \n");
		out.print("    </div><!-- end of container-fluid -->\n");
		out.print("    <div id=\"map\"></div>\n");
		out.print("<script type=\"text/javascript\">\n");
		
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
		
		out.print("			// coords = (lat, lon) = (40, -86)\n");
		out.print("			//var userLat = 40.4258333;\n");
		out.print("			//var userLon = -86.9080556;\n");
		out.print("			if (navigator.geolocation) {\n");
		out.print("				navigator.geolocation.getCurrentPosition(showPosition);\n");
		out.print("			}				\n");
		out.print("			function showPosition(position) {\n");
		out.print("				userLat = position.coords.latitude;\n");
		out.print("				userLon = position.coords.longitude;\n");
		out.print("				console.log(\"(\" + userLat + \", \" + userLon + \")\");\n");
		out.print("			}\n");
		out.print("			var position = new OpenLayers.LonLat( userLon , userLat ).transform( fromProjection, toProjection);\n");
		out.print("			map = new OpenLayers.Map(\"map\");\n");
		out.print("			map.addLayer(new OpenLayers.Layer.OSM());\n");
		out.print("			if (prevCenterLat == 0 || prevCenterLon == 0) {\n");
		out.print("				map.setCenter( position, zoom );\n");
		out.print("			} else {\n");
		out.print("				map.setCenter( new OpenLayers.LonLat( prevCenterLon , prevCenterLat ), zoom );\n");
		out.print("			}\n");
		out.print("			var userLayer = new OpenLayers.Layer.Vector(\"Overlay\");\n");
		out.print("			var point = new OpenLayers.Geometry.Point( position.lon, position.lat );\n");
		out.print("			var userLoc = new OpenLayers.Feature.Vector(point, {userFeature: true}, {externalGraphic: 'img/marker.png', graphicHeight: 25, graphicWidth: 16});\n");
		out.print("			poiLayer.addFeatures(userLoc);\n");
		out.print("			map.addLayer(poiLayer);\n");
		out.print("			//map.addLayer(userLayer);\n");
		out.print("			var drag=new OpenLayers.Control.DragFeature(poiLayer,{    \n");
		out.print("				 'onDrag':function(feature, pixel){\n");
		out.print("						if (feature.attributes.userFeature == true) {\n");
		out.print("							position       = new OpenLayers.LonLat( feature.geometry.x  , feature.geometry.y ).transform( toProjection, fromProjection);\n");
		out.print("						}\n");
		out.print("				 }\n");
		out.print("			});\n");
		out.print("			var selectControl  = new OpenLayers.Control.SelectFeature(poiLayer,{				\n");
		out.print("				onSelect: onPopupFeatureSelect,\n");
		out.print("				onUnselect: onPopupFeatureUnselect,\n");
		out.print("				hover: true\n");
		out.print("			});\n");
		out.print("			map.addControl(drag);\n");
		out.print("			drag.activate();\n");
		out.print("			map.addControl(selectControl );\n");
		out.print("			selectControl.activate();\n");
		out.print("			function onPopupFeatureSelect(feature) {\n");
		out.print("				if (feature.attributes.userFeature == false) {\n");
		out.print("					drag.deactivate();\n");
		out.print("					\n");
		out.print("					var popup = new OpenLayers.Popup.FramedCloud(\"popup\",\n");
		out.print("						OpenLayers.LonLat.fromString(feature.geometry.toShortString()),\n");
		out.print("						null,\n");
		out.print("						\"Name: \" + feature.attributes.Name + \"<br>Type: \" + feature.attributes.Type,\n");
		out.print("						null,\n");
		out.print("						true,\n");
		out.print("						null\n");
		out.print("					);\n");
		out.print("					popup.autoSize = true;\n");
		out.print("					popup.maxSize = new OpenLayers.Size(400,800);\n");
		out.print("					popup.fixedRelativePosition = true;\n");
		out.print("					feature.popup = popup;\n");
		out.print("					map.addPopup(popup);\n");
		out.print("				}\n");
		out.print("			}\n");
		out.print("			function onPopupFeatureUnselect(feature) {\n");
		out.print("				if (feature.attributes.userFeature == false) {\n");
		out.print("					map.removePopup(feature.popup);\n");
		out.print("					feature.popup.destroy();\n");
		out.print("					feature.popup = null;\n");
		out.print("					drag.activate();\n");
		out.print("				}\n");
		out.print("			}\n");
		out.print("</script>\n");
		out.print("</body>\n");		 

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
