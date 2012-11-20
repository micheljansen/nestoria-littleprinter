//= require listing_collection.js
//= require serp_map_view.js
//= require lib/jquery.history.js

var $j = jQuery;

// set up History.js
(function(window,undefined){
    var History = window.History;
    if ( !History.enabled ) {
        return false;
    }

    // Bind to StateChange Event
    History.Adapter.bind(window,'statechange',on_state_change);
})(window);


jQuery(document).ready(function($) {

  if($("body").hasClass("serp")) {
    init_serp();
    init_serp_content();
  }


});

// inits static parts of serp
function init_serp() {
  function replace_selects_with_slider($min_select, $max_select, $slider, $label, id) {
    var $min_options = $min_select.find("option");
    var $max_options = $max_select.find("option");

    var slider_values = $.map($min_options, function(opt) {return $(opt).val()});
    var min_idx = $.inArray($min_select.val()+"", $.map($min_options, function(opt) {return $(opt).val(); }))
    var max_idx = $.inArray($max_select.val()+"", $.map($max_options, function(opt) {return $(opt).val(); }))
    var slider_labels = $.map($min_options, function(opt) {return $(opt).text()});


    $slider.slider({
      range: true,
      min: 0,
      max: $max_options.size()-1,
      step: 1,
      values: [min_idx, max_idx],
      slide: function(event, ui) {
        // $("#bed-amount").html($($min_options[ui.values[0]]).html() +" - "+ $($min_options[ui.values[1]]).html());
        $label.html(format_slider_display_text(ui.values[0], ui.values[1], slider_labels, id));
        // debugger;
        return true;
      },
      change: function(event, ui) {
        $min_select.val($($min_options[ui.values[0]]).val());
        $max_select.val($($max_options[ui.values[1]]).val());
        dynamic_update();
      }
    });

    $label.html(format_slider_display_text(min_idx, max_idx, slider_values, id));
    $min_select.hide();
    $max_select.hide();
  }

  replace_selects_with_slider($("#min_beds_select"), $("#max_beds_select"), $("#bed-slider"), $("#bed-amount"), "beds");
  replace_selects_with_slider($("#min_price_select"), $("#max_price_select"), $("#price-slider"), $("#price-amount"), "price");

  $("#bath-slider").slider({
    range: true,
    min: 1,
    max: 6,
    values: [1, 6],
    slide: function(event, ui) {
      return $("#bath-amount").html("<em>" + ui.values[0] + " – " + ui.values[1] + "</em> bathrooms");
    },
    change: function() {
      flash_alert("the bathrooms slider does not work yet");
    }
  });
  $(".advanced-search").toggle((function() {
    $("section#advanced").slideDown(0, function() {});
    $("#results").animate({
      marginTop: "126px"
    }, 0);
    $("#sidebar").animate({
      top: "80px"
    }, 0);
    return $(this).html("&uarr;");
  }), function() {
    $("section#advanced").slideUp(0, function() {});
    $("#results").animate({
      marginTop: "50px"
    }, 0);
    $("#sidebar").animate({
      top: "0px"
    }, 0);
    return $(this).html("&darr;");
  });
  /*
  $(".draw a.bar").toggle((function(e) {
    e.preventDefault();
    return $(this).siblings(".content").show(0);
  }), function(e) {
    e.preventDefault();
    return $(this).siblings(".content").hide(0);
  });
  $(".draw a.bar").click(function(e) {
    e.preventDefault();
    $(".content").hide(0);
    return $(this).siblings(".content").show(0);
  });
  */
  $("#map_panel .content").show();

  var location = undefined;
  try {
    location = locals.response.locations[0];
  } catch(e) {}
  // todo only do this on serp
  try {
    window.temp_listings = new Nestoria.ListingCollection(locals.listings);
    window.serp_map_view = new Nestoria.SerpMapView({collection: temp_listings,
                                                    el: $("#main_map"),
                                                    location: location})
    serp_map_view.render();
    serp_map_view.refresh();
  }catch(e) {}

}

// inits dynamic parts of serp (results)
function init_serp_content() {
  // progressively enhance sort dropdown
  $("#update_sort").hide();

  $("#sort_input").change(function() {
    // $("#search_form").submit();
    dynamic_update();
  });

  $(".heart").toggle((function() {
    return $(this).addClass("has_heart");
  }), function() {
    return $(this).removeClass("has_heart");
  });

  var $pagination_links = $(".pagination a");
  $pagination_links.on("click", function() {
    window.scrollTo(0,0);
    dynamic_update_from_url($(this).attr("href"), true);
    return false;
  });

  var $property_type_links = $("#property_type_select a");
  $property_type_links.on("click", function() {
    window.scrollTo(0,0);
    $property_type_links.removeClass("active");
    $(this).addClass("active");
    dynamic_update_from_url($(this).attr("href"), true);
    return false;
  });


}

// use the form
function dynamic_update() {
  window.scrollTo(0,0);
  $("#loading_message").show();
  var $form = $("#search_form");
  var params = $form.serialize();
  $.ajax("/search", {data: params, success: dynamic_update_success});
}

// use a URL
function dynamic_update_from_url(url, worksyet) {
  if(!worksyet) {
    window.location = url;
  }
  window.scrollTo(0,0);
  $("#loading_message").show();
  $.ajax(url, {success: dynamic_update_success});
}

function dynamic_update_success(data, textStatus, jqXHR) {

  $('#results').html(data['results_html']);

  $(["property", "house", "flat"]).each(function(i, tp) {
    $("#other_type_"+tp).attr("href", data["other_urls"][tp]);
  });

  init_serp_content();
  window.temp_listings.reset(data.listings);
  // only re-center the map
  // if this was not an update triggered by the map
  // this is ugly and will surely be a cause for bugs later,
  // but hey, it's a prototype
  if(locals.location == data.location) {
    serp_map_view.refresh();
  }

  window.locals = data;
  window.temp_last_url = data.current_url;
  History.pushState({relative_url: data.current_url}, data.verbose_title, data.current_url);
}

function on_state_change() {
  var state = History.getState();

  if(!state.data || !state.data['relative_url']) {
    // console.log("no URL passed, doing hard reload");
    window.location = state.cleanUrl;
    return;
  }

  if(window.temp_last_url == state.data['relative_url']) {
    // console.log("ignoring change to existing state", window.temp_last_url);
    return;
  }

  dynamic_update_from_url(state.data['relative_url']);
}


function format_slider_display_text( lo, hi, aVals, id ) {
  var sName;


  if ( lo==hi && hi < aVals.length-1 ){
    if (id == "bed") {
      sName = "exactly";
    }
    else if (id == "room") {
      sName = "exactly";
    }
    else if ( lo==aVals.length-1 ){ 
      sName = id + '_maximum';
    }
    else if ( lo==0 ){ 
      sName = id + '_minimum'; 
    }
    else {
      sName='around';
    }
  }
  else if ( lo==0 ){
    if ( hi==aVals.length-1 ){
      sName='any';
    } else { 
      sName='lessthan';
    }
  }
  else if ( hi==aVals.length-1 ){
    sName='morethan';
  }
  else{
    sName='between';
  }
  var sTemp = String( locals.filters.sl_templates[sName] );
  var strFormatted = sTemp.replace(/LOWSLIDER/,aVals[lo]);
  var strFinal = strFormatted.replace(/HIGHSLIDER/,aVals[hi]);
  return strFinal;
}

function flash_alert(message) {
  $alert = $('<div style="display: none" id="flash_message"><div class="flash-notice">'+message+'</div></div>');
  $("body").append($alert);
  $alert.fadeIn(100).delay(1000).fadeOut(100, function() {$(this).remove()});
}
