<?php

require_once 'header.php';


?>
	
<div id="map"></div>


<div id="map" class="map"></div>
    <script type="text/javascript">
      var openCycleMapLayer = new ol.layer.Tile({
  source: new ol.source.OSM({
    attributions: [
      new ol.Attribution({
        html: 'All maps &copy; ' +
            '<a href="http://www.opencyclemap.org/">OpenCycleMap</a>'
      }),
      ol.source.OSM.ATTRIBUTION
    ],
    url: 'http://{a-c}.tile.opencyclemap.org/cycle/{z}/{x}/{y}.png'
  })
});

var openSeaMapLayer = new ol.layer.Tile({
  source: new ol.source.OSM({
    attributions: [
      new ol.Attribution({
        html: 'All maps &copy; ' +
            '<a href="http://www.openseamap.org/">OpenSeaMap</a>'
      }),
      ol.source.OSM.ATTRIBUTION
    ],
    crossOrigin: null,
    url: 'http://tiles.openseamap.org/seamark/{z}/{x}/{y}.png'
  })
});


var map = new ol.Map({
  layers: [
    openCycleMapLayer,
    openSeaMapLayer
  ],
  target: 'map',
  controls: ol.control.defaults({
    attributionOptions: /** @type {olx.control.AttributionOptions} */ ({
      collapsible: false
    })
  }),
  view: new ol.View({
    maxZoom: 18,
    center: ol.proj.transform([ -86.9080556, 40.4258333], 'EPSG:4326', 'EPSG:3857'),
    zoom: 15
  })
});
    </script>


</body>








