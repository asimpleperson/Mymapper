
# this script parses the map.osm file and prints each location it contains to std out in the form:
# location_id~location_name~location_type~location_latitude~location_longitude\n

use Data::Dumper;
use XML::Simple;

# read the map date into a table of arrays ($data) and also into a table of hash tables ($dataHash)
# the map.osm data file needs to be in the same directory as this script
$fileName = "map.osm";
print STDERR "building data map...\n";
$data = XMLin($fileName, KeyAttr => [], ForceArray => ['node','way','tag','relation','nd']) or die "couldn't open file $fileName \n";
print STDERR "50% done\n";
$dataHash = XMLin($fileName) or die "couldn't open file $fileName \n";
print STDERR "100% done\n\n";

#iterate through all nodes
$count = 0;
foreach $node (@{$data->{node}}) {	
	
	$relevant = 0;
	# iterate through the node's properties
	foreach $tag (@{$node->{tag}}) {
		# if the node is a type we're interested in (a shop, or restaurant, etc) mark it as relevant
		if ($tag->{k} eq "amenity" || $tag->{k} eq "shop" || $tag->{k} eq "building" || $tag->{k} eq "tourism") {
			$relevant = 1;
		}
	}
	
	# if the node is relevant, write its properties to std out in the form id~type~name~lat~lon
	if ($relevant) {
		$count++;
		
		$name = "";
		$type = "";
		$lat = $node->{lat};
		$lon = $node->{lon};
		$id = $node->{id};	
		foreach $tag (@{$node->{tag}}) {
			if ($tag->{k} eq "amenity" || $tag->{k} eq "shop" || $tag->{k} eq "building" || $tag->{k} eq "tourism") {
				if ($tag->{v} ne "yes") {
					$type = $tag->{v};
				}
			} elsif ($tag->{k} eq "name") {
				$name = $tag->{v};
			}
		}
		
		if ($name eq "") {
			#print "id: " . $id . ", type: " . $type . ", (lat,long): (" . $lat . "," . $lon . ")\n";
			print "$id~~$type~$lat~$lon\n";
		} else {
			#print "id: " . $id . ", name: " . $name . ", type: " . $type . ", (lat,long): (" . $lat . "," . $lon . ")\n";
			print "$id~$name~$type~$lat~$lon\n";
		}
		
	}
}

# iterate through each waypoint
foreach $way (@{$data->{way}}) {	
	$relevant = 0;
	# iterate through the waypoint's properties
	foreach $tag (@{$way->{tag}}) {
		# if the waypoint is a type we're interested in (a shop, or restaurant, etc) mark it as relevant
		if ($tag->{k} eq "amenity" || $tag->{k} eq "shop" || $tag->{k} eq "building" || $tag->{k} eq "tourism") {
			$relevant = 1;
		}
	}
	
	if ($relevant) {
		$count++;
		
		$id = $way->{id};	
		$name = "";
		$type = "";		
		$lat = 0;
		$lon = 0;
		$n = 0;
		
		# calculate the average lat and long for all of the waypoint's points
		# a waypoint contains multiple geographic locations (ie: a road would have a point for each intersection, a square building would have a point for each corner)
		foreach $ref (@{$way->{nd}}) {
			$nodeId = $ref->{ref};
			$nodeLat = $dataHash->{node}->{$nodeId}->{lat};
			$nodeLon = $dataHash->{node}->{$nodeId}->{lon};
			$n++;
			$lat = $lat + $nodeLat;
			$lon = $lon + $nodeLon;
		}
		$lat = $lat / $n;
		$lon = $lon / $n;
		
		
		foreach $tag (@{$way->{tag}}) {
			if ($tag->{k} eq "amenity" || $tag->{k} eq "shop" || $tag->{k} eq "building" || $tag->{k} eq "tourism") {
				if ($tag->{v} ne "yes") {
					$type = $tag->{v};
				}
			} elsif ($tag->{k} eq "name") {
				$name = $tag->{v};
			}
		}
		
		if ($name eq "") {
			#print "id: " . $id . ", type: " . $type . ", (lat,long): (" . $lat . "," . $lon . ")\n";
			print "$id~~$type~$lat~$lon\n";
		} else {
			#print "id: " . $id . ", name: " . $name . ", type: " . $type . ", (lat,long): (" . $lat . "," . $lon . ")\n";
			print "$id~$name~$type~$lat~$lon\n";
		}
		
	}
}

print STDERR "\nlocations: $count\n";
