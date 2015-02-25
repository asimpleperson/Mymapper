/*!
* JqueryOpenStreetMap Pluggin v1.0
*
* This jquery plugin show a OpenStreetMap Layer map.
* Please see licence and documentation on https://github.com/apoutchika/JqueryOpenStreetMap
*/


(function($) {

    // Redirect error of function name
    $.fn.openStreeMap = function(p) {
        $(this).openStreetMap(p);
        return this;
    };


    $.fn.openStreetMap = function (p)
    {
        var mapId = 0;
        $(this).map(function(index, el){
            if ($(el).attr('id') == undefined) 
            {
                while ($('#ApoutchikaJqueryOpenStreetMap'+mapId).length != 0) 
                {
                    mapId++;
                } 
                $(el).attr('id', 'ApoutchikaJqueryOpenStreetMap'+mapId);
            }
            $(el).generateOpenStreetMap(p);
        });

        return this;
    };

    $.fn.generateOpenStreetMap = function (p)
    {
        if (p == undefined)
        {
            var p = {};
        }

        // Set the default zoom
        if (!p.zoom)
        {
            p.zoom = 1;
        }

        // If center is undefined
        if (!p.center)
        {
            p.center = {};
        }

        // Set the default lat
        if (!p.center.lat)
        {
            p.center.lat = 0;
        }

        // Set the default lng
        if (!p.center.lng)
        {
            p.center.lng = 0;
        }

        // Generate the map
        var map = khtml.maplib.Map(document.getElementById($(this).attr('id')));
        map.centerAndZoom(new khtml.maplib.LatLng(p.center.lat, p.center.lng), p.zoom);

        // Show the zoombar ?
        if (p.zoombar)
        {
            var zoominger = new khtml.maplib.ui.Zoombar();
            map.addOverlay (zoominger);
        }

        // Add a callback function when marker is draggend
        addCallbackFunction = function (id, func)
        {
            markers[id].addCallbackFunction( function() {
                var latLng = this.getPosition();	
                func({
                    lat: latLng.latitude,
                    lng: latLng.longitude
                });
            });	    
        }

        // generate a infobox for marker
        addInfobox = function (marker, infobox, open)
        {
            var infobox = new khtml.maplib.overlay.InfoWindow({content: infobox});
            marker.attachEvent( 'click', function() {
                infobox.open(map, this);
            });

            if (open==true)
            {
                infobox.open (map, marker);
            }
        }

        // place all markers
        var markers = [];
        for (var i in p.markers)
        {
            // The infos content the khtml marker, see khtml.maplib.overlay.Marker for more...
            var infos = {
                position: new khtml.maplib.LatLng(p.markers[i].pos.lat,p.markers[i].pos.lng),
                map: map,
                icon: {
                    url: "http://maps.gstatic.com/intl/de_de/mapfiles/ms/micons/red-pushpin.png",
                    size: {width: 26, height: 32},
                    origin: {x: 0, y: 0},
                    anchor: {x: -10,y: -32}
                },
                shadow: {
                    url: "http://maps.gstatic.com/intl/de_de/mapfiles/ms/micons/pushpin_shadow.png",
                    size: { width: 40,height: 32},
                    origin: {x: 0, y: 0},
                    anchor: {x: 0, y: -32 }
                },
            };

            // The marker is draggable ?
            if (p.markers[i].draggable)
            {
                infos.draggable = true;
            }

            // Add the title
            infos.title =  (p.markers[i].title) ? p.markers[i].title : 'Marker '+i;

            // Insert the marker in map
            markers[i] = new khtml.maplib.overlay.Marker(infos);

            // If a callback function is defined
            if (typeof (p.markers[i].draggend) == "function")
            {
                addCallbackFunction(i, p.markers[i].draggend);
            }

            // If the infobox is defined
            if (p.markers[i].infobox && p.markers[i].infobox.content)
            {
                var open = (p.markers[i].infobox.open) ? true : false;
                addInfobox(markers[i], p.markers[i].infobox.content, open);
            }	     
        }

        return this;
    };

})(jQuery);


