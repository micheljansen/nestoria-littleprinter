//= require nestoria.js
//= require lib/underscore.js
//= require lib/backbone.js

window.Nestoria.SerpMapView = Backbone.View.extend({
    initialize: function() {

        // set up bindings

        // bind the functions 'add' and 'remove' to the view.
        _(this).bindAll('add', 'remove', 'reset', 'onOrientationChange', 'resizeToFit', 'onMapMove');

        // bind this view to the add and remove events of the collection!
        this.collection.bind('add'   , this.add   )
                       .bind('remove', this.remove)
                       .bind('reset' , this.reset );


        // set up the map
        var container = $(this.el);

        if ( ! container.length ){
            return;
        }

        this.markers = {};
        this._rendered = false;

        // todo: loading... content
        container.css({
            width: '100%', // todo: put in CSS file
            height: '100%'
        });

        // see http://leaflet.cloudmade.com/reference.html#map-options
        //TODO make the initial center sensible
        var map_options = {
            center: new L.LatLng(51.505, -0.09), // London
            zoom: 17,
            scrollWheelZoom: false
        };
        // .get() returns the DOM element
        this.map = new L.Map(container.get(0), map_options);

        this.location = this.options.location;

        // Google titles
        // var url = 'http://mt1.google.com/vt/hl=en&x={x}&y={y}&z={z}&s=',
            // attrib = 'Map data &copy;2012 Google',
            // openmq = new L.TileLayer(url, {zoom: 15, maxZoom: 18, attribution: attrib});

        // OpenMapQuest tiles
        var url = 'http://otile1.mqcdn.com/tiles/1.0.0/osm/{z}/{x}/{y}.png',
            attrib = 'Map data &copy; 2012 OpenStreetMap contributors, Imagery &copy; 2012 MapQuest',
            openmq = new L.TileLayer(url, {maxZoom: 18, attribution: attrib});

        this.map.addLayer(openmq);

        this.map.on("dragend", this.onMapMove );

    },
    render: function() {
        var self = this;
        var container = $(this.el);
        if ( ! container.length ){
            return;
        }

        if(!this._rendered) {
            // first time we need a full render
            this._rendered = true;

            // create markers and popups
            this.collection.each(function(l){
                self.add(l, true);
            });
        }
    },
    // add a marker for a listing to the map
    // l: the listing to add
    // silent: set to true to suppress refreshing the map
    add: function(l, silent) {
        if ( ! l.get('longitude') ){ return } // so they don't end up in the ocean

        var marker_icon = L.Icon.extend({
            // iconUrl: N.Conf['base_img_url'] + '/i/all/all/all/leaflet/marker.png',
            // shadowUrl: null
        });

        var marker = new L.Marker(
            new L.LatLng( l.get('latitude'), l.get('longitude'))
        );

        marker.bindPopup("<h2><a href='"+l.get("lister_url")+"'>"+l.get("title")+"</a> <span style='float:right'>"+l.get("nice_price")+"</span></h2><div>"+l.get("keywords")+"</div>");

        this.markers[l.get("id")] = marker;
        // marker.bindPopup(render_one_map_popup(l));
        this.map.addLayer(marker);

        if(!silent) {
            refresh();
        }
    },
    remove: function(l) {
        var marker = this.markers[l.get("id")];
        if(!marker) {
            // console.log("WARNING: tried to remove nonexsting marker for", l);
            return;
        }

        this.map.removeLayer(marker);

        delete this.markers[l.get("id")];
    },
    reset: function(new_collection) {
        var self = this;

        _(this.markers).each(function(marker) {
            self.map.removeLayer(marker);
        });

        this.markers = {};

        this.collection.each(function(l) {
            self.add(l, true);
        });

        this.render();
    },
    getLatLngs: function() {
        var c = this.collection
            .filter(function(l) { return l.has('latitude') && l.has('longitude')})
            .map(function(l) { return new L.LatLng(
                                                    l.get('latitude'),
                                                    l.get('longitude')); 
                                                });
        return c;
    },
    getMarkerBounds: function() {
        var bounds = new L.LatLngBounds(this.getLatLngs());

        if(this.location) {
          bounds.extend( new L.LatLng (this.location['center_lat'], this.location['center_long']) )
          // should set bouding box here, but it's not available in the public API
          /*
          c.push( new L.LatLng( N.Conf.search_location['min_lat'], N.Conf.search_location['min_long']) );
          c.push( new L.LatLng( N.Conf.search_location['min_lat'], N.Conf.search_location['max_long']) );
          c.push( new L.LatLng( N.Conf.search_location['max_lat'], N.Conf.search_location['min_long']) );
          c.push( new L.LatLng( N.Conf.search_location['max_lat'], N.Conf.search_location['max_long']) );
          */
        }

        return bounds;
    },
    getMapBounds: function() {
      return this.map.getBounds();
    },
    refresh: function() {
        // usuallly render() is called when the map is not visible
        // yet (height=0) and thus the bounds of the map and the
        // map markers are wrong
        // with refresh() we can align them again

        this.map._sizeChanged = true;
        this.map.fitBounds(this.getMarkerBounds().pad(.1));

        // _(this.markers).each(function(marker) {
        //     _fix_marker_image(marker);
        // });
    },
    // triggered on resize and orientationchange events. wait a bit and then resize the map, then scroll to top.
    onOrientationChange: function() {
    },
    onMapMove: function(e) {
      var bounds = this.getMapBounds().pad(-.1);
      var ne = bounds.getNorthEast();
      var sw = bounds.getSouthWest();
      var string = "coord_"+_([ne.lat, ne.lng, sw.lat, sw.lng]).join(',')
      $("#coordinate_input").val(string);
      dynamic_update();
    },
    resizeToFit: function() {
    },
    destroy: function() {
    }
});
